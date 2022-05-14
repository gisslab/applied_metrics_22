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
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random, Plots, Combinatorics

push!(LOAD_PATH,"./MonteCarlo_final/");
push!(LOAD_PATH,"./PS5/");

# adding working directory/src/ to load path
LOAD_PATH

# loading model
using BankSearchModel, MyRegression
m = BankSearchModel

theme(:juno)

# Initializing primitive struct
#ϕ = m.Primitives(k = 1)
ϕ = m.Primitives(k = 1, α₁ = 21, α₂ = 23, β₁ = -0.03, β₂ = -0.07)

data = m.simulate(ϕ , n = 10000);

describe(data)



ĝ = m.get_moments(data, filter = Vector{Integer}((1:20)) );
name_moments = ["E[d]", "E[c]", "E[d|b=1]", "E[d|b=0]", "E[c|b=1]","E[c|b=0]",
                "E[p]","E[b]","E[p|d=0]", "E[p|d=1]", "E[p|c=0]",
                "E[p|c=1]",  "V[p|d=0]", "V[p|d=1]", "V[p|c=0]", "V[p|c=1]",
                "E[p1]", "E[p2]","V[p1]", "V[p2]" ];
moments = DataFrame(moments = name_moments,
                    value = ĝ )


# choosing moments
filt = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18, 19, 20];
#filt = [1,2,3,4,5,6,8];
#filt = [1,3,5];
#filt = [1]

#get estimate for alpha and betas by OLS: α₁, β₁, α₂, β₂
est1 = MyRegression.ols(data.p[data.b.==1], data.x[data.b.==1])
est2 = MyRegression.ols(data.p[data.b.==0], data.x[data.b.==0])

# vector of moments already estimated in the following order:
θ₀  = [est1.β[1], est1.β[2], est2.β[1], est2.β[2]]

# estimating sigma
residual = data.p[data.b .== 1] .- est1.β[2].*data.x[data.b .== 1] .- est1.β[1];
#fit(Normal, residual)
residual2 = data.p[data.b .== 0] .- est2.β[2].*data.x[data.b .== 0] .- est2.β[1];
#fit(Normal, residual)

histogram(residual, bins=:scott)


# now we estimate parameters of price variatioon ϵ : σ₁, σ₂, ρ and k
# "real data" is the data from before
# initial guess order: σ₁, σ₂, ρ, k
initial_guess = [ 0.4];
lower = [ 0.1];
upper = [ 2.0];
println("******* estimation smm *******")
est = m.simulated_method_moments(data, θ₀, initial_guess, lower, upper, filter = filt)

# ploting

#σ1s = (ϕ.σ₁-2):0.001:(ϕ.σ₁+2);
#ρs = (ϕ.ρ-0.4):0.001:(ϕ.ρ+0.4)
ks = (ϕ.k-1):0.01:(ϕ.k+1);


#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , ϕ.σ₂, ϕ.ρ, ϕ.k ], ĝ) for x in σ1s];
#ρobj = [m.simulated_method_moments_objective(θ₀, [ϕ.σ₁, ϕ.σ₂ , x, ϕ.k ], ĝ) for x in ρs];
#kobj = [m.simulated_method_moments_objective(θ₀, [ϕ.σ₁, ϕ.σ₂ , ϕ.ρ, x ], ĝ) for x in ks];

#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , ϕ.k ], ĝ[filt], filter = filt) for x in σ1s];
kobj = [m.simulated_method_moments_objective(θ₀, [x ], ĝ[filt], filter = filt) for x in ks];
#σ1obj= [m.simulated_method_moments_objective(θ₀, [x , est[2] ], ĝ[filt], filter = filt) for x in σ1s];
kobj = [m.simulated_method_moments_objective(θ₀, [x ], ĝ[filt], filter = filt) for x in ks];



#plot(ρs, ρobj, labels="SMM", title="\\rho identification", color = "violet")
#plot!([ϕ.ρ], seriestype="vline", labels="\\rho ", linestyle=:dash, color = "blue")
#plot!([est[3]], seriestype="vline", labels="\\rho est ", linestyle=:dot, color = "red")


#plot(σ1s , σ1obj, labels="SMM", title="\\sigma identification", color = "violet")
#plot!([ϕ.σ₁], seriestype="vline", labels="\\sigma  ", linestyle=:dash, color = "blue")
#plot!([est[1]], seriestype="vline", labels="\\sigma  est ", linsestyle=:dot, color = "red")

plot(ks, kobj, labels="SMM", title="k identification", color = "violet")
plot!([ϕ.k], seriestype="vline", labels="k", linestyle=:dash, color = "blue")
plot!([est[1]], seriestype="vline", labels="k est", linestyle=:dot, color = "red")

# dctionary of best estimates per number of moments
dict = Dict()
#get best fit
for i in 1:length(filt)
  best = 10000.0
  best_filter = [1]
  for c in combinations(filt,i)
    fit = m.simulated_method_moments(data, θ₀, initial_guess, lower, upper, filter = c)[1]
    if abs(ϕ.k - best) > abs(ϕ.k - fit) 
      best = round(fit, digits = 4)
      best_filter = c
    end

  end
  println("best fit for ", string(i) , " moments, is ", string(best_filter),   " filters, fit is ", string(best))
  dict = Dict(i => [best, best_filter])
end