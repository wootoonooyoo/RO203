"""
Running this file
-----------------
cd("/Users/shawnliewhongwei/Desktop/JuliaTP/TP_Julia")
include("generation.jl")
"""


"""
Generate an instance of the game

Arguments
---------
n -- Size of the board
filename -- Name of the file to save the board to
"""
function generateInstance(n::Integer = 8, filename::String = "data/board.txt")

    # Check if argument is even
    if n % 2 != 0
        error("n must be even")
    end

    # create a 2d array of n x n with default values of 2
    board = fill(2, (n, n))

    count = 0
    board_validity = false
    while(!board_validity)

        i = 0
        while i < floor(2*n)
            
            # choose a random number from 1 to n^2 
            random_number = rand(0:n*n - 1)

            # convert the random number to a row and column
            row = trunc(Int, random_number/n) + 1
            col = random_number % n + 1

            # if the value of board at row and col is 2, then change it to 0 or 1
            black_or_white = rand(0:1)
            if board[row, col] == 2 
                board[row, col] = black_or_white
            end

            # prevent more than half of the squares in a row/column being the same colour
            count = 0
            count_subrule_validity = false
            for i in 1:n
                if board[row, i] == black_or_white
                    count += 1
                end
            end

            if count < n/2
                count_subrule_validity = true
            end

            for j in 1:n
                if board[j, col] == black_or_white
                    count += 1
                end
            end

            if count < n/2
                count_subrule_validity = true
            end

            # to check against the 3 consecutive squares rule, we will extract a 8x8 neighbourhood around the move
            # use the cplexSolve function
            if row - 3 < 1
                lower_row = 1
                upper_row = 8
            elseif row + 4 > n
                lower_row = n - 7
                upper_row = n
            else
                lower_row = row - 3
                upper_row = row + 4
            end

            if col - 3 < 1
                lower_col = 1
                upper_col = 8
            elseif col + 4 > n
                lower_col = n - 7
                upper_col = n
            else
                lower_col = col - 3
                upper_col = col + 4
            end

            sub_board = board[lower_row:upper_row, lower_col:upper_col]
            cplexSolve_subrule_validity = false
            cplexSolve_subrule_validity,_,_= cplexSolve(sub_board)

            if (cplexSolve_subrule_validity && count_subrule_validity)
                i += 1
            else 
                board[row, col] = 2 # undo move
            end

        end
        
        # solve the problem
        include("unruly.jl")
        board_validity,_,_ = cplexSolve(board)
        count += 1

        if count > 50
            error("Unable to generate a valid board")
        end

    end

    # Print board in txt file

    # Open and Prevent overwriting
    filename_new = filename
    count = 0
    while(isfile(filename_new))
        
        # split the string
        filename_split = split(filename, ".")
        filename_new = filename_split[1] * "_" * string(count) * "." * filename_split[2]

        # increment count
        count += 1
    end

    # Write to file
    io = open(filename_new, "w")
    for i in 1:n
        for j in 1:n
            write(io, Char(board[i, j]+'0'))
            if j != n
                write(io,',')
            end
        end
        write(io, "\n")
    end
    close(io)

    return nothing

end


"""
Generate multiple instances of the game

Arguments
---------
n -- Size of the board
num_instances -- Number of instances to generate
filename -- Name of the file to save the board to
"""

function generateDataSet(n::Integer = 8, num_instances::Integer = 1, filename::String = "data/board.txt",)

    for i = 1:num_instances
        generateInstance(n, filename)
    end

end

