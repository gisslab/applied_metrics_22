using Printf, Combinatorics, Statistics, StatsBase
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

d1 = m1.simulate(2000)

ols = MyRegression.ols(d1[:,4],d1[:,5])

# corr coefficient
corr = cor(d1[:, 1:4])

# 2sls with instruments
iv_1 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1]])
iv_2 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2]])
iv_3 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[3]])
iv_12 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,2]])
iv_13 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1,3]])
iv_23 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[2,3]])
iv_123 = MyRegression.tsls(d1[:,4],d1[:,5], d1[:,[1, 2, 3]])



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

###############################################
# Question 2, Part 2
###############################################

d2 = m2.simulate(10000,2)

d2d = m2.simulate(10000, 3)

te = m2.treatment_effects(d2)

te1 = m2.treatment_effects(d2d)