* 16/12 : change constant calculation to avoid a log of 0 & change eps.
* 19/12 change covariance matrix calculation for large data set
* 19/12 : add correction when no covariate is included.
* 21/12 : Manual iteration of 2SLS GMM + options to control nb iterations /convergence..
* 04/01 : retour de la constante + check de convergence 
* 21/01 : symmetric S.E. + correction de syntax + check singleton de PPML
* 02/02 : drop preserve for speed + memory gain, correction for 'touse', and post-estimates
* 03/02 : drop singleton using Correia, Zylkin and Guimaraes method
* 04/02 : warm starting point
* 07/02 : degrees of freedom in ereturn
cap program drop i2SLS_delta
program define i2SLS_delta, eclass
//syntax anything(fv ts numeric) [if] [in] [aweight pweight fweight iweight]  [, DELta(real 1) LIMit(real 0.00001) MAXimum(real 1000) Robust CLuster(string)  ]

syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) from(name) endog(varlist) instr(varlist) LIMit(real 1e-8)  MAXimum(real 10000) Robust CLuster(string)]           

marksample touse   
markout `touse'  `cluster', s  
	
	if "`gmm2s'" !="" {
		local opt0 = "`gmm2s' "
	}
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "cluster(`cluster') "
	}
	local option = "`opt0'`opt1'`opt2'"
	*** Obtain lists of variables 
	local list_var `varlist'
	gettoken depvar list_var : list_var
	gettoken _rhs list_var : list_var, p("(")
foreach var of varlist  `depvar' `_rhs' `endog' `instr'{
quietly replace `touse' = 0 if missing(`var')	
}
loc tol = 1e-5
tempvar u w xb
quietly: gen `u' =  !`depvar' if `touse'
quietly: su `u'  if `touse', mean
loc K = ceil(r(sum) / `tol' ^ 2)
quietly: gen `w' = cond(`depvar', `K', 1)  if `touse'
while 1 {
	*qui reghdfe u [fw=w], absorb(id1 id2) resid(e)
quietly:	reg `u' `_rhs' `endog' [fw=`w']  if `touse'
quietly:	predict double `xb'  if `touse', xb
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
	local var_list `endog' `r(varlist)' `cste'  
	local instr_list `instr' `r(varlist)' `cste' 
	local exogenous `r(varlist)'
	*** Initialisation de la boucle
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + `delta') if `touse'
	** prepare 2SLS
	*local var_list  `endog' `indepvar' `cste'
	*local instr_list `instr' `indepvar' `cste'
	mata : X=.
	mata : Z=.
	mata : y_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list'","`touse'")
	mata : st_view(Z,.,"`instr_list'","`touse'")
	mata : st_view(y_tilde,.,"`y_tild'","`touse'")
	mata : st_view(y,.,"`depvar'","`touse'")
	mata : invPzX = invsym(cross(X,Z)*invsym(cross(Z,Z))*cross(Z,X))*cross(X,Z)*invsym(cross(Z,Z))
	
	** initial value 
capture	 confirm matrix `from'
if _rc==0 {
	mata : beta_initial = st_matrix("`from'")
	mata : beta_initial = beta_initial'
}
else {
	mata : beta_initial = invPzX*cross(Z,y_tilde)
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
		* Nouveaux beta
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1]) ))
	mata: beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat))- xb_hat)
		* 2SLS 
	mata: beta_new = invPzX*cross(Z,y_tilde)
		* DiffÃ©rence entre les anciens betas et les nouveaux betas
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
    mata: q_hat_m =  mm_median(q_hat[((`k'-49)..`k'),.] ,1)
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
	* Calcul du "bon" rÃ©sidu
	mata: xb_hat = X*beta_new
	mata : y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat)) - xb_hat)
	mata : ui = y:*exp(-xb_hat)
	mata: weight = ui:/(ui :+ `delta')
	* Retour en Stata 
	cap drop `y_tild' 
	mata: st_store(., st_addvar("double", "`y_tild'"), "`touse'", y_tilde)
quietly: ivreg2 `y_tild' `exogenous' (`endog' = `instr') [`weight'`exp'] if `touse', `option' 
	* Calcul de Sigma_0, de I-W, et de Sigma_tild
	local dof `e(Fdf2)'
	matrix beta_final = e(b) // 	mata: st_matrix("beta_final", beta_new)
	matrix Sigma = e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (cross(X,Z)*invsym(cross(Z,Z))*cross(Z,X):/rows(X))*Sigma_hat*(cross(X,Z)*invsym(cross(Z,Z))*cross(Z,X):/rows(X)) // recover original HAC 
	mata : invXpPzIWX = invsym(0.5:/rows(X)*cross(X,Z)*invsym(cross(Z,Z))*cross(Z,weight,X)+ 0.5:/rows(X)*cross(X,weight,Z)*invsym(cross(Z,Z))*cross(Z,X))
	mata : Sigma_tild = invXpPzIWX*Sigma_0*invXpPzIWX
	mata : Sigma_tild = (Sigma_tild+Sigma_tild'):/2 
    	mata: st_matrix("Sigma_tild", Sigma_tild) // used in practice
	*** Stocker les resultats dans une matrice
	local names : colnames beta_final
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
	cap drop _COPY
	quietly: gen _COPY = `touse'
    ereturn post beta_final Sigma_tild , obs(`e(N)') depname(`depvar') esample(`touse')  dof(`=e(Fdf2)') 
	 cap drop i2SLS_xb_hat
	cap drop i2SLS_error
	*quietly mata: st_addvar("double", "iOLS_xb_hat")
	*mata: st_store(.,"iOLS_xb_hat",xb_hat)
	*quietly mata: st_addvar("double", "iOLS_error")
	*mata: st_store(.,"iOLS_error",ui)
    	mata: st_store(., st_addvar("double", "i2SLS_error"), "_COPY", ui)
    	mata: st_store(., st_addvar("double", "i2SLS_xb_hat"),"_COPY", xb_hat)
		cap drop _COPY

ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn scalar widstat = e(widstat) 
ereturn scalar df_r = dof
ereturn scalar arf = e(arf)
ereturn local cmd "i2SLS_delta"
ereturn local vcetype `option'
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
ereturn display
end

