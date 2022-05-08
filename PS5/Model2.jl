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


end # end of module