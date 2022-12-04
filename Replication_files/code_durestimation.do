* STATA 14
* MCVL - Discrete time duration model job security Cooperatives

clear all
capture log close
capture program drop _all
set more 1
set seed 13
*set max_memory 200g
set segmentsize 3g
set matsize 11000

use ../Data/duration.dta, clear

*Exit
bys idspell (month_wobs): gen sep = reason_endspell!=0 & _n==_N
qui replace sep = 0 if spellend_date > mdy(12,31,2016)

*Quit
bys idspell (month_wobs): gen quit = reason_endspell==51 & _n==_N
qui replace quit = 0 if spellend_date > mdy(12,31,2016)
*Layoff
bys idspell (month_wobs): gen layoff = ( reason_endspell==54  | (reason_endspell>=91 & reason_endspell<=94)  | (reason_endspell==69 | reason_endspell==77)) & _n==_N
qui replace layoff = 0 if spellend_date > mdy(12,31,2016) 

gen durdep = tenure
drop tenure 

forvalues n = 2/12 {
qui g  durdep`n' = durdep==`n' 
 }

qui compress

forvalues n =13(6)31 {
qui g  durdep`n' =  durdep>=`n'  &  durdep <  `n' + 6
}

qui compress

forvalues n = 37(12)61 {
qui g  durdep`n' =  durdep>=`n'  &  durdep <  `n' + 12
}

forvalues n = 73(24)121 {
qui g  durdep`n' =  durdep>=`n'  &  durdep <  `n' + 24
}

qui compress

qui g  durdepT =  durdep>=144

qui drop  durdep

qui xi i.provinceplant

qui drop provinceplant

qui rename _I* *

qui xi i.industry

qui drop industry

qui rename _I* *

qui compress

global controls " durdep* college age spanish female lnw hs temp ftime fage lnsize provin* indu*"

qui keep sep quit layoff coop $controls id* month*

qui gen quarter = qofd(dofm(month_wobs))
qui xi i.quarter

qui rename _I* *

logit sep       coop $controls quarter_* , cluster(idplant) or

gen csep = 0

replace csep = 1 if quit==1

replace csep = 2 if layoff==1

mlogit csep     coop $controls quarter_* , cluster(idplant) rrr


