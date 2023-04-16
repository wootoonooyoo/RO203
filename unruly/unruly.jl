"""
Running this file
-----------------
cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia")
include("unruly.jl")
include("generation.jl")

[Eg usage]
cplexSolve(readInputFile("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/data/board.txt"))

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

using JuMP
using CPLEX
using Printf
using CSV

function cplexSolve(board::Matrix{Int64})

    include("io.jl")

    # Determining size of board
    n = first(size(board))

    # Formulation of problem   
    model = Model(CPLEX.Optimizer) 
    @variable(model, x[i = 1:n, j = 1:n], Bin) # x_ij = {1 if white 0 if black}
    @objective(model, Min, sum(x[i, j] for i = 1:n for j = 1:n) - n^2/2)

    # Constraint 1
    for i = 1:n
        @constraint(model, sum(x[i, j] for j = 1:n) == n/2)
    end

    # Constraint 2
    for j = 1:n
        @constraint(model, sum(x[i, j] for i = 1:n) == n/2)
    end

    # Constraint 3
    for i = 1:n
        for j = 1:n-2
            @constraint(model, sum(x[i, j] + x[i, j+1] + x[i, j+2]) >= 1)
            @constraint(model, sum(x[i, j] + x[i, j+1] + x[i, j+2]) <= 2)
        end
    end

    # Constraint 4
    for i = 1:n-2
        for j = 1:n
            @constraint(model, sum(x[i, j] + x[i+1, j] + x[i+2, j]) >= 1)
            @constraint(model, sum(x[i, j] + x[i+1, j] + x[i+2, j]) <= 2)
        end
    end

    # Constraint 5 -- read the board and impose constraints
    for i in 1:n
        for j in 1:n
            if board[i,j] == 1
                @constraint(model, x[i,j] == 1)
            elseif board[i,j] == 0
                @constraint(model, x[i,j] == 0)
            end
        end
    end

    # avoid verbose output
    # set_silent(model)

    # solve problem
    start_time = time()
    optimize!(model)
    end_time = time()

    time_taken = 0
    time_taken = end_time - start_time

    # check if solution exists
    if termination_status(model) == MOI.OPTIMAL

        return true, time_taken, x
        
    else
        println("Solution does not exist")
        return false, time_taken, x
    end
    
end

"""
Solve and record the solution of one instance of the game
"""
function recordInstance(filename::String = "data/board.txt")
    board = readInputFile(filename)
    isOptimal, time_taken, sol = cplexSolve(board)

    # create new txt file
    filename_split = split(filename, "/")
    filename_new = "res/" * filename_split[2]

    # # write to file
    io = open(filename_new, "w")

    # write solution
    n = first(size(board))
    display(sol[1,1])
    # print matrix
    for i = 1:n
        for j = 1:n
            write(io, string(trunc(Int,(abs(value(sol[i,j]))))))
            write(io, " ")
        end
        write(io, "\n")
    end

    # write is optimal and time taken
    write(io, "isOptimal = ")
    write(io, string(isOptimal))
    write(io, "\n")
    write(io, "time_taken = ")
    write(io, string(time_taken))
    write(io, "\n")
    close(io)

    # record results to summary file too
    io = open("res/summary.txt", "a")
    write(io,string(isOptimal))
    write(io,",")
    write(io, string(n))
    write(io,",")
    write(io,string(time_taken))
    write(io,",")
    write(io, filename)
    write(io,",")
    write(io, filename_new)
    write(io, "\n")
    close(io)


end

"""
Solve and record the solutions of all the puzzles in the folder
"""
function recordAllInstances()

    # get all the files in the folder
    files = readdir("data")

    # solve and record all the instances
    for file in files
        
        # only process files of .txt format
        if !endswith(file, ".txt")
            continue
        end
        println("Solving " * file)
        recordInstance("data/" * file)
    end


    # recordInstance("data/board_0.txt")
end


