
using TexTables


function create_table(keys_nse::Array{String}, values_nse, colabels::Array{String};
    keys_se::Array{String}=String[], values_se=[[]], se=[[]])
    
    # TODO: Put some assertions here to check that the arrays are the same length
    
    ntables = length(values_nse)
    ncols   = length(values_nse[1])
    
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