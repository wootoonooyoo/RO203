"""
Running this file
-----------------
cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/palisade/src")
include("io.jl")
include("generation.jl")
include("flowContiguity.jl")

[Eg usage]
cplexSolve(readInputFile("../data_palisade/Instance_1_5_5.txt"))

"""

using JuMP
using CPLEX


function cplexSolve()

    """
    Formulation of problem
    ----------------------
    We assume that this is a n x n grid.

    Variables:
        c_i = value of node i
        x_i = 1 if chosen for inclusion, 0 otherwise
        w_i = 1 if node is chosen as sink, 0 otherwise
        y_ij ≥ 0 ~~ non-negative continuous variable indicating the amount of flow from node i to node j
        M = number of units to be included in the contiguous area

    Objective:
        Min sum_i x_i * i        

    Constraints:
        1. sum_i w_i = 1 # only one sink in the network
        2. [y_i(j-1) + y_i(j+1) + y_i(j-n) + y_i(j+n)] - [y_(j-1)i + y_(j+1)i + y_(j-n)i + y_(j+n)i] = 0 for each i
        3. [y_i(j-1) + y_i(j+1) + y_i(j-n) + y_i(j+n)] ≤ (M-1) * x_i

        [Including Additional Constraints for Singles]
        4. sum_i 

    """
    

    # Create the model
    model = Model(CPLEX.Optimizer)

    n = 5
    M = 4 # number of units to be included in the contiguous area (excluding the sink)
    custom_sink = 1 # if 0, then no custom sink is chosen
    
    # Define the variables
    @variable(model, x[i = 1:n*n], Bin)
    @variable(model, w[i = 1:n*n], Bin)
    @variable(model, y[i = 1:n*n, j = 1:n*n] >= 0)

    v1 = [1 1 1 1 1]
    v2 = [1 1 1 1 1]
    v3 = [1 1 1 1 1]
    v4 = [1 1 1 1 1]
    v5 = [1 1 1 1 1]

    v = hcat(v1,v2,v3,v4,v5)

    # Print v
    for i in 1:n*n
        print(v[i]," ")
        if i%n == 0
            println()
        end
    end

    print(v[4]==1)

    c1 = [1 9 4 1 2]
    c2 = [3 4 1 1 2]
    c3 = [1 4 9 1 3]
    c4 = [1 1 1 1 1]
    c5 = [7 4 2 3 1]

    c = hcat(c1,c2,c3,c4,c5)

    # Define the objective function
    @objective(model, Min, sum(c[i]*x[i] for i = 1:n*n))

    # Define the constraints

    # Define a custom sink if necessary
    if custom_sink != 0
        @constraint(model, w[custom_sink] == 1)   
    else
        @constraint(model, sum(w[i] for i = 1:n*n) == 1)
    end

    # Ensure that a block (i,j) cannot be both a dependent unit and a sink at the same time
    for i in 1:n*n
        @constraint(model, sum(w[i] + x[i]) <= 1)
    end

    
    # Evaluate the neighbouring positions
    # We add a modification depending on the matrix of V (validity)
    # If the neighbouring position is not valid, then we do not include it in the sum
    for i in 1:n*n

        # compute general case
        sum_constraint_3 = 0
    
        # if not left-most column
        if i % n != 1 && v[i-1] == 1
            sum_constraint_3 += y[i,i-1]
        end
        
        # If not right-most column
        if i % n != 0 && v[i+1] == 1
            sum_constraint_3 += y[i, i+1]
        end

        # If not top-most column
        if i > n && v[i-n] == 1
            sum_constraint_3 += y[i,i-n]
        end

        # If not bottom-most column
        if i <= n*(n-1) && v[i+1] == 1
            sum_constraint_3 += y[i,i+n]
        end   

        @constraint(model, sum_constraint_3 <= (M-1) * x[i]) 
    end

    for i in 1:n*n

        # compute general case
        difference_of_sum = 0
        
        # if not left-most column
        if i % n != 1 && v[i-1] == 1
            difference_of_sum += y[i,i-1] - y[i-1,i]
        end
        
        # If not right-most column
        if i % n != 0 && v[i+1] == 1
            difference_of_sum += y[i, i+1] - y[i+1,i]
        end

        # If not top-most column
        if i > n && v[i-n] == 1
            difference_of_sum += y[i,i-n] - y[i-n,i]
        end

        # If not bottom-most column
        if i <= n*(n-1) && v[i+n] == 1
            difference_of_sum += y[i,i+n] - y[i+n,i]
        end    

        @constraint(model, difference_of_sum == x[i] - M * w[i])
    end

    
    # Optimise
    optimize!(model)

    # Print the objective value and the solution
    println("Objective value: ", objective_value(model))

    println("\nc")
    for i = 1:n*n
        print(trunc(Int,value(c[i])))
        print(" ")
        if i%n == 0 
            println()
        end
    end


    println("\nSolution")
    for i = 1:n*n

        if trunc(Int,value(x[i])) == 1
            print(trunc(Int,value(x[i])))
        elseif trunc(Int,value(w[i])) == 1
            print(trunc(Int,value(w[i])))
        else
            print("0")
        end
        print(" ")

        if i%n == 0 
            println()
        end
    end





    

end

