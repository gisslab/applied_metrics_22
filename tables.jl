using TexTables


#### Example use
#= Table:

----------------------------------------------------------
|    # moments   ||    5   ||    9   ||   14   ||   24   |
----------------------------------------------------------
|       ω        ||   x_5  ||   x_9  ||  x_14  ||  x_24  |
----------------------------------------------------------
|       β        ||   y_5  ||   y_9  ||  y_14  ||  y_24  |
----------------------------------------------------------
|       σ        ||   z_5  ||   z_9  ||  z_14  ||  z_24  |
----------------------------------------------------------
| No Convergence ||   w_5  ||   w_9  ||  w_14  ||  w_24  |
----------------------------------------------------------

=#

# Fitst you need to define the keys
key = ["ω", "β", "σ", "No Convergence"]
# Tables are created by columns 
col_1 = rand(4) .* 100
col_2 = rand(4) .* 100
col_3 = rand(4) .* 100
t1 = TableCol("5", key, col_1)
col_4 = rand(4) .* 100
t2 = TableCol("9", key, col_2)
t3 = TableCol("14", key, col_3)
t4 = TableCol("24", key, col_4)

table = hcat(t1, t2, t3, t4)

#= Table:
Suppose we want to add Standard errors:
----------------------------------------------------------
|    # moments   ||    5   ||    9   ||   14   ||   24   |
----------------------------------------------------------
|       ω        ||   x_5  ||   x_9  ||  x_14  ||  x_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
|       β        ||   y_5  ||   y_9  ||  y_14  ||  y_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
|       σ        ||   z_5  ||   z_9  ||  z_14  ||  z_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
| No Convergence ||   w_5  ||   w_9  ||  w_14  ||  w_24  |
----------------------------------------------------------

=#
# Note that here the last ropw have a standard error and it shouldn't this is somethign to fix on my function
se1 = rand(4)
se2 = rand(4)
se3 = rand(4)
se4 = rand(4)
table = hcat(TableCol("5", key, col_1, se), TableCol("9", key, col_2, se2), TableCol("14", key, col_3, se3), TableCol("24", key, col_4, se4))

# ✔ Let's try the following 
key1 = ["ω", "β", "σ"]
key2 = ["No Convergence"]
col_11 = rand(3) .* 100
col_12 = Int.(round.(rand(1) .* 1000))
se1 = rand(3)
col_21 = rand(3) .* 100
col_22 = Int.(round.(rand(1) .* 1000))
se2 = rand(3)
col_31 = rand(3) .* 100
col_32 = Int.(round.(rand(1) .* 1000))
se3 = rand(3)
col_41 = rand(3) .* 100
col_42 = Int.(round.(rand(1) .* 1000))
se4 = rand(3)
t1 = vcat(TableCol("5", key1, col_11, se), TableCol("5", key2, col_12))
t2 = vcat(TableCol("9", key1, col_21, se2), TableCol("9", key2, col_22))
t3 = vcat(TableCol("14", key1, col_31, se3), TableCol("14", key2, col_32))
t4 = vcat(TableCol("24", key1, col_41, se4), TableCol("24", key2, col_42))

table = hcat(t1, t2, t3, t4) 

# Now I want to add the last piece of the puzzle:
#= Table:
Suppose we want to add the sample size:
----------------------------------------------------------
|    # moments   ||    5   ||    9   ||   14   ||   24   |
----------------------------------------------------------
T = 500
----------------------------------------------------------
|       ω        ||   x_5  ||   x_9  ||  x_14  ||  x_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
|       β        ||   y_5  ||   y_9  ||  y_14  ||  y_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
|       σ        ||   z_5  ||   z_9  ||  z_14  ||  z_24  |
|                ||  (se)  ||  (se)  ||  (se)  ||  (se)  |
----------------------------------------------------------
| No Convergence ||   w_5  ||   w_9  ||  w_14  ||  w_24  |
----------------------------------------------------------

I think this part have to be done directly in latex

=#

# I need 5 elements to create a table:
# * Keys of elemetns with standard errors 
# * Elements with standa errors
# * Standard error
# * Keys of elements without standard errors
# * Elements without standard errors
# My convention will be to put elements with stand errors first


# Keys of elelemts with standard errors
key1 = ["\$\\omega\$", "\$\\beta\$", "\$\\sigma\$"]
# Since I want to generate 5 tables of 4 rows each I need to have 5 lists of 4 lists
ncols = 4
ntables = 5
values1 = [[rand(length(key1)) .* 100 for i ∈ 1:ncols] for j ∈ 1:ntables]
se = [[rand(length(key1)) for i ∈ 1:ncols] for j ∈ 1:ntables]
# Now for the elements without standard errors
key2 = ["T"]
values2 = [[Int.(round.(rand(length(key2)) .* 1000)) for i ∈ 1:ncols] for j ∈ 1:ntables]
colabels = ["5", "9", "14", "24"] 



function create_tables8(keys_nse::Array{String}, values_nse, colabels::Array{String};
    keys_se::Array{String}=String[], values_se=[[]], se=[[]])
    
    # TODO: Put some assertions here to check that the arrays are the same length
    
    ntables = length(values_nse)
    nrows   = length(values_nse[1])
    se_part = length(se[1]) != 0
    
    table = []
    # Create the table
    for t ∈ 1:ntables
        ## Create subtables
        ### If there are elements with standard errors create that part first
        if se_part
            table_se =  hcat([TableCol(colabels[i], keys_se, values_se[t][i], se[t][i]) for i ∈ 1:ncols]...)
        else
            table_se =  []
        end
        ### Then create the rest of the table
        table_nse = hcat([TableCol(colabels[i], keys_nse, values_nse[t][i]) for i ∈ 1:ncols]...)
        # Add both subtables to the table in the correct order
        table = vcat(table,  vcat(table_se, table_nse))
    end 
    
    # @show vcat(table...)
    return vcat(table...)
end


a = create_table(key2, values2, colabels, keys_se = key1, values_se = values1, se = se  )



function test23(a::Array{String})
end

test23(String[])

values2


to_tex(a) |> print

a |> x -> write_tex("test.tex", x)