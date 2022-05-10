using Printf, Combinatorics, Statistics, StatsBase, Latexify
# adding working directory to load path
push!(LOAD_PATH,"./PS5/");

# adding working directory/src/ to load path
LOAD_PATH

# loading model
using Model1, Model2, MyRegression
m1 = Model1
m2 = Model2

###############################################
# Question 1, Part 2
###############################################

# a: simulate data, N = 2000
d1 = m1.simulate(2000)

# b: ols estimates
ols = MyRegression.ols(d1[:,4],d1[:,5])

# c: instruments

# corr coefficient
corr = cor(d1[:, 1:4])

# d: iv estimates
# 2sls with instruments
iv_1 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1]])
iv_2 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2]])
iv_3 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[3]])
iv_12 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,2]])
iv_13 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,3]])
iv_23 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2,3]])
iv_123 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1, 2, 3]])

matrix_latex = [ols.V[1,1] iv_1.V[1,1] iv_2.V[1,1] iv_3.V[1,1] iv_12.V[1,1] iv_13.V[1,1] iv_23.V[1,1] iv_123.V[1,1];
                ols.β[1] iv_1.β[1] iv_2.β[1] iv_3.β[1] iv_12.β[1] iv_13.β[1] iv_23.β[1] iv_123.β[1];
                ols.V[2,2] iv_1.V[2,2] iv_2.V[2,2] iv_3.V[2,2] iv_12.V[2,2] iv_13.V[2,2] iv_23.V[2,2] iv_123.V[2,2];
                ols.β[2] iv_1.β[2] iv_2.β[2] iv_3.β[2] iv_12.β[2] iv_13.β[2] iv_23.β[2] iv_123.β[2];
                0 iv_1.Fstat iv_2.Fstat iv_3.Fstat iv_12.Fstat iv_13.Fstat iv_23.Fstat iv_123.Fstat]

matrix_latex = round.(matrix_latex, sigdigits = 4)
head_ = ["OLS"  "IV1" "IV2" "IV3" "IV12" "IV13" "IV23" "IV123"]
side_ = ["","", "intercept", "" , "\\beta", "F stat"]

latex = latexify(matrix_latex, env = :table, head = head_ , side = side_,
                latex = false, adjustment = :r, booktabs = true)

# f: estimate N=500000
d1 = m1.simulate(500000)

ols = MyRegression.ols(d1[:,4],d1[:,5])

# 2sls with instruments
iv_1 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1]])
iv_2 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2]])
iv_3 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[3]])
iv_12 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,2]])
iv_13 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,3]])
iv_23 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2,3]])
iv_123 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1, 2, 3]])


matrix_latex = [ols.V[1,1] iv_1.V[1,1] iv_2.V[1,1] iv_3.V[1,1] iv_12.V[1,1] iv_13.V[1,1] iv_23.V[1,1] iv_123.V[1,1];
                ols.β[1] iv_1.β[1] iv_2.β[1] iv_3.β[1] iv_12.β[1] iv_13.β[1] iv_23.β[1] iv_123.β[1];
                ols.V[2,2] iv_1.V[2,2] iv_2.V[2,2] iv_3.V[2,2] iv_12.V[2,2] iv_13.V[2,2] iv_23.V[2,2] iv_123.V[2,2];
                ols.β[2] iv_1.β[2] iv_2.β[2] iv_3.β[2] iv_12.β[2] iv_13.β[2] iv_23.β[2] iv_123.β[2];
                0 iv_1.Fstat iv_2.Fstat iv_3.Fstat iv_12.Fstat iv_13.Fstat iv_23.Fstat iv_123.Fstat]

matrix_latex = round.(matrix_latex, sigdigits = 4)
latex = latexify(matrix_latex, env = :table, head = head_ , side = side_,
                latex = false, adjustment = :r, booktabs = true)

###############################################
# Question 2, Part 2
###############################################

d2 = m2.simulate(10000,2)

d2d = m2.simulate(10000, 3)

te = m2.treatment_effects(d2)

te1 = m2.treatment_effects(d2d)