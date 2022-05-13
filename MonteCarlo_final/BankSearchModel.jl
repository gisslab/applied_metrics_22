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


@with_kw struct Primitives
    # parameter to generate data, observables:
    # creditwordiness distributes exponential parameter lambda
    λ::Float64 = 0.01 # lambda parameter of expoential distribution 
    μₓ::Float64 = 1/λ  # mean of X, creditworthiness  
    xdist::Exponential{Float64} = Exponential{Float64}(μₓ) # distribution of X, creditworthiness
    # true observed parameters from valuation of individuals
    v₁::Float64 = 10 # valuation from bank 1
    v₂::Float64 = 8 # valuation from bank 2
    
    # population percent in bank 1 and 2
    p::Float64 = 0.5 # percent of population in bank 1
    zdist::Bernoulli{Float64} = Distributions.Bernoulli(p)

    # unknow parameter from prices of banks 
    α₁dist::Uniform{Float64} = Distributions.Uniform(15, 25)
    α₂dist::Uniform{Float64} = Distributions.Uniform(19, 23)
    β₁dist::Uniform{Float64} = Distributions.Uniform(-0.1, 0)
    β₂dist::Uniform{Float64} = Distributions.Uniform(-0.1, 0)
    α₁::Float64 = round(rand(α₁dist),digits = 2) # constant bank 1
    α₂::Float64 = round(rand(α₂dist),digits = 2)  # constant bank 2
    β₁::Float64 = round(rand(β₁dist),digits = 2)  # coefficient creditwordiness bank 1
    β₂::Float64 = round(rand(β₂dist),digits = 2) # coefficient creditwordiness bank 2

    # unknown mutable parameters from error term
    σ₁::Float64 = 1 # variance of price of bank 1
    σ₂::Float64 = 1 # variance of price of bank 2
    ρ::Float64  = 0.5 # correlation coefficient between price of bank 1 and price of bank 2
    Σ::Array{Float64, 2} = [σ₁ ρ*σ₁*σ₂; ρ*σ₁*σ₂ σ₂] # covariance matrix
    ϵdist::MvNormal{Float64} = Distributions.MvNormal([0,0], Σ)
    
    # true unobserved parameter representing search cost
    k::Float64 = 1  # search cost

end


q = Primitives(σ₁ = 0.5, k = 5)

    """
    simulate(θ,1000)

    Simulate sample data from the model. Returns matrix with sample. 

    # Arguments: 
        - prim: struct Primitives
        - n: number of individuals to simulate
        - seed:  seed for the random number generator

"""
function simulate(prims::Primitives;  n::Integer = 1000, seed::Integer = 350)

    # unpacking primitives from struct
    @unpack v₁, v₂, k, α₁, α₂, β₁, β₂, α₁dist, α₂dist, 
      β₁dist, β₂dist, xdist, ϵdist, zdist = prims

    # setting seed 
    Random.seed!(seed)
    
    # generating creditwordiness
    x = rand(prims.xdist, n)
    # generating arrays of n error terms
    ε = rand(prims.ϵdist, n)' # identification error
    # allocation of homebank, 1 = bank 1, 0 = bank 2
    z = rand(prims.zdist, n) # random initial bank  

    # outcome from bank 1: prices 
    p₁ = α₁ .+ β₁ .* x .+ ε[:,1]    
    # outcome from bank 2: prices
    p₂ = α₂ .+ β₂ .* x .+ ε[:,2]
    # expected price from bank 1
    p₁_ = mean(α₁dist) .+ mean(β₁dist) .* x 
    # expected price from bank 2
    p₂_ = mean(α₂dist) .+ mean(β₂dist) .* x 

    # consumers utility from dealing with price and no search
    # utility from bank 1: 
    u₁ = v₁ .- p₁ 
    # utility from bank 2: 
    u₂ = v₂ .- p₂
    # expected utility from bank 1
    u₁_ = v₁ .- p₁_
    # expected utility from bank 2
    u₂_ = v₂ .- p₂_

    # search: you search if the utility from homebank is smaller than expected utility of other bank - search cost. 
    # d = 0 if no search , d = 1 if search
    d = u₁.*z .+ u₂.*(1 .- z) .<= u₁_.*(1 .- z) .+ u₂_.*z .- k

    # if homebank is not optimal h = 1, if it is optimal h = 0
    h = u₁.*z .+ u₂.*(1 .- z) .<= u₁.*(1 .- z) .+ u₂.*z .- k

    # change banks c = 1 if change bank, c = 0 if no change bank. change when search, and search is optimal.
    c = d .* h

    # choice bank b is 1 if bank 1 is the choice bank and 0 if bank 2 is the choice bank
    b = z .* (1 .- c) .+ (1 .- z) .* c

    # observable price
    p = p₁ .* b .+ p₂ .* (1 .- b)

    # returning DataFrame of simulated data
    data = DataFrame(i = 1:n,
                    x = x,
                    d = d,
                    h = h,
                    c = c,
                    z = z,
                    p = p,
                    u₁ = u₁,
                    u₂ = u₂,
                    b = b,
        )
    return data
end

simulate(q,n = 100000)
end