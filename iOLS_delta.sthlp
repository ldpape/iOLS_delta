{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "iOLS_delta##syntax"}{...}
{viewerjumpto "Description" "iOLS_delta##description"}{...}
{viewerjumpto "Citation" "iOLS_delta##citation"}{...}
{viewerjumpto "Authors" "iOLS_delta##contact"}{...}
{viewerjumpto "Examples" "iOLS_delta##examples"}{...}
{viewerjumpto "Description" "iOLS_delta##Testing"}{...}
{viewerjumpto "Stored results" "iOLS_delta##results"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:iOLS_delta} {hline 2}} Iterated Ordinary Least Squares (iOLS) with delta {p_end}

{p2colreset}{...}

{pstd}{cmd:Introduction} This program implements iterated Ordinary Least Squares with delta, as described by {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3444996":Bellego, Benatia, and Pape (2021)}. {cmd: iOLS_delta} is a solution to the problem of the log of zero.  This method relies on running the "regress" function iteratively. This provides the reader with the final OLS estimates and allows the use the post-estimation commands available under regress (using Y_tilde = log(Y + delta*exp(xb))) as a dependent variable. Delta allows the user to assess several moment conditions to assess the robustness of the parameter estimates to moment specification. The program {cmd:iOLS_delta_test} provide a test to assess how well each of these moments, which have implications in terms of the patter n of zeros in the data, compare to the pattern of zeros observed in the data.

{pstd}{cmd:Note:} This program automatically checks for the presence of seperation, which would preclude the existence of estimates, using the method proposed by {browse "https://arxiv.org/pdf/1903.01633.pdf":Correia, Guimarães, and Zylkin (2019)}. This results in dropping problematic observations.


{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:iOLS_delta}
{depvar} [{indepvars}]
{if}  {cmd:,} delta(#) [{help iOLS_delta##options:options}] {p_end}

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of explanatory variables {p_end}
{synoptline}
{p2colreset}{...}

{marker opt_summary}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Standard Errors: Classical/Robust/Clustered}
{synopt:{opt vce}{cmd:(}{help iOLS_delta##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be classical if unspecified (assuming homoskedasticity), {opt r:obust}, or vce({opt cl:uster} varlist) (allowing two- and multi-way clustering){p_end}
{syntab: Delta}
{synopt:{opt delta}{cmd:(}{help iOLS_delta##delta:delta}{cmd:)}}{it:delta} is any strictly positive constant. Set to 1 if unspecified. {p_end}
{syntab: Convergence}
{synopt:{opt limit}{cmd:(}{help iOLS_delta##limit:limit}{cmd:)}} Choose convergence criteria in terms of mean squared difference between two set of paramter estimates between two iterations. Set to 1e-8 if unspecified. {p_end}
{synopt:{opt maximum}{cmd:(}{help iOLS_delta##maximum:maximum}{cmd:)}} Maximum number of iterations. Set to 10,000 if unspecified. {p_end}

{marker Post-Estimation}{...}
{title:Post-Estimation}

{pstd} This program generates two variables : {cmd:iOLS_delta_xb} which calculates the linear index for the final sample and {cmd:iOLS_delta_U} which provides the un-transformed residual U_i. 

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

{pstd} We will replicate Example 1 from Stata's
{browse "https://www.stata.com/manuals/rpoisson.pdf":poisson manual}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. iOLS_delta injuries XYZowned, delta(1) robust}{p_end}
{phang2}{cmd:. poisson injuries XYZowned, robust}{p_end}
{hline}

{pstd} You can convert your results into latex using esttab where "eps" provides the convergence criteria:
{p_end}
{pstd}  We use data on households' trips away from home, as used in {browse "https://www.stata.com/manuals/rivpoisson.pdf":ivpoisson manual}.
to study the effect of cost of transportation (tcost).  Note that iOLS_delta is compatible with using "xi:" for categorical variables (i.e, if you type i. ), as in 
{p_end}
{hline}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. webuse trip }{p_end}
{phang2}{cmd:. eststo clear}{p_end}
{phang2}{cmd:. xi: eststo: iOLS_delta trips cbd ptn worker i.weekend tcost, delta(1) robust }{p_end}
{phang2}{cmd:. xi: eststo: iOLS_delta trips cbd ptn worker i.weekend tcost, delta(10) robust }{p_end}
{phang2}{cmd:. esttab * using table.tex,  scalars(delta eps) }{p_end}
{hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_delta} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}} number of observations{p_end}
{synopt:{cmd:e(sample)}} marks the sample used for estimation {p_end}
{synopt:{cmd:e(eps)}} sum of the absolute differences between the parameters from the last two iterations of iOLS {p_end}
{synopt:{cmd:e(k)}} number of iterations of iOLS{p_end}
{synopt:{cmd:iOLS_delta_U}} un-transformed residual U_hat from Y = exp(Xb)*U {p_end}
{synopt:{cmd:iOLS_delta_xb}} estimated linear index Xb {p_end}

