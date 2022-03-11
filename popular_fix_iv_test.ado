cap program drop popular_fix_iv_test
program define popular_fix_iv_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, NONparametric excluded(varlist) k(real 1) endog(varlist) instr(varlist) fix(real 1) ]   
	marksample touse
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	quietly: reg `endog' `instr' `indepvar' `excluded' if `dep_pos' & `touse'
	tempvar xb_hat 
	quietly: predict `xb_hat' if `touse', xb
	tempvar res
	quietly: gen `res' = log(`fix'+`depvar') if `touse'
	quietly: ivreg2 `res' `indepvar' `excluded' ( `endog' = `instr' )  if `touse'    
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	replace `endog' = `instr'
	tempvar xb2s 
	predict `xb2s' if `touse' , xb 
	quietly: replace `touse' = e(sample)
	tempvar u_hat
	quietly : predict `u_hat' if `touse', resid 
	
******************************************************************************
*                            PROBABILITY MODEL 	            	     		 *
******************************************************************************
 if  "`nonparametric'" =="" {
di in red "Using Logit Probability Model"
quietly: logit `dep_pos' `indepvar' `instr' if `touse'
tempvar p_hat_temp
quietly:predict `p_hat_temp' if `touse', pr 
cap drop  lambda_stat
quietly: gen lambda_stat = `xb2s'*(1-`p_hat_temp')/`p_hat_temp' if `touse'
quietly: reg `u_hat' lambda_stat if `dep_pos' & `touse', nocons 
	}
	else{
	/*
di in red "Using Royston & Cox (2005) multivariate nearest-neighbor smoother"
tempvar p_hat_temp
quietly: mrunning  `dep_pos'   `indepvar' `instr' if `touse' , nograph predict(`p_hat_temp')
quietly: _pctile `p_hat_temp', p(10)
local w1=max(r(r1),0.01)
quietly: _pctile `p_hat_temp', p(90)
local w2=min(r(r2),0.99) 
*/
di in red "kNN Discrimination Probability Model"
tempvar p_hat_temp p_hat_neg
quietly: sum `touse' if `touse'
if `k'==1 {
local k = floor(sqrt(r(N))) 
}
quietly: discrim knn `indepvar' if `touse' , k(`k') group(`dep_pos') notable ties(nearest)   mahalanobis   priors(proportional) 
quietly: predict `p_hat_neg' `p_hat_temp'  if `touse', pr
quietly: _pctile `p_hat_temp', p(5)
local w1=max(r(r1),1e-5)
quietly: _pctile `p_hat_temp', p(95)
local w2=min(r(r1),1) 
cap drop  lambda_stat
quietly: gen lambda_stat = `xb2s'*(1-`p_hat_temp')/`p_hat_temp' if `touse'
quietly: reg `u_hat' lambda_stat if `dep_pos' & `touse' & inrange(`p_hat_temp',`w1',`w2') , nocons       	
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

