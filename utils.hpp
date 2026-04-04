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


#endif