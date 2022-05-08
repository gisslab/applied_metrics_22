module MyRegression

"""
    Define the structure that contains beta coefficients and variance-covariance matrix.
"""
struct OLSprimitive
    β::Vector{Float64} # regression coefficients
    V::Matrix{Float64} # variance-covariance matrix 
end

"""
    Define the structure that contains beta coefficients and variance-covariance matrix.
"""
struct TSLSprimitive
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
    return OLSprimitive(β=β, V=V)
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

    # adjust Z to include all exogenous variables
    Z = [Z X[:, setdiff(1:p, 1 + intercept)]]

    # compute beta coefficients
    β = inv(X'Z * inv(Z'Z) * Z'X) * X'Z * inv(Z'Z) * Z'Y

    # compute variance-covariance matrix
    Ω = (Y - X*β)'*(Y - X*β)/(size(Y, 1) - size(X, 2))
    V = inv(X'Z*inv(Z'Z)*Z'X).*Ω 

    # compute the F statistic from the first-stage regression
    X = X[:, 1 + intercept] # remove the intercept
    Z_ = X[:, setdiff(1:p, 1 + intercept)] # remove the covariate = X? or z

    reg = ols(X_, Z; intercept=false) 
    σ¹ = (X_ - Z*reg.β)' * (X_ - Z*reg.β) # residual variance

    reg = ols(X_, Z_; intercept=false) 
    σᶜ = (X_ - Z_*reg.β)' * (X_ - Z_*reg.β) # residual variance

    F = ((σᶜ - σ¹) * (nᵢ - k_)) / ( k* σ¹) # F-statistic

    return TSLSprimitive(β=β, V=V, Fstat=F)


end # 2SLS()



end # end module