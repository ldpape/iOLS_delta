cap program drop popular_fix_test
program define popular_fix_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] 
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	tempvar res
	quietly: gen `res' = log(1+`depvar')
	quietly: reg `res' `indepvar' if `touse'    
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	replace `touse' = e(sample)
	cap drop xb_hat
	cap drop u_hat
	quietly : predict u_hat if `touse', resid 
	quietly : predict xb_hat if `touse', xb 
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test
	quietly: logit `dep_pos' `indepvar' if `touse'
	tempvar p_hat_temp
    quietly: predict `p_hat_temp' if `touse', pr 
    cap drop lambda_stat
    quietly: gen lambda_stat = xb_hat*(1-`p_hat_temp')/`p_hat_temp' if `touse'
	* regress
	quietly: reg u_hat lambda_stat if `dep_pos' & `touse', nocons       
	matrix b = e(b)
	local lambda = _b[lambda_stat]	
	cap drop lambda_stat
******************************************************************************
*                   Return the information to STATA output		     		 *
******************************************************************************
di ""
di as result "Lambda Statistic = " in ye `lambda'
di "Interpretation: If the model is correct, lambda should be close to one. Reject lambda far from 1."
ereturn post b
ereturn scalar lambda = `lambda'
end

