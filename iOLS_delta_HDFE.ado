* 15/12/2021 : corrected "cross" in S.E. inversion to increase speed. Note: this required deleting the diagonalization step.
* 15/12/2021 : corrected iteration logical specification
* 16/12/2021 : corrected absorb from varlist to string, as in ppmlhdfe
* 22/12/2021 : coded with matrix multiplication instead of pre-canned program
* 22/12/2021 : added convergence control (limit and maximum)
* 04/01/2022 : added constant + checks for convergence
* 01/02/2022 : drop preserve + post estimation variables
* 04/02/2022 : warm starting point + Correia, Zylkin and Guimarares singleton check
cap program drop iOLS_delta_HDFE
program define iOLS_delta_HDFE, eclass 
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) from(name)  MAXimum(real 10000) ABSorb(string)  Robust CLuster(string)]        

//	syntax [anything] [if] [in] [aweight pweight fweight iweight] [, DELta(real 1)  ABSorb(string) LIMit(real 0.00001) MAXimum(real 1000) Robust CLuster(varlist numeric)]
	marksample touse
	markout `touse'  `cluster', s     
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "vce(cluster `cluster') "
	}
    if "`absorb'" !="" {
		local opt3 = "absorb(`absorb') "
	}
	local option = "`opt1'`opt2'"	
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	//gettoken indepvar list_var : list_var, p("(")
gettoken _rhs list_var : list_var, p("(")
foreach var of varlist `depvar' `_rhs' {
quietly replace `touse' = 0 if missing(`var')	
}
loc tol = 1e-5
tempvar u w xb e
quietly: gen `u' =  !`depvar' if `touse'
quietly: su `u'  if `touse', mean
loc K = ceil(r(sum) / `tol' ^ 2)
quietly: gen `w' = cond(`depvar', `K', 1)  if `touse'
quietly: sum `w'
if r(mean)!=0{
while 1 {
	*qui reghdfe u [fw=w], absorb(id1 id2) resid(e)
quietly:	reghdfe `u' `_rhs' [fw=`w']  if `touse' , absorb(`absorb') resid(`e')
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
}
*quietly keep if `touse'	
	** drop collinear variables
		tempvar cste
quietly:	gen `cste' = 1
    _rmcoll `_rhs' `cste' , forcedrop 
	local var_list `r(varlist)'
		*** FWL Theorem Application
	cap drop M0_*
	cap drop Y0_*
	cap drop xb_hat*
	tempvar new_sample
	quietly hdfe `var_list' if `touse' [`weight'] , absorb(`absorb') generate(M0_) sample(`new_sample') 
local df_a = e(df_a)
quietly:	replace `touse' = 1 if `new_sample'
	tempvar y_tild  
	quietly gen `y_tild' = log(`depvar' + `delta') 
	cap drop `new_sample'
	quietly	hdfe `y_tild' if `touse'  , absorb(`absorb') generate(Y0_) sample(`new_sample') 
quietly:	replace `touse' = 1 if `new_sample'
	mata : X=.
	mata : PX=.
	mata : y_tilde =.
	mata : Py_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list'","`touse'")
	mata : st_view(PX,.,"M0_*","`touse'")
	mata : st_view(y_tilde,.,"`y_tild'","`touse'")
	mata : st_view(Py_tilde,.,"Y0_","`touse'")
	mata : st_view(y,.,"`depvar'","`touse'")	
	* prepare  future inversions 
	mata : invPXPX = invsym(cross(PX,PX))
	
	** initial value 
capture	 confirm matrix `from'
if _rc==0 {
	mata : beta_initial = st_matrix("`from'")
	mata : beta_initial = beta_initial'
}
else {
	mata : beta_initial = invPXPX*cross(PX,Py_tilde)
}
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
	* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: alpha = log(mean(y:*exp(-xb_hat)))
	mata: y_tilde = log(y + `delta'*exp(xb_hat :+ alpha )) :-mean(log(y + `delta'*exp(xb_hat :+ alpha)) -xb_hat :- alpha  )
	cap drop `y_tild' 
	*quietly mata: st_addvar("double", "`y_tild'")
	*mata: st_store(.,"`y_tild'",y_tilde)
	mata: st_store(., st_addvar("double", "`y_tild'"), "`touse'", y_tilde)
	cap drop Y0_
    quietly hdfe `y_tild' if `touse'  [`weight'] , absorb(`absorb') generate(Y0_)
	mata : st_view(Py_tilde,.,"Y0_","`touse'")
	* OLS
	mata: beta_new = invPXPX*cross(PX,Py_tilde)
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
	*local k = `maximum'
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
	mata: xb_hat_M = PX*beta_initial 
	mata: xb_hat_N = X*beta_initial
	mata: fe = y_tilde - Py_tilde + xb_hat_M - xb_hat_N
*	mata: P_eta = Py_tilde + xb_hat_M
*	cap drop P_eta 
*	quietly mata: st_addvar("double", "P_eta")
*	mata: st_store(.,"P_eta",P_eta)
	mata: xb_hat = xb_hat_N + fe :+ alpha 
	*mata : constant_c = mean(log(y + `delta'*exp(xb_hat :+ alpha)) -xb_hat :- alpha)
	*mata: Pu = exp(P_eta :+ constant_c) :-`delta'
*	cap drop xb_hat 
*	quietly mata: st_addvar("double", "xb_hat")
*	mata: st_store(.,"xb_hat",xb_hat)
mata: ui = y:*exp(-xb_hat)
mata: weight = ui:/(ui :+ `delta')
	//mata: weight =  Pu:/(Pu :+`delta')
 *** Calcul de la matrice de variance-covariance
  	foreach var in `var_list' {     // rename variables for last ols
	quietly	rename `var' TEMP_`var'
	quietly	rename M0_`var' `var'
	}
cap _crcslbl Y0_ `depvar'
 quietly: reg Y0_ `var_list'  if `touse' [`weight'`exp'], `option' noconstant 
 local df_r = e(df_r) - `df_a'
  	if "`cluster'" !="" {
 local df_r = e(df_r) 
	}
 * Calcul du "bon" residu
	matrix beta_final = e(b) // 
	matrix Sigma = (e(df_r) / `df_r')*e(V)
	*cap drop xb_hat
	*quietly predict xb_hat, xb
	*cap drop ui
*quietly gen ui = `depvar'*exp(-xb_hat)
	*mata : ui= st_data(.,"ui")
*	quietly gen ui = `depvar'*exp(-xb_hat)
*	quietly gen weight = ui/(`delta'+ ui)
*	mata : weight= st_data(.,"weight")
*** rename variables
	foreach var in `var_list' {      // rename variables back
	quietly	rename `var' M0_`var'
	quietly	rename TEMP_`var' `var'
	}
* Calcul de Sigma_0, de I-W, et de Sigma_tild
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (cross(PX,PX))*Sigma_hat*(cross(PX,PX)) // recover original HAC 
	mata : invXpIWX = invsym(cross(PX, weight,PX)) 
	mata : Sigma_tild = invXpIWX*Sigma_0*invXpIWX
	mata: Sigma_tild = (Sigma_tild+Sigma_tild'):/2
    mata: st_matrix("Sigma_tild", Sigma_tild) // used in practice
	*** Stocker les resultats dans une matrice
	local names : colnames beta_final
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
		cap drop _COPY
	quietly: gen _COPY = `touse'
   ereturn post beta_final Sigma_tild , obs(`=e(N)') depname(`depvar') esample(`touse')  dof(`df_r')
	cap drop iOLS_delta_HDFE_xb_hat
	cap drop iOLS_delta_HDFE_fe
	cap drop iOLS_delta_HDFE_error

		    mata: st_store(., st_addvar("double", "iOLS_delta_HDFE_fe"), "_COPY", fe)
	    mata: st_store(., st_addvar("double", "iOLS_delta_HDFE_error"), "_COPY", ui)
    	mata: st_store(., st_addvar("double", "iOLS_delta_HDFE_xb_hat"),"_COPY", xb_hat_N)
		cap drop _COPY
cap drop Y0_*
cap drop M0_*   
ereturn scalar delta = `delta'
ereturn scalar eps =   `eps'
ereturn scalar niter =  `k'
ereturn local cmd "iOLS_HDFE"
ereturn local vcetype `option'
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
ereturn display

end
