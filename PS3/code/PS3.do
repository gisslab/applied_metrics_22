
clear all
log using "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 3/log_ps3.log", replace


/*
	Problem set 3, Econ 717
	
	Date created:  19 Mar 2022
	
	Last modified: 27 Mar 2022
	
	Author: Giselle Labrador-Badia (labradorbada@wisc.edu)
*/


/* Setup */


// establish working directory
cd "/Users/gisellelab/pCloud Drive/PHD/Courses/02 - Second Year/ECON 717 (Metrics)/Problem Sets/Problem Set 3"


// Loading data
use "Economics 717 Miron and Tetelbaum Data.dta", clear

// save outreg 
glob opts "tex(frag) nor noobs noas"


/* question 1 */
/*
Tell Stata that this is panel data using the command xtset state year
*/

xtset state year

/* question 2 */
/*
Create a binary treatment indicator called "mlda21" that equals one for state-years 
in which the MLDA equals 21 and zero for all other state-years.
*/

gen mlda_21 = (mlda == 21)

/* question 3 */
/*
Ignore the panel nature of the data and obtain a naïve estimate of the treatment effect.
*/

reg rate18_20ht mlda_21, robust
outreg2 using tableq3_q4.tex, replace `opts' addtext(year FE, -, state FE, -, cluster,- ) keep(mlda_21)

/* question 4 */
/*
Obtain two other naïve treatment effect estimates by repeating the exercise in the preceding problem.
*/

//adding only state fixed effects
reg rate18_20ht mlda_21 i.state, robust
outreg2 using tableq3_q4.tex, append `opts'  addtext(year FE,-  , state FE, X, cluster,- ) keep(mlda_21)
		
// adding only year fixed effects. 
		
reg rate18_20ht mlda_21 i.year, robust
outreg2 using tableq3_q4.tex, append `opts'  addtext(year FE, -, state FE, X, cluster, -) keep(mlda_21)


/* question 5 */
/*
Obtain the standard estimate of the treatment effect by regressing the traffic fatality 
rate on the treatment indicator and including both state and year fixed effect
*/

reg rate18_20ht mlda_21 i.state i.year, robust cl(state)
outreg2 using tableq3_q4.tex, append `opts'  addtext(year FE,X, state FE, X, cluster,X ) keep(mlda_21)


/* question 6 */
/*
Repeat the exercise in the preceding problem but omitting the "cluster(state)" option.
*/

reg rate18_20ht mlda_21 i.state i.year, robust 
outreg2 using tableq3_q4.tex, append `opts' addtext(year FE,X, state FE, X, cluster,-) keep(mlda_21)


/* question 7 */
/*
Repeat Problem 6 but ut omitting years of data after 1990. 
*/

reg rate18_20ht mlda_21 i.state i.year ///
    if year <= 1990, ///
	robust cl(state)
outreg2 using tableq3_q4.tex, append `opts' addtext(year FE,X, state FE, X, cluster,-) keep(mlda_21)

/* question 8 */
/*
Perform a "pre-program test" by coding up a placebo treatment indicator called "placebo82".
hen estimate the model in Problem 5 using only the states that always have an MLDA of 21 
or that switch in 1987, and using only the years of data prior to 1987.
*/

// generate placebo  treratent indicator 
gen placebo82 = (mldayr == 1987 & year >= 1982) 

//  generate variable with states that have mlda = 21
egen low_mlda = min(mlda), by(state)
	
// run regression with placebo on states if switch and if min is mlda 21
reg rate18_20ht placebo82 i.state i.year 	///
	if low_mlda == 21 | mldayr == 1987, robust cl(state)
outreg2 using tableq3_q4.tex, append `opts' sortvar(mlda_21) addtext(year FE,X, state FE, X, cluster,X )  keep(placebo82)


/* question 9 */
/*
Separately for MI and MD, estimate the treatment effect of switching to an MLDA of 21 using 
data for that state and for the "always treated" states. Interpret the resulting estimates. 
*/
// state = 21
reg rate18_20ht mlda_21 i.state i.year ///
    if state == 21 | low_mlda == 21, ///
	robust cl(state)
outreg2 using tableq9-10.tex, replace `opts' sortvar(mlda_21) addtext(year FE,X, state FE, X, cluster,X) keep(mlda_21)

// state = 23
reg rate18_20ht mlda_21 i.state i.year ///
    if state == 23 | low_mlda == 21, ///
	robust cl(state)
outreg2 using tableq9-10.tex, append `opts' sortvar(mlda_21) addtext(year FE,X, state FE, X, cluster,X) keep(mlda_21)


/* question 10 */
/*
Repeat the exercise in the preceding problem but estimating treatment effects in relative 
time by replacing the "mlda21" treatment indicator with indicators for the first four years
 of treatment and remaining years of treatment. 
*/

// new treatment indicators
bys state mlda (year): gen mlda_first = (year - year[1] <= 3 & mlda == 21 & low_mlda == 18)
bys state mlda (year): gen mlda_remaining = (year - year[1] > 3 & mlda == 21 & low_mlda == 18)

// state = 21
reg rate18_20ht mlda_first mlda_remaining i.state i.year 	///
	if state == 21 | low_mlda == 21, ///
	robust cl(state)
outreg2 using tableq9-10.tex, append `opts' addtext(year FE,X, state FE, X, cluster,X) keep(mlda_first mlda_remaining)

// state = 23
reg rate18_20ht mlda_first mlda_remaining i.state i.year 	///
	if state == 23 | low_mlda == 21, ///
	robust cl(state)
outreg2 using tableq9-10.tex, append `opts' addtext(year FE,X, state FE, X, cluster,X) keep(mlda_first mlda_remaining)



// regression did
log close

