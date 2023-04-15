
using JuMP
using CPLEX

m = Model(CPLEX.Optimizer)

# Define variables
n = 10
@variable(m, x[1:n], Int)
@variable(m, y >= 0)

# Define constraints
@constraint(m, x[1] + y >= 4)

# constraint for i from 1 to n/2
for i in 1:n/2
    @constraint(m, x[floor(Int,i)] + x[n-floor(Int,i)+1] <= n)
end

# constraint: sum of i divisible by 3 ≤1
@constraint(m, sum(x[i] for i in 1:n if i%3==0) <= 1)

# Define objective
@objective(m, Max, sum(x[i] for i in 1:n) - y)

# Resolve the model
optimize!(m)

# Récupération du status de la résolution
# Verifier qu'une solution existe et c'est optimale
isOptimal = termination_status(m) == MOI.OPTIMAL
solutionFound = primal_status(m) == MOI.FEASIBLE_POINT

if solutionFound

    # # Récupération des valeurs d’une variable
    for i in 1:n
        println(JuMP.value.(x[i]))
    end
    println(JuMP.value.(y))

    # Récupération de la valeur de l’objectif
    println("Solution")
    obj = JuMP.objective_value(m)

end