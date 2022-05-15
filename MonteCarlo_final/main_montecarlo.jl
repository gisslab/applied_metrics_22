###############################################################################
#== 
  Final Monte Carlo , Metrics 717, Spring 22

  Module Model of search of credit cards/mortgage/loans.

  author: 
    name: Giselle Labrador Badia
    email: labradorbada@wisc.edu

  This file contains functions use to define and generate the data.

==#
###############################################################################

# importing libraries
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random, Plots, Combinatorics, Latexify
include("table_func.jl")

push!(LOAD_PATH,"./MonteCarlo_final/");
push!(LOAD_PATH,"./PS5/");

# adding working directory/src/ to load path
LOAD_PATH

# loading model
using BankSearchModel, MyRegression
m = BankSearchModel


Plots.theme(:vibrant); # :dark, :light, :vibrant
default(fontfamily="Computer Modern", framestyle=:box); # LaTex-style
gr(size = (800, 600)); # default plot

#########################################
#Primitives and initial simulation test
#########################################

# Initializing primitive struct
#ϕ = m.Primitives(k = 1)
ϕ = m.Primitives(k = 1, α₁ = 21, α₂ = 23, β₁ = -0.03, β₂ = -0.07)

#number of samples
n = 5000
data = m.simulate(ϕ , n = n);

describe(data)

#########################################
# Getting moments of data
#########################################

#total number of moments
number_moments = 24
# getting moments 
ĝ = m.get_moments(data, filter = Vector{Integer}((1:number_moments)) );
name_moments = ["E[d]", "E[c]",
                "E[d|b=1]", "E[d|b=0]", "E[c|b=1]","E[c|b=0]",
                "E[d|z=1]", "E[d|z=0]", "E[c|z=1]","E[c|z=0]",
                "E[p]","E[b]","E[p|d=0]", "E[p|d=1]", "E[p|c=0]",
                "E[p|c=1]",  "V[p|d=0]", "V[p|d=1]", "V[p|c=0]", "V[p|c=1]",
                "E[p1]", "E[p2]","V[p1]", "V[p2]" ];
desc_moments = ["Percent of individuals who search.",
"Percent of individuals who change banks.", 
"Expectation of search conditional on bank 1 being chosen.",
"Expectation of search conditional on bank 2 being chosen.",
"Expectation of change conditional on bank 1 being chosen.",
"Expectation of change conditional on bank 2 being chosen.",
"Expectation of search conditional on homebank being bank 1.", 
"Expectation of search conditional on homebank being bank 2.",
"Expectation of change conditional on homebank being bank 1.",
"Expectation of change conditional on homebank being bank 2.",
"Expectation of price",
"Percent of individuals that choose bank 1",  
"Expectation of price conditional on no search",
"Expectation of price conditional on search",
"Expectation of price conditional on no change",
"Expectation of price conditional on change",
"Variance of price conditional on no search",
"Variance of price conditional on search",
"Variance of price conditional on no change",
"Variance of price conditional on change",
"Expectation of price bank 1",
"Expectation of price bank 2",
"Variance of price bank 1",
"Variance of price bank 2"];
moments = DataFrame(moments = name_moments,
                    value = ĝ,
                    desription = desc_moments )




#######################################
# Estimation of α₁, β₁, α₂, β₂
#######################################

#get estimate for alpha and betas by OLS: α₁, β₁, α₂, β₂
est1 = MyRegression.ols(data.p[data.b.==1], data.x[data.b.==1])
est2 = MyRegression.ols(data.p[data.b.==0], data.x[data.b.==0])

# vector of moments already estimated in the following order:
θ₀  = [est1.β[1], est1.β[2], est2.β[1], est2.β[2]]

matrix_latex = [ϕ.α₁ ϕ.α₂  θ₀[1] θ₀[3]; 
                0  0   est1.V[1,1] est2.V[1,1]; 
                ϕ.β₁ ϕ.β₂  θ₀[2] θ₀[4];
                0  0   est1.V[2,2] est2.V[2,2]];
              

matrix_latex = round.(matrix_latex, sigdigits = 4)
head_ = ["True Bank 1" "True Bank 2" "Bank 1 estimates"  "Bank 2 estimates" ]
side_ = ["","", "\\alpha", "" , "\\beta"]

latex = latexify(matrix_latex, env = :table, head = head_ , side = side_,
                latex = false, adjustment = :r, booktabs = true)


# estimating sigma
residual = data.p[data.b .== 1] .- est1.β[2].*data.x[data.b .== 1] .- est1.β[1];
#fit(Normal, residual)
residual2 = data.p[data.b .== 0] .- est2.β[2].*data.x[data.b .== 0] .- est2.β[1];
#fit(Normal, residual)



histogram(residual, bins=:scott)



#######################################
# Estimation of k by SMM
#######################################

# now we estimate parameters of price variatioon ϵ : σ₁, σ₂, ρ and k
# "real data" is the data from before
# generating real data
data = m.simulate(ϕ, n = n);
# choosing moments
filt = Vector{Integer}((1:24)) ;
#filt = [1,2,3,4,5,6,8];
#filt = [11 12];
#filt = [7]
# simulated sample size
n = 500
# initial guess order: σ₁, σ₂, ρ, k
initial_guess = [ 0.4];
lower = [ 0.1];
upper = [ 2.0];
println("******* estimation smm *******")
θ⁰ = [ϕ.α₁,ϕ.β₁,ϕ.α₂,ϕ.β₂]
# not using estimated θ₀
est = m.simulated_method_moments(data, θ⁰, initial_guess, lower, upper, filter = filt, n = n )

# ploting

ĝ = m.get_moments(data, filter = Vector{Integer}((1:number_moments)) );

#σ1s = (ϕ.σ₁-2):0.001:(ϕ.σ₁+2);
#ρs = (ϕ.ρ-0.4):0.001:(ϕ.ρ+0.4)
ks = (ϕ.k-1):0.01:(ϕ.k+1);


#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , ϕ.σ₂, ϕ.ρ, ϕ.k ], ĝ) for x in σ1s];
#ρobj = [m.simulated_method_moments_objective(θ₀, [ϕ.σ₁, ϕ.σ₂ , x, ϕ.k ], ĝ) for x in ρs];
#kobj = [m.simulated_method_moments_objective(θ₀, [ϕ.σ₁, ϕ.σ₂ , ϕ.ρ, x ], ĝ) for x in ks];

#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , ϕ.k ], ĝ[filt], filter = filt) for x in σ1s];
kobj = [m.simulated_method_moments_objective(θ⁰, [x ], ĝ[filt], filter = filt, n = n) for x in ks];
#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , est[2] ], ĝ[filt], filter = filt) for x in σ1s];
kobj = [m.simulated_method_moments_objective(θ⁰, [x ], ĝ[filt], filter = filt, n = n) for x in ks];



#plot(ρs, ρobj, labels="SMM", title="\\rho identification", color = "violet")
#plot!([ϕ.ρ], seriestype="vline", labels="\\rho ", linestyle=:dash, color = "blue")
#plot!([est[3]], seriestype="vline", labels="\\rho est ", linestyle=:dot, color = "red")


#plot(σ1s , σ1obj, labels="SMM", title="\\sigma identification", color = "violet")
#plot!([ϕ.σ₁], seriestype="vline", labels="\\sigma  ", linestyle=:dash, color = "blue")
#plot!([est[1]], seriestype="vline", labels="\\sigma  est ", linsestyle=:dot, color = "red")

plot(ks, kobj, labels="SMM", title="k Identification", color = "violet", linewidth = 1.6)
plot!([ϕ.k], seriestype="vline", labels="k", linestyle=:dash, color = "blue", linewidth = 1.6)
plot!([est[1]], seriestype="vline", labels="k est", linestyle=:dot, color = "red", linewidth = 1.6)


savefig("kfit_n500_m24.pdf")

###########################################
# moments
###########################################

# moments descriptors to latex
head_ = [ "moments" "value" "description" ];
side_ = Vector{Integer}(1:24);

#matrix_latex = round.(matrix_latex, sigdigits = 4)
matrix_latex = [reshape(string.(name_moments), (1,length(side_)));
                reshape(string.(round.(ĝ, digits = 3)), (1, length(side_)));
                reshape(desc_moments, (1, length(side_)))];

matrix_latex = permutedims(matrix_latex)               
latex = latexify(matrix_latex, env = :table, head = head_ , side = side_,
                latex = false, adjustment = :r, booktabs = true)

############################################
# replications 
############################################

#n = number of individuals per simulation
n = 5000;
#replics = number of replications (initial data)
replics = 3;
# number of moments to test
num_moments = [1,2,3,4,24]
  # dctionary of best estimates per number of moments
dict_best = Dict();
dict_all = Dict();

# initializing  dictionaries
for i in num_moments
  dict_best[i] = [];
  dict_all[i] = [];
end

# loop over number of replications 
for r in 1:replics
  data = m.simulate(ϕ , n = n);
  print("r=", r," - ")
  # loop over number of moments
  for i in num_moments#length(filt)
    best = 10000.0
    best_filter = [1]

    for c in combinations(filt,i)
      # for this we will use other parameters from original data, to not introduce further noise
      θ₀ = [ϕ.α₁,ϕ.β₁,ϕ.α₂,ϕ.β₂]
      # estimate parameter k
      fit = m.simulated_method_moments(data, θ₀, initial_guess, lower, upper, n = n, filter = c)[1]
      # comparing with best fit for i parameters (dont need to do this since we are saving all..)
      if abs(ϕ.k - best) > abs(ϕ.k - fit) 
        best = round(fit, digits = 4)
        best_filter = c
      end
      push!(dict_all[i], fit)
    end
    #println("best fit for ", string(i) , " moments, is ", string(best_filter),   " filters, fit is ", string(best))
    push!(dict_best[i], [best, best_filter]) 
    
  end
end

n_list = [500,1000,2000,5000]
i =4
col_names = ["m=1", "m=2", "m=3", "m=4", "m=24"]

key_k_se = ["\$\\hat{k}\$"]
key_k_nse = ["\$max(\\hat{k})\$", "n"]
#values_se = []
#values_nse = []
#se = []
push!(values_se, [])
push!(values_nse, [])
push!(se, [])
# Getting mean standard error and best fit for each number of moments
# loop over numer of moments

for c in sort(collect(keys(dict_all)))
    meank = mean(dict_all[c])
    std_error = std(dict_all[c])/sqrt(length(dict_all[c]))
    min_diff = findmin(abs.(dict_all[c] .- ϕ.k))
    push!(values_se[i], [meank])
    push!(se[i], [std_error])
    push!(values_nse[i], [dict_all[c][min_diff[2]], n_list[i]])
end

values_se

values_nse

# to latex
table = create_table(key_k_nse, values_nse, col_names,
            keys_se=key_k_se, values_se=values_se, se=se)


print(to_tex(table))





