# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using GLPK
include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(V)
    N = size(V,1)
    M = size(V,2)
    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))
    #m = Model(GLPK.Optimizer)

    # TODO
    println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")
    """
    Formulation of problem:
    -----------------------
    Constants: 
    N : height of the grid/ number of elements per block
    M : width of the grid/ nomber of blocks
    V : Matrix n*m containing the values of the initial neighbouring constraints in each case.
    
    Variables:
    X : N*M*M matrix indicating if the case (i,j) is in the k bloc by Xijk ==1, else 0
    A : N*M*4 matrix indicating if the case (i,j) is opened to its first,second,third or fourth neighbour (==1 if Y 0 else)
                 1
    such as : 4  i,j 2
                 3

    Constraints: 
    If Vij != -1 : Sum_p (Aijp) == 4-Vij : Number of neighbours matches the values
    Sum_(i,j) Xijk = n for all k : n cases in a block
    Sum_k Xijk = 1 for all i,j : every case has a unique block
    If Aijp == 1 : Xijk == X(p)k for all k : Neigbours in the same block
    """

    @variable(m, X[i = 1:N, j = 1:M,k = 1:M], Bin)
    @variable(m, A[i = 1:N, j = 1:M,p = 1:4], Bin)

    @objective(m,Min, sum(X[i, j, k] for i = 1:N for j = 1:M for k = 1:M))
    
    # Constraint 1:
    for i = 1:N 
        for j = 1:M
            if V[i,j] != -1
                @constraint(m, sum(A[i,j,p] for p= 1:4)== 4-V[i,j])
            end
        end
    end
    #Constraint 2
    for k = 1:M
        @constraint(m,sum(X[i,j,k] for i = 1:N for j=1:M)==N )
    end
    # Constraint 3 
    for i= 1:N
        for j = 1: M
            @constraint(m,sum(X[i,j,k] for k = 1:M)==1)
        end
    end

    # Constraint 4
    for i= 1: N 
        for j = 1: M
            if i>1 
                @constraint(m,sum(A[i,j,1]*(X[i-1,j,k] - X[i,j,k] + (1 - X[i-1,j,k])) for k = 1:M)<=1 )
            elseif i < N 
                @constraint(m,sum(A[i,j,3]*(X[i+1,j,k] - X[i,j,k] + (1 - X[i+1,j,k])) for k = 1:M)<=1 )
            elseif j>1
                @constraint(m,sum(A[i,j,4]*(X[i,j-1,k] - X[i,j,k] + (1 - X[i,j-1,k])) for k = 1:M)<=1 )
            elseif j<M
                @constraint(m,sum(A[i,j,2]*(X[i,j+1,k] - X[i,j,k] + (1 - X[i,j+1,k])) for k = 1:M)<=1 )
            end
        end
    end

    
    # Start a chronometer
    start = time()
    
    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    ### Si une solution est trouvé, l'afficher ainsi que la valeur de l'objectif associé
    if primal_status(m) == MOI.FEASIBLE_POINT
        println("Valeur de l'objectif : ",JuMP.objective_value(m))
    end
    return value.(X)
    #return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
