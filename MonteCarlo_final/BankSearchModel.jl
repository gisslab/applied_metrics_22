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

module BankSearchModel

# importing libraries
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random


@with_kw mutable struct Primitives
    # parameter to generate data, observables
    μₓ::Float64 = 100 # mean of X, creditworthiness  
    σₓ::Float64 = 10 # variance of X, creditworthiness

    # true unobserved parameters from valuation of indifuduals
    v₁::Float64 = 10 # valuation from bank 1
    v₂::Float64 = 8 # valuation from bank 2

    # unknown mutable parameters from error term
    σ₁::Float64 = 1 # variance of price of bank 1
    σ₂::Float64 = 1 # variance of price of bank 2
    ρ::Float64  = 0.5 # correlation coefficient between price of bank 1 and price of bank 2
    Σ::Array{Float64, 2} # covariance matrix
    
    # true unobserved parameter representing search cost
    k::Float64 = 1  # search cost

end
    

    """
    simulate(θ,1000)

    Simulate sample data from the model. Returns matrix with sample. 

    # Arguments: 
        - n: number of individuals to simulate
        - seed:  seed for the random number generator

"""
function simulate(n::Integer=1000, constantz = 2, seed::Integer=350)

    # unpacking primitives from struct
    @unpack p, σ₀, σ₁, σ₂, σ01, σ02, σ12, Σ = Primitives()

    # setting seed 
    Random.seed!(seed)
    
    # generating arrays of n individuals
    ε = rand(Distributions.MvNormal([0, 0, 0], Σ), n)' # idiosyncratic shocks ϵ = (u1,u1,uv)
    z = rand(Distributions.Bernoulli(p), n) # random experiment   

    y₀ = 1 .+  ε[:,1]    
    y₁ = 4 .+  ε[:,2] 
    v =  (constantz .* z) .+ ε[:,3] .- 1

    v₀ = ε[:,3] .- 1
    v₁ = constantz .+ ε[:,3] .- 1

    d = v .>= 0
    y = y₁ .* d + y₀.* (1 .- d)
    complier = (v₀ .< 0) .* (v₁ .> 0)

    # returning DataFrame of simulated data
    data = DataFrame(i = 1:n,
                    d = d,
                    z = z,
                    y = y,
                    y0 = y₀,
                    y1 = y₁,
                    v = v,
                    c = complier)
    return data
end


end