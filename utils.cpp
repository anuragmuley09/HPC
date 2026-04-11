#include "utils.hpp"


vector<int> getRandomVector(int size) {
    vector<int> nums;
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<int> dist(-1000, 1000); // INT_MAX + INT_MAX == long long 
    while(size--) nums.push_back(dist(gen));
    return nums;   
}

vector<vector<int>> getRandomMatrix(int m, int n) {
    vector<vector<int>> matrix;
    random_device rd;
    mt19937 gen(rd());
    uniform_int_distribution<int> dist(0, 100); // cause matrix mult will overload 'int', and not in a mood to use long long 
    vector<int> row;
    while(m--) {
        row.clear();
        for(int i=0;i<n;i++) row.push_back(dist(gen));
        matrix.push_back(row);
    } 
    return matrix;
}

void printVector(vector<int>& nums) {
    for(const int& num : nums) cout << num << " ";
    cout << "\n";
}

void printMatrix(vector<vector<int>>& matrix) {
    for(int i=0;i<matrix.size();i++) {
        for(int j=0;j<matrix[0].size();j++) {
            cout << matrix[i][j] << " ";
        } cout << endl;
    }
}