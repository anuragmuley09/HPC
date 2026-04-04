# HPC Practical Assignment 3 - **Parallel Reduction**


```text
Name:       Anurag Muley
Batch:      B2
CRN:        22120087
Subject:    HPC
Title:      HPC-Assign3- Parallel Reduction
```

## Problem Statement
Implement Min, Max, Sum and Average operations using Parallel Reduction.

## Parallel Reduction
Parallel Reduction is a foundational high performance computing technique which effectively combines multiple inputs such as min, max etc to produce a single output using parallel processing. 

It reduces `O(N)` sequential operations into `O(log N)` parallel steps. 

- uses *divide n conquer* approach, where pairs of intermediate results are combined in parallel until a single result is obtained. 


<div style="background: white; color: black;">
  <iframe 
    src="https://www.sciencedirect.com/topics/computer-science/parallel-reduction"
    width="1000" 
    height="800"
    style="filter: none !important;"
  ></iframe>
</div>

## what i understood
- parallel reduction is a computational pattern, which enables efficient aggregation of data elements. Like, sums, max, min etc. Across multiple processors or cores. 
- This pattern optimizes performance in large scale data processing. 
- sequential execution/reduction processes one element at a time, whereas parallel reduction restructures the computation into a reduction tree, basically allowing multiple reduction operations to be perform simultaneously at each step. 
- this reduces the number of operations, hence performance is increased. 

- ability to parallelize reduction computations depends on the mathematical property of the reduction operator, associativity and commutativity. 
- Associativity ensures that the grouping of operands does not affect the end result formally `(a.b).c == a.(b.c) ∀ a, b, c`
- Commutativity guarantees that the order of the operands can be changed without affecting the results. 
- These properties allow the reduction to be safely decomposed and executed in parallel without any ambiguity in final result. 





## compile and run
`g++ main.cpp "D:\8th SEM\HPC\HPC_CODES\utils.cpp" -o out` then `./out <flag> <size>`
