# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
#using GLPK
include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve4(V)
    N = size(V,1)
    M = size(V,2)
    # Create the model
    m = Model(CPLEX.Optimizer)
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
    Y : N*M*N*M*M matrix such as Y[a,b,c,d,k] =  X[a,b,k] * X[c,d,k] ==1 iff 2 cases are neighbours in the same region 

    Constraints: 
    
    """

    @variable(m, X[i = 1:N, j = 1:M,k = 1:M], Bin)
    @variable(m, Y[a = 1:N, b = 1:M,c=1:N,d=1:M, k = 1:M], Bin) 

    @objective(m,Min, sum(X[i, j,k] for i = 1:N for j = 1:M for k = 1:M))
    
    # Constraint 1:
    
    # ça marche
    #Constraint 2
    for k = 1:M
        @constraint(m,sum(X[i,j,k] for i = 1:N for j=1:M)==N )
        # marche bien
    end
    # Constraint 3 
    for i= 1:N
        for j = 1: M
            @constraint(m,sum(X[i,j,k] for k = 1:M)==1)
            # marche bien
            if V[i,j]!=-1
                @constraint(m,sum(Y[i,j,a,b,k] for a = 1:N for b =1:M for k = 1:M if  abs(i-a) + abs(b-j) == 1)==4-V[i,j]) 
            else 
                @constraint(m,sum(Y[i,j,a,b,k] for a = 1:N for b =1:M for k = 1:M if a!=i && b!=j)>=1)
                @constraint(m,sum(Y[i,j,a,b,k] for a = 1:N for b =1:M for k = 1:M if a!=i && b!=j)<=4)
            end
        end
    end


    for a = 1:N, b = 1:M, c = 1:N, d = 1:M, k = 1:M
        #if abs(a-c) + abs(b-d) != 1 || (a!=c || b!=d)
        #    @constraint(m, Y[a,b,c,d,k] == 0) #si non voisines alors Y nul pour tout k
        #end
        @constraint(m,Y[a,b,c,d,k]-Y[c,d,a,b,k]==0) # symétrie
    end
    # pas de mur entre deux cases de la même région
    for i = 1:N
        for j = 1:M
            for k = 1:M
                #@constraint(m, Y[i,j,i,j,k] == 1) # case non voisine avec elle même
            end
        end
    end
    
    
    # Constraint 4
    for i= 1: N 
        for j = 1: M
            for a= 1:N
                for b = 1: M
                    for k= 1:M
                        @constraint(m,Y[i,j,a,b,k]-X[i,j,k]<=0)
                        #@constraint(m,Y[i,j,a,b,k]-X[a,b,k]<=0)
                        @constraint(m,Y[i,j,a,b,k]-X[i,j,k]-X[a,b,k]+1>=0)
                    end      
                end
            end
        end
    end

    # Constraint 5 
  

    
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
    return  value.(X) 
    #return value.(A) 
    #return value.(Y1)
    #return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end

"""
    changebloc(B, k,l){
    n = size(B,1)
    m = size(B,2)
    min= min(k,l)
    for i=1:n
        for j=1:m
            if B[i,j]==k | B[i,j]==l
                B[i,j]=min
   

Heuristically solve an instance
"""
function mini(k,l)
    if k<l
        min = k
    else 
        min = l
    end
    return min
end

function changebloc(B, k,l)
    n = size(B,1)
    m = size(B,2)
    min= mini(k,l)
    for i=1:n
        for j=1:m
            if B[i,j]==k || B[i,j]==l
                B[i,j]=min
            end
        end
    end
end

function nb_par_bloc(B,k)
    n = size(B,1)
    m = size(B,2)
    s=0
    for i=1:n
        for j=1:m
            if B[i,j]==k 
                s+=1
            end
        end
    end
    return s
end

function rattache(L,blocks,act,vois)
    println(" ")
    println("       Nous somme dans rattache")
    # relie les elmts d'un bloc entre eux
    n = size(blocks,1)
    m = size(blocks,2)
    for i=1:n
        for j=1:m
            if i>1 && blocks[i,j]>0 && blocks[i,j] == blocks[i-1,j] && L[i,j,1]==0
                L[i,j,1]=1
                L[i-1,j,3]=1
                act[i,j]-=1
                act[i-1,j]-=1
                vois[i,j]-=1
                vois[i-1,j]-=1
                println("       Block rattaché dans la direction 1:",(i,j),"_",blocks[i,j])
            end
            if j<m && blocks[i,j]>0 && blocks[i,j] == blocks[i,j+1] && L[i,j,2]==0
                L[i,j,2]=1
                L[i,j+1,4]=1
                act[i,j+1]-=1
                act[i,j]-=1
                vois[i,j+1]-=1
                vois[i,j]-=1
                println("       Block rattaché dans la direction 2:",(i,j),"_",blocks[i,j])
            end
            if i<n && blocks[i,j]>0 && blocks[i,j] == blocks[i+1,j] && L[i,j,3]==0
                L[i+1,j,1]=1
                L[i,j,3]=1
                act[i,j]-=1
                act[i+1,j]-=1
                vois[i,j]-=1
                vois[i+1,j]-=1
                println("       Block rattaché dans la direction 3:",(i,j),"_",blocks[i,j])
            end
            if j>1 && blocks[i,j]>0 && blocks[i,j] == blocks[i,j-1] && L[i,j,4]==0
                L[i,j-1,2]=1
                L[i,j,4]=1
                act[i,j]-=1
                act[i,j-1]-=1
                vois[i,j]-=1
                vois[i,j-1]-=1
                println("       Block rattaché dans la direction 4:",(i,j),"_",blocks[i,j])
            end
        end
    end
end

function detache(L,blocks,act,k,l)
    # Si deux éléments ne sont pas voisins alors aucun membre d'un bloc ne peut-être relié à l'autre
    n = size(blocks,1)
    m = size(blocks,2)
    for i=1:n
        for j=1:m
            if blocks[i,j] ==k 
                if i>1 && blocks[i-1,j]==l && L[i,j,1]==0
                    L[i,j,1]=-1
                    L[i-1,j,3]=-1
                    act[i,j]-=1
                    act[i-1,j]-=1
                end
                if j<m && blocks[i,j+1]==l && L[i,j,2]==0
                    L[i,j,2]=-1
                    L[i,j+1,4]=-1
                    act[i,j+1]-=1
                    act[i,j]-=1
                end
                if i<n && blocks[i+1,j]==l && L[i,j,3]==0
                    L[i+1,j,1]=-1
                    L[i,j,3]=-1
                    act[i,j]-=1
                    act[i+1,j]-=1
                end
                if j>1 && blocks[i,j-1]==l && L[i,j,4]==0
                    L[i,j-1,2]=-1
                    L[i,j,4]=-1
                    act[i,j]-=1
                    act[i,j-1]-=1
                end
            end
        end
    end
end
function maxi(A)
    n = size(A,1)
    m = size(A,2)
    max = A[1,1]
    for i = 1:n
        for j = 1:m
            if A[i,j]>max
                max =A[i,j]
            end
        end
    end
    return max
end
function detache_simple(L,blocks,act,b)
    # on détache tout du bloc b 
    n = size(blocks,1)
    m = size(blocks,2)
    for i=1:n
        for j=1:m
            if blocks[i,j] ==b 
                if i>1 && blocks[i-1,j]!=b && L[i,j,1]==0
                    L[i,j,1]=-1
                    L[i-1,j,3]=-1
                    act[i,j]-=1
                    act[i-1,j]-=1
                end
                if j<m && blocks[i,j+1]!=b && L[i,j,2]==0
                    L[i,j,2]=-1
                    L[i,j+1,4]=-1
                    act[i,j+1]-=1
                    act[i,j]-=1
                end
                if i<n && blocks[i+1,j]!=b && L[i,j,3]==0
                    L[i+1,j,1]=-1
                    L[i,j,3]=-1
                    act[i,j]-=1
                    act[i+1,j]-=1
                end
                if j>1 && blocks[i,j-1]!=b && L[i,j,4]==0
                    L[i,j-1,2]=-1
                    L[i,j,4]=-1
                    act[i,j]-=1
                    act[i,j-1]-=1
                end
            end
        end
    end
end
function decision_simple(L,blocks,act,vois,i,j)
    println("       Nous sommes dans decision SIMPLE")
    n = size(blocks,1)
    m = size(blocks,2)
    if vois[i,j]==3
        b1 = -1
        b2 = -2
        b3 = -3
        b4 = -4
        if i>1 && blocks[i-1,j] >0
            b1 = blocks[i-1,j]
        end
        if j<m && blocks[i,j+1] >0
            b2 = blocks[i,j+1]
        end
        if i<n && blocks[i+1,j] >0
            b3 = blocks[i+1,j]
        end
        if i<n && blocks[i,j-1] >0
            b4 = blocks[i,j-1]
        end
        if b1==b2 || b1==b3 || b1==b4 || b2==b3 || b2==b4 || b3==b4
            
        end
    end 
end

function decision(L,blocks,act,vois,i,j)
    # n'est vraiment utile que pour vois = 3 et s =2 ...
    println("       Nous sommes dans decision youpi")
    n = size(blocks,1)
    m = size(blocks,2)
    for ind=1:maxi(blocks)
        s= 0
        if i>1 && blocks[i-1,j]==ind && L[i,j,1]==0
            s += 1
        end
        if j<m && blocks[i,j+1]==ind && L[i,j,2]==0
            s+=1
        end
        if i<n && blocks[i+1,j]==ind && L[i,j,3]==0
            s+=1
        end
        if j>1 && blocks[i,j-1]==ind && L[i,j,4]==0
            s+=1
        end
        if s+vois[i,j]>=4
            if i>1 && blocks[i-1,j]==ind && L[i,j,1]==0
                L[i,j,1] = 1
                act[i,j] -= 1
                vois[i,j] -= 1
                L[i-1,j,3] = 1
                act[i-1,j] -= 1
                vois[i-1,j] -= 1
                if blocks[i,j]>0
                    changebloc(blocks,blocks[i-1,j],blocks[i,j])
                else 
                    blocks[i,j]= blocks[i-1,j]
                end
            end
            if j<m && blocks[i,j+1]==ind && L[i,j,2]==0
                L[i,j,2] = 1
                act[i,j] -= 1
                vois[i,j] -= 1
                L[i,j+1,4] = 1
                act[i,j+1] -= 1
                vois[i,j+1] -= 1
                if blocks[i,j]>0
                    changebloc(blocks,blocks[i,j+1],blocks[i,j])
                else 
                    blocks[i,j]= blocks[i+1,j]
                end
            end
            if i<n && blocks[i+1,j]==ind && L[i,j,3]==0
                L[i,j,3] = 1
                act[i,j] -= 1
                vois[i,j] -= 1
                L[i+1,j,1] = 1
                act[i+1,j] -= 1
                vois[i+1,j] -= 1
                if blocks[i,j]>0
                    changebloc(blocks,blocks[i+1,j],blocks[i,j])
                else 
                    blocks[i,j]= blocks[i,+1j]
                end
            end
            if j>1 && blocks[i,j-1]==ind && L[i,j,4]==0
                L[i,j,4] = 1
                act[i,j] -= 1
                vois[i,j] -= 1
                L[i,j-1,2] = 1
                act[i,j-1] -= 1
                vois[i,j-1] -= 1
                if blocks[i,j]>0
                    changebloc(blocks,blocks[i,j-1],blocks[i,j])
                else 
                    blocks[i,j]= blocks[i,j-1]
                end
            end
            rattache(L,blocks,act,vois)
            fermeture_blocs(L,blocks,act)
            println("            Une décision a été prise entre " , (i,j), " et le bloc ", ind)
            println(vois[i,j]," ",s," ",nb_par_bloc(blocks,ind))
            if nb_par_bloc(blocks,ind)+vois[i,j] == n ## on détache le reste du bloc s'il y a suffisament de voisins pour faire un bloc
                println("détachement du reste du bloc")
                for ki=1:n
                    for kj=1:m
                        if blocks[ki,kj] ==ind && ki != i && kj!= j
                            if ki>1 && blocks[ki-1,kj]!=ind && L[ki,kj,1]==0
                                println(    "on détache ", (ki-1,kj))
                                L[ki,kj,1]=-1
                                L[ki-1,kj,3]=-1
                                act[ki,kj]-=1
                                act[ki-1,kj]-=1
                            end
                            if kj<m && blocks[i,j+1]!=ind && L[i,j,2]==0
                                println(    "on détache ", (ki,kj+1))
                                L[ki,kj,2]=-1
                                L[ki,kj+1,4]=-1
                                act[ki,kj+1]-=1
                                act[ki,kj]-=1
                            end
                            if ki<n && blocks[ki+1,j]!=ind && L[ki,j,3]==0
                                println(    "on détache ", (ki+1,kj))
                                L[ki+1,kj,1]=-1
                                L[ki,kj,3]=-1
                                act[ki,kj]-=1
                                act[ki+1,kj]-=1
                            end
                            if kj>1 && blocks[ki,kj-1]!=ind && L[ki,kj,4]==0
                                println(    "on détache ", (ki,kj-1))
                                L[ki,kj-1,2]=-1
                                L[ki,kj,4]=-1
                                act[ki,kj]-=1
                                act[ki,kj-1]-=1
                            end
                        end
                    end
                end
            end
        end
    end
end
function fermeture_blocs(L,blocks,act)
    # détruit les liaisons entre block complet -> autre
    println("fermeture de blocs")
    n = size(blocks,1)
    m = size(blocks,2)
    for ind=1:maxi(blocks)
        s = 0
        for i = 1:n
            for j = 1:m
                if blocks[i,j]==ind
                    s +=1
                end
            end
        end
        if s==n
            println("       Le bloc ",ind," est complet")
            detache_simple(L,blocks,act,ind)
        end
    end
end

function heuristicSolve4(V)
    n = size(V,1)
    m = size(V,2)

    # matrice des contraintes de voisinage restantes
    vois = zeros(n,m)
    println(vois)
    ind_i = []
    ind_j = []
    for i = 1:n
        for j = 1:m
            if V[i,j]!=-1
                vois[i,j]=4-V[i,j]
                append!(ind_i,i) 
                append!(ind_j,j) 
            else
                vois[i,j]=-1
            end
        end
    end
    # Matrice du nombre de voisins actuels
    act = fill(4, (n, m))
    act[1,:] .= 3
    act[end,:] .= 3
    act[:,1] .= 3
    act[:,end] .= 3
    act[1,1] = 2
    act[1,end] = 2
    act[end,1] = 2
    act[end,end] = 2
    # Matrice des liaisons 
    L = zeros(n,m,4) # 1 si lié, -1 si impossible 0 si pas encore traité
    for i = 1:n 
        L[i,1,4]=-1
        L[i,m,2]=-1
    end
    for j = 1:m 
        L[1,j,1]=-1
        L[n,j,3]=-1
    end
    # Matice des blocks
    blocks = zeros(n,m) # numéro des blocs par case
    ind_block = 1 # indice du prochain bloc à créer
    # TODO
    #println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    iter = 0
    while act != zeros(n,m) && iter <10
        for i =1:n
            for j=1:m
                println("---------------",i,",",j,"-----------------")
                decision(L,blocks,act,vois,i,j)
                if vois[i,j]== act[i,j] || floor(act[i,j])==1 
                    #println("diff des contraintes ",(i,j)," = " ,vois[i,j]- act[i,j] )
                    #println("voisins actuels ",(i,j)," = ",act[i,j])
                    println("On est dans if")
                    # si contraintes voisinage = nb de voisins possibles ou plus qu'un seul chemin possibles
                    # on relie 
                    
                    if blocks[i,j]==0 #si pas encore de bloc attribué
                        blocks[i,j] = ind_block # on met le prochain numéro de bloc dispo
                        ind_block += 1
                        println( "  ind bloc ",i,",",j, ":  ",ind_block)
                        println(blocks)
                    end
                    for p=1:4 
                        if L[i,j,p]== 0 # si liaison pas encore traitée
                            L[i,j,p]=1 # alors voisins
                            act[i,j] -= 1 # 1 voisin possible en moins
                            vois[i,j] -= 1 # 1 contrainte de voisinage en moins
                            if p==1 && i >1
                                println("on ajoute dans la direction 1")
                                L[i-1,j,3] = 1
                                act[i-1,j] -= 1
                                vois[i-1,j] -= 1
                                if blocks[i-1,j]>0
                                    changebloc(blocks,blocks[i-1,j],blocks[i,j])
                                # la case voisine est dans le même bloc, on change toutes les valeurs de bloc obsolètes pour le min  
                                else 
                                    blocks[i-1,j]= blocks[i,j]
                                end
                                println(blocks)
                                rattache(L,blocks,act,vois)
                                fermeture_blocs(L,blocks,act)
                                println(blocks)
                            elseif p==2 && j<m
                                println("on ajoute dans la direction 2")
                                L[i,j+1,4] = 1
                                act[i, j+1] -= 1
                                vois[i, j+1] -= 1
                                if blocks[i,j+1]>0
                                    #println("changement de bloc ",i,",",j," direction 2",blocks[i,j+1],",",blocks[i,j])
                                    changebloc(blocks,blocks[i,j+1],blocks[i,j])
                                else
                                    blocks[i,j+1]= blocks[i,j]
                                end
                                println(blocks)
                                rattache(L,blocks,act,vois)
                                fermeture_blocs(L,blocks,act)
                                println(blocks)
                            elseif p==3 && i<n
                                println("on ajoute dans la direction 3")
                                L[i+1,j,1] = 1
                                act[i+1, j] -= 1
                                vois[i+1, j] -= 1
                                if blocks[i+1,j]>0
                                    #println("changement de bloc ",i,",",j," direction 3",blocks[i+1,j],",",blocks[i,j])
                                    changebloc(blocks,blocks[i+1,j],blocks[i,j])
                                else
                                    blocks[i+1,j]= blocks[i,j]
                                end
                                println(blocks)
                                rattache(L,blocks,act,vois)
                                fermeture_blocs(L,blocks,act)
                                println(blocks)
                            elseif p==4 && j>1
                                println("on ajoute dans la direction 4")
                                L[i,j-1,2] = 1
                                act[i, j-1] -= 1
                                vois[i, j-1] -= 1
                                if blocks[i,j-1]>0
                                    #println("changement de bloc ",i,",",j," direction 4",blocks[i,j-1],",",blocks[i,j-1])
                                    changebloc(blocks,blocks[i,j-1],blocks[i,j])
                                else
                                    blocks[i,j-1]= blocks[i,j]
                                end
                                println(blocks)
                                rattache(L,blocks,act,vois)
                                fermeture_blocs(L,blocks,act)
                                println(blocks)
                            end
                            #println("actuels voisins : ", act)
                            #println("actuelles contraintes : ", vois)
                            println("   Voisinage de (4,2) : ", L[4,2,1]," ", L[4,2,2]," ", L[4,2,3]," ", L[4,2,4],"---",act[4,2])
                            println("   Voisinage de (5,3) : ",L[5,3,1]," ", L[5,3,2]," ", L[5,3,3]," ", L[5,3,4],"---",act[5,3])
                        end
                    end
                elseif (i in ind_i && j in ind_j && vois[i,j]==0) || act[i,j]==0 # Si plus de voisins possibles
                    println("on est dans le else")
                        for p=1:4
                            if L[i,j,p]== 0
                                println(" on retire la direction ", p )
                                L[i,j,p]=-1 # alors pas voisin
                                act[i,j] -= 1 # 1 voisin possible en moins
                                if p==1 && i >1
                                    L[i-1,j,3] = -1 #on enlève symétriquement cette possibilité pour l'autre côté de l'arrête
                                    act[i-1,j] -= 1
                                    if blocks[i-1,j]>0
                                        detache(L,blocks,act,blocks[i,j],blocks[i-1,j])
                                        println(blocks)
                                    end
                                    
                                elseif p==2 && j<m
                                    L[i,j+1,4] = -1
                                    act[i, j+1] -= 1
                                    if blocks[i,j+1]>0
                                        detache(L,blocks,act,blocks[i,j],blocks[i,j+1])
                                        println(blocks)
                                    end
                                elseif p==3 && i<n
                                    L[i+1,j,1] = -1
                                    act[i+1, j] -= 1
                                    if blocks[i+1,j]>0
                                        detache(L,blocks,act,blocks[i,j],blocks[i+1,j])
                                        println(blocks)
                                    end
                                elseif p==4 && j>1
                                    L[i,j-1,2] = -1
                                    act[i, j-1] -= 1
                                    if blocks[i,j-1]>0
                                        detache(L,blocks,act,blocks[i,j],blocks[i,j-1])
                                        println(blocks)
                                    end
                                end
                            end
                        end
                    
                end
            end
        end
        println("fin d'une itération")
        rattache(L,blocks,act,vois) #on rattache tous les nouvelles cases de bloc au reste de leur bloc
        println("   act après rattache:", act)
        fermeture_blocs(L,blocks,act)
        println("   Voisinage de (4,2) : ", L[4,2,1]," ", L[4,2,2]," ", L[4,2,3]," ", L[4,2,4],"---",act[4,2])
        println("   Voisinage de (5,3) : ",L[5,3,1]," ", L[5,3,2]," ", L[5,3,3]," ", L[5,3,4],"---",act[5,3])

        #println("   act après fermeture:", act)
        println(blocks)
        iter += 1
    end
    return blocks
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
