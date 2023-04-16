#cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia")
#include("XXXX.jl")

## solve problem
using JuMP
using CPLEX
using Printf
# include("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/io.jl")


m = Model(CPLEX.Optimizer)

"""
Formulation of problem
----------------------
Variables:
    n = size of original board
    i = integer [1:2*(n+1)]
    j = integer [1:2*(n+1)]
    k = integer [1:n]
    a_ij = {0, 1} for every i,j from [1:2n+1]
    v_ij = {1, ... , n} representing the block number
    c_ij = {0, 1, 2, 3} where 0 represents no constraint and 1,2,3 represent the number of edges of a node
Objective: Min sum over k of (sum over i,j of a_ijk - n)
Constraints: 
    1. 1 < v_ij < n
    2. count of (v_ij = k) = n for every k from [1:n] for every i and j in [2:2n] where i is even and j is even

    11. a_ij = 1 if i = 1 or if i = 2n+1 or if j = 1 or if j = 2n+1
    12. a_ij = a_i(j+2) if a_i(j+1) = 1 for every i,j from [2:2n] where i is even and j is even
    13. a_ij = a_(i+2)j if a_(i+1)j = 1 for every i,j from [2:2n] where i is even and j is even
    14. a_(i-2)j + a_(i+2)j + a_i(j-2) + a_i(j+2) = c_ij for every i,j from [2:2n] where i is even and j is even
"""

n = 5 # size of board
# edges and nodes
@variable(m, a[i = 1:2*n+1, j = 1:2*n+1], Bin) # a_ijk = {0, 1} for every i,j from [2:2n+1]
@variable(m, q[i = 2:2*n, j = 2:2*n], Int) # block 1

@objective(m, Max, sum(q[i,j] for i = 2:2*n for j = 2:2*n))

for i in 2:2*n
    for j in 2:2*n
        @constraint(m, 0 <= q[i,j] <= n)
    end
end

@constraint(m, sum(q[i,j] for i = 2:2*n for j = 2:2*n) == 5*n)



# solve problem
optimize!(m)

# check if solution exists
if termination_status(m) == MOI.OPTIMAL
    println("Optimal solution found")

    # print solution
    for i = 2:2*n
        for j = 2:2*n
            @printf("%.0f ", abs(value(q[i, j])))
        end
        println()
    end

else
    println("No solution found")
end
