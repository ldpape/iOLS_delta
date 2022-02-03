{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "i2SLS_delta##syntax"}{...}
{viewerjumpto "Description" "i2SLS_delta##description"}{...}
{viewerjumpto "Citation" "i2SLS_delta##citation"}{...}
{viewerjumpto "Authors" "i2SLS_delta##contact"}{...}
{viewerjumpto "Examples" "i2SLS_delta##examples"}{...}
{viewerjumpto "Description" "i2SLS_delta##Testing"}{...}
{viewerjumpto "Stored results" "i2SLS_delta##results"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:i2SLS_delta} {hline 2}} Iterated Two Stage Least Squares (i2SLS) with delta {p_end}

{p2colreset}{...}

{pstd}{cmd:Introduction} This program implements iterated Two Stage Least Squares with delta, as described by {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3444996":Bellego, Benatia, and Pape (2021)}. {cmd: i2SLS_delta} is a solution to the problem of the log of zero with endogenous covariates.  This method relies on running the "ivreg2" function iteratively. This provides the reader with the final IV estimates and allows the use the post-estimation commands available under regress (using Y_tilde = log(Y + delta*exp(xb))) as a dependent variable. Delta allows the user to assess several moment conditions to assess the robustness of the parameter estimates to moment specification. The program {cmd:i2SLS_delta_test} provide a test to assess how well each of these moments, which have implications in terms of the patter n of zeros in the data, compare to the pattern of zeros observed in the data.

{pstd}{cmd:Note:} This program automatically checks for the presence of seperation, which would preclude the existence of estimates, using the method proposed by {browse "https://arxiv.org/pdf/1903.01633.pdf":Correia, Guimaraes, and Zylkin (2019)}. This results in dropping problematic observations.


{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:i2SLS_delta}
{depvar} [{indepvars}]
{if}  {cmd:,} delta(#) endog({endogvars}) instr({instruments}) [{help i2SLS_delta##options:options}] {p_end}

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of exogenous explanatory variables {p_end}
{synopt:{it:endogvars}} List of endogenous explanatory variables {p_end}
{synopt:{it:instruments}} List of instrumental variables {p_end}

{synoptline}
{p2colreset}{...}

{marker opt_summary}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Standard Errors: Classical/Robust/Clustered}
{synopt:{opt vce}{cmd:(}{help i2SLS_delta##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be classical if unspecified (assuming homoskedasticity), {opt r:obust}, or vce({opt cl:uster} varlist) (allowing two- and multi-way clustering){p_end}
{syntab: Delta}
{synopt:{opt delta}{cmd:(}{help i2SLS_delta##delta:delta}{cmd:)}}{it:delta} is any strictly positive constant. Set to 1 if unspecified. {p_end}
{syntab: Convergence}
{synopt:{opt limit}{cmd:(}{help i2SLS_delta##limit:limit}{cmd:)}} Choose convergence criteria in terms of mean squared difference between two set of paramter estimates between two iterations. Set to 1e-8 if unspecified. {p_end}
{synopt:{opt maximum}{cmd:(}{help i2SLS_delta##maximum:maximum}{cmd:)}} Maximum number of iterations. Set to 10,000 if unspecified. {p_end}

{marker Post-Estimation}{...}
{title:Post-Estimation}

{pstd} This program generates two variables : {cmd:i2SLS_delta_xb} which calculates the linear index for the final sample and {cmd:i2SLS_delta_U} which provides the un-transformed residual U_i. 

{marker authors}{...}
{title:Authors}

{pstd} Christophe Bellego, David Benatia, Louis Pape {break}
CREST - ENSAE - HEC Montréal - Ecole Polytechnique {break}
Contact: {browse "mailto:louis.pape@polytechnique.edu":louis.pape@polytechnique.edu} {p_end}

{marker citation}{...}
{title:Citation}

{pstd}
Bellégo Christophe, Benatia David, and Pape Louis-Daniel, Dealing with Logs and Zeros in Regression Models (2019).
Série des Documents de Travail n° 2019-13.
Available at SSRN: https://ssrn.com/abstract=3444996 

or in BibTex :

@misc{bellego_benatia_pape_2019, title={Dealing with logs and zeros in Regression Models}, journal={SSRN}, author={Bellégo, Christophe and Benatia, David and Pape, Louis-Daniel}, year={2019}, month={Sep}} 


{marker examples}{...}
{title:Examples}

{pstd} We compare i2SLS_ivreg2 with IV-Poisson (using ivpois)
{browse "http://www.haghish.com/statistics/stata-blog/stata-programming/download/ivpois.html":ivpois help file}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. i2SLS_delta injuries airline , endog(XYZowned) instr(n) , delta(100) vce(robust)}{p_end}
{phang2}{cmd:. ivpois injuries ,endog(XYZowned) exog(n) }{p_end}
{hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:i2SLS_delta} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}} number of observations{p_end}
{synopt:{cmd:e(sample)}} marks the sample used for estimation {p_end}
{synopt:{cmd:e(eps)}} sum of the absolute differences between the parameters from the last two iterations of iOLS {p_end}
{synopt:{cmd:e(k)}} number of iterations of iOLS{p_end}
{synopt:{cmd:i2SLS_delta_U}} un-transformed residual U_hat from Y = exp(Xb)*U {p_end}
{synopt:{cmd:i2SLS_delta_xb}} estimated linear index Xb {p_end}

