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


__global__ void gpu_matrix_mult(int *a, int *b, int *c, int m, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < m && col < m) {
        int sum = 0;
        for (int i = 0; i < n; i++) {
            sum += a[row * n + i] * b[i * m + col];
        }
        c[row * m + col] = sum;
    }
}

// non contiguous cannot be copied directly into GPU
// CUDA expects flat array (1 D)
// thats why this.
// 
std::vector<int> flatten(const std::vector<std::vector<int>>& mat) {
    int rows = mat.size();
    int cols = mat[0].size();

    std::vector<int> flat(rows * cols);

    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            flat[i * cols + j] = mat[i][j];

    return flat;
}

void cudaAddition(std::vector<int>& a, std::vector<int>& b, std::vector<int>& c) {
    int N = a.size();
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
    std::cerr << "...checking cuda errors for vector addition...\n";
    std::cerr << "Error code: " << err << "\n";
    std::cerr << "Error string: " << cudaGetErrorString(err) << "\n";

    // wait for GPU
    cudaDeviceSynchronize();

    cudaMemcpy(c.data(), d_c, N * sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
}

void cudaMatrixMultiplication(
    std::vector<std::vector<int>>& A,
    std::vector<std::vector<int>>& B,
    std::vector<std::vector<int>>& C,
    int m, int n
) {
    // Flatten matrices, as cuda need contagious memory 
    std::vector<int> flatA = flatten(A);   // m x n
    std::vector<int> flatB = flatten(B);   // n x m
    std::vector<int> flatC(m * m);

    int *d_a, *d_b, *d_c;

    cudaMalloc(&d_a, m * n * sizeof(int));
    cudaMalloc(&d_b, n * m * sizeof(int));
    cudaMalloc(&d_c, m * m * sizeof(int));

    cudaMemcpy(d_a, flatA.data(), m * n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, flatB.data(), n * m * sizeof(int), cudaMemcpyHostToDevice);

    dim3 threads(16, 16);
    dim3 blocks((m + 15) / 16, (m + 15) / 16);

    gpu_matrix_mult<<<blocks, threads>>>(d_a, d_b, d_c, m, n);    // check kernel errors
    
    
    cudaError_t err = cudaGetLastError();
    std::cerr << "...checking cuda errors for matrix multiplication...\n";
    std::cerr << "Error code: " << err << "\n";
    std::cerr << "Error string: " << cudaGetErrorString(err) << "\n";

    cudaDeviceSynchronize(); // wait for gpu

    cudaMemcpy(flatC.data(), d_c, m * m * sizeof(int), cudaMemcpyDeviceToHost);

    // Convert back to 2D, as per our requirement! 
    for (int i = 0; i < m; i++)
        for (int j = 0; j < m; j++)
            C[i][j] = flatC[i * m + j];

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
}

void showData(std::string& flag, vector<int>& nums, vector<vector<int>>& matrix) {
    if(flag == "-y") {
        std::cout << "\n-------------- VECTOR ADDITION RESULT --------------\n";
        printVector(nums);
        std::cout << "----------------------------------------------------";

        std::cout << "\n-------------- MATRIX MULTIPLICATION RESULT --------------\n";
        printMatrix(matrix);
        std::cout << "----------------------------------------------------------";
    }

}   

int main(int argc, char* argv[]) {
    int N;
    // std::vector<int> a, b, c;
    std::string flag;
    int m, n;
    try {
        if(argc != 5) throw std::invalid_argument("Invalid argument count");
        
        flag = argv[1];

        if (flag != "-y" && flag != "-n") throw invalid_argument("Invalid flag");

        N = std::stoi(argv[2]); if(N <= 0)  throw std::invalid_argument("Size must be positive");
        m = std::stoi(argv[3]); if(m <= 0) throw std::invalid_argument("Size must be positive");
        n = std::stoi(argv[4]); if((n <= 0)) throw std::invalid_argument("Size must be positive");

        std::cout << "Size: " << N << " |  m: " << m << " | n: " << n << std::endl;

    } catch (...) {
        std::cerr << "USAGE: ./out <show_vector_flag> <number_of_elements> <m> <n>" << std::endl;
        return 1;
    }

    /**
     * Variable names could have been better. 
     * TODO: rename variables to something insightful. (or leave it? who cares? I DO)
     */
    std::vector<int> a = getRandomVector(N);
    std::vector<int> b = getRandomVector(N);
    std::vector<int> c(N);
    std::vector<vector<int>> A = getRandomMatrix(m, n);
    std::vector<vector<int>> B = getRandomMatrix(n, m);
    std::vector<vector<int>> C(m, std::vector<int>(m));


    cudaAddition(a, b, c);
    cudaMatrixMultiplication(A, B, C, m, n);

    showData(flag, c, C);

    return 0;
}