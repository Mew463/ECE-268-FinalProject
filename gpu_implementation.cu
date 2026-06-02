#include <stdio.h>
#include <cuda_runtime.h>

using bignum = __int128;

#define VERBOSE_PRINT = true;

__device__ void verbose_printf(const char* message) {
    if(threadIdx.x && VERBOSE_PRINT){
        printf("%s", message);
    }
}




__device__ bignum do_modular_multiplication( bignum a, bignum b, bignum mod) {
    return (a * b) % mod;
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

__device__ bignum encrypt( bignum e, bignum n, char message) {
    // __int128 big_message = (unsigned char)message;
    return do_modular_exponentiation((int)message, e, n);
}

__global__ void parallel_rsa_encrypt_decrypt(char *input_message,  int size_message, char *output_message,  bignum e,  bignum d,  bignum n) { // Function that all threads run 
    int tx = threadIdx.x;
    int bs = blockDim.x; // Num threads per block

    if (tx == 0) {
        verbose_printf("INPUT MESSAGE FROM GPU: \n");
        for (int i = 0; i < size_message; i++) {
            printf("%c", input_message[i]);
        }
        verbose_printf("\n");
    }
    __syncthreads();

    int chars_per_thread = ceilf(float(size_message) / float(bs));

    for(int i=0;i<chars_per_thread; i++){
        int idx = (i*bs)+tx;
        if(idx < size_message) {
            char input_char = input_message[idx]; 
            verbose_printf("INPUT CHAR: %c\n", input_char);
            bignum output = encrypt(e, n, input_char);
            char outChar = decrypt(d, n, output);
            verbose_printf("OUTPUT CHAR: %c\n", outChar);
            output_message[idx] = outChar;
        }
    }
    
    __syncthreads();
    if (tx == 0) {
        verbose_printf("OUTPUT MESSAGE FROM GPU: \n");
        for (int i = 0; i < size_message; i++) {
            printf("%c", output_message[i]);
        }
        verbose_printf("\n");
    }

}


VERBOSE_PRINT = true;


int main() {

    int NUM_TESTS = 10;
    float total_time = 0;
    for(int i =0; i<NUM_TESTS;i++){

        // GENERATE E , D ,and N
        bignum e = 65537;
        
        // bignum p = 9461917253336215331;
        // bignum q = 13954742674334932447;

        bignum p = 7;
        bignum q = 13;

        RSAKeyPair keys = generate_keys(p, q, e);
        bignum d = keys.private_key.exponent;
        bignum n = keys.private_key.modulus;

        printf("Launching kernel...\n");
        char original_message[] = "HELLO THIS IS BOBXYZabcdefghjijklmnopZYX";
        int size_message = sizeof(original_message) / sizeof(original_message[0]);
        char output_message[100];


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

        parallel_rsa_encrypt_decrypt<<<1, 32>>>(d_input, size_message, d_output, e, d, n);

        // Conclude timer operations
        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&test_time, start, stop);
        cudaEventDestroy(start);
        cudaEventDestroy(stop);
        cudaDeviceSynchronize();

        cudaMemcpy(output_message, d_output, size_message * sizeof(char), cudaMemcpyDeviceToHost);

        printf("TOOK %f SECONDS TO RUN THIS TEST");

        for(int char_num = 0; char_num<100;char_num++){
            printf("%d",int(output_message[char_num]));
        }
        // printf(output_message);

        // Update total accumulated time
        total_time+=test_time;
    }
    printf("Done.\n");
    printf("AVERAGE TIME ACROSS %d TESTS: %f ms\n",NUM_TESTS, ceilf(float(total_time)/float(NUM_TESTS)));
    return 0;
}