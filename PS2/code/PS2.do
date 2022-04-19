
clear all
log using "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 2/log_ps2.log", replace


/*
	Problem set 2, Econ 717
	
	Date created:  02 Mar 2022
	
	Last modified: 08 Mar 2022
	
	Author: Giselle Labrador-Badia (labradorbada@wisc.edu)
*/


/* Setup */


// establish working directory
cd "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 2"


// Loading data
/* National Supported Work Demonstration (NSW). This is the 
same data used by LaLonde (1986), Heckman and Hotz (1989), Dehejia and Wahba (1999,2002) 
and Smith and Todd (2005) and many others. */
use "Economics 717 Spring 2022 NSW Data.dta", clear

//Software: psmatch2.ado for Stata 
//net search psmatch2 
//ssc install psmatch2, replace

//generating age squared variable
gen age2 = age^2

// independent variables in macro, no treatment variable
glob X1 age age2 edu black hisp married nodegree
glob X age age2 edu black hisp married nodegree re74 re75

// save outreg 
glob opts "tex(frag) nor noobs noas"

/* question 0 */
/*
Drop the observations from the PSID comparison group. 
*/

drop if sample == 3


/* question 1 */
/*
Generate an experimental impact estimate by running a regression of earnings in 1978 on the 
treated variable along with age, age squared, education, black, Hispanic, married, no degree and 
earnings in "1974" and 1975.
*/

reg re78 treated $X, robust
outreg2 using table_q1.tex, replace `opts'

/* question 2 */
/*
Drop the experimental treatment group.  
*/

drop if treated == 1 

//sample size
glob sample_size = _N

/* question 3 */
/*
Estimate two sets of propensity scores using a probit model. 
*/

// creating experiment variable  d = 1 if sample = 1,  d = 0 if sample = 2
gen exp = 1 if sample == 1 //for the experimental sample (the union of the treatment and control groups) 
replace exp = 0 if sample == 2 //for the comparison group from the Current Population Survey (CPS) 

// analysis of differences in characteristics accross d=1 and d=0
eststo clear
hist age, by(exp) color(red%30)
hist educ, by(exp) color(blue%30)


// probit without re74, re75 ("coarse" scores)
probit exp  $X1
predict pscorea, pr

// probit with re74, re75 ("rich" scores)
probit exp $X
predict pscoreb, pr



/* question 4 */
/*
Examine the distributions of estimated propensity scores in the control group and comparisons 
group samples. 
*/

//distribution of propensity scores

tabstat pscorea, by(exp) stat(min p25 median mean p75 max n)
tabstat pscoreb, by(exp) stat(min p25 median mean p75 max n)

est clear
eststo: estpost tabstat pscorea, by(exp) stat(min p25 median mean p75 max n)
esttab using "question4a.tex", replace unstack cells("Min p25 p50 Mean p75 Max count") compress ///
title("pscorea")

est clear
eststo: estpost tabstat pscoreb, by(exp) stat(min p25 median mean p75 max n)
esttab using "question4b.tex", replace unstack cells("Min p25 p50 Mean p75 Max count") compress ///
title("pscoreb")

		
/* question 5 */
/*
Construct a histogram of the estimated propensity scores for the combined experimental 
control group and for the CPS comparison group.
*/
//method 1
twoway hist pscorea, by(exp) title(Propensty Score A) color(red%30) xlab(0(.1)0.8) width(0.1)
twoway hist pscoreb, by(exp) title(Propensity Score B)  color(blue%30) xlab(0(.1)0.8) width(0.1)


//method 2
twoway	///
	hist pscorea if exp == 0, width(0.05) color(red%30)		||	///
	hist pscorea if exp == 1, width(0.05) color(green%30)			///
		ylab(, angle(horizontal)) graphregion(color(white))		///
		leg(lab(1 "exp = 0") lab(2 "exp = 1") region(lstyle(none)) nobox) 	///
		xlab(0(.2)0.8) name(pscorea_hist, replace)		///
		xtitle("Propensity Score A") ytitle("Count")

twoway	///
	hist pscoreb if exp == 0, width(0.05) color(red%30)		||		///
	hist pscoreb if exp == 1, width(0.05) color(green%30)				///
		ylab(, angle(horizontal)) graphregion(color(white))			///
		leg(lab(1 "exp=0") lab(2 "exp=1") region(lstyle(none)) nobox) 	///
		xlab(0(.2)0.8) xtitle("Propensity Score B") ytitle("Count")			///
		name(pscoreb_hist, replace)

// method 3
egen binsa = cut(pscorea), at(0(0.05)1) icodes
graph bar (count) pscorea, over(exp) over(binsa, label(nolab)) asyvars 

egen binsb = cut(pscoreb), at(0(0.05)1) icodes
graph bar (count) pscoreb, over(exp) over(binsb, label(nolab)) asyvars

/* question 6 */
/*
Construct non-experimental bias estimates for both sets of estimated propensity scores using 
single nearest neighbor matching without replacement. Impose the common support condition 
using the min-max version described in the lecture notes. 
*/


// Psmatch, coarse pscores
psmatch2 exp, outcome(re78) pscore(pscorea) common noreplacement
// Count observations to drop
sum pscorea if _support == 0 & treated == 0


// Psmatch, rich pscores
psmatch2 exp, outcome(re78) pscore(pscoreb) common noreplacement

/* question 7 */
/*
Repeat Problem 6 but using single nearest neighbor matching with replacement. 
*/

// Psmatch coarse scores
psmatch2 exp, outcome(re78) pscore(pscorea) common

// Psmatch rich scores
psmatch2 exp, outcome(re78) pscore(pscoreb) common

/* question 8 */
/*
Estimate the standardized difference in "real earnings in 1974" and "real earnings in 1975" 
based on the raw data and based on the rich scores and single nearest neighbour matching with 
replacement. 
*/

// Standardized differences in the raw data
//stddiff calculates the standardized difference between two groups
stddiff re74, by(exp)
stddiff re75, by(exp)

//coarse scores
// Standardized differences in the matched data
psmatch2 exp, outcome(re78) pscore(pscorea) common
//computes Kolmogorov-Smirnov and Cramer-von Mises type tests for the null hypothesis
//that a parametric model for the propensity score is is correctly specified. 
pstest re74 
pstest re75


//rich scores
// Standardized differences in the matched data
psmatch2 exp, outcome(re78) pscore(pscoreb) common
//computes Kolmogorov-Smirnov and Cramer-von Mises type tests for the null hypothesis
//that a parametric model for the propensity score is is correctly specified. 
pstest re74 
pstest re75


/* question 9 */
/*
Create propensity score matching estimates using the rich propensity scores and kernel 
matching with a Gaussian (normal) kernel and bandwidths of 0.02, 0.2 and 2.0. Impose the 
common support condition as in Problem 6. Describe the resulting impact estimates
*/


psmatch2 exp, outcome(re78) pscore(pscoreb) kernel kerneltype(normal) bwidth(0.02) common
psmatch2 exp, outcome(re78) pscore(pscoreb) kernel kerneltype(normal) bwidth(0.20) common
psmatch2 exp, outcome(re78) pscore(pscoreb) kernel kerneltype(normal) bwidth(2.0) common


/* question 10 */
/*
Repeat Problem 9 but using local linear matching rather than kernel matching.
*/
psmatch2 exp, outcome(re78) pscore(pscoreb) llr bwidth(0.02) common //broke stata?
psmatch2 exp, outcome(re78) pscore(pscoreb) llr bwidth(0.20) common
psmatch2 exp, outcome(re78) pscore(pscoreb) llr bwidth(2.0) common


/* question 11 */
/*
Obtain an estimate of the bias by estimating a linear regression of real earnings in 1978 on 
the variables in the rich propensity scores and a treatment dummy using all of the observations in 
the control group and the CPS comparison group. 
*/

reg re78 exp $X


/* question 12 */
/*
Obtain an estimate of the bias by estimating a linear regression of real earnings in 1978 on 
the variables in the rich propensity scores using only the untreated observations. Use the 
predicted values from this regression, evaluated at the covariate values associated with each 
treated unit, as the estimated expected counterfactual outcomes for the treated units. 
*/

reg re78 $X if exp == 0
//Generate predicted values based on the regression
predict xb
//find the difference between actual 1978 earnings and what I predict for those who are in the experimental sample
gen dif = re78 - xb if exp == 1
// take the mean to get the avg diff
mean(dif)

/* question 13 */
/*
Obtain an estimate of the bias using inverse probability weighting and the rich propensity 
scores. Implement this estimator "by hand" (i.e. code it up yourself in Stata) and do it in two 
ways: rescaling the weights to sum to one and not rescaling the weights to sum to one. 
*/


// Not normalized

//mean outcome of treated
gen mtt1a = re78*exp
egen mtt1b = sum(mtt1a)
count if exp == 1
gen mtt1 = mtt1b / r(N)

egen uncondp = mean(pscoreb)
gen mtt2a = pscoreb*re78*(1-exp)/(1-pscoreb)*(1-uncondp)/uncondp
egen mtt2b = sum(mtt2a)
count if exp==0
gen mtt2 = mtt2b/r(N)

// ipw estimates
gen mtt = mtt1-mtt2

display mtt

// Normalized
gen mtt_wt1a =pscoreb*(1-exp)/(1-pscoreb)
egen mtt_w1b =sum(mtt_wt1a)
count if exp == 0
gen mtt_w1=r(N)/mtt_w1b
 
gen mtt2_norma =pscoreb*re78*(1-exp)/(1-pscoreb)
gen mtt2_normb =mtt_w1*mtt2_norma
egen mtt2_normc=sum(mtt2_normb)
count if exp==0
gen mtt2_norm = mtt2_normc/r(N)

// ipw estimates
gen mtt_norm = mtt1-mtt2_norm

display mtt_norm




log close

