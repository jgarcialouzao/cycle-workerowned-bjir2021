* STATA 14
* MCVL - Final panel of plants
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13


log using logs\plantpanel_final.log, replace	


use ../data/plantpanel_initial.dta, replace

gunique idplant if size!=0

*General regime and remaining activities in primary sector
drop if regime>111
drop if (sector1d==1 | sector2d == 97)
drop regime

gunique idplant if size!=0

*Standard labor relationships - this excludes partners in the General Regime.
*drop if type1plant>0 
keep if type1plant==0 | type1plant==930
drop if sector1d>=13

gunique idplant if size!=0

keep year_mcvl extdate idfirm idplant provinceplant* sector1d sector2d size size_lag size_wgt entry exit creation_date socialeco  nocont type1plant

gen month_wobs = mofd(extdate)
format month_wobs %tm

*Cooperative variable 
gen coop=1 if socialeco>=2
recode coop .=0
label var coop "Cooperative"

*log Size 
gen lnsize = ln(size)
replace size_wgt = 1 if size_wgt==0

*Plant age
gen yearbirth = yofd(creation_date)
gen age = year_mcvl - yearbirth
gen age_group = 1 if age<1
replace age_group = 2 if age>=1 & age<5
replace age_group = 3 if age>=5 

*Multi-establishment firms
bys idfirm year_mcvl: gen nobs = _N
gen multi = 1 if nobs>1
recode multi .=0
drop nobs

*Unemp rate
gen year = year_mcvl


merge m:1 year using ../Data/inedataurate.dta, keep(match) keepusing(urate urate_lag)
drop _merge 


gunique idplant if size!=0

label var urate_lag      "Unemp. rate"


foreach v in lag   { 

gen urate_`v'_coop = urate_`v'*coop

}

label var urate_lag_coop "Unemp. rate x Coop"


*Time vars
gen trend= year_mcvl - 2005 + 1 
gen trend2=trend*trend

xi i.year_mcvl
rename _I* *


*Province vars
xi i.provinceplant, noomit
rename _I* *

*Sector vars
gen industry = 1     if sector1d==2
replace industry = 2 if sector1d==3
replace industry = 3 if sector1d==4 
replace industry = 4 if sector1d==5 
replace industry = 5 if sector1d==6
replace industry = 6 if sector1d>6
xi i.industry, noomit
rename _I* *

xi i.age_group, noomit
rename _I* *
drop age_group age_group_2


compress
*save ../Data/plantpanel.dta, replace

*use ../Data/plantpanel.dta, clear
*Keep only plants that have workers
preserve
tempfile tmp1
use ../Data/workerpanel_monthly.dta, clear
keep idplant
bys idplant: keep if _n == 1
keep idplant
save `tmp1'
restore

merge m:1 idplant using `tmp1' , keep(1 3)
drop if _m == 1 & type1plant!=930
drop _merge

drop if size==0

gunique idplant

save ../Data/plantpanel_final_wpartners.dta, replace


log close


