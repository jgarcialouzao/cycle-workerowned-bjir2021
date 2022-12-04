* STATA 14
* MCVL - Worker panel Monthly Frequency
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13


log using logs\workerpanel.log, replace	

use ../mcvl_stata/contempspells.dta, clear
drop skill ptime year_mcvl spellstart_old regime

gunique idplant
gunique idperson

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

expand nobs_spellmonth

gen month_wobs=month_startspell
bys idspell: replace month_wobs = month_wobs + _n - 1
format month* %tm

gen year_w=yofd(dofm(month_wobs))

drop if year_w>=2017

drop month_start* month_end* nobs* 

gunique idplant
gunique idperson

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

*Earnings are reported in a monthly basis for worker-plant matches - if more than one spell with the same employer in a given month, then collapse days and keep last obs
bys idperson idplant month_wobs: gegen tmp = total(days)
bys idperson idplant month_wobs: gen nobs = _N
replace days = tmp if nobs>1
bys idperson idplant month_wobs (spellend_date): keep if _n == _N
drop tmp nobs*

gunique idplant
gunique idperson

*Employer info - pick workers from selected plants: CFs vs WFs
gen year_mcvl = year_w
set more 1
merge m:1 idplant year_mcvl using ../Data/plantpanel_initial.dta, keepusing(idfirm size extdate provinceplant* sector* creation_date socialeco nocont regime type1plant multi) keep(match)
drop if size==0
drop _merge

tab year_w socialeco, col

gunique idplant
gunique idperson

**Merge personal information from individual panel - not matched obs. have some missing key information
merge m:1 idperson year_mcvl using ../mcvl_stata/wpanel.dta, keepusing(educ female nationality countrybirth datebirth provincebirth) keep(match)
drop _merge

tab year_w socialeco, col

** Keep only worker(-plant) matches with complete info
	*Personbal traits
drop if datebirth==. | female==. | (nationality==. & countrybirth==. & provincebirth==.) | education == .
	*Keep workers age 20-60
gen age = year_w - yofd(datebirth)
keep if age>=20 & age<=60

tab year_w socialeco, col

gunique idplant
gunique idperson

**Merge job-characteristics - changes at extraction moment (year freq.)
gen  year_obs = year_w
merge m:1 idperson idplant year_obs using ../mcvl_stata/job_tvchar.dta, keepusing(skill_tv ptime_tv) keep(match)
drop _merge

tab socialeco
*Part-time measure below 10 are typically typos, should be dropped (see MCVL documentation)
drop if ptime_tv<10

tab year_w socialeco, col

gunique idplant
gunique idperson

**Merge monthly earnings
  merge m:1 idperson idplant month_wobs using ../mcvl_stata/wages_m20052017.dta, keep(match) keepusing(w)
drop _merge

tab year_w socialeco, col

gunique idplant
gunique idperson

*General regime and remaining activities in primary sector
drop if regime>111
drop if (sector1d==1 | sector2d == 97)
drop regime

gunique idplant
gunique idperson

*Standard labor relationships
drop if type1plant>0 
drop type1plant
drop if sector1d>=13

gunique idplant
gunique idperson

*Discard missing contract but also internships other very peculiar contracts no relevant
drop if contract==0
drop if contract==420 | contract==421 | contract==520 // internships
drop if contract==540 | contract==541  // partial-retirement and its temporal replacement for the rest of time
*drop if contract==410 | contract==418 | contract==441 | contract==510 | contract==518 // replacement workers

gunique idplant
gunique idperson


*Merge max cap - from SS
fmerge m:1 year_w using ../Data/capsgeneralregime.dta, keep(match) keepusing(maxbase minbase)
drop _merge

gunique idplant
gunique idperson

*SS calculates daily caps dividing by 30 days in a month
gen dailymaxk  = maxbase/30
gen dailymink  = minbase/30

*From now on, daily wages strictly capped
gen dailyw = w/30
replace dailyw = dailymaxk if dailyw>dailymaxk
replace dailyw = dailymink if ptime==100 & dailyw==dailymink

*Add cpi2016
fmerge m:1 year_w using ../Data/cpi2016.dta, keep(match) keepusing(cpi2016)
drop _merge 

*Gen real daily wages and caps
gen rdailyw    = dailyw/(cpi2016/100)
gen rdailymaxk = dailymaxk/(cpi2016/100)
gen rdailymink = dailymink/(cpi2016/100)
drop cpi2016

*Identify censored observation
*maximum cap
gen  maxcens = 1 if rdailyw==rdailymaxk
recode maxcens . = 0

*minimum caps
gen mincens = 1 if rdailyw==rdailymink & ptime==100
recode mincens . = 0

	sum maxcens mincens

 *Exclude very short *sporadic* worker-firm matches and those paying less than 1/12 of the minimum wage - not even needed in the cell tobits
bys idperson idplant year_w: gegen d = total(days)
drop if d<=30
drop d
bys idperson idplant year_w: gegen totalw = total(w)
gegen minw = mean(minbase)
drop if totalw<minw
drop if rdailyw<=1
drop totalw minw dailyw dailymaxk dailymink maxbase

compress
tab year_w socialeco, col

gunique idplant
gunique idperson

save ../Data/workerpanel_monthly.dta, replace

log close


*Correct top-coded earnings using cell-by-cell Tobit models
do code_celltobit


