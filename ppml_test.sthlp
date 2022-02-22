{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "ppml##syntax"}{...}
{viewerjumpto "Description" "ppml##description"}{...}
{viewerjumpto "Citation" "ppml##citation"}{...}
{viewerjumpto "Authors" "ppml##contact"}{...}
{viewerjumpto "Examples" "ppml##examples"}{...}
{viewerjumpto "Description" "ppml##Testing"}{...}
{viewerjumpto "Stored results" "ppml##results"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:ppml_test} {hline 2}} External Validity Test for Additive Poisson (ppml) {p_end}

{p2colreset}{...}

{pstd}{cmd:Introduction} The program {cmd:ppml_test} provide a test to assess the externality of ppml with respect to how well it fits the pattern of zeros observed in the data. This test is based on the implied proportionality condition which relates the conditional probability of a zero given X in the data to the residuals of Additive Poisson (PPML) estimated by iterated Ordinary Least Squares. This program first estimates ppml and a parametric (logit) or semi-nonparametric conditional probability model (multivariate nearest-neighbor smoother). It then assesses if the residuals from ppml are proportional to the predicted probabilities of the latter model, as described by {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3444996":Bellego, Benatia, and Pape (2021)}.  It provides the reader with a statistic, lambda, which should be near 1 if (a) the probability model is a consistent estimate of Pr(Y>0|Z) and (b) ppml captures well the pattern of zeros in the data. 

{pstd}{cmd:Note:} This program automatically checks for the presence of seperation, which would preclude the existence of estimates, using the method proposed by 
{browse "https://arxiv.org/pdf/1903.01633.pdf" :Correia, Guimaraes, and Zylkin (2019)}.
 This results in dropping problematic observations. Similarly, the probability model drops observations which suffer from separation. 




{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:ppml_test}
{depvar} [{indepvars}]
{if}  {cmd:,} [{help ppml##options:options}] {p_end}

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
{syntab: Probability Model}
{synopt:{opt nonparametric}} If this option is added, the command estimates the probability model using the multivariate nearest-neighbor smoother of {browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X0500500309":Royston & Cox (2005)}.
 Without this option, the program estimates a logistic probability model. {p_end}


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

{pstd} You can convert your results into latex with esttab (estout package) and use the bootstrap.
{p_end}
{pstd}  We use data on households' trips away from home, as used in {browse "https://www.stata.com/manuals/rivpoisson.pdf":ivpoisson manual}.
to study the effect of cost of transportation (tcost).  Note that ppml is compatible with using "xi:" for categorical variables (i.e, if you type i. ), as in 
{p_end}
{hline}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. webuse trip }{p_end}
{phang2}{cmd:. eststo clear}{p_end}
{phang2}{cmd:. xi: eststo reg1: ppml trips cbd ptn worker i.weekend tcost }{p_end}
{phang2}{cmd:. xi: bootstrap lambda_stat=e(lambda) ,    reps(50):  ppml_test trips cbd ptn worker i.weekend tcost ,  nonparametric  }{p_end}
{phang2}{cmd:.	matrix lambda = e(b) }{p_end}
{phang2}{cmd:.	scalar lambda = lambda[1,1] }{p_end}
{phang2}{cmd:.  estadd scalar lambda: reg1 }{p_end}
{phang2}{cmd:.	matrix se = e(se) }{p_end}
{phang2}{cmd:.	scalar se = se[1,1] }{p_end}
{phang2}{cmd:.  estadd scalar se: reg1 }{p_end}
{phang2}{cmd:.  test lambda_stat=1 }{p_end}
{phang2}{cmd:.  estadd scalar pval=r(p): reg1 }{p_end}
{phang2}{cmd:.  esttab * using table.tex, scalars(lambda se pval) }{p_end}
{hline}
{pstd}  We recommend choosing the model which maximizes the associated p-value of lambda (which requires bootstraps of lambda) or directly which  minimizes the squared distance with 1, i.e : MSE = (lambda_stat - 1)^2.
{p_end}
{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ppml} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(lambda)}} Lambda statistic {p_end}
