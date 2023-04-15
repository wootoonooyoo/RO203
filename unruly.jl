#cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia")
#include("XXXX.jl")

# want to write a function that takes in n as an argument where n must be even
function generateBoard(x::Int64)

    # check for even
    if x%2 != 0
        println("Please enter an even number")
        return error("not even")
    end

    # create a 2D array n x n
    board = zeros(Int8, x, x)

    # populate the 2D array
    board = [0 0 0 1 1 0; 
            -1 -1 0 0 0 0; 
            0 0 0 0 0 0; 
            -1 0 -1 -1 0 0; 
            0 0 0 0 -1 1; 
            1 0 -1 0 0 0]

    display(board)
end

## solve problem
using JuMP
using CPLEX
using Printf

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
    5. Custom-imposed constraints to increase difficulty
"""
n = 6
@variable(m, x[i = 1:n, j = 1:n], Bin)   # board

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

# constraint 5
@constraint(m, x[1,3] == 0)
@constraint(m, x[2,1] == 1)
@constraint(m, x[2,4] == 0)
@constraint(m, x[2,5] == 1)
@constraint(m, x[3,3] == 1)
@constraint(m, x[3,5] == 1)
@constraint(m, x[4,1] == 1)
@constraint(m, x[4,2] == 0)
@constraint(m, x[4,6] == 1)
@constraint(m, x[5,5] == 1)
@constraint(m, x[6,1] == 1)
@constraint(m, x[6,2] == 1)

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