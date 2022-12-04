* STATA 14
* MCVL - Worker panel Monthly Frequency
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13



log using logs\workerpanel_final.log, replace

use ../Data/workerpanel_monthly.dta, clear
keep idperson idplant idfirm month_wobs year_w days educ female age idspell contract ptime_tv skill_tv nationality provinceplant creation_date extdate size socialeco nocont sector1d multi spellstart_date spellend_date reason_endspell rdailyw
merge 1:1 idperson idplant month_wobs using ../Data/lnrdailywcorr.dta, keep(match) keepusing(lnrdailyw_sim)

gen rw = rdailyw * days
gen rw_sim = exp(lnrdailyw_sim) * days

*Number of jobs with same establishment in a year
bys idperson idplant spellstart_date spellend_date year_w: gen job = _n == 1

gcollapse (sum) ryearw_sim = rw_sim ryearw_orig = rw days nojobs = job ///
(lastnm) educ female age idspell contract ptime_tv skill_tv nationality provinceplant creation_date extdate size socialeco nocont sector1d multi spellend_date  /// 
(firstnm) spellstart_date , by(idperson idplant idfirm year_w)


gunique idplant
gunique idperson

** Construct and adjust covariates

*Dependent variables
*Earnings

foreach v in orig sim {
gen rdailywft_`v' = ryearw_`v' / (days * (ptime_tv/100))
gen lnryw_`v' = ln(ryearw_`v')
gen lnrdwft_`v' = ln(rdailywft_`v')

label var lnryw_`v'   "(ln) Real annual earnings (`v')"
label var lnrdwft_`v' "(ln) Real ft-equiv. daily wages (`v')"
}

*Days
gen lndays = ln(days)
label var lndays "(ln) Number of days"

*Hours
gen lnptime = ln(ptime_tv)
label var lnptime "(ln) Part-time percentage"

*Female dummy
label var female "Female"
label define femalelb 0 "Male" 1 "Female"
label values female femalelb

*Skill categories
rename skill occupation
gen skill = .
replace skill = 1 if occupation >= 8
replace skill = 2 if occupation == 4 | occupation == 5 | occupation == 6 | occupation==7
replace skill = 3 if occupation == 1 | occupation == 2 | occupation == 3
label define skilllb 1 "Low-skill" 2 "Mid-skill" 3 "High-skill", modify
label values skill skilllb

*Education categories
gen educ=.
replace educ=1 if education<=32
replace educ=2 if education>=40 & education<=43
replace educ=3 if education>=44 & education!=.
label define educlb 1 "Primary ed. (or less)" 2 "Secondary ed." 3 "Tertiary ed.", modify
label values educ educlb
drop education

*Nationality dummy - 
*note that observations with missing nationality have countrybirth abroad
gen spanish=0
replace spanish=1 if nationality==0
label var spanish "Spanish"
label define spanishlb 0 "Non spanish" 1 "Spanish", modify
label values spanish spanishlb
drop nationality 

*Age deviations
*gen age = year - yofd(datebirth)
gen agedev = age - 40
gen agedev2 = (agedev^2)/100
gen agedev3 = (agedev^3)/100
label var age "Age (yr)"
label var agedev2 "Age dev.$^2$/100"
label var agedev3 "Age dev.$^3$/100"

*Create newcomer dummy variable for those with less than a year in the current job
gen tenure = int((mdy(12,31,year_w) - spellstart_date)/360)
gen tenure2 = tenure*tenure
label var tenure  "Tenure (yr)"
label var tenure2 "Tenure sq."
gen newcomer_job = 1 if tenure<1
recode newcomer_job . = 0
label var newcomer_job "Newcomer"


*Fixed-term contract
gen temp = 1 if contract>=300
recode temp .=0
label var temp "Temporary contract"
drop contract


*Cooperative variable 
gen coop=1 if socialeco==2
recode coop .=0
label var coop "Cooperative"

gen newcomer_coop = newcomer * coop
label var newcomer_coop "Newcomer x Coop"

*Plant age
gen yearbirth = yofd(creation_date)
gen fage = year_w - yearbirth
gen age_group = 1 if fage<1
replace age_group = 2 if fage>=1 & fage<5
replace age_group = 3 if fage>=5 

*log Size	
gen lnsize=ln(size)


*Time trend
gen trend= year_w - 2005 + 1
gen trend2=trend^2

*Unemp rate
gen year = year_w
*merge m:1 year provinceplant using ../Data/inedataurprov.dta, keep(match) keepusing(urate_lag )
*drop _merge
*rename urate urate_prov
*rename urate_lag urate_lag_prov

merge m:1 year using ../Data/inedataurate.dta, keep(match) keepusing(urate_lag)
drop _merge

*merge m:1 year using ../Data/fedea_annual.dta, keep(match) keepusing(fedea fedea_lag)
*drop _merge year

*Urate lag12
label var urate_lag      "Unemp. rate"


foreach v in  lag  { 
gen urate_`v'_nc   = urate_`v'*newcomer_job

gen urate_`v'_coop = urate_`v'*coop
gen urate_`v'_coopnc   = urate_`v'*newcomer_coop

}
label var urate_lag_coop       "Unemp. rate x Coop"

label var urate_lag_nc       "Unemp. rate x Newcomer"

label var urate_lag_coopnc       "Unemp. rate x Coop x Newcomer"


*Dummy variables
xi i.skill, noomit
rename _I* *
label var skill_2 "Mid-skill"
label var skill_3 "High-skill"
xi i.educ, noomit
rename _I* *
label var educ_1 "Primary ed."
label var educ_2 "Secondary ed."
label var educ_3 "Tertiary ed."

xi i.provinceplant
rename _I* *
drop skill educ

*Sector vars
xi i.sector1d, noomit
rename _I* *

xi i.age_group, noomit
rename _I* *
drop age_group age_group_2


*xi i.year_mcvl
*rename _I* *

compress

gunique idperson
gunique idplant

save ../Data/workerpanel_final.dta, replace

log close








/*
/*
*rename rdailyw rdailyw_orig
rename lnrdailyw lnrdailyw_orig
gen rdailyw_orig = exp(lnrdailyw_orig)
gen rdailyw_sim  = exp(lnrdailyw_sim)

*Real daily wages ft-equivalent
gen rdailywft_orig = rdailyw_orig / (ptime_tv/100)
gen rdailywft_sim  = rdailyw_sim  / (ptime_tv/100)

*Real monthly wages 
gen rmonthlyw_orig = rdailywft_orig * days * (ptime_tv/100)
gen rmonthlyw_sim  = rdailywft_sim * days * (ptime_tv/100)

*Create annual earnings by idmatch (worker-plant combination)
gegen idmatch = group(idperson idplant)
gen year = yofd(dofm(month_wobs))

*Number of jobs with same establishment in a year
bys idperson idplant spellstart_date_cont spellend_date_cont year: gen job = _n == 1

*Gen full-time equivalent days worked
gen ptime_days = ptime*days


keep year idperson idplant idfirm idmatch r* days ptime_days job socialeco ///
datebirth female education nationality countrybirth provincebirth provinceplant sector1d creation_date size month_wobs seniority contract skill spellstart_date_cont 

replace idfirm = idplant if idfirm==""

gcollapse (sum) ryearw_orig = rmonthlyw_orig ryearw_sim = rmonthlyw_sim year_days = days ptime_days nojob = job ///
(lastnm) idmatch socialeco datebirth female education nationality countrybirth provincebirth   ///
provinceplant sector1d creation_date size month_wobs seniority contract skill rdailymink (firstnm) spellstart_date_cont , by(idperson idplant idfirm year)
*(mean) rdailyw_orig_yavg = rdailyw_orig  rdailywft_orig_yavg = rdailywft_orig  rdailyw_sim_yavg = rdailyw_sim  rdailywft_sim_yavg = rdailywft_sim


order year idperson idplant idfirm idmatch year_days ptime_days r*

gunique idplant
gunique idperson

replace year_days = 360 if year_days>360
gen year_ptime_wgtavg = ptime_days / year_days

gen year_days_job = year_days / nojob

save ../data_ready/tmpwkrpanel.dta, replace

use ../data_ready/tmpwkrpanel.dta, clear
*/
/*
gunique idperson
gunique idplant

*Keep the one main job based on days worked in the year
bys idperson socialeco year: gen nobs = _N
bys idperson socialeco year: gegen maxd = max(year_days)
drop if maxd!=year_days & nobs>1
drop maxd nobs

bys idperson socialeco year: gen nobs = _N
bys idperson socialeco year: gegen maxw = max(ryearw_sim)
drop if maxw!=ryearw_sim & nobs>1
drop maxw nobs

*If still duplicated, drop both obs
bys idperson socialeco year: gen nobs = _N
drop if nobs>1 
drop nobs 
*/
gunique idperson
gunique idplant
