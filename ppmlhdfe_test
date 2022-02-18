cap program drop ppmlhdfe_test
program define ppmlhdfe_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [,  from(name) absorb(varlist)  logit]   
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	quietly: ppmlhdfe `varlist' if `touse'    , absorb(`absorb') d
    *lhs of test
	tempvar xb_temp mean_u_temp u_hat_temp E_u_hat
  quietly:  predict `xb_temp', xb 
	quietly: replace `xb_temp' = `xb_temp' + _ppmlhdfe_d
   quietly: gen `u_hat_temp' = `depvar'*exp(-`xb_temp')
   quietly: egen `E_u_hat' = mean(`u_hat_temp' ) if `touse'
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	quietly: replace `touse' = e(sample)
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test

	if  "`logit'" =="logit" {
local vlist1
foreach item of varlist `absorb' {
    local vlist1 `vlist1' i.`item'
}
quietly:	xi: logit `dep_pos' `indepvar' `vlist1' if `touse'
	tempvar p_hat_temp
    quietly: predict `p_hat_temp' if `touse', pr 
	}
	else{
		quietly: reghdfe `dep_pos' `indepvar'  if `touse' , absorb(`absorb') resid 
		tempvar p_hat_temp
		quietly: predict `p_hat_temp' if `touse', xbd
	}

    cap drop lambda_stat
    quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
	* regress
	quietly: reg `u_hat_temp' lambda_stat if `dep_pos' & `touse', nocons       
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
if  "`xb_hat'"=="" {
	ereturn matrix beta_hat_iols = beta_hat
	ereturn matrix var_beta_hat_iols = var_cov_beta_hat
}
end

	
