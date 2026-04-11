#ifndef UTILS_HPP
#define UTILS_HPP

#include <iostream>
#include <omp.h>
#include <random>
#include <vector>
#include <climits>
#include <chrono>
#include <thread>
#include <string>
using namespace std;


vector<int> getRandomVector(int size);
void printVector(vector<int>& nums);

vector<vector<int>> getRandomMatrix(int m, int n);
void printMatrix(vector<vector<int>>& matrix);


#endif