
clear all
log using "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 1/log_ps1.log", replace


/*
	Problem set 1, Econ 717
	
	Date created:  10 Feb 2022
	
	Last modified: 16 Feb 2022
	
	Author: Giselle Labrador-Badia (labradorbada@wisc.edu)
*/


/* Setup */




// establish working directory
cd "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 1"


// Loading data
use "Field et al (2010) Analysis Sample.dta", clear

// independent variables in macro	`'
glob X Treated Client_Age Client_Married Client_Education HH_Size HH_Income ///
		muslim Hindu_SC_Kat 
		
// independent variables in without muslin and married
glob X1 Treated Client_Age Client_Education HH_Size HH_Income ///
		Hindu_SC_Kat 

/* parameters */

// tolerance parameter
glob tol = 1e-3

//cutoff
glob cutoff = 0.5

// save outreg 
glob opts "tex(frag) nor noobs noas"

/* question 1 */
/*
Drop observations with missing values of client age or client marital status or client education 
or client household income
*/

//dropping missing values in selected fields
drop if missing(Client_Age,Client_Married,HH_Income, Client_Education)
// manually since the missing values are not properly coded
drop if Client_Age == 0 

//sample size
glob sample_size = _N

/* question 2 */
/*
Estimate a linear probability model with loan take-up as the dependent variable.
*/


// Linear Probability Model (LPM)
reg taken_new $X 
estimates store model_ols

// exporting table of coefficients
//outreg2 using table1.tex, replace ctitle("LPM") $opts	

// getting from return list value coefficient of age
loc lpm_coeff = r(value) 

// getting predicted take ups (questions 4)
predict lpm_taken_xb, xb
predict lpm_resid, residuals

/* question 3 */
/*
Repeat the estimation in Problem 2 with the robust option. How big are the differences, if 
any? Which standard errors are larger?  
*/

// robust regression
//rreg taken_new `X'
reg taken_new $X , robust
estimates store model_robust
//exporting table of coefficients
//outreg2 using table1.tex, append ctitle("RLPM") $opts


/* question 4 */
/*
Generate predicted probabilities of loan take-up using the estimated coefficients from Problem 
2. Do any of these probabilities lie outside [0, 1].
*/


sum lpm_taken_xb
//exporting
tabstat lpm_taken_xb, c(stat) stat(mean sd min max n)
estpost tabstat lpm_taken_xb, c(stat) stat(mean sd min max n)
esttab using "table_q4.tex", replace ///
 cells(" mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min max count") nonumber ///
  nomtitle nonote noobs label collabels( "Mean" "SD" "Min" "Max" "N")

/* question 5 */
/*
Estimate the model by weighted least squares using Stata's vwls (variance weighted least 
squares) command. 
*/


egen sd_var = sd(taken_new)
vwls taken_new $X , sd(sd_var)
estimates store model_wls
// exporting table of coefficients
//outreg2 using table1.tex, append ctitle("WLS") $opts

/* question 6 */
/*
Estimate probit and logit models of loan take-up using the same independent variables as in 
Problem 2. 
*/

//probit regression
probit taken_new $X 
estimates store  model_prob
//outreg2 using table1.tex, append ctitle("Probit") $opts
// getting estimates for question 7
predict prob_taken_pr, pr
predict prob_taken_xb, xb
loc prob_beta_age = _b[Client_Age]
	
// logit regression
logit taken_new $X 
estimates store  model_log
//outreg2 using table1.tex, append ctitle("Logit") $opts
// getting estimates for question 7
predict log_taken_pr, pr
predict log_taken_xb, xb
//posestimation
loc log_beta_age = _b[Client_Age]


/* question 7 */
/*
Calculate the mean partial derivatives (a.k.a. marginal effects or average partial effects) of the 
conditional probabilities of loan take-up with respect to client age for the LPM, logit and probit 
models.
*/

//LPM
display `lpm_coeff'

//Logit
// mean of distribution for each obs times coefficient for age
tempvar mean_log
//logit formula
gen mean_log = `log_beta_age'*(exp(log_taken_xb)/((1 + exp(log_taken_xb))^2))
loc logit_coeff = r(value)


//Probit

// a) dprobit
dprobit taken_new $X
// ereturn list to matrix
mat deriv = e(dfdx)
loc prob_a = r(value)


// b) "by hand"
//set trace on
gen mean_prob = `prob_beta_age'* normalden(prob_taken_xb) 
sum mean_prob
loc prob_b = r(value)
	
// c) change age by a little bit
probit taken_new $X 
replace Client_Age = Client_Age + $tol
predict prob_predict_7c, pr 
replace mean_prob = (prob_predict_7c - prob_taken_pr)/$tol
sum mean_prob
loc prob_c = r(value)
	
// d) margins command
margins, dydx(Client_Age)
mat deriv_d = r(table)
loc prob_d = r(value)

// back to normal, age
replace Client_Age = Client_Age - $tol

/* question 8 */
/*
Re-estimate the LPM including a quartic in client age (i.e. including linear, squared, cubed and 
fourth power terms), rather than just a linear term. Calculate the average derivative numerically, 
as in part c.
*/

//generating variables
gen age2 = Client_Age^2
gen age3 = Client_Age^3
gen age4 = Client_Age^4

// regressing with quartic (LPM)
reg taken_new Treated Client_Age age2 age3 age4 Client_Married Client_Education HH_Size HH_Income ///
	muslim Hindu_SC_Kat 
//estimates store  model_quartic
//outreg2 using table1.tex, append ctitle("QLPM") $opts
//save log-likelilood (question 9)
loc loglik = e(ll) 
// save prediction
predict qlpm, xb


// same as in 7c
replace Client_Age = Client_Age + $tol

//generating variables
replace age2 = Client_Age^2
replace age3 = Client_Age^3
replace age4 = Client_Age^4

predict qlpm_7c, xb

replace mean_prob = (qlpm_7c - qlpm)/$tol
sum mean_prob
loc qlpm_c = r(value)

/* question 9 */
/*
 For the probit model estimated in Problem 6, calculate the value of the LRI "by hand" by 
obtaining the likelihood values for the model in Problem 6 and a model with only an intercept 
and plugging them into the LRI formula. 
*/

probit taken_new 
estimates store  model_prob0
//LRI
lrtest model_prob model_prob0
//by hand
display (1 - (`loglik'/e(ll)))

/* question 10 */
/*
Calculate the correct prediction rate for the probit model estimated in Problem 6 using both 
0.5 and the sample fraction taking up a loan as cutoff values. In each case, take the equally 
weighted average of the correct prediction rates for those who take up a loan and those who do 
not.
*/

// calculating prediction rates using 0.5 and cutoff fraction (population rate)
//ols

quietly sum taken_new 
loc pop_rate = r(mean)
display `pop_rate'
sum prob_taken_xb

//probit

// 0.5 cutoff
count if   ((prob_taken_pr >= $cutoff & taken_new == 1) | (prob_taken_pr < $cutoff  & taken_new == 0)) 
glob pred_count_prob = r(N)/$sample_size

//population rate
count if   ((prob_taken_pr >= `pop_rate' & taken_new == 1) |(prob_taken_pr < `pop_rate'  & taken_new == 0)) 
glob pred_count_prob_mean = r(N)/$sample_size		

/* question 11 */
/*
Examine the difference between in-sample and out-of-sample predictive success by 
estimating the model using the usual covariates but only those observations with imidlineid < 
1400. 
*/
//obtaining population size out-of-sample
count if imidlineid >= 1400
loc sample_size_2 = r(N)

//in-sample and out-of-sample predictive success


// probit

probit  taken_new $X if imidlineid < 1400
predict prob_pred_xb, xb  // if !e(sample) 
quietly sum taken_new if imidlineid < 1400
loc pop_rate1 = r(mean)
display `pop_rate1'

		
// 0.5 cutoff
count if   ((imidlineid >= 1400) & ((prob_taken_pr >= $cutoff & taken_new == 1) | (prob_taken_pr < $cutoff  & taken_new == 0))) 
glob pred_count_prob_out = r(N)/`sample_size_2'
display $pred_count_prob_out

//population rate  
count if   ((imidlineid >= 1400) & ((prob_taken_pr >= `pop_rate1' & taken_new == 1) |(prob_taken_pr < `pop_rate1'  & taken_new == 0))) 
glob pred_count_prob_mean_out = r(N)/`sample_size_2'
display $pred_count_prob_mean_out	
	

/* question 12 */
/*
Estimate a probit model of loan take-up including the usual covariates plus an interaction 
term between married and Muslim. 
*/

//creating interaction term
gen mus_married = muslim*Client_Married
probit taken_new $X i.mus_married
outreg2 using table_q12.tex, replace ctitle("muslim*Client_Married") $opts

/* question 13 */
/*
Compare mean finite differences of the interaction term calculated without the additional 
terms highlighted in the Ai and Norton (2003) paper in the probit model estimated in Question 
12 with mean interaction effects that included these terms calculated "by hand" in Stata 
*/
//probit model without interaction

probit taken_new $X 
// variable to build effects
gen y = _b[_cons]

foreach x in $X1{
    replace y = y //+ _b[`x']*`x'
}


// effect for married
replace y = normal(y + _b[Client_Married]) - normal(y)
quietly sum y
glob marr13_ = r(mean)

// effect for muslim
replace y = normal(y+ _b[muslim]) - normal(y)
sum y
glob mus13_ = r(mean)


glob all13_= $marr13_ + $mus13_



//  model without interaction


probit taken_new $X 1.mus_married
// variable to build effects
replace y = _b[_cons]

// = constant + beta * x
foreach x in $X1{
    replace y = y + _b[`x']*`x'
}
gen y_copy = y


// interaction effect
replace y = normal(y + _b[Client_Married] + _b[muslim] ///
			+ _b[1.mus_married]) ///
			- normal(y + _b[muslim]) ///
			+ normal(y) ///
			- normal(y+ _b[Client_Married]) ///

quietly sum y
glob mus_marr13 = r(mean)
display r(sd)


// effect for married
replace y = normal(y_copy + _b[Client_Married]) - normal(y_copy)
quietly sum y    
glob marr13 = r(mean)

// effect for muslim
replace y = normal(y_copy + _b[muslim]) - normal(y_copy)
quietly sum y   
glob mus13 = r(mean)

// all three effects
glob all13 = $mus13 + $marr13 + $mus_marr13 


/* question 14 */
/*
What is the standard deviation of the estimated interaction effects?
*/
qui count if muslim == 1 & Client_Married == 1 
display r(N)
display (r(N)/_N)

/* question 15 */
/*
Estimate a regression of the squared residuals from a linear probability model of loan take-up 
with the usual covariates on the usual covariates.
*/
gen resid2 = lpm_resid^2 
//regression of the squared resid using OLS
reg resid2 Client_Age Client_Married Client_Education HH_Size HH_Income muslim Hindu_SC_Kat Treated
outreg2 using table_q15.tex, replace ctitle("Resid2") $opts

// heteroskedasticity test
// H0: no heteroskedasticity
di "LM=",e(N)*e(r2)
local chi = chi2tail(8,4.4958)
dis `chi''// fail to reject H0 

/* question 16 */
/*
Using the hetprob command, estimate a probit model of loan take-up on the usual 
covariates, allowing for heteroskedasticity that depends on client age and education. 
*/

hetprob taken_new $X, het(Client_Age Client_Education)
outreg2 using table_q12.tex, append ctitle("Hetprob", "lnsigms (Hetprob)") $opts


log close

