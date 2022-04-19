//export table

esttab using "regression1.tex", replace  ///
 b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
 coeflabel(Client_Age "age" Client_Married "married" Client_Education "education" HH_Size "hh size" HH_Income "hh_income" Hindu_SC_Kat "hindu cast" Treated "treated") ///
 booktabs alignment(D{.}{.}{-1}) ///
 title(My very first basic regression table \label{reg1})   

// Question 4
 esttab, ///
 cells("sum(fmt(%13.0fc)) mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min max count") nonumber ///
  nomtitle nonote noobs label collabels("Sum" "Mean" "SD" "Min" "Max" "N")
 
 // save list of file
loc files table_q7_q8 table_q10_11 write table_q13
//open all files in write mode 
foreach f in `files'{
	capture file close `f'
	file open `f' using `f'.tex, write replace
}

// generating table for question 7 and question 8
 file write table_q7_q8	///
	"\begin{tabular}{rcccc}"										_newline ///
	_tab "& LPM & Logit & Probit & QLPM \\\hline"			_newline ///
	_tab "\hline" _newline ///
	_tab "Mean Partial Effect & $lpm_coeff & $logit_coeff & - & -\\"	_newline ///
	_tab "Question 7a) & - & - & $prob_a & - \\"								_newline ///
	_tab "Question 7b) & - & - & $prob_b & - \\"								_newline ///
	_tab "Question 7c) & - & - & $prob_c & $qlpm_7c \\"							_newline ///
	_tab "Question 7d) & - & - & $prob_d & - \\"								_newline /// 
	"\end{tabular}"
	
// generating table for question 10 and 11
file write table_q10_11	///
	"\begin{tabular}{rcccc}"										_newline ///
	_tab 			" & \multicolumn{2}{c}{In-sample} 		"				 ///
					" & \multicolumn{2}{c}{Out-of-sample} \\"		_newline ///
	_tab 			" & cutoff $0.5$ 		& mean prob     "				 ///
					" & cutoff $0.5$ 		& mean prob  \\\hline"	_newline ///
	_tab "\hline" _newline ///
	_tab "Probit 	  & $pred_count_prob & $pred_count_prob_mean"					 ///
					" & $pred_count_prob_out & $pred_count_prob_mean_out \\"		_newline ///
	"\end{tabular}"
	
// generating table for question 13 and question 14
file write table_q13 	///
	"\begin{tabular}{cc|cc}"										_newline ///
	_tab "&&\multicolumn{2}{c}{\small{Mean Finite Difference}} \\"	_newline ///
	_tab "married$ & muslim"							 ///
		 "& not muslin or married& muslin and married \\\hline"				_newline ///
	_tab "1 & 0 & $mus13_ & $mus13 \\"							_newline ///
	_tab "0 & 1 & $marr13_ & $marr13 \\"							_newline ///
	_tab "1 & 1 & $all13_ & $all13  \\"							_newline ///
	"\end{tabular}"
	
//closing files
foreach f in `files'{
	file close `f'
}
