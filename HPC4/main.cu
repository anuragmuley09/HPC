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



























/**
 * OUTPUT:
 * D:\8th SEM\HPC\HPC_CODES\HPC4>out -y 100 16 16
Size: 100 |  m: 16 | n: 16
...checking cuda errors for vector addition...
Error code: 0
Error string: no error
...checking cuda errors for matrix multiplication...
Error code: 0
Error string: no error

-------------- VECTOR ADDITION RESULT --------------
715 -1383 113 1030 -144 -568 603 959 -1028 786 122 -853 1 1686 1614 1157 -102 953 -212 -1421 473 168 953 1023 -16 -58 -662 -752 -368 373 -522 1006 678 282 526 -1344 -93 -325 -521 -300 398 -928 -1036 131 -1520 -722 45 -914 734 -304 107 -221 -906 104 -643 -692 -1051 -987 -110 -302 -996 -1111 -545 490 584 410 -252 238 -1354 -9 -491 344 -497 -526 481 233 -816 -1902 481 147 -1888 181 -122 970 71 237 155 1326 692 296 -956 -97 -1148 1450 -168 -1057 235 741 -540 594
----------------------------------------------------
-------------- MATRIX MULTIPLICATION RESULT --------------
43189 43502 48275 53342 36618 35804 46458 49692 42107 44136 46964 47560 40899 51975 44010 51747
25253 33152 37906 39155 30977 25367 37653 32169 30087 28066 35166 31245 36017 42317 33068 39611
27855 33528 31956 27929 22167 21860 27664 26869 30117 22672 31936 34902 27522 36451 28271 34583
35624 35180 41836 46199 30505 35386 42004 43432 34497 31444 40488 36576 31772 44399 37547 47235
36815 32911 28671 33764 31105 21272 30248 37200 30555 34622 29827 28499 33669 35165 39449 39971
29935 36358 31793 34603 29369 32757 40191 38208 32139 29152 36896 37046 38435 41822 39361 38416
30487 32569 34178 33508 24285 28065 33256 30852 30772 19587 31757 33568 27280 35838 29271 36083
26906 28030 33583 29095 26010 31107 33058 32047 26887 27142 35272 31003 24140 38793 28063 30859
44401 45764 45561 38307 33519 37294 52147 38669 39855 36616 46905 48732 43937 53324 39252 42100
33619 38243 48539 49549 36918 39732 52171 49763 40127 39542 44421 46311 35837 51695 38818 46706
28587 36263 38418 45383 32199 35862 44553 42215 39219 33042 39267 39931 36161 45229 40325 45374
33966 35182 43421 46960 33613 30578 41909 39652 34941 26133 35712 41068 30858 39658 35362 45395
33125 35897 31580 35546 30264 26558 34083 30387 32167 33374 32500 32293 31420 44318 37271 40990
24573 31352 28612 34136 22864 28055 31718 29772 26143 28823 27044 34431 23376 35556 27895 30187
38497 34664 31411 36932 25655 29417 36876 37413 33973 32431 39499 33020 36932 38571 42486 41734
32512 35040 38369 40078 29348 32587 40239 36279 37376 27752 31378 38382 28928 47772 31187 42159
----------------------------------------------------------
D:\8th SEM\HPC\HPC_CODES\HPC4>
 */