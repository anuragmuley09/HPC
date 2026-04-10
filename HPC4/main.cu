#include <iostream>
#include <vector>
#include <string>
#include <cuda_runtime.h>
#include "../utils.hpp"


__global__ void add(int *a, int *b, int *c, int N) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < N) {
        c[idx] = a[idx] + b[idx];
    }
}

int main(int argc, char* argv[]) {
    int N;
    // std::vector<int> a, b, c;
    string flag;
    try {
        if(argc != 3) throw std::invalid_argument("Invalid argument count");
        
        flag = argv[1];

        if (flag != "-y" && flag != "-n") throw invalid_argument("Invalid flag");

        N = std::stoi(argv[2]);

        if(N <= 0)  throw std::invalid_argument("Size must be positive");

        std::cout << "Size: " << N << std::endl;

    } catch (...) {
        std::cerr << "USAGE: ./out <show_vector_flag> <number_of_elements>" << std::endl;
        return 1;
    }


    std::vector<int> a = getRandomVector(N);
    std::vector<int> b = getRandomVector(N);
    std::vector<int> c(N);


    int *d_a, *d_b, *d_c;

    cudaMalloc(&d_a, N * sizeof(int));
    cudaMalloc(&d_b, N * sizeof(int));
    cudaMalloc(&d_c, N * sizeof(int));

    cudaMemcpy(d_a, a.data(), N * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b.data(), N * sizeof(int), cudaMemcpyHostToDevice);

    int threads = 256;
    int blocks = (N + threads - 1) / threads;

    add<<<blocks, threads>>>(d_a, d_b, d_c, N);

    // check kernel errors
    cudaError_t err = cudaGetLastError();
    std::cerr << "Error code: " << err << "\n";
    std::cerr << "Error string: " << cudaGetErrorString(err) << "\n";

    // wait for GPU
    cudaDeviceSynchronize();

    cudaMemcpy(c.data(), d_c, N * sizeof(int), cudaMemcpyDeviceToHost);


    if(flag == "-y") printVector(c);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

    return 0;
}