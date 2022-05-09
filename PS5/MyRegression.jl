module MyRegression

using Parameters, LinearAlgebra, Distributions, LinearAlgebra, StatsBase, Random

"""
    Define the structure that contains beta coefficients and variance-covariance matrix.
"""
@with_kw mutable struct OLSprimitive
    β::Vector{Float64} # regression coefficients
    V::Matrix{Float64} # variance-covariance matrix 
end

"""
    Define the structure that contains beta coefficients and variance-covariance matrix.
"""
@with_kw struct TSLSprimitive
    β::Vector{Float64} # regression coefficients
    V::Matrix{Float64} # variance-covariance matrix 
    Fstat::Float64 # F-test statistic
end

"""
    ols(Y,X)

    # Arguments:
    - Y: a vector of dependent variables
    - X: a matrix of independent variables
    - intercept: boolean, true if the model has an intercept
"""
function ols(Y::Vector{Float64}, X::Array{Float64}; intercept::Bool = true)

    nᵢ = size(X, 1) # number of individuals
    p = size(X, 2) # number of independent variables

    #  column of 1 when intercept is true
    if intercept
        X = [ones(nᵢ) X]
    end

    # compute beta coefficients 
    β = inv(X'X)*X'Y

    # compute variance-covariance matrix
    Ω = (Y - X*β)'*(Y - X*β)/(nᵢ - p)
    V = inv(X'X).*Ω

    # return the point estimates and variance-covariance matrix
    return OLSprimitive(β, V)
end    # end of OLS function


"""
    tsls(Y,X)

    # Arguments:
    - Y: a vector of dependent variables
    - X: a matrix of independent variables
    - intercept: boolean, true if the model has an intercept
"""
function tsls(Y::Vector{Float64}, X::Array{Float64}, Z::Array{Float64}; 
    intercept::Bool=true, Ftest::Bool=false,
    endogIndex::Int64=1)

    nᵢ = size(X, 1) # number of individuals
    p = size(X, 2) # number of independent variables
    k = size(Z, 2) # number of exogenous variables, instrumental variables

    #  column of 1 when intercept is true
    if intercept
        X = [ones(nᵢ, 1) X]
    end

    #Z includes all exogenous variables
    Z = [Z X[:, setdiff(1:p, 1 + intercept)]]

    # compute beta coefficients
    β = inv(X'Z * inv(Z'Z) * Z'X) * X'Z * inv(Z'Z) * Z'Y

    # compute variance-covariance matrix
    Ω = (Y - X*β)'*(Y - X*β)/(size(Y, 1) - size(X, 2))
    V = inv(X'Z*inv(Z'Z)*Z'X).*Ω 

    #########################################################
    # compute the F statistic from the first-stage regression
    Z_ = X[:, setdiff(1:p, 1 + intercept)] # remove the covariate = X? or z
    X = X[:, 1 + intercept] # remove the intercept

    reg = ols(X, Z; intercept=false) 
    σ = (X - Z*reg.β)' * (X - Z*reg.β) # residual variance

    reg = ols(X, Z_; intercept=false) 
    σ₂ = (X - Z_*reg.β)' * (X - Z_*reg.β) # residual variance


    F = ((σ₂ - σ) * (nᵢ - k+1)) / ( (k)* σ) # F-statistic

    return TSLSprimitive(β, V, F)


end # 2SLS()



end # end module