cap program drop iOLS_delta_test
program define iOLS_delta_test, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) k(real 1) from(name) excluded(varlist) xb_hat(varlist) u_hat(varlist)  MAXimum(real 10000) NONparametric]   
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
}
else {
quietly:  iOLS_delta `varlist' `excluded' if `touse' , delta(`delta') limit(`limit') from(`from') maximum(`maximum')  
	quietly: replace `touse' = e(sample)
	matrix beta_hat = e(b)
	matrix var_cov_beta_hat = e(V)
	* lhs of test
	tempvar dep_pos
	quietly: gen `dep_pos' = `depvar'>0 if `touse'
	tempvar lhs_temp
    quietly: gen `lhs_temp' = log(`delta'+iOLS_error) - log(`delta') if `touse'
	* rhs of test
	tempvar temp 
    quietly: gen `temp' = log(`depvar' + `delta'*exp(iOLS_xb_hat)) - iOLS_xb_hat if `touse'
	tempvar c_hat_temp
    quietly: egen `c_hat_temp' = mean(`temp') if `touse'
}

******************************************************************************
*                            PROBABILITY MODEL 	            	     		 *
******************************************************************************
 if  "`nonparametric'" =="" {
 di in red "Using Logit Probability Model"
quietly: logit `dep_pos' `indepvar' if `touse'
tempvar p_hat_temp
quietly:predict `p_hat_temp' if `touse', pr 
cap drop lambda_stat
quietly: _pctile `p_hat_temp', p(5)
local w1=min(r(r1),0)
quietly: _pctile `p_hat_temp', p(95)
local w2=max(r(r1),1) 
quietly: gen lambda_stat = (`c_hat_temp'-log(`delta'))/`p_hat_temp' if `touse'
quietly: reg `lhs_temp' lambda_stat if `dep_pos' & `touse' & inrange(`p_hat_temp',`w1',`w2'), nocons 
	}
	else{
	di in red "kNN Discrimination Probability Model"
tempvar p_hat_temp p_hat_neg
quietly: sum `touse' if `touse'
if `k'==1 {
local k = floor(sqrt(r(N))) 
}
quietly: discrim knn `indepvar' if `touse' , k(`k') group(`dep_pos') notable ties(nearest)      priors(proportional) 
quietly: predict `p_hat_neg' `p_hat_temp'  if `touse', pr
*quietly: mrunning  `dep_pos'   `indepvar'  if `touse' , nograph predict(`p_hat_temp')
quietly: _pctile `p_hat_temp', p(5)
local w1=max(r(r1),1e-5)
quietly: _pctile `p_hat_temp', p(95)
local w2=min(r(r1),1) 
cap drop lambda_stat
quietly: gen lambda_stat = (`c_hat_temp'-log(`delta'))/`p_hat_temp' if `touse'
quietly: reg `lhs_temp' lambda_stat if `dep_pos' & `touse' & inrange(`p_hat_temp',`w1',`w2') , nocons       	
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
	ereturn matrix beta_hat_iols = beta_hat
	ereturn matrix var_beta_hat_iols = var_cov_beta_hat
}
end

