{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "iOLS_delta_hdfe##syntax"}{...}
{viewerjumpto "Description" "iOLS_delta_hdfe##description"}{...}
{viewerjumpto "Citation" "iOLS_delta_hdfe##citation"}{...}
{viewerjumpto "Authors" "iOLS_delta_hdfe##contact"}{...}
{viewerjumpto "Examples" "iOLS_delta_hdfe##examples"}{...}
{viewerjumpto "Description" "iOLS_delta_hdfe##Testing"}{...}
{viewerjumpto "Stored results" "iOLS_delta_hdfe##results"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:iOLS_delta_hdfe} {hline 2}} Iterated Ordinary Least Squares (iOLS) with delta and High-Dimensional Fixed Effects {p_end}

{p2colreset}{...}

{pstd}{cmd:Introduction} This program implements iterated Two Stage Least Squares with delta, as described by {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3444996":Bellego, Benatia, and Pape (2021)}. {cmd: iOLS_delta_hdfe} is a solution to the problem of the log of zero.  This method relies on running the "regress" function iteratively. This provides the reader with the final estimates and allows the use the post-estimation commands available under regress (using Y_tilde = log(Y + delta*exp(xb))) as a dependent variable. Delta allows the user to assess several moment conditions to assess the robustness of the parameter estimates to moment specification. The program {cmd:iOLS_delta_hdfe_test} provide a test to assess how well each of these moments, which have implications in terms of the patter n of zeros in the data, compare to the pattern of zeros observed in the data. 

{pstd}{cmd:Fixed-Effects:} This package takes a within-transformation to difference out high-dimensional fixed effects. To do so, it relies on the HDFE package developed by {browse "http://scorreia.com/research/hdfe.pdf": Sergio Correia (2017)}. In turn, the obtained standard errors will slightly differ from those obtained running the same model with iOLS_delta_hdfe. 

{pstd}{cmd:Note:} This program automatically checks for the presence of seperation, which would preclude the existence of estimates, using the method proposed by {browse "https://arxiv.org/pdf/1903.01633.pdf": Correia, Guimarães, and Zylkin (2019) }. This results in dropping problematic observations.

{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:iOLS_delta_hdfe}
{depvar} [{indepvars}]
{it:if}  {cmd:,} delta(#) absorb({it:fixed-effects}) [{help iOLS_delta_hdfe##options:options}] {p_end}

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of exogenous explanatory variables {p_end}
{synopt:{it:fixed-effects}} List of categorical variables which are to be differenced-out {p_end}

{synoptline}
{p2colreset}{...}

{marker opt_summary}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Standard Errors: Classical/Robust/Clustered}
{synopt:{opt vce}{cmd:(}{help iOLS_delta_hdfe##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be classical if unspecified (assuming homoskedasticity), {opt r:obust}, or vce({opt cl:uster} varlist) (allowing two- and multi-way clustering){p_end}
{syntab: Delta}
{synopt:{opt delta}{cmd:(}{help iOLS_delta_hdfe##delta:delta}{cmd:)}}{it:delta} is any strictly positive constant. Set to 1 if unspecified. {p_end}
{syntab: Convergence}
{synopt:{opt limit}{cmd:(}{help iOLS_delta_hdfe##limit:limit}{cmd:)}} Choose convergence criteria in terms of mean squared difference between two set of paramter estimates between two iterations. Set to 1e-8 if unspecified. {p_end}
{synopt:{opt maximum}{cmd:(}{help iOLS_delta_hdfe##maximum:maximum}{cmd:)}} Maximum number of iterations. Set to 10,000 if unspecified. {p_end}
{syntab: Starting Point}
{synopt:{opt from}{cmd:(}{help i2SLS_delta##limit:limit}{cmd:)}} Indicate a matrix of parameters to use as a starting point (i.e, from ppml or ivreg2 with log(1+Y) for example). {p_end}

{marker Post-Estimation}{...}
{title:Post-Estimation}

{pstd} This program generates three variables : {cmd:iOLS_delta_hdfe_xb} which calculates the linear index for the final sample, {cmd:iOLS_delta_hdfe_U} which provides the un-transformed residual U_i, and {cmd:iOLS_delta_hdfe_fe} which calculates the sum of individual fixed-effects for each observations. 

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

{browse "http://www.haghish.com/statistics/stata-blog/stata-programming/download/ivpois.html":ivpois help file}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. gen fixed_effect = _n<3}{p_end}
{phang2}{cmd:. iOLS_delta_HDFE injuries airline  , absorb(fixed_effect) delta(100) robust }{p_end}
{hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_delta_hdfe} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}} number of observations{p_end}
{synopt:{cmd:e(sample)}} marks the sample used for estimation {p_end}
{synopt:{cmd:e(eps)}} sum of the absolute differences between the parameters from the last two iterations of iOLS {p_end}
{synopt:{cmd:e(k)}} number of iterations of iOLS{p_end}
{synopt:{cmd:iOLS_delta_hdfe_U}} un-transformed residual U_hat from Y = exp(Xb+fe)*U {p_end}
{synopt:{cmd:iOLS_delta_hdfe_xb}} estimated linear index Xb {p_end}
{synopt:{cmd:iOLS_delta_hdfe_fe}} estimated fixed effect fe {p_end}

