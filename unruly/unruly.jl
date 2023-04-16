#cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia")
#include("XXXX.jl")

## solve problem
using JuMP
using CPLEX
using Printf
include("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/io.jl")


m = Model(CPLEX.Optimizer)

# Setup the problem
"""
Formulation of problem
----------------------
Variables:
    n = size of square (must be even)
    x_ij = {1 if white 0 if black} for i = 1 to n
Objective: Min sum of x_ij - n^2/2
Constraints: 
    1. sum of x_ij = n/2 for i = 1 to n
    2. sum of x_ij = n/2 for j = 1 to n
    3. 0 < sum of |x_ij + x_(i+1)j + x_(i+2)j| < 3 for i = 1 to n
    4. 0 <sum of |x_ij + x_i(j+1) + x_i(j+2)| < 3 for j = 1 to n
    5. Custom-imposed constraints according to a pre-defined board
"""

n = 6 # size of board
@variable(m, x[i = 1:n, j = 1:n], Bin) # x_ij = {1 if white 0 if black}
@objective(m, Min, sum(x[i, j] for i = 1:n for j = 1:n) - n^2/2)

# constraint 1
for i = 1:n
    @constraint(m, sum(x[i, j] for j = 1:n) == n/2)
end

# constraint 2
for j = 1:n
    @constraint(m, sum(x[i, j] for i = 1:n) == n/2)
end

# constraint 3
for i = 1:n
    for j = 1:n-2
        @constraint(m, sum(x[i, j] + x[i, j+1] + x[i, j+2]) >= 1)
        @constraint(m, sum(x[i, j] + x[i, j+1] + x[i, j+2]) <= 2)
    end
end

# constraint 4
for i = 1:n-2
    for j = 1:n
        @constraint(m, sum(x[i, j] + x[i+1, j] + x[i+2, j]) >= 1)
        @constraint(m, sum(x[i, j] + x[i+1, j] + x[i+2, j]) <= 2)
    end
end

# constraint 5 -- read the board and impose constraints
# Read instanceTest.txt
board = readInputFile("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/instanceTest.txt")
display(board)

# impose constraints accordingly
for i in 1:n
    for j in 1:n
        if board[i,j] == 1
            @constraint(m, x[i,j] == 1)
        elseif board[i,j] == 0
            @constraint(m, x[i,j] == 0)
        end
    end
end

# solve problem
optimize!(m)

# display solution
println("Objective value: ", objective_value(m))
for i = 1:n
    for j = 1:n
        @printf "%.0f " abs(value(x[i, j]))
    end
    println()
end