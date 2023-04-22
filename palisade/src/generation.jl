"""
Running this file
-----------------
cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/palisade/src")
include("generation.jl")
include("resolution.jl")


Theoretical formulation
-----------------------
To divide a 5 x 5 grid into 5 different partitions, we would like to draw a hamiltonian path on the grid.
To do so, we would start off with a path that looks like this (follow the increasing numbers):

    1   2   3   4   5
    10  9   8   7   6
    11  12  13  14  15
    20  19  18  17  16
    21  22  23  24  25
    
We will then implement the backbiting algorithm to modify the hamiltonian path. This involves:
    - Choosing either one of the end points of the path randomly
    - Choosing a new edge randomly
    - At the destination node, among the 3 edges:
        1. Newly connected edge
        2. The desired edge to be kept
        3. Edge -- if unremoved -- would generate a cycle
        We will remove the 3rd edge.
    - Repeat until desired.

* - Backbiting algorithm see here https://journals.aps.org/pre/abstract/10.1103/PhysRevE.74.051801

Upon doing so, we would follow the hamiltonian path from start to finish. For instance,
    First 5 blocks would be assigned to partition 1
    Next 5 blocks would be assigned to partition 2
    Subsequent 5 blocks would be assigned to partition 3
    et cetera

We would then have generated a 5 x 5 grid that may look like this: 

    1 1 1 2 3
    1 2 2 2 3
    1 2 5 5 3
    4 4 4 5 3
    4 4 5 5 3
        
For each coordinate, we would count the number of adjacent coordinates that do not have the same number.
For the example above, we would then have

    0 1 2 2 1
    1 2 2 2 1
    2 3 3 2 1
    1 1 3 2 1
    0 0 2 1 1

For the bordering coordinates, we would have to add +1 (if not a corner) and +2 (if a corner) due to the walls formed by the boundary.
For the example above, we would then have

    2 2 3 3 3
    2 2 2 2 2
    3 3 3 2 2
    2 1 3 2 2
    2 1 3 2 3

To form the puzzle, we would then randomly remove some coordinates and then replace in with 9 (to represent an unknown value).
For illustration purposes, we would use a hyphen - instead of 9.

    2 - - - 3
    - - - - 2
    - - 3 - -
    - 1 3 - -
    2 1 - 2 -


Implementation
--------------
We create a 5 x 5 node and connect the edges between them accordingly.
We then create a hamiltonian path and then apply the backbiting algorithm to it.
"""

# Create a graph with 25 vertices
g = SimpleGraph(25)

# Add edges
for i = 1:24
    add_edge!(g, i, i+1)
end

# To simplify calculations, we also add the list of possible neighbours for each vertex
# This is to simplify the backbiting algorithm
neighbours_all = Int64[]

for i = 1:25
    neighbours_all[i] 
end

# visualise the graph
# t = plot(g)

# We now start with the backbiting algorithm
head_end_array = Int64[]

for i = 1:25

    # If only one, add to head_end_array
    if length(neighbors(g, i)) == 1
        append!(head_end_array, i)
    end

end

println(head_end_array)

# Choose one of the elements randomly
candidate_node = head_end_array[rand(1:2)]

# From the candidate node, we will now choose to add an edge randomly.
