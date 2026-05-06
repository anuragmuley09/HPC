#include <bits/stdc++.h>
#include <omp.h>
#include <chrono>

using namespace std;
using namespace chrono;

void printTraversal(const string &name, const vector<int> &order) {
    cout << name << " (" << order.size() << "): ";
    for (size_t i = 0; i < order.size(); i++) {
        if (i) cout << " ";
        cout << (order[i] + 1);
    }
    cout << "\n";
}

int serialTraverse(int start, int m, int n, bool dfs, vector<int> *order) {
    vector<char> visited(m * n, 0);
    deque<int> dq;
    visited[start] = 1;
    dq.push_back(start);
    int count = 0;

    while (!dq.empty()) {
        int node = dfs ? dq.back() : dq.front();
        if (dfs) dq.pop_back();
        else dq.pop_front();

        count++;
        if (order) order->push_back(node);

        int r = node / n;
        int c = node % n;

        auto try_push = [&](int nb) {
            if (!visited[nb]) {
                visited[nb] = 1;
                dq.push_back(nb);
            }
        };

        if (r > 0)     try_push(node - n);
        if (r < m - 1) try_push(node + n);
        if (c > 0)     try_push(node - 1);
        if (c < n - 1) try_push(node + 1);
    }
    return count;
}

int parallelTraverse(int start, int m, int n, bool dfs, vector<int> *order) {
    vector<atomic<uint8_t>> visited(m * n);
    for (auto &v : visited) v.store(0, memory_order_relaxed);

    vector<int> frontier, next_frontier;
    visited[start].store(1, memory_order_relaxed);
    frontier.push_back(start);
    int count = 0;

    while (!frontier.empty()) {
        int fsize = static_cast<int>(frontier.size());
        count += fsize;
        if (order) order->insert(order->end(), frontier.begin(), frontier.end());

        int nthreads = omp_get_max_threads();
        vector<vector<int>> local_nexts(nthreads);

        #pragma omp parallel for schedule(static)
        for (int i = 0; i < fsize; i++) {
            int tid = omp_get_thread_num();
            int node = frontier[i];
            int r = node / n;
            int c = node % n;

            auto try_push = [&](int nb) {
                uint8_t expected = 0;
                if (visited[nb].compare_exchange_strong(expected, 1, memory_order_relaxed)) {
                    local_nexts[tid].push_back(nb);
                }
            };

            if (r > 0)     try_push(node - n);
            if (r < m - 1) try_push(node + n);
            if (c > 0)     try_push(node - 1);
            if (c < n - 1) try_push(node + 1);
        }

        next_frontier.clear();
        if (dfs) {
            for (int t = nthreads - 1; t >= 0; t--)
                next_frontier.insert(next_frontier.end(), local_nexts[t].begin(), local_nexts[t].end());
        } else {
            for (auto &v : local_nexts)
                next_frontier.insert(next_frontier.end(), v.begin(), v.end());
        }
        frontier.swap(next_frontier);
    }
    return count;
}

int main(int argc, char* argv[]) {
    if (argc != 3) { cout << "Usage: ./out m n\n"; return 0; }

    int m = stoi(argv[1]), n = stoi(argv[2]);
    long long totalNodes = 1LL * m * n;
    bool printTraversalFlag = (totalNodes <= 1000);
    cout << "Grid: " << m << " x " << n << "\n";
    cout << "Threads: " << omp_get_max_threads() << "\n\n";

    int start = 0;

    vector<int> bfs_s_order, bfs_p_order, dfs_s_order, dfs_p_order;
    vector<int> *bfs_s_ptr = printTraversalFlag ? &bfs_s_order : nullptr;
    vector<int> *bfs_p_ptr = printTraversalFlag ? &bfs_p_order : nullptr;
    vector<int> *dfs_s_ptr = printTraversalFlag ? &dfs_s_order : nullptr;
    vector<int> *dfs_p_ptr = printTraversalFlag ? &dfs_p_order : nullptr;

    auto t1 = high_resolution_clock::now();
    int bfs_s = serialTraverse(start, m, n, false, bfs_s_ptr);
    auto t2 = high_resolution_clock::now();

    auto t3 = high_resolution_clock::now();
    int bfs_p = parallelTraverse(start, m, n, false, bfs_p_ptr);
    auto t4 = high_resolution_clock::now();

    auto t5 = high_resolution_clock::now();
    int dfs_s = serialTraverse(start, m, n, true, dfs_s_ptr);
    auto t6 = high_resolution_clock::now();

    auto t7 = high_resolution_clock::now();
    int dfs_p = parallelTraverse(start, m, n, true, dfs_p_ptr);
    auto t8 = high_resolution_clock::now();

    cout << "Visited nodes (all should match):\n";
    cout << "  Serial BFS:   " << bfs_s << "\n";
    cout << "  Parallel BFS: " << bfs_p << "\n";
    cout << "  Serial DFS:   " << dfs_s << "\n";
    cout << "  Parallel DFS: " << dfs_p << "\n";

    if (printTraversalFlag) {
        cout << "\nTraversal order (1-based node ids):\n";
        printTraversal("Serial BFS", bfs_s_order);
        printTraversal("  Parallel BFS", bfs_p_order);
        printTraversal("  Serial DFS", dfs_s_order);
        printTraversal("  Parallel DFS", dfs_p_order);
    } else {
        cout << "\nTraversal order skipped (m*n > 1000).\n";
    }

    cout << "\nExecution Time:\n";
    cout << "  Serial BFS:   " << duration<double>(t2 - t1).count() << " sec\n";
    cout << "  Parallel BFS: " << duration<double>(t4 - t3).count() << " sec\n";
    cout << "  Serial DFS:   " << duration<double>(t6 - t5).count() << " sec\n";
    cout << "  Parallel DFS: " << duration<double>(t8 - t7).count() << " sec\n";

    return 0;
}

