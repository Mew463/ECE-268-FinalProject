# Our Project
We implemented the extended euclidean algorithm for computing the modular inverse. Our goal is to demonstrate our working functions by performing RSA encryption/decryption on the CPU and GPU and compare the result to see if GPU parallelism can speed up the process.

The CPU implementations were tested on a MacBook M3 Pro 18GB running Python 3.13.3 and a Ryzen 5 5600H with Python 3.13.7. The GPU implementation was completed with UCSD datahub's NVIDIA GeForce RTX 2080ti with CUDA Version 12.2. It is important to note that the GPU implementation is written in the native CUDA language. 

# Running on CPU
`python3 cpu_implementation.py`


# Compile and Run on Datahub GPU
`nvcc gpu_implementation.cu -o test && ./test`

