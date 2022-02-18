cap program drop ppml_test
program define ppml_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] 
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	quietly: ppml `varlist' if `touse'    
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	replace `touse' = e(sample)
	cap drop xb_hat
	cap drop u_hat
	quietly: predict xb_hat, xb
	quietly : gen u_hat = `depvar'*exp(-xb_hat)
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test
	tempvar E_u_hat
    quietly: egen `E_u_hat' = mean(u_hat) if `touse'
	quietly: logit `dep_pos' `indepvar' if `touse'
	tempvar p_hat_temp
    quietly: predict `p_hat_temp' if `touse', pr 
   cap drop lambda_stat
    quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
	* regress
	quietly: reg u_hat lambda_stat if `dep_pos' & `touse', nocons       
	matrix b = e(b)
	local lambda = _b[lambda_stat]	

******************************************************************************
*                   Return the information to STATA output		     		 *
******************************************************************************
di ""
di as result "Lambda Statistic = " in ye `lambda'
di "Interpretation: If the model is correct, lambda should be close to one. Reject lambda far from 1."
ereturn post b
ereturn scalar lambda = `lambda'
end

