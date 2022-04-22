###############################################################################
#== 
  Problem Set 4, Metrics 717, Spring 22

  author: 
    name: Giselle Labrador Badia
    email: labradorbada@wisc.edu

  This file contains functions use to define and solve
   a simple Roy model.
    Functions called y nb_ps4.ipynb
==#
###############################################################################


# importing libraries
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random, Optim

"""
    Define the structure that contains the "true" model parameters.

"""
@with_kw mutable struct Primitives
# true unobserved parameters
    # normalized parameters
    π₁::Float64 = 1.0  # wage in occupation 1
    π₂::Float64 = 1.0  # wage in occupation 2

    # unknown mutable parameters
    # ln(Sᵢ) =μᵢ + ϵᵢ  # log of individual skills by occupation i
    μ₁::Float64 # mean of log skill in occupation 1
    μ₂::Float64 # mean of log skill in occupation 2
    σ₁::Float64 # std of log skill in occupation 1
    σ₂::Float64 # std of log skill in occupation 2
    ρ::Float64  # correlation coefficient
    Σ::Array{Float64, 2} # covariance matrix

end

"""
    initialize(θ)

    Initialize the model and returns Primitives struct.
    
    # Arguments: 
        - θ: a vector structure containing the true parameters in the order: 
        (π₁, π₂, μ₁, μ₂, σ₁, σ₂, ρ).

"""
function initialize(θ::Vector{Float64} = [1, 1, 0, 0, 0.5, 0.5, 0.5 ])

    # Unpack the parameters of the float vector
    π₁, π₂, μ₁, μ₂, σ₁, σ₂, ρ = θ

    # filling covariance matrix
    σ₁₂ = ρ * σ₁ * σ₂ # by ρ= σ₁₂/σ₁ * σ₂
    Σ = [σ₁^2  σ₁₂;
        σ₁₂ σ₂^2] 
    prim = Primitives(π₁=π₁, π₂=π₂, μ₁=μ₁, μ₂=μ₂, σ₁=σ₁, σ₂=σ₂,ρ=ρ, Σ=Σ)

    # Return the primitives struct, parameter vector, and data
    return prim

end 

"""
    simulate(θ,1000)

    Simulate sample data from the model. Returns DataFrame with sample. 

    # Arguments: 
        - θ: a Primitives structure containing the true parameters
        - n: number of individuals to simulate
        - seed:  seed for the random number generator
        - wlowerbound: lower bound on the wage of occupation 1

"""
function simulate(θ::Primitives; n::Integer=1000, seed::Integer=350, w1lowerbound::Float64=-Inf)

    # unpacking primitives from struct
    @unpack π₁, π₂, μ₁, μ₂, σ₁, σ₂, ρ, Σ = θ

    # setting seed 
    Random.seed!(seed)

    # generating array of n individuals
    ε = rand(Distributions.MvNormal([0, 0], Σ), n)' 

    s₁ = exp.(μ₁ .+  ε[:,1])     
    s₂ = exp.(μ₂ .+  ε[:,2])

    w₁ = max.(π₁.*s₁, w1lowerbound)
    w₂ = π₂.*s₂
 
    # returning DataFrame of observations
    data = DataFrame(ind = 1:n,
                    d = 1*(w₁ .>= w₂), # 1 if w₁ >= w₂, 0 otherwise check this 
                    wage=(w₁ .>= w₂).*w₁ + (w₁ .< w₂).*w₂)
    return data
end

"""
    get_params_percent(percent)

    Give a vector of params for which a certain percent of the individuals choose occupation 1. 
    Default bounds look only across correlation parameter ρ.  
    The vector of parameters is (π₁, π₂, μ₁, μ₂, σ₁, σ₂, ρ).

    # Arguments: 
        - percent: the percent of individuals that choose occupation 1
        - precision: the length of the search grids of parameters
        - lower_bounds: lower bounds of the search grids of parameters,
        - upper_bounds: upper bounds of the search grids of parameters

"""
function get_params_percent(percent::Float64, precision::Float64 = 10000.0; 
    lower_bounds = [1.0, 1.0, 1.2, 1, 0.5, 0.01, 0.5], 
    upper_bounds = [1.0, 1.0, 1.2, 1, 0.5, 30 ,0.5], 
    tol = 1e-3)

    # generating grids
    steps = (upper_bounds - lower_bounds .+ 0.1) ./ precision 
    grid = [lower_bounds[t]:steps[t]:upper_bounds[t] for t in 1:length(lower_bounds)]

    # to use for loop over all params, TODO: make more general
    #@sync @distributed for ijklm in 1:n) 
    #        i,j,k,l,m = Tuple(CartesianIndices(ni,nj,nk,nl,nm)[ijklm])
    #end
    
    # simple version just looping over sigma2
    for i in grid[6]
        θ =  [grid[1][1], grid[2][1], grid[3][1], grid[4][1], grid[5][1], i,grid[7][1]]
        # cheching distance to the desired percent, return is close enough
        #println(mean(simulate(initialize(θ)).d .== 1))
        if abs(percent - mean(simulate(initialize(θ), n = 10000).d .== 1)) < tol  return θ end
    end
    # not found
    return [1.0, 1.0, 1.4, 1, 0.4,-Inf,0.5]

end

"""
    get_wlowerbound_percent(percent)

    Give a wage lower bound for which a certain percent of the individuals choose occupation 1. 
    
    # Arguments: 
        - percent: the percent of individuals that choose occupation 1
        - precision: the length of the search grids of parameters

"""
function get_wlowerbound_percent(percent::Float64, θ::Vector{Float64}, precision::Integer =10000)
    # generating grids

    for i in -2:(12/precision):10
        if abs(percent - mean(simulate(initialize(θ),w1lowerbound = i).d .== 1)) < 1e-3  return i end
    end
    return -Inf
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
function simulated_method_moments_objective(θ::Vector{Float64}, ĝ::Vector{Float64};
     n::Int64 = 100000,  weights::Matrix{Float64} = 1.0*Matrix(I, length(ĝ), length(ĝ)))

    # compute observed moments from argument data
    g = get_moments(simulate(initialize(θ), n=n))

    # objective function
    return (g - ĝ)'*weights*(g - ĝ)
end

"""
    get_moments(data::DataFrame)

    Compute the moments of the data, moments are E[d], E[w|d=0], E[w|d=1], V[w|d=0], V[w|d=1].

    # Arguments: 
        - data: a DataFrame with the data.

"""
function get_moments(data::DataFrame)
    # computing the moments from data
    g = [ mean(data.d .== 1), # E[d]
        mean(data.wage[data.d .== 0]), # E[w|d=0]
        mean(data.wage[data.d .== 1]),  # E[w|d=1]
        var(data.wage[data.d .== 0]), # V[w|d=0]
        var(data.wage[data.d .== 1]), # V[w|d=1]
    ]
    return g
end



""" 
    simulated_method_moments(data)

    Estimate the parameters of the model using simulated moments, optimzing the objective function.

    # Arguments:
        - data: a DataFrame with the data.
        - θ₂: the true known parameters.
"""
function simulated_method_moments(data::DataFrame, θ₂::Vector{Float64})
    
    ĝ = get_moments(data)

    #initial guess
    θ₁_0 = [1,0.1]

    result = optimize(θ₁ -> simulated_method_moments_objective(vcat(θ₂[1:2],θ₁[1], θ₂[3:5], θ₁[2]), ĝ),
            θ₁_0 ,
            NelderMead(),
            Optim.Options(g_tol = 1e-12, iterations = 2000))

    return result.minimizer
end




