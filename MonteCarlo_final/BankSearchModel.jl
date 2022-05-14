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
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random, Optim


@with_kw struct Primitives
    # parameter to generate data, observables:
    # creditwordiness distributes exponential parameter lambda
    λ::Float64 = 0.01 # lambda parameter of expoential distribution 
    μₓ::Float64 = 1/λ  # mean of X, creditworthiness  
    xdist::Exponential{Float64} = Exponential{Float64}(μₓ) # distribution of X, creditworthiness
    # true observed parameters from valuation of individuals
    v₁::Float64 = 20 # valuation from bank 1
    v₂::Float64 = 18# valuation from bank 2
    
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
    σ₁::Float64 = 0.5 # variance of price of bank 1
    σ₂::Float64 = 0.5 # variance of price of bank 2
    ρ::Float64  = 0.2 # correlation coefficient between price of bank 1 and price of bank 2
    Σ::Array{Float64, 2} = [σ₁ ρ*σ₁*σ₂; ρ*σ₁*σ₂ σ₂] # covariance matrix
    ϵdist::MvNormal{Float64} = Distributions.MvNormal([0,0], Σ)
    
    # true unobserved parameter representing search cost
    k::Float64 = 1  # search cost

end


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
    data = DataFrame(x = x,
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



"""
    get_moments(data::DataFrame)

    Compute the moments from the data.

    # Arguments: 
        - data: a DataFrame with the data.

"""
function get_moments(data::DataFrame; filter = [1,2,3,4])
    # computing the moments from data

    g = [ mean(data.d .== 1), # E[d]
          mean(data.c .==1) ,#E[c]
          mean(data.d[data.b .== 1]), # E[d|b=1]
          mean(data.d[data.b .== 0]), # E[d|b=0]
          mean(data.c[data.b .== 1]), # E[c|b=1]
          mean(data.c[data.b .== 0]), # E[c|b=0]
          mean(data.p), # E[p]
          mean(data.b),  # percent of population that chose bank 1
          mean(data.p[data.d .== 0]), # E[p|d=0] # mean of prices when search
          mean(data.p[data.d .== 1]), # E[p|d=1] # mean of prices when no search
          mean(data.p[data.c .== 0]), # E[p|c=0] # mean price homebank when change
          mean(data.p[data.c .== 1]), # E[p|c=1] # mean price other bank when change
          var(data.p[data.d .== 0]), # V[p|d=0] # variance price when search
          var(data.p[data.d .== 1]), # V[p|d=1] # variance price bank when search
          var(data.p[data.c .== 0]), # V[p|c=0] # variance price homebank when no change
          var(data.p[data.c .== 1]), # V[p|c=1] # variance price other bank when change
          mean(data.p[data.b .== 1]), # E[p1] # mean price bank 1 (observables only)
          mean(data.p[data.b .== 0]), # E[p2] # mean price bank 2 (observables only)
          var(data.p[data.b .== 1]), # V[p1] # variance price bank 1 (observables only)
          var(data.p[data.b .== 0]), # V[p2] # variance price bank 2 (observables only)
    ]
    return g[filter]
end

"""
    simulated_method_moments_objective()

    Objective function that compares simulated moments with moments passed in arguments.
    The vector of parameters is (π₁, π₂, μ₁, μ₂, σ₁, σ₂, ρ).

    # Arguments:
        - θ: a vector containing the true parameters
        - ĝ: a vector containing the data moments
        - n: number of individuals to simulate
        - weights: a matrix of weights for the moments

"""
function simulated_method_moments_objective(θ₀::Vector{Float64}, 
        θ₁::Vector{Float64},
        ĝ::Vector{Float64};
        n::Int64 = 100000,  
        filter = [1,2,3,4],
        weights::Matrix{Float64} = 1.0*Matrix(I, length(filter), length(filter)))

    # positive variance
    if θ₁[1] <= 0 return Inf end

    # creating primitive from params
    prim = Primitives(α₁ = θ₀[1], β₁ = θ₀[2], α₂ = θ₀[3], β₂ = θ₀[4], 
                       k = θ₁[1])
    # compute observed moments from argument data
    g = get_moments(simulate(prim, n=n), filter = filter)
    # adjusting weight matrix
    for i in 1:length(ĝ) weights[i,i] = 1\ĝ[i] end
    # objective function
    return (g - ĝ)'*weights*(g - ĝ)
end


""" 
    simulated_method_moments(data)

    Estimate the parameters of the model using simulated moments, optimzing the objective function.

    # Arguments:
        - data: a DataFrame with the data.
        - θ₂: the true known parameters.
"""
function simulated_method_moments(data::DataFrame, 
                                  θ₀::Vector{Float64},
                                  initial_guess::Vector{Float64},
                                  lower::Vector{Float64}, 
                                  upper::Vector{Float64};
                                  filter = [1,2,3,4])
    
    ĝ = get_moments(data, filter = filter)

    # simulate moments 


    result = optimize(θ₁ -> simulated_method_moments_objective(θ₀, θ₁, ĝ, filter = filter),
            lower, 
            upper,
            initial_guess,
            NelderMead(),
            Optim.Options(g_tol = 1e-12, iterations = 100000))
            #,Fminbox(GradientDescent()),
            #Optim.Options(g_tol = 1e-12, iterations = 5000))

    return result.minimizer
end




end # module