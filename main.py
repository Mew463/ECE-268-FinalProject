import time
import argparse
import random

def do_modular_multiplication(a, b, mod):
    return (a * b) % mod

def do_modular_exponentiation(a, b, mod):
    return (a^b) % mod

def do_modular_inverse_extended_euclidean(A, B):
    # Initialization
    Q, T = 0,0
    T1 = 0
    T2 = 1
    R = -1
    while True:
        R = A % B
        Q = A // B
        T = T1 - T2 * Q
        if (R == 0):
            return T2
            # We've finished
        else:
            A = B
            B = R
            T1 = T2 
            T2 = T
    
def generate_keys(p, q, e):
    """
    p, q = 2 primes 
    e = public exponent 
    returns json containing public and private key
    """
    n = p * q
    phi_n = (p-1)*(q-1)
    # Generate private key with mod inverse 
    d = do_modular_inverse_extended_euclidean(e, phi_n)
    return {
        "public_key" : (e, n),
        "private_key" : (d, n)
    }
    
def encrypt(pub_key, text):
    # return do_modular_exponentiation(pub_key[0], mes, pub_key[1]) # I think this works too
    return [pow(ord(c), pub_key[0], pub_key[1]) for c in text]

def decrypt(priv_key, cipher):
    # return do_modular_exponentiation(cipher, priv_key[0], priv_key[1]) # I think this works too
    return ''.join(chr(pow(c, priv_key[0], priv_key[1])) for c in cipher)

def extended_euclidean(a, b):
    if b == 0:
        return a, 1, 0
    
    gcd, x, y = extended_euclidean(b, a%b)

    x_r = y
    y_r = x - (a//b) * y

    return gcd, x_r, y_r

def is_prime(n, k=10): # Miller-Rabin Primality Test give probability if the number is prime (donno how it works but it should)
    if n <= 1 or n % 2 == 0:

def generate_large_prime(bits = 1024): # 1024 bit prime number, could be laarger if we want to make it larger
    

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
    

print(do_modular_inverse_extended_euclidean(640, 49))






# RSA Demo Bob sends a message to Alice

# First we want to choose a public key (n and e) as Alice which Bob should use
n = 
e = 


# Bob will then encrypt his message using Alice's public key components
original_message = "Hello this is Bob"
print(f"Bob wants to send {original_message} to Alice")
encrypted_message = ()      # Only Bob has this
print(f"Bob is actually sending {encrypted_message} on the channel")


# After sending the message on the channel, Alice (and anyone viewing the channel) sees Bob's encrypted message
message_to_decrypt = encrypted_message      # We assume the message is not tampered with




# As part of the key generation process, Alice will run a keygen to get her private key














sum_time = 0
num_iter = 10000
for i in range(num_iter):    
    start_time = time.perf_counter()          
    # do_modular_inverse_extended_euclidean(640, 49)
    extended_euclidean(640, 49)
    end_time = time.perf_counter()
    sum_time+=(end_time-start_time)
print(f"Karon's avg time measured: {sum_time/num_iter}")



sum_time = 0
num_iter = 10000
for i in range(num_iter):
    start_time = time.perf_counter()    
    # extended_euclidean(640, 49)
    do_modular_inverse_extended_euclidean(640, 49)
    end_time = time.perf_counter()
    sum_time+=(end_time-start_time)
print(f"Ming avg time measured: {sum_time/num_iter}")




# print(extended_euclidean(640, 49))