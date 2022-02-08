cap program drop i2SLS_delta_test
program define i2SLS_delta_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) from(name) endog(varlist) instr(varlist) xb_hat(varlist) u_hat(varlist)  MAXimum(real 10000) Robust CLuster(string)]   
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
if  "`xb_hat'" !="" {
	* lhs of test
	tempvar dep_pos
	quietly:gen `dep_pos' = `depvar'>0 if `touse'
	tempvar lhs_temp
    quietly: gen `lhs_temp' = log(`delta'+`u_hat') - log(`delta') if `touse'
	* rhs of test
	tempvar temp 
    quietly: gen `temp' = log(`depvar' + `delta'*exp(`xb_hat')) - `xb_hat' if `touse'
	tempvar c_hat_temp
     quietly: egen `c_hat_temp' = mean(`temp') if `touse'
	 quietly: logit `dep_pos' `indepvar' `instr' if `touse'
	tempvar p_hat_temp
    quietly:predict `p_hat_temp' if `touse', pr 
    tempvar lambda
    quietly: gen `lambda' = (`c_hat_temp'-log(`delta'))/`p_hat_temp' if `touse'
	* regress
	quietly: reg `lhs_temp' `lambda' if `dep_pos' & `touse', nocons 
	matrix b = e(b)
	local lambda = _b[`lambda']
		}
else {
quietly:  i2SLS_delta `varlist' if `touse' , delta(`delta') limit(`limit') from(`from') maximum(`maximum') endog(`endog') instr(`instr') 
	replace `touse' = e(sample)
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	tempvar lhs_temp
    quietly: gen `lhs_temp' = log(`delta'+i2SLS_error) - log(`delta') if `touse'
	* rhs of test
	tempvar temp 
    quietly: gen `temp' = log(`depvar' + `delta'*exp(i2SLS_xb_hat)) - i2SLS_xb_hat if `touse'
	tempvar c_hat_temp
    quietly: egen `c_hat_temp' = mean(`temp') if `touse'
	quietly: logit `dep_pos' `indepvar' `instr' if `touse'
	tempvar p_hat_temp
    quietly: predict `p_hat_temp' if `touse', pr 
    tempvar lambda
    quietly: gen `lambda' = (`c_hat_temp'-log(`delta'))/`p_hat_temp' if `touse'
	* regress
	quietly: reg `lhs_temp' `lambda' if `dep_pos' & `touse', nocons       
	matrix b = e(b)
	local lambda = _b[`lambda']	
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
	ereturn matrix beta_hat_i2sls = beta_hat
	ereturn matrix var_beta_hat_i2sls = var_cov_beta_hat
}
end
