###############################################################################
#== 
  Problem Set 5, Metrics 717, Spring 22

  Module Question 1

  author: 
    name: Giselle Labrador Badia
    email: labradorbada@wisc.edu

  This file contains functions use to define and solve
   a simple Erning vs Schooling model.

==#
###############################################################################

module Model1

# importing libraries
using Parameters, DataFrames, LinearAlgebra, Distributions
using LinearAlgebra, StatsBase, Random, Optim

"""
    Define the structure that contains the "true" model parameters and DGP of earnings.

"""
@with_kw struct Earnings

        # hourly earnings
        lnwfun::Function = (s, a, ϵ) -> 1 + 0.05*s + 0.1*a + ϵ
        # variables distributiions
        ϵdist::Normal{Float64} = Normal(0, 0.5)
        adist::Normal{Float64} = Normal(0, 4)

end

"""
    Define the structure that contains the "true" model parameters and DGP of schooling.

"""
@with_kw struct Schooling

        # schooling function
        sfun::Function = (a, z₁, z₂, η) -> 3*a + z₁ + z₂ + η
        #  variables distributions
        z₁dist::Normal{Float64} = Distributions.Normal(0, 0.1)
        z₂dist::Normal{Float64} = Distributions.Normal(0, 25)
        z₃dist::Uniform{Float64} = Distributions.Uniform(0, 25)
        ηdist::Normal{Float64} = Distributions.Normal(0, 1)
end

"""
    getprimitives()

    Initialize the model and returns Primitives struct.

"""
function getprimitives()

    # return the primitives structs
    return  Earnings(),Schooling()
end


"""
    simulate(θ,1000)

    Simulate sample data from the model. Returns matrix with sample. 

    # Arguments: 
        - n: number of individuals to simulate
        - seed:  seed for the random number generator

"""
function simulate(n::Integer=1000, seed::Integer=350)

    # set seed for reproducibility
    Random.seed!(seed)

    # unpack model primitives 
    @unpack  lnwfun, adist, ϵdist  = Earnings()
    @unpack sfun, z₁dist, z₂dist, z₃dist, ηdist = Schooling()
    
    # generate arrays of n individuals per variable

    # earning vars
    a, ϵ = rand(adist, n)', rand(ϵdist, n)' #a is actually a shared variable :/
    # scholing vars
    z₁, z₂, z₃, η = rand(z₁dist, n)', rand(z₂dist, n)', rand(z₃dist, n)',rand(ηdist, n)'

    s = sfun.(a, z₁, z₂, η) # schooling
    lnw = lnwfun.(s, a, ϵ) # earnings

     # matrix of observables
    return [z₁' z₂' z₃' lnw' s']

    #DataFrame
    #return DataFrame(i = 1:n, z1 = z₁', z2 = z₂', z3 = z₃',
    #                 s = convert(Array{Float64},s), lnw = convert(Array{Float64},lnw)')
end




end # end of module