* STATA 14
* MCVL - Sample selection for aggregate evidence (plant sample)
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13

log using logs\popcoverage.log, replace	


*Goal: select plants to create a panel 
use ../data/fpanel.dta, clear

gunique idplant if size!=0

keep year_mcvl idplant idfirm legal* type* CNAE* size* regime provinceplant* creation_date extdate

**Create exhaustive and mutually exclusive employer categories using information on legal structure, type of plant (CCC), type of labor relationship between worker and employer
*Legal structure

*Valid tax ID
keep if legal1firm == 9 

*Changing tax ID
gegen group = group(idfirm)
bys idplant: gegen sd=sd(group)
drop if sd!=0
drop group sd

*Select SA, SRL, foreign firms and coops from information on legal structure (personalidad jurídica) + sole proprietors 
keep if legal2firm==1 | legal2firm==2 | legal2firm==6 | legal2firm==10 | legal2firm==17 | legal2firm==88

*Use information on the speficic type of plant to filter plants -keep cooperativas de trabajo asociado, labor societies, and others 
drop if type2plant==100 | type2plant==110 | type2plant==120 | type2plant==1303 |  type2plant==2200 | type2plant==2600 | type2plant==2601 | type2plant==4100 | type2plant==5081

gen coop_we=1 if legal2firm==6 & (type2plant==5161 | type2plant==9999)
gen coop_worker_we=1 if coop_we==1 & type1plant!=930
gen coop_partner_we=1 if coop_we==1 & type1plant==930

gen ls_we=1 if (legal2firm==1 | legal2firm==2) & type2plant==5180
gen ls_worker_we=1 if ls_we==1 & type1plant!=951
gen ls_partner_we=1 if ls_we==1 & type1plant==951

gen kfirm_we=1 if (legal2firm==1 | legal2firm==2 | legal2firm==10 | legal2firm==17) & type2plant==9999 & type1plant!=930

*gen soleprop_we=1 if legal2firm==88 & type2plant==9999

gen socialeco=1 if kfirm_we==1 
replace socialeco=2 if coop_we==1
replace socialeco=3 if ls_we==1
*replace socialeco=4 if soleprop_we==1
label define socialecolb 1 "Capitalist firm" 2 "Cooperative"  3 "Labor society" /*4 "Sole proprietor"*/, modify
label values socialeco socialecolb
drop if socialeco==.

drop coop_we coop_worker_we coop_partner_we ls_we ls_worker_we ls_partner_we kfirm_we //soleprop_we

*Main analaysis focus on the General Regime excluding special regimes embedded.
* Given that the population data does not differentiate between them. For comparative reasons I decide to follow the same approach.
keep if regime<=137
drop if size==0
keep if socialeco == 1 | socialeco==2

tempfile plantsworkers
save `plantsworkers'

preserve
tempfile workerspop
*Workers
use ../../MCVL/data_stata/wempspells.dta, clear

*Drop spells that finished or started outside the observation window
drop if spellend_date<mdy(1,1,2005)
drop if spellstart_date>=mdy(1,1,2018)

**Transform dataset to individual-year-spell
gen y_startspell=yofd(spellstart_date)
replace y_startspell = yofd(mdy(1,1,2005)) if spellstart_date < mdy(1,1,2005)
gen y_endspell=yofd(spellend_date)
replace y_endspell = yofd(mdy(12,31,2017)) if spellend_date > mdy(12,31,2017)

gen nobs_spelly= (y_endspell - y_startspell) + 1

expand nobs_spelly

gen y_wobs=y_startspell
bys idperson spellstart_date spellend_date idplant: replace y_wobs = y_wobs + _n - 1

gen year_w=y_wobs

drop if year_w<2005 | year_w>2017

drop  y_*  year_mcvl

*Point-in-time employment stock: active jobs last day of each month
gen datestock = mdy(12,31,year_w)
format datestock %td

keep if spellstart_date<=datestock & spellend_date>=datestock

**Pick workers from active plants in the plant panel
gen year_mcvl = year_w
merge m:1 idplant year_mcvl using `plantsworkers' , keep(match)
drop _merge 


*No. employee-employer (plant) matches
bys year_w idperson idplant: gen tmpW_type = _n == 1 

*No plants
bys year_w idplant: gen tmpP_type = _n == 1 

*No firms
bys year_w idfirm: gen tmpF_type = _n == 1 

gcollapse (sum) noworkers_dec = tmpW_type nofirms_dec = tmpF_type noplants_dec = tmpP_type, by(socialeco year_w)

save `workerspop'
restore


*Unique identifier for plants/firms
gen tmpP_type = 1 
bys year_mcvl socialeco idfirm: gen tmpF_type = _n == 1 

gen year_w = year_mcvl


gcollapse  (sum) noworkers_ext = size noplants_ext = tmpP_type nofirms_ext = tmpF_type , by(socialeco year_w)


merge 1:1 socialeco year_w using `workerspop'
drop _merge
merge 1:1 socialeco year_w using ../../SuppData/meyssdata.dta 
drop _merge

save ../data/populationcoverage.dta, replace



