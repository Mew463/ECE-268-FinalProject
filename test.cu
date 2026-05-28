#include <stdio.h>
#include <cuda_runtime.h>

__global__ void hello_kernel() {
    printf("Hello from GPU thread %d\n", threadIdx.x);
}

int main() {
    printf("Launching kernel...\n");

    hello_kernel<<<1, 8>>>();

    cudaDeviceSynchronize();

    printf("Done.\n");

    return 0;
}