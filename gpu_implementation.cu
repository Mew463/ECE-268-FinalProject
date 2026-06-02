#include <stdio.h>
#include <cuda_runtime.h>
#include <cstdint>
#include <random>
#include <inttypes.h>

using bignum = __int128;

__device__ void print_int128(__int128 x) {

    if (x == 0) {
        printf("0");
        return;
    }

    if (x < 0) {
        printf("-");
        x = -x;
    }

    char buf[50];
    int i = 0;

    while (x > 0) {
        buf[i++] = '0' + (int)(x % 10);
        x /= 10;
    }

    while (i > 0) {
        printf("%c", buf[--i]);
    }
}

__device__ bignum do_modular_multiplication( bignum a, bignum b, bignum mod) {
    bignum result = 0;
    a %= mod;

    while (b > 0) {
        if (b & 1)
            result = (result + a) % mod;

        a = (a + a) % mod;
        b >>= 1;
    }

    return result;
}



__device__ bignum do_modular_exponentiation( bignum a, bignum b, bignum mod ) { // Performs square and multiply real fast
    bignum result = 1;
    a = a % mod;
    while (b > 0) {
        // If b is odd
        if (b & 1) {
            result = do_modular_multiplication(
                result,
                a,
                mod
            );
        }
        b >>= 1;
        a = do_modular_multiplication(
            a,
            a,
            mod
        );
    }
    return result;
}

bignum extended_euclidean(bignum a, bignum b, bignum *x, bignum *y) {

    if(b == 0){
        *x = 1;
        *y = 0;
        return a;
    }

    bignum x1, y1;
    bignum gcd = extended_euclidean(b, a%b, &x1, &y1);

    *x = y1;
    *y = x1 - (a/b) * y1;  
    
    return gcd; 

}

std::mt19937_64 rng(std::random_device{}());

uint64_t random64()
{
    return rng();
}
bignum mod_mul(bignum a, bignum b, bignum mod) //cpu version
{
    bignum result = 0;
    a %= mod;

    while (b > 0){
        if (b & 1)
            result = (result + a) % mod;

        a = (a + a) % mod;
        b >>= 1;
    }
    return result;
}


bignum mod_exp( bignum a, bignum b, bignum mod ) { //cpu version
    bignum result = 1;
    a = a % mod;
    while (b > 0) {
        // If b is odd
        if (b & 1) {
            result = mod_mul(
                result,
                a,
                mod
            );
        }
        b >>= 1;
        a = mod_mul(
            a,
            a,
            mod
        );
    }
    return result;
}

// MILLER-RABIN for large prime generation ;)

bool is_prime(uint64_t n, int rounds = 10)
{
    if (n < 2) return false;
    if (n == 2 || n == 3) return true;
    if (n % 2 == 0) return false;

    uint64_t d = n - 1;
    int r = 0;

    while ((d & 1) == 0)
    {
        d >>= 1;
        r++;
    }

    std::uniform_int_distribution<uint64_t> dist(2, n - 2);

    for (int i = 0; i < rounds; i++)
    {
        uint64_t a = dist(rng);

        uint64_t x = mod_exp(a, d, n);

        if (x == 1 || x == n - 1)
            continue;

        bool witness = true;

        for (int j = 0; j < r - 1; j++)
        {
            x = mod_mul(x, x, n);

            if (x == n - 1)
            {
                witness = false;
                break;
            }
        }

        if (witness)
            return false;
    }

    return true;
}


uint64_t generate_prime(int bits = 64)
{
    while (true)
    {
        uint64_t num = random64();

        if (bits < 64)
            num &= ((1ULL << bits) - 1);

        num |= (1ULL << (bits - 1)); // ensure top bit
        num |= 1ULL;                 // ensure odd

        if (is_prime(num))
            return num;
    }
}


typedef struct{
    bignum exponent;
    bignum modulus;
}PublicKey;

typedef struct{
    bignum exponent;
    bignum modulus;
}PrivateKey;

typedef struct{
    PublicKey public_key;
    PrivateKey private_key;
}RSAKeyPair;

RSAKeyPair generate_keys(bignum p, bignum q, bignum e){
    RSAKeyPair keys;
    bignum n = p*q;
    bignum phi_n = (p-1)*(q-1);

    bignum x, y;

    bignum gcd = extended_euclidean(e, phi_n, &x, &y);
    
    if(gcd != 1){
        printf("Error: e and phi_n are not coprime! ;( \n");
    }
    
    bignum d = (x % phi_n + phi_n) % phi_n; // c++ doesn't have a clean mod so we need to do this

    keys.public_key.exponent = e;
    keys.public_key.modulus = n;
    keys.private_key.exponent = d;
    keys.private_key.modulus = n;
    
    return keys;
}


__device__ char decrypt( bignum d,  bignum n,  bignum c) {
    return do_modular_exponentiation(c, d, n);  
}

__device__ bignum encrypt( bignum e, bignum n, unsigned char message) {
    // __int128 big_message = (unsigned char)message;
    return do_modular_exponentiation((int)message, e, n);
}

__global__ void parallel_rsa_encrypt_decrypt(char *input_message,  int size_message, char *output_message,  bignum e,  bignum d,  bignum n) { // Function that all threads run 
    int tx = threadIdx.x;
    int bs = blockDim.x; // Num threads per block

    int chars_per_thread = ceilf(float(size_message) / float(bs));

    printf("size_msg: %d,  chars_per:%d\n",size_message,chars_per_thread);

    for(int i=0;i<chars_per_thread; i++){
        int idx = (i*bs)+tx;
        if(idx < size_message) {
            char input_char = input_message[idx];

            bignum output = encrypt(e, n, input_char);

            char outChar = decrypt(d, n, output);
            
            output_message[idx] = outChar;
            printf("INPUT: %c\n",input_char);
            printf("OUTPUT: %c\n",outChar);
            
        }
    }

}





int main() {

    int msg_size = 0;
    int num_errors = 0;
    int NUM_TESTS = 1;
    float total_time = 0;
    char original_message[] = "Hello this is bruh.";
    // char original_message[] = 
    //     "One morning, when Gregor Samsa woke from troubled dreams, he found"
    //     "himself transformed in his bed into a horrible vermin.  He lay on"
    //     "his armour-like back, and if he lifted his head a little he could"
    //     "see his brown belly, slightly domed and divided by arches into stiff"
    //     "sections.  The bedding was hardly able to cover it and seemed ready"
    //     "to slide off any moment.  His many legs, pitifully thin compared"
    //     "with the size of the rest of him, waved about helplessly as he"
    //     "looked."

    //     "'What's happened to me?' he thought.  It wasn't a dream.  His room,"
    //     "a proper human room although a little too small, lay peacefully"
    //     "between its four familiar walls.  A collection of textile samples"
    //     "lay spread out on the table - Samsa was a travelling salesman - and"
    //     "above it there hung a picture that he had recently cut out of an"
    //     "illustrated magazine and housed in a nice, gilded frame.  It showed"
    //     "a lady fitted out with a fur hat and fur boa who sat upright,"
    //     "raising a heavy fur muff that covered the whole of her lower arm"
    //     "towards the viewer."

    //     "Gregor then turned to look out the window at the dull weather."
    //     "Drops of rain could be heard hitting the pane, which made him feel"
    //     "quite sad.  How about if I sleep a little bit longer and forget all"
    //     "this nonsense, he thought, but that was something he was unable to"
    //     "do because he was used to sleeping on his right, and in his present"
    //     "state couldn't get into that position.  However hard he threw"
    //     "himself onto his right, he always rolled back to where he was.  He"
    //     "must have tried it a hundred times, shut his eyes so that he"
    //     "wouldn't have to look at the floundering legs, and only stopped when"
    //     "he began to feel a mild, dull pain there that he had never felt"
    //     "before.";
    int size_message = sizeof(original_message) / sizeof(original_message[0]) - 1;
    msg_size = size_message;
    char output_message[2000];

    for(int i =0; i<NUM_TESTS;i++){

        // GENERATE E , D ,and N
        bignum e = 65537;
        
        // bignum p = 958475160727834319;
        // bignum q = 879811033379399741;
        // bignum p = generate_prime(60);
        // bignum q = generate_prime(60);
        // // printf("P: %d and q %d", p);
        // printf("P: %" PRIu64 ", and ", p);
        // printf("q:   %" PRIu64 "\n", q);

        bignum p = 13;
        bignum q = 131;

        RSAKeyPair keys = generate_keys(p, q, e);
        bignum d = keys.private_key.exponent;
        bignum n = keys.private_key.modulus;

        printf("Launching kernel...\n");
        
        
    
        char *d_input;
        char *d_output;
        
        cudaMalloc(&d_input, size_message * sizeof(char));
        cudaMalloc(&d_output, size_message * sizeof(char));
        
        cudaMemcpy(d_input, original_message, size_message * sizeof(char), cudaMemcpyHostToDevice);
                
        // Begin timer operations
        float test_time = 0;
        cudaEvent_t start, stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        cudaEventRecord(start, 0);
        
        // Run Kernel
        int numThreads = 6000;
        int numBlocks = 1;

        parallel_rsa_encrypt_decrypt<<<numBlocks, numThreads>>>(d_input, size_message, d_output, e, d, n);

        // Conclude timer operations
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&test_time, start, stop);
        cudaEventDestroy(start);
        cudaEventDestroy(stop);
        cudaDeviceSynchronize();

        cudaMemcpy(output_message, d_output, size_message * sizeof(char), cudaMemcpyDeviceToHost);

        // Update total accumulated time
        total_time+=test_time;

        // Verify message
        if(strcmp(original_message,output_message) != 0){
            num_errors++;
            for(int z = 0; z < msg_size; z++ ){
                printf("%c", original_message[z]);
            }
            for(int z = 0; z < msg_size; z++ ){
                printf("%c", output_message[z]);
            }
        }

    }
    printf("Done.\n");

    
    for(int z = 0; z < msg_size;z++ ){
        printf("%d", (int)output_message[z]);
    }

    if(num_errors == 0){
        printf("Data Matched ! :D\n");
    } else {
        printf("Detected %d errors :(\n", num_errors);
    }

    printf("AVERAGE TIME ACROSS %d TESTS: %f ms\n", NUM_TESTS, (double)ceilf(float(total_time)/float(NUM_TESTS)));
    return 0;
}