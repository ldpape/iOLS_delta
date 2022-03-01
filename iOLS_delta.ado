** 28/06/2021 : Corrected error on Diagonal Matrix of Weights using "cross".
** 14/12/2021 : Corrected convergence criteria with "( . )"
** 14/12/2021 : Changed Convergence Criteria from Absolute change to Relative Change
** 14/12/2021 : Added a quietly after "preserve" 
** 14/12/2021 : Changed the constant calculation to avoid numerical log(0).
** 21/12/2021 : Updated to matrix form for speed and options to control convergence.
** 04/01/2021 : Add additional stopping criteria + return of the constant alpha.
** 20/01/2021 : Corrected S.E. for symmetrization & Added PPML Singleton & Separation drop.
** 01/02/2021 : Drop "preserve" to gain speed & postestimation
** 03/02/2021 : Check Singleton using Sergio Correia, Zylkin and Guimarães method.
** 04/02/2021 : Warm starting point modification
** 05/ 02 / 2021 : add dof as ereturn. 
cap program drop iOLS_delta
program define iOLS_delta, eclass 
//	syntax [anything] [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) Robust LIMit(real 0.00001) MAXimum(real 1000) CLuster(varlist numeric)]
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8) from(name) MAXimum(real 10000) Robust CLuster(string)]        

	marksample touse
	markout `touse'  `cluster', s     
	*** prepare options 
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "vce(cluster `cluster') "
	}
	local option = "`opt1'`opt2'"
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken _rhs list_var : list_var, p("(")
* check singleton 
foreach var of varlist `depvar' `_rhs' {
quietly: replace `touse' = 0 if missing(`var')	
}
loc tol = 1e-5
tempvar u w xb
quietly: gen `u' =  !`depvar' if `touse'
quietly: su `u'  if `touse', mean
loc K = ceil(r(sum) / `tol' ^ 2)
quietly: gen `w' = cond(`depvar', `K', 1)  if `touse'
while 1 {
	*qui reghdfe u [fw=w], absorb(id1 id2) resid(e)
	quietly: reghdfe `u' `_rhs' [fw=`w']  if `touse' , resid noabsorb 
	quietly: predict double `xb'  if `touse', xbd
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
	** drop collinear variables
	tempvar cste
	gen `cste' = 1
    _rmcoll `_rhs' `cste' if `touse', forcedrop 
	local var_list `r(varlist)' 
	*** prepare iOLS 
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + `delta') if `touse'
	*** Initialisation de la boucle
	mata : X=.
	mata : y_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list' `cste'","`touse'")
	mata : st_view(y_tilde,.,"`y_tild'","`touse'")
	mata : st_view(y,.,"`depvar'","`touse'")
	mata : invXX = invsym(cross(X,X))
** initial value 
capture	 confirm matrix `from'
if _rc==0 {
	mata : beta_initial = st_matrix("`from'")
	mata : beta_initial = beta_initial'
}
else {
	mata : beta_initial = invXX*cross(X,y_tilde)
}
** initiate
	mata : beta_t_1 = beta_initial // needed to initialize
	mata : beta_t_2 = beta_initial // needed to initialize
	mata : q_hat_m0 = 0
	local k = 1
	local eps = 1000	
	mata: q_hat = J(`maximum', 1, .)
	*** ItÃ©rations iOLS
	_dots 0
	while ( (`k' < `maximum') & (`eps' > `limit') ) {
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1])))
	mata : beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat))- xb_hat)
		* 2SLS 
	mata: beta_new = invXX*cross(X,y_tilde)
		* Difference entre les anciens betas et les nouveaux betas
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
*	local k = `maximum'
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
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1])))
	mata : beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
	mata : y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat)) - xb_hat) 
	mata: ui = y:*exp(-xb_hat)
	mata: weight = ui:/(ui :+ `delta')
 	* Retour en Stata 
	cap drop `y_tild' 
	mata: st_store(., st_addvar("double", "`y_tild'"), "`touse'", y_tilde)
	quietly: reg `y_tild' `var_list' [`weight'`exp'] if `touse', `option'
	local dof `e(df_r)'
	matrix beta_final = e(b)
	matrix Sigma = e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (quadcross(X,X))*Sigma_hat*(quadcross(X,X))
	mata : invXpIWX = invsym(quadcross(X, weight, X))
	mata : Sigma_tild = invXpIWX*Sigma_0*invXpIWX
	mata : Sigma_tild = (Sigma_tild+Sigma_tild'):/2 
 	mata: st_matrix("Sigma_tild", Sigma_tild)
	*** Stocker les resultats dans une matrice
	local names : colnames beta_final
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
	cap drop _COPY
	quietly: gen _COPY = `touse'
    ereturn post beta_final Sigma_tild , obs(`=e(N)') depname(`depvar') esample(`touse')  dof(`dof') 
    cap drop iOLS_xb_hat
	cap drop iOLS_error
    	mata: st_store(., st_addvar("double", "iOLS_error"), "_COPY", ui)
    	mata: st_store(., st_addvar("double", "iOLS_xb_hat"),"_COPY", xb_hat)
		cap drop _COPY
ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn scalar df_r = `dof'
ereturn local cmd "iOLS"
ereturn local vcetype `option'
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
ereturn display
end

