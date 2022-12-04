* STATA 14
* MCVL - Duration data
clear all
capture log close
capture program drop _all
set more 1
set seed 13


use ../mcvl_stata/contempspells.dta, clear
drop skill ptime spellstart_old regime

*Discard missing contract but also internships other very peculiar contracts no relevant
drop if contract==0
drop if contract==420 | contract==421 | contract==520 // internships
drop if contract==540 | contract==541  // partial-retirement and its temporal replacement for the rest of time
*drop if contract==410 | contract==418 | contract==441 | contract==510 | contract==518 // replacement workers

*Keep only stayers and separations related to quits or laid-offs, anything else no relevant for the question
keep if reason_endspell==0 | reason_endspell==51  | ( reason_endspell==54  | (reason_endspell>=91 & reason_endspell<=94)  | (reason_endspell==69 | reason_endspell==77))

*Drop spells that finished or started outside the observation window
drop if spellend_date<mdy(1,1,2005)
drop if spellstart_date>=mdy(1,1,2017)

compress

*Create idspell
gegen idspell = group(idperson spellstart_date spellend_date idplant)

**Transform dataset to individual-spell-month format
gen month_startspell=mofd(spellstart_date)
replace month_startspell = mofd(mdy(1,1,2005)) if spellstart_date < mdy(1,1,2005)
gen month_endspell=mofd(spellend_date)
replace month_endspell = mofd(mdy(12,31,2016)) if spellend_date > mdy(12,31,2016)

gen nobs_spellmonth = (month_endspell - month_startspell) + 1

*Spells lasting less than a month are excluded in the duration model, they would require an alternative modelling strategy
drop if (month_endspell - month_startspell)  < 1

expand nobs_spellmonth

gen month_wobs=month_startspell
bys idspell: replace month_wobs = month_wobs + _n - 1
format month* %tm

gen year_w=yofd(dofm(month_wobs))

drop if year_w>=2017

*Count days worked in a month
*First and last day of a month
gen first=dofm(month_wobs)
gen last=dofm(month_wobs + 1) - 1

gen 	days = .
replace days = spellend_date - first + 1 if spellstart_date<=first & spellend_date<last
replace days = last - spellstart_date + 1 if spellstart_date>first & spellend_date>=last
replace days = spellend_date - spellstart_date + 1  if spellstart_date>first & spellend_date<last

*SS computes month-daily caps by dividing by 360 days per year - 30 days each month
replace days = 30 if spellstart_date<=first & spellend_date>=last
drop first last 

*Employer info - pick workers from selected plants: CFs vs WFs
gen year_mcvl = year_w
set more 1
merge m:1 idplant year_mcvl using ../Data/plantpanel_initial.dta, keepusing(idfirm size extdate provinceplant* sector* creation_date socialeco nocont regime type1plant multi) keep(match)
drop if size==0
*General regime and remaining activities in primary sector
drop if regime>111
drop if (sector1d==1 | sector2d == 97)
drop regime

*Standard labor relationships
drop if type1plant>0 
drop type1plant
drop if sector1d>=13
drop _merge

**Merge personal information from individual panel - not matched obs. have some missing key information
merge m:1 idperson year_mcvl using ../mcvl_stata/wpanel.dta, keepusing(educ female nationality countrybirth datebirth provincebirth) keep(match)
drop _merge

** Keep only worker(-plant) matches with complete info
	*Personbal traits
drop if datebirth==. | female==. | (nationality==. & countrybirth==. & provincebirth==.) | education == .
	*Keep workers age 20-60
gen age = year_w - yofd(datebirth)
keep if age>=20 & age<=60

**Merge job-characteristics - changes at extraction moment (year freq.)
gen  year_obs = year_w
merge m:1 idperson idplant year_obs using ../mcvl_stata/job_tvchar.dta, keepusing(skill_tv ptime_tv) keep(1 3)
drop _merge

foreach v in skill_tv ptime_tv {
gen flag1 = -month_wobs
bys idspell (flag1): replace `v' = `v'[_n-1] if `v'==. & `v'[_n-1]!=.
drop flag1
bys idspell (month_wobs): replace `v' = `v'[_n-1] if `v'==. & `v'[_n-1]!=.
}

set more 1
**Merge monthly earnings
  merge m:1 idperson idplant month_wobs using ../mcvl_stata/wages_m20052018.dta, keep(1 3) keepusing(w)
drop _merge

replace w = . if w<=1

foreach v in w {
gen flag1 = -month_wobs
bys idspell (flag1): replace `v' = `v'[_n-1] if `v'==. & `v'[_n-1]!=.
}
drop flag1
drop if w == .

*Merge max cap - from SS
fmerge m:1 year_w using ../Data/capsgeneralregime.dta, keep(match) keepusing(maxbase minbase)
drop _merge

*SS calculates daily caps dividing by 30 days in a month
gen dailymaxk  = maxbase/30
gen dailymink  = minbase/30

*From now on, daily wages strictly capped
gen dailyw = w/30
replace dailyw = dailymaxk if dailyw>dailymaxk
replace dailyw = dailymink if ptime==100 & dailyw<=dailymink

*Add cpi2016
fmerge m:1 month_wobs using ../Data/cpi2016m.dta, keep(match) keepusing(cpi2016)
drop _merge 

*Gen real daily wages and caps
gen rdailyw    = dailyw/(cpi2016/100)

*Cooperative variable 
gen coop=1 if socialeco==2
recode coop .=0
label var coop "Cooperative"

gen quarter = qofd(dofm(month_wobs))
merge m:1 quarter using ../Data/ineurate.dta, keep(match) keepusing(urate urate_lag)
drop _merge

*Tenure 
gen tenure = month_wobs - mofd(spellstart_date) + 1

*Full-time
gen ftime = ptime_tv ==100

*Wage
gen lnw = ln(rdailyw)

*Female dummy
label var female "Female"
label define femalelb 0 "Male" 1 "Female"
label values female femalelb

*High-skill
qui g hs = skill == 1 | skill == 2 | skill == 3
qui drop skill

*College
qui g college = education>=44 & education!=.
qui drop educ

*Nationality dummy - 
*note that observations with missing nationality have countrybirth abroad
gen spanish=0
replace spanish=1 if nationality==0
label var spanish "Spanish"
label define spanishlb 0 "Non spanish" 1 "Spanish", modify
label values spanish spanishlb
drop nationality 

*Fixed-term contract
gen temp = 1 if contract>=300
recode temp .=0
label var temp "Temporary contract"
drop contract

*Plant age
gen yearbirth = yofd(creation_date)
gen fage = year_w - yearbirth

*log Size	
gen lnsize=ln(size)

gen industry = 1     if sector1d==2
replace industry = 2 if sector1d==3
replace industry = 3 if sector1d==4 
replace industry = 4 if sector1d==5 
replace industry = 5 if sector1d==6
replace industry = 6 if sector1d>6

keep idperson idspell idplant idfirm month_wobs coop urate* tenure ///
provinceplant hs college industry* lnsize fage temp age spanish female lnw ftime year_w spellstart_date spellend_date reason_endspell 

compress

save ../Data/duration.dta, replace
