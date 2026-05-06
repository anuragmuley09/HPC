#include <iostream>
#include <vector>
#include <omp.h>
#include <climits>
#include "../utils.hpp"

using namespace std;

int main(int argc, char* argv[]) {

    int size;
    vector<int> nums;
    try {
        if (argc != 3) throw invalid_argument("Invalid argument count");

        string flag = argv[1];

        if (flag != "-y" && flag != "-n") throw invalid_argument("Invalid flag");

        size = stoi(argv[2]);

        if (size <= 0) throw invalid_argument("Size must be positive");
        
        cout << "Flag: " << flag << endl;
        cout << "Size: " << size << endl;

        nums = getRandomVector(size);

        if(flag == "-y") printVector(nums);

    } catch (...) {
        cerr << "USAGE: ./out <show_vector_flag> <number_of_elements>" << endl;
        return 1;
    }


    int min_val = INT_MAX;
    int max_val = INT_MIN;
    long long sum = 0;

    // Parallel Reduction for multiple operations simultaneously
    // why to write 3 for-loops when you can do job in one lol
    #pragma omp parallel for reduction(min:min_val) reduction(max:max_val) reduction(+:sum)
    for (int i = 0; i < size; i++) {
        min_val = min(min_val, nums[i]);
        max_val = max(max_val, nums[i]);
        sum += nums[i];
    }

    double average = (double)sum / size;

    cout << "Min: " << min_val << endl;
    cout << "Max: " << max_val << endl;
    cout << "Sum: " << sum << endl;
    cout << "Average: " << average << endl;

    return 0;
}
