cap program drop i2SLS_MP_test
program define i2SLS_MP_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) NONparametric from(name) endog(varlist) instr(varlist) xb_hat(varlist) u_hat(varlist)  MAXimum(real 10000) ]   
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
     tempvar lhs 
     quietly: gen `lhs' = `u_hat'
		}
else {
 i2SLS_MP `varlist' if `touse' , delta(`delta') limit(`limit') from(`from') maximum(`maximum')  endog(`endog') instr(`instr')
   quietly: iOLS_MP `varlist' if `touse' , delta(`delta') limit(`limit') from(`from') maximum(`maximum')   
  	quietly: replace `touse' = e(sample)
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	* rhs of test
	tempvar E_u_hat
    quietly: egen `E_u_hat' = mean(i2SLS_MP_error) if `touse'
       tempvar lhs 
     quietly: gen `lhs' = i2SLS_MP_error
   }
******************************************************************************
*                            PROBABILITY MODEL 	            	     		 *
******************************************************************************
tempvar dep_pos
quietly: gen `dep_pos' = `depvar'>0 if `touse'
 if  "`nonparametric'" =="" {
di in red "Using Logit Probability Model"
quietly: logit `dep_pos' `indepvar' `instr' if `touse'
tempvar p_hat_temp
quietly:predict `p_hat_temp' if `touse', pr 
cap drop lambda_stat
quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
quietly: reg  `lhs' lambda_stat if `dep_pos' & `touse', nocons 
	}
	else{
	di in red "Using Royston & Cox (2005) multivariate nearest-neighbor smoother"
tempvar p_hat_temp
quietly: mrunning  `dep_pos'   `indepvar' `instr'  if `touse' , nograph predict(`p_hat_temp')
quietly: _pctile `p_hat_temp', p(2.5)
local w1=r(r1)
quietly: _pctile `p_hat_temp', p(97.5)
local w2=r(r2) 
cap drop lambda_stat
quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
quietly: reg  `lhs' lambda_stat if `dep_pos' & `touse' & inrange(`p_hat_temp',`w1',`w2') , nocons       	
	}	
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
	ereturn matrix beta_hat_i2sls_MP = beta_hat
	ereturn matrix var_beta_hat_i2sls_MP = var_cov_beta_hat
}
end

