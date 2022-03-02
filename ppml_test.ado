program define ppml_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, NONparametric excluded(varlist) ] 
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	quietly: ppml `varlist' `excluded' if `touse'    
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	quietly: replace `touse' = e(sample)
	tempvar xb_hat u_hat
	quietly: predict `xb_hat', xb
	quietly : gen `u_hat' = `depvar'*exp(-`xb_hat')
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	* rhs of test
tempvar E_u_hat
quietly: egen `E_u_hat' = mean(`u_hat') if `touse'
tempvar lhs
quietly: gen `lhs' = `u_hat'/exp(`xb_hat')

******************************************************************************
*                            PROBABILITY MODEL 	            	     		 *
******************************************************************************
 if  "`nonparametric'" =="" {
 di in red "Using Logit Probability Model"
 quietly: logit `dep_pos' `indepvar' if `touse'  
tempvar p_hat_temp
quietly:predict `p_hat_temp' if `touse', pr 
cap drop lambda_stat
quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
quietly: reg `lhs'  lambda_stat if `dep_pos' & `touse', nocons 
	}
	else{
di in red "Using Royston & Cox (2005) multivariate nearest-neighbor smoother"
tempvar p_hat_temp
quietly: mrunning  `dep_pos'   `indepvar' if `touse', nograph predict(`p_hat_temp')
quietly: _pctile `p_hat_temp', p(10)
local w1=max(r(r1),0.01)
quietly: _pctile `p_hat_temp', p(90)
local w2=min(r(r2),0.99) 
cap drop lambda_stat
quietly: gen lambda_stat = (`E_u_hat')/`p_hat_temp' if `touse'
quietly: reg `lhs'  lambda_stat if `dep_pos' & `touse' & inrange(`p_hat_temp',`w1',`w2') , nocons       	
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
end

