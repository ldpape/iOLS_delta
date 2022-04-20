# iOLS_delta : This repository includes all available STATA programs  of iterated Ordinary Least Squares

This repository includes code for iOLS_delta, i2SLS_delta, iOLS_MP as well as iOLS_HDFE and i2SLS_HDFE which allows for high-dimensional fixed effects, as described in Bellego, Benatia and Pape (2021). These programs rely on other programs : you will need to have them installed.

>ssc install hdfe

>ssc install reghdfe  // If an error appears, try downloading the more recent version from http://scorreia.com/software/reghdfe/install.html

>ssc install moremata

>ssc install ivreg2

>ssc install ftools

>ssc install ppml

>ssc install ppmlhdfe 

>ssc install ranktest

To install this code into Stata, run the following (requires at least Stata 14) : 

>cap ado uninstall iOLS_delta

>net install iOLS_delta, from("https://raw.githubusercontent.com/ldpape/iOLS_delta/master/")

This installation provides the following estimation programs : iOLS_delta, iOLS_delta_HDFE (iOLS_delta with many fixed effects) , iOLS_MP (Multiplicative Poisson estimated by iOLS), as well as i2SLS_delta, i2SLS_delta_HDFE (i2SLS_delta with many fixed effects), i2SLS_MP (Multiplicative Poisson estimated by iOLS). 

These estimation programs are complemented by testing programs : iOLS_delta_test, iOLS_delta_HDFE_test, iOLS_MP_test, i2SLS_delta_test, i2SLS_delta_HDFE_test, i2SLS_MP_test, as well as ppml_test, ppmlhdfe_test, popular_fix_test, and popular_fix_iv_test. 

Please feel free to contact me to report a bug or ask a question. 

Note, this code is provided as is and may include potential errors.  It has been tested for Stata version 16 but has also worked on Stata 14. 

