* 15/12/2021 : corrected "cross" in S.E. which is complicated by the symmetrization
* 15/12/2021 : corrected iteration logical specification
* 16/12/2021 : corrected absorb from varlist to string, as in ppmlhdfe
* 22/12/2021 : coded with matrix multiplication instead of pre-canned program
* 22/12/2021 : added convergence control (limit and maximum)
* 04/01/2022 : added constant + checks for convergence + corrected problem with collinear variables affecting final 2SLS
* 21/01/2022 : added symmetrization + check for singleton / existence using PPML + correction S.E. + syntax change
* 22/01/2022 : apparently, new syntax does not drop missing obs.
*3/2/2022 : drop preserve + add singleton selection based on Correia, Zylkin and Guimaraes.
cap program drop i2SLS_delta_HDFE
program define i2SLS_delta_HDFE, eclass

syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) ABSorb(varlist) LIMit(real 1e-8) from(name)  MAXimum(real 10000) ENDog(varlist) INSTR(varlist)  Robust CLuster(string)]              

//	syntax [anything] [if] [in] [aweight pweight fweight iweight]  [, DELta(real 1) ABSorb(varlist) LIMit(real 0.00001) MAXimum(real 1000) Robust CLuster(varlist numeric) ]
	marksample touse
	markout `touse'  `cluster', s     
	quietly keep if `touse'
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "cluster(`cluster') "
	}
	local option = "`opt1'`opt2'"
	*** Obtain lists of variables 
	local list_var `varlist'
	gettoken depvar list_var : list_var
	gettoken _rhs list_var : list_var, p("(")	
foreach var of varlist `depvar' `_rhs' `endog' `instr'{
quietly  replace `touse' = 0 if missing(`var')	
}
	
*** check seperation : code from "ppml"
 loc tol = 1e-5
tempvar u w xb e
quietly: gen `u' =  !`depvar' if `touse'
quietly: su `u'  if `touse', mean
loc K = ceil(r(sum) / `tol' ^ 2)
quietly: gen `w' = cond(`depvar', `K', 1)  if `touse'
while 1 {
	*qui reghdfe u [fw=w], absorb(id1 id2) resid(e)
quietly:	reghdfe `u' `_rhs'  `endog'  [fw=`w']  if `touse' , absorb(`absorb') resid(`e')
quietly:	predict double `xb'  if `touse', xbd
quietly:	replace `xb' = 0 if (abs(`xb') < `tol')&(`touse')

	* Stop once all predicted values become non-negative
quietly:	 cou if (`xb' < 0) & (`touse')
	if !r(N) {
		continue, break
	}

quietly:	replace `u' = max(`xb', 0)  if `touse'
quietly:	drop `xb' `w'
}
*quielty: gen is_sep = `xb' > 0
quietly: replace `touse'  = (`xb' <= 0) // & (`touse')

*quietly keep if `touse'	
	** drop collinear variables
	tempvar cste
	gen `cste' = 1
    _rmcoll `_rhs' `endog' `cste' if `touse' , forcedrop 
if r(k_omitted) >0 di 
	local alt_varlist `r(varlist)'
	local alt_varlist: list alt_varlist- endog
	local var_list `endog' `alt_varlist' 
	local instr_list `instr' `alt_varlist' 
	*** FWL Theorem Application
	cap drop Z0_*
	cap drop E0_*
	cap drop M0_*
	cap drop Y0_*
	cap drop xb_hat*
	if "`alt_varlist'"=="" { // case with no X , only FE 
	quietly hdfe `endog' if `touse' [`weight'] , absorb(`absorb') generate(E0_)
	quietly hdfe `instr' if `touse' [`weight'] , absorb(`absorb') generate(Z0_)
	tempvar y_tild  
	quietly gen `y_tild' = log(`depvar' + `delta') if `touse'
	quietly	hdfe `y_tild'  if `touse' [`weight'] , absorb(`absorb') generate(Y0_) 
	local df_a = e(df_a)
	mata : X=.
	mata : PX=.
	mata : PZ=.
	mata : y_tilde =.
	mata : Py_tilde =.
	mata : y =.
	mata : st_view(X,.,"`endog'","`touse'")
	mata : st_view(PX,.,"E0_*","`touse'")
	mata : st_view(PZ,.,"Z0_*","`touse'")
	mata : st_view(y_tilde,.,"`y_tild'","`touse'")
	mata : st_view(Py_tilde,.,"Y0_","`touse'")
	mata : st_view(y,.,"`depvar'","`touse'")	
	}
	else { // standard case with both X and FE
	quietly hdfe `alt_varlist'  if `touse'  [`weight'] , absorb(`absorb') generate(M0_)
	quietly hdfe `endog'  if `touse'  [`weight'] , absorb(`absorb') generate(E0_)
	quietly hdfe `instr'  if `touse'  [`weight'] , absorb(`absorb') generate(Z0_)
	tempvar y_tild  
	quietly gen `y_tild' = log(`depvar' + `delta') if `touse'
	quietly	hdfe `y_tild'  if `touse'  [`weight'] , absorb(`absorb') generate(Y0_) 
	local df_a = e(df_a)

	local dof_hdfe = e(df_a)
	mata : X=.
	mata : PX=.
	mata : PZ=.
	mata : y_tilde =.
	mata : Py_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list'","`touse'")
	mata : st_view(PX,.,"E0_* M0_*","`touse'")
	mata : st_view(PZ,.,"Z0_* M0_*","`touse'")
	mata : st_view(y_tilde,.,"`y_tild'","`touse'")
	mata : st_view(Py_tilde,.,"Y0_","`touse'")
	mata : st_view(y,.,"`depvar'","`touse'")	
	}
	
	** initial value 
		mata : invPzX = invsym(cross(PX,PZ)*invsym(cross(PZ,PZ))*cross(PZ,PX))*cross(PX,PZ)*invsym(cross(PZ,PZ))
capture	 confirm matrix `from'
if _rc==0 {
	mata : beta_initial = st_matrix("`from'")
	mata : beta_initial = beta_initial'
}
else {
	mata : beta_initial = invPzX*cross(PZ,Py_tilde)
}
	* prepare  future inversions 
	
		mata : beta_t_1 = beta_initial // needed to initialize
	mata : beta_t_2 = beta_initial // needed to initialize
	mata : q_hat_m0 = 0
	local k = 1
	local eps = 1000	
	mata: q_hat = J(`maximum', 1, .)
	*** Iterations iOLS
	_dots 0
	while ((`k' < `maximum') & (`eps' > `limit' )) {
	mata: xb_hat_M = PX*beta_initial 
	mata: xb_hat_N = X*beta_initial
	mata: fe = y_tilde - Py_tilde + xb_hat_M - xb_hat_N
	mata: xb_hat = xb_hat_N + fe		
		* update du alpha
	mata: alpha = log(mean(y:*exp(-xb_hat)))
	mata: y_tilde = log(y + `delta'*exp(xb_hat :+ alpha )) :-mean(log(y + `delta'*exp(xb_hat :+ alpha)) -xb_hat :- alpha  )
		* regression avec le nouvel y_tild
	cap drop `y_tild' 
	mata: st_store(., st_addvar("double", "`y_tild'"), "`touse'", y_tilde)
	cap drop Y0_
    quietly hdfe `y_tild' if `touse' [`weight'] , absorb(`absorb') generate(Y0_)
	mata : st_view(Py_tilde,.,"Y0_","`touse'")
		* 2SLS 
	mata : beta_new = invPzX*cross(PZ,Py_tilde)
	mata: criteria = mean(abs(beta_initial - beta_new):^(2))
	mata: st_numscalar("eps", criteria)
	mata: st_local("eps", strofreal(criteria))
		* safeguard for convergence.
	if `k'==`maximum'{
		  di "There has been no convergence so far: increase the number of iterations."  
	}
	if `k'>4{
	mata: q_hat[`k',1] = mean(log( abs(beta_new-beta_initial):/abs(beta_initial-beta_t_2)):/log(abs(beta_initial-beta_t_2):/abs(beta_t_2-beta_t_3)))	
	mata: check_3 = abs(mean(q_hat)-1)
		if mod(`k'-4,50)==0{
    mata: q_hat_m =  mm_median(q_hat[((`k'-49)..`k'),.] ,rownonmissing(q_hat[((`k'-49)..`k'),.]))
	mata: check_1 = abs(q_hat_m - q_hat_m0)
	mata: check_2 = abs(q_hat_m-1)
	mata: st_numscalar("check_1", check_1)
	mata: st_local("check_1", strofreal(check_1))
	mata: st_numscalar("check_2", check_2)
	mata: st_local("check_2", strofreal(check_2))
	mata: st_numscalar("check_3", check_3)
	mata: st_local("check_3", strofreal(check_3))
	mata: q_hat_m0 = q_hat_m
		if ((`check_1'<1e-4)&(`check_2'>1e-2)) {
di "Convergence may be slow : consider using another delta"
*	local k = `maximum'
		}
		if ((`check_3'>0.5) & (`k'>500)) {
	*local k = `maximum'
di "Convergence may be slow : consider using another delta"
		}
					  }
	}
	if `k'>2 { // keep in memory the previous beta_hat for q_hat 
	mata:   beta_t_3 = beta_t_2
	mata:   beta_t_2 = beta_initial
	}
	mata: beta_initial = beta_new
	local k = `k'+1
	_dots `k' 0
	}
	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" residu
	mata: ui = y:*exp(-xb_hat :- alpha)
	mata: weight = ui:/(`delta' :+ ui)
	* Final 2SLS with ivreg2 
		foreach var in `alt_varlist' {     // rename variables for last ols
	quietly	rename `var' TEMP_`var'
	quietly	rename M0_`var' `var'
	}	
		foreach var in `instr'  {     // rename variables for last ols
	quietly	rename `var' TEMP_`var'
	quietly	rename Z0_`var' `var'
	}
		foreach var in `endog'  {     // rename variables for last ols
	quietly	rename `var' TEMP_`var'
	quietly	rename E0_`var' `var'
	}
cap _crcslbl Y0_ `depvar' // label Y0 correctly
quietly: ivreg2 Y0_ `alt_varlist' (`endog' = `instr') [`weight'`exp'] if `touse' , `option' noconstant   // standard case with X and FE 
if "`alt_varlist'"=="" {
quietly: ivreg2 Y0_ `alt_varlist' (`endog' = `instr') [`weight'`exp'] if `touse'  , `option' noconstant   // case with no X , only FE 
}
local df_r = e(Fdf2) - `df_a'
	foreach var in `alt_varlist' {      // rename variables back
	quietly	rename `var' M0_`var'
	quietly	rename TEMP_`var' `var'
	}
		foreach var in  `instr' {      // rename variables back
	quietly	rename `var' Z0_`var'
	quietly	rename TEMP_`var' `var'
	}
		foreach var in `endog'{      // rename variables back
	quietly	rename `var' E0_`var'
	quietly	rename TEMP_`var' `var'
	}
	* Calcul de Sigma_0, de I-W, et de Sigma_tild
	matrix beta_final = e(b) // 	mata: st_matrix("beta_final", beta_new)
	matrix Sigma = (e(Fdf2) / `df_r')*e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (cross(PX,PZ)*invsym(cross(PZ,PZ))*cross(PZ,PX):/rows(PX))*Sigma_hat*(cross(PX,PZ)*invsym(cross(PZ,PZ))*cross(PZ,PX):/rows(PX)) // recover original HAC 
	mata : invXpPzIWX = invsym(0.5:/rows(PX)*cross(PX,PZ)*invsym(cross(PZ,PZ))*cross(PZ,weight,PX)+ 0.5:/rows(PX)*cross(PX,weight,PZ)*invsym(cross(PZ,PZ))*cross(PZ,PX))
	mata : Sigma_tild = invXpPzIWX*Sigma_0*invXpPzIWX
	mata : Sigma_tild = (Sigma_tild+Sigma_tild'):/2 
    mata: st_matrix("Sigma_tild", Sigma_tild) // used in practice
	*** Stocker les rÃ©sultats dans une matrice
	local names : colnames beta_final
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
	local dof_final = e(df r)- `dof_hdfe'
			cap drop _COPY
	quietly: gen _COPY = `touse'
    ereturn post beta_final Sigma_tild , obs(`=e(N)') depname(`depvar') esample(`touse')  dof(`df_r')
	cap drop i2SLS_delta_HDFE_xb_hat
	cap drop i2SLS_delta_HDFE_fe
	cap drop i2SLS_delta_HDFE_error
		    mata: st_store(., st_addvar("double", "i2SLS_delta_HDFE_fe"), "_COPY", fe)
	    mata: st_store(., st_addvar("double", "i2SLS_delta_HDFE_error"), "_COPY", ui)
    	mata: st_store(., st_addvar("double", "i2SLS_delta_HDFE_xb_hat"),"_COPY", xb_hat_N)
		cap drop _COPY
	ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn local cmd "i2SLS_HDFE"
ereturn local vcetype `option'
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
ereturn display

* drop 
	cap drop E0_*
	cap drop Z0_*
	cap drop M0_* 
	cap drop Y0_*
	cap drop xb_hat*
end
