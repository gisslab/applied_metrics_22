###############################################################################
#== 
  Problem Set 5, Metrics 717, Spring 22

  Module Question 1

  author: 
    name: Giselle Labrador Badia
    email: labradorbada@wisc.edu

  This file contains functions use to define and solve
   a simple Roy model.

==#
###############################################################################

module Model2 

# importing libraries
using Parameters, DataFrames, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random, Optim

"""
    Define the structure that contains the "true" model parameters.

"""
@with_kw struct Primitives
# true unobserved parameters
    
    p::Float64 = 0.3 # probability Z=1
    σ₀::Float64 = 1.0
    σ₁::Float64 = 1.0
    σ₂::Float64  = 1.0# variance of V
    σ01::Float64 = 0.5
    σ02::Float64 = 0.3
    σ12::Float64 = 0.7
    # covariance matrix
    Σ= [σ₀ σ01 σ02;  σ01 σ₁ σ12;  σ02 σ12 σ₂] #::Array{Float64, 3}  ,error
                            
end

"""
    Define the structure for treatment effects.

"""
@with_kw mutable struct TreatmentEffect
    # true unobserved parameters
        
    ate::Float64  
    atet::Float64
    ateu::Float64
    ols_coeff::Vector{Float64}
    iv_coeff::Vector{Float64}
    itt::Float64            
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

    d = v .>= 0
    y = y₁ .* d + y₀.* (1 .- d)

    # returning DataFrame of simulated data
    data = DataFrame(i = 1:n,
                    d = d,
                    z = z,
                    y = y,
                    y0 = y₀,
                    y1 = y₁,
                    v = v)
    return data
end

"""
treatmente_ffects(data)

    Calculate ATE, ATET, ATEU, ols,direct/reduced reform/itt and iv. 
    Returns a struct TreatmentEffect with the results.

    # Arguments:
        - data: DataFrame with the simulated data.
"""
function treatment_effects(data)

    te = TreatmentEffect()
    # ate
    te.ate = mean(data.y1 .- data.y0)

    # atet
    te.atet = mean(data.y1[data.v .> 0] .- data.y0[d.v .> 0])

    # ateu
    te.ateu = mean(data.y1[data.v .< 0] .- data.y0[d.v .< 0])

    # ols naive estimator
    te.ols = mean(data.y[data.v .> 0]) - mean(data.y[data.v .< 0])

    # iv 
    num_iv = (mean(data.y[data.z .== 1]) - mean(data.y[data.z .== 0]))
    den_iv = (mean(data.d[data.z .== 1]) - mean(data.d[data.z .== 0]))
    te.iv =  num_iv / den_iv

    # direct/reduced form/itt estimator
    te.itt = num_iv

    return te
end # end of module