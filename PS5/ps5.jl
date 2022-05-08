
# adding working directory to load path
#push!(LOAD_PATH,"./src/");
push!(LOAD_PATH,"./PS5/");

# adding working directory/src/ to load path
LOAD_PATH

# loading model
using Model1, Model2, MyRegression
m1 = Model1
m2 = Model2


m1.simulate()

m2.simulate()

m2.simulate(1000, 3)
