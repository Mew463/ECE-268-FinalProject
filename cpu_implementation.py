import time
import argparse
import random
import sys


verbose_print = False
num_errors = 0

def do_modular_multiplication(a, b, mod):
    return (a * b) % mod

def do_modular_exponentiation(a, b, mod):
    return pow(a, b, mod)

def do_modular_inverse_extended_euclidean(A, B):
    B_original = B

    T1 = 0
    T2 = 1

    while True:
        R = A % B
        Q = A // B

        T = T1 - T2 * Q

        if R == 0:
            return T2 % B_original

        A = B
        B = R
        T1 = T2
        T2 = T
    
def generate_keys(p, q, e) -> dict:
    """
    p, q = 2 primes 
    e = public exponent 
    returns json containing public and private key
    """
    n = p * q
    phi_n = (p - 1) * (q - 1)

    gcd, x, y = extended_euclidean(e, phi_n)

    if gcd != 1:
        raise ValueError("e and phi_n are not coprime")

    d = x % phi_n
    return {
        "public_key": (e, n),
        "private_key": (d, n)
    }
    
def encrypt(pub_key: tuple, text: str) -> list[int] :
    return [do_modular_exponentiation(ord(c), pub_key[0], pub_key[1]) for c in text]

def decrypt(priv_key: tuple, cipher: list[int]) -> str:
    return ''.join(chr(do_modular_exponentiation(c, priv_key[0], priv_key[1])) for c in cipher)

def extended_euclidean(a, b):
    if b == 0:
        return a, 1, 0
    
    gcd, x, y = extended_euclidean(b, a%b)

    x_r = y
    y_r = x - (a//b) * y

    return gcd, x_r, y_r

def is_prime(n, k=10): # Miller-Rabin Primality Test give probability if the number is prime (donno how it works but it should)
    if n <= 1 or n % 2 == 0:
        return False
    if n in (2,3):
        return True
    
    r,d = 0, n-1
    while d % 2 == 0:
        r += 1
        d //= 2
    
    for _ in range(k):
        a = random.randrange(2,n-2)
        x = pow(a,d,n)
        
        if x == 1 or x == n - 1:
            continue

        for _ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False

    return True

def generate_large_prime(bits = 2048): # 2048 bit prime number, could be larger if we want to make it larger
    while True:
        num = random.getrandbits(bits)
        num |= (1<<bits-1) | 1
        if is_prime(num):
            return num

# Some small primes we can mess with
primes = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 
    31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 
    127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 
    179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 
    233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 
    283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 
    353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 
    419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 
    467, 479, 487, 491, 499, 503, 509, 521, 523, 541
]
    
# large_primes = [generate_large_prime() for  _ in range(2)]
# print(large_primes)

# print(do_modular_inverse_extended_euclidean(640, 49))



def print_v(in_str):
    global verbose_print
    if(verbose_print):
        print(in_str)


def do_rsa(p,q):

    ############        ###############              ########
    ############        ###############             ##########
    ###     ###         ###                        ####    ####
    ###    ###          ###                       ####      ####          
    #########           ###############          ################
    ###    ###          ###############         ##################
    ###     ###                     ###        ####            ####                
    ###      ###                    ###       ####              ####          
    ###        ###      ###############      ####                ####            
    ###         ###     ###############     ####                  ####              

    ####################################
    ### Bob sends a message to Alice ###
    ####################################

    # First Alice chooses p and q compute n with, along with public exponent e

    e = 65537 # 65537 is commonly used because it is a prime
    keyset = generate_keys(p,q,e)
    n = keyset["public_key"][1]
    print_v(f"Alice publishes {n} and {e}")


    # Bob will then encrypt his message using Alice's public key components
    # original_message = "A"
    # original_message = "Hello this is Bob"
    original_message = """
    
        One morning, when Gregor Samsa woke from troubled dreams, he found
        himself transformed in his bed into a horrible vermin.  He lay on
        his armour-like back, and if he lifted his head a little he could
        see his brown belly, slightly domed and divided by arches into stiff
        sections.  The bedding was hardly able to cover it and seemed ready
        to slide off any moment.  His many legs, pitifully thin compared
        with the size of the rest of him, waved about helplessly as he
        looked.

        "What's happened to me?" he thought.  It wasn't a dream.  His room,
        a proper human room although a little too small, lay peacefully
        between its four familiar walls.  A collection of textile samples
        lay spread out on the table - Samsa was a travelling salesman - and
        above it there hung a picture that he had recently cut out of an
        illustrated magazine and housed in a nice, gilded frame.  It showed
        a lady fitted out with a fur hat and fur boa who sat upright,
        raising a heavy fur muff that covered the whole of her lower arm
        towards the viewer.

        Gregor then turned to look out the window at the dull weather.
        Drops of rain could be heard hitting the pane, which made him feel
        quite sad.  "How about if I sleep a little bit longer and forget all
        this nonsense", he thought, but that was something he was unable to
        do because he was used to sleeping on his right, and in his present
        state couldn't get into that position.  However hard he threw
        himself onto his right, he always rolled back to where he was.  He
        must have tried it a hundred times, shut his eyes so that he
        wouldn't have to look at the floundering legs, and only stopped when
        he began to feel a mild, dull pain there that he had never felt
        before.

    """


    print_v(f"Bob wants to send '{original_message}' to Alice")
    # encrypted_message = do_modular_exponentiation(original_message,e,n)      # Only Bob has this
    # print(keyset)
    encrypted_message = encrypt(keyset["public_key"], original_message)
    # print_v(f"Bob is actually sending '{encrypted_message}' on the channel")


    #################################################
    ### Alice recieves the message on the channel ###
    #################################################

    # After sending the message on the channel, Alice (and anyone viewing the channel) sees Bob's encrypted message
    message_to_decrypt = encrypted_message      # We assume the message is not tampered with
    # print_v(f"Alice recieves '{message_to_decrypt}' on the channel")

    # As part of the key generation process, Alice will run a keygen to get her private key
    keyset = generate_keys(p,q,e)
    d = keyset["private_key"][0]    # Only Alice will compute/ store this
    print_v(f"Alice generates private key {d}")

    # Alice then can decrypt the message, as she knows p,q,
    decrypted_message = decrypt(keyset["private_key"], message_to_decrypt)
    # decrypted_message = do_modular_exponentiation(message_to_decrypt,d,n)
    print_v(f"Alice decrypts Bob's message as: '{decrypted_message}'")
    
    global num_errors
    if(original_message != decrypted_message):
        print_v(f"Data ERROR: \n Original message: {original_message} \n Decrypted Message: {decrypted_message}")
        num_errors +=1

        


verbose_print = False

sum_time = 0
num_iter = 10
prime_size = 60
for i in range(num_iter):    
    p = generate_large_prime(prime_size)
    q = generate_large_prime(prime_size)
    start_time = time.perf_counter()          
    do_rsa(p=p,q=q)
    end_time = time.perf_counter()
    sum_time+=(end_time-start_time)
if(num_errors == 0):
    print("All data matched :D")
else:
    print(f"Detected {num_errors} :(")
print(f"RSA average time (ms): {1000 * sum_time/num_iter }")



# sum_time = 0
# num_iter = 10000
# for i in range(num_iter):
#     start_time = time.perf_counter()    
#     # extended_euclidean(640, 49)
#     do_modular_inverse_extended_euclidean(640, 49)
#     end_time = time.perf_counter()
#     sum_time+=(end_time-start_time)
# print(f"Ming avg time measured: {sum_time/num_iter}")




# # print(extended_euclidean(640, 49))