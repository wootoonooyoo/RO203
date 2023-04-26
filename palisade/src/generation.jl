"""
Running this file
-----------------
cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia/palisade/src")
include("generation.jl")


Theoretical formulation
-----------------------
To divide a 5 x 5 grid into 5 different partitions, we would lie to draw a hamiltonian path on the grid.
To do so, we would start off with a path that loos lie this (follow the increasing numbers):

    1   2   3   4   5
    10  9   8   7   6
    11  12  13  14  15
    20  19  18  17  16
    21  22  23  24  25
    
We will then implement the bacbiting algorithm to modify the hamiltonian path. This involves:
    - Choosing either one of the end points of the path randomly
    - Choosing a new edge randomly
    - At the destination node, among the 3 edges:
        1. Newly connected edge
        2. The desired edge to be ept
        3. Edge -- if unremoved -- would generate a cycle
        We will remove the 3rd edge.
    - Repeat until desired.

* - Bacbiting algorithm see here https://journals.aps.org/pre/abstract/10.1103/PhysRevE.74.051801

Upon doing so, we would follow the hamiltonian path from start to finish. For instance,
    First 5 blocs would be assigned to partition 1
    Next 5 blocs would be assigned to partition 2
    Subsequent 5 blocs would be assigned to partition 3
    et cetera

We would then have generated a 5 x 5 grid that may loo lie this: 

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

To form the puzzle, we would then randomly remove some coordinates and then replace in with 9 (to represent an unnown value).
For illustration purposes, we would use a hyphen - instead of 9.

    2 - - - 3
    - - - - 2
    - - 3 - -
    - 1 3 - -
    2 1 - 2 -


Implementation
--------------
We create a 5 x 5 node and connect the edges between them accordingly.
We then create a hamiltonian path and then apply the bacbiting algorithm to it.

   The initial path is arranged as followed


   1    2   3   4   5
   --------->-------|   
   6   7   8   9    10
   |--------<--------
   11   12  13  14  15
   ---------->-------|
   16   17  18  19  20
   |---------<--------
   21   22  23  24  25
   --------->--------

   1. We will add edges as followed
   2. We will add potential neighbours into another array to simplify calculations
"""


using Graphs
# using GraphMaie.NetworLayout
using Plots
using Compose, Cairo, Fontconfig

function removeEdge(g, origin::Int, dest::Int)

    # Remove the edge
    rem_edge!(g,origin,dest)

    # Chec if there's still a cycle
    if length(cycle_basis(g)[1]) > 0
        return false
    else
        return true
    end
    
end

function generateInstance(width::Integer = 5, height::Integer = 5, partition_size::Integer = 5, verbose::Bool = false)

    g = Graphs.grid([width,height])

    # Grab potential neighbours of each bloc
    potential_neighbours = []
    for i = 1:width*height
        push!(potential_neighbours,copy(neighbors(g,i)))
    end

    # Remove unnecessary edges to create a hamiltonian path as shown above
    for i = 1:width
        for j = 0:height-1

            # Don't remove the vertical lines at the edge
            if j % 2 != 0 && i != 1
                rem_edge!(g,width * j + i, width * (j+1) + i)
            end

            if j % 2 != 1 && i != width
                rem_edge!(g,width * j + i, width * (j+1) + i)
            end

        end
    end

    function backBite(g)
        # Perform the bacbiting algorithm

        # 1. Find where the end points of the path are (i.e. with one neighbour only)
        endpoints = []

        for i = 1:width*height
            if length(neighbors(g,i)) == 1
                push!(endpoints,i)
            end
        end

        # 2. Choose candidate node randomly
        candidate = endpoints[rand(1:length(endpoints))]

        # 3. Among the possible neighbours, gather the unused edges
        unused_edges = []
        for i = 1:length(potential_neighbours[candidate])
            if !has_edge(g,candidate,potential_neighbours[candidate][i])
                push!(unused_edges,copy(potential_neighbours[candidate][i]))
            end
        end

        # 4. Choose a random unused edge and add it to the graph
        destination = copy(unused_edges[rand(1:length(unused_edges))])
        add_edge!(g,candidate,destination)

        # 5. At the destination node, determine the neighbours now
        dest_edges = copy(neighbors(g,destination))

        # 6. Remove the origin from the dest_edges
        deleteat!(dest_edges, findall(x->x==candidate,dest_edges))

        # 7. Remove the edge that would generate a cycle
        # For each edge at the destination, chec if removing it will get rid of the cycle
        for i = 1:length(dest_edges)

            # Remove the edge
            rem_edge!(g,destination,dest_edges[i])

            # Chec for cycle
            if isempty(cycle_basis(g))
                break
            else
                # Add the edge bac
                add_edge!(g,destination,dest_edges[i])
            end

        end

        return g

    end

    # Randomise for a large number of times
    for i = 1:width * height * 137
        g = backBite(g)
    end

    # Trace the line from one end to the other
    headNode = []
    for i = 1:width*height
        if length(neighbors(g,i)) == 1
            push!(headNode,i)
            break
        end
    end

    # Follow the generated path then record the nodes it passes from start to end
    path = []
    currentNode = []

    for i = 1:width*height

        # Load initial values
        if i == 1
            global currentNode = headNode[1]
        end

        # Push into path array
        push!(path, currentNode)


        # Ensure it doesn't backtrack
        for i = 1:length(neighbors(g,currentNode))
            if neighbors(g,currentNode)[i] ∉ path
                global currentNode = neighbors(g,currentNode)[i]
                break
            end
        end
        
    end

    # Now with the hamiltonian path, we wish to give the first  nodes a value of 1 and the next  nodes a value of 2, etc
    # Create a 2D array to store the values
    block_grid = zeros(width,height)

    for i = 1:width*height
        block_grid[rem(path[i] - 1, width) + 1, fld(path[i] - 1, width) + 1] = cld(i,partition_size)
    end


    # Look at the grid with the contiguous blocks
    if (verbose)
        for i = 1:width
            for j = 1:height
                print(trunc(Int,block_grid[i,j]))
            end
            println()
        end
    end

    # Using the block_grid, we now change it to number_neighbours_grid
    # For each square, we count the number of neighbours around that have a different value to it
    number_neighbours_grid = zeros(width,height)

    for i = 1:width
        for j = 1:height

            local count = 0
            
            # if not top
            if j != 1
                if block_grid[i,j] != block_grid[i,j-1]
                    count += 1
                end
            end

            # if not bottom
            if j != height
                if block_grid[i,j] != block_grid[i,j+1]
                    count += 1
                end
            end

            # if not left
            if i != 1
                if block_grid[i,j] != block_grid[i-1,j]
                    count += 1
                end
            end

            # if not right
            if i != width
                if block_grid[i,j] != block_grid[i+1,j]
                    count += 1
                end
            end

            # record
            number_neighbours_grid[i,j] = count        

        end
    end

    # Look at the grid with the number of neighbours blocks
    if (verbose)
        println()
        println("Neighbouring Blocs without Walls")
        for i = 1:width
            for j = 1:height
                print(trunc(Int,number_neighbours_grid[i,j]))
            end
            println()
        end
    end

    # Add border walls
    for i = 1:width
        for j = 1:height

            # If on the top edge
            if j == 1
                number_neighbours_grid[i,j] += 1
            end

            # If on the bottom edge
            if j == height
                number_neighbours_grid[i,j] += 1
            end

            # If on the left edge
            if i == 1
                number_neighbours_grid[i,j] += 1
            end

            # If on the right edge
            if i == width
                number_neighbours_grid[i,j] += 1
            end

        end
    end

    # Look at the grid with the number of neighbours blocks
    if (verbose)
        println()
        println("Neighbouring Blocks with Walls")
        for i = 1:width
            for j = 1:height
                print(trunc(Int,number_neighbours_grid[i,j]))
            end
            println()
        end
    end

    blocks_to_remove = 0.6 * width * height

    while (blocks_to_remove > 0)
        x = rand(1:width)
        y = rand(1:height)

        if number_neighbours_grid[x,y] != 0
            number_neighbours_grid[x,y] = 0
            blocks_to_remove -= 1
        end
    end

    # Look at the grid with the number of neighbours blocks
    if(verbose)
        println()
        println("Removed")
        for i = 1:width
            for j = 1:height
                print(trunc(Int,number_neighbours_grid[i,j]))
            end
            println()
        end
    end

    # Write to a text file and prevent overwriting
    duplicate_number = 0
    filename = "../data_palisade/palisade.txt"

    while(isfile(filename)) 
        duplicate_number += 1
        filename = "../data_palisade/palisade" * string(duplicate_number) * ".txt"
    end

    io = open(filename, "w") 
    for j = 1:height
        for i = 1:width
            if trunc(Int,number_neighbours_grid[i,j]) == 0
                write(io," ")
            else
                write(io,string(trunc(Int,number_neighbours_grid[i,j])))
            end

            if i != width
                write(io,",")
            end
        end
        write(io,"\n")
    end

    close(io)

end

function generateDataSet(number_of_instances::Integer = 1, width::Integer = 5, height::Integer = 5, partition_size::Integer = 5, verbose::Bool = false)
    for i = 1:number_of_instances
        generateInstance(width,height,partition_size,verbose)
    end
end
