cap program drop iOLS_MP_test
program define iOLS_MP_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) from(name)  xb_hat(varlist) u_hat(varlist)  MAXimum(real 10000) Robust CLuster(string)]   
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
if  "`xb_hat'" !="" {
	* lhs of test
	tempvar dep_pos
	quietly:gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test 
	tempvar E_u_hat
     quietly: egen `E_u_hat' = mean(`u_hat') if `touse'
	 quietly: logit `dep_pos' `indepvar' if `touse'
	tempvar p_hat_temp
    quietly:predict `p_hat_temp' if `touse', pr 
    tempvar lambda
    quietly: gen `lambda' = (`E_u_hat')/`p_hat_temp' if `touse'
	* regress
	quietly: reg `u_hat' `lambda' if `dep_pos' & `touse', nocons 
	matrix b = e(b)
	local lambda = _b[`lambda']
		}
else {
  quietly: iOLS_MP `varlist' if `touse' , delta(`delta') limit(`limit') from(`from') maximum(`maximum')   
  	replace `touse' = e(sample)
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test
	tempvar E_u_hat
    quietly: egen `E_u_hat' = mean(iOLS_MP_error) if `touse'
	quietly: logit `dep_pos' `indepvar' if `touse'
	tempvar p_hat_temp
    quietly: predict `p_hat_temp' if `touse', pr 
    cap drop lambda_stat
    quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
	* regress
	quietly: reg iOLS_MP_error lambda_stat if `dep_pos' & `touse', nocons       
	matrix b = e(b)
	local lambda = _b[lambda_stat]	
		}
******************************************************************************
*                   Return the information to STATA output		     		 *
******************************************************************************
di ""
di as result "Lambda Statistic = " in ye `lambda'
di "Interpretation: If the model is correct, lambda should be close to one. Reject lambda far from 1."
ereturn post b
ereturn scalar lambda = `lambda'
if  "`xb_hat'"=="" {
	ereturn matrix beta_hat_iols_mp = beta_hat
	ereturn matrix var_beta_hat_iols_mp = var_cov_beta_hat
}
end

