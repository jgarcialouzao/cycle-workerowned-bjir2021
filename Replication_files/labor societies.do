* STATA 14
* MCVL - Employment regression analysis
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\empreg_allp.log, replace	

global fixed                "multi age_group*"
global sectorFEprovFEtrend  "sector1d_3 - sector1d_12 provincep_2 - provincep_50 trend trend2"

/* add labor societies start from employer, do everything here

use ../data_mcvl/employer.dta, clear

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

*No size first time observed
drop if size_wgt == . 

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
drop if socialeco==.

drop coop_we coop_worker_we coop_partner_we ls_we ls_worker_we ls_partner_we kfirm_we //soleprop_we

*first/last year with positive employment
bys idplant: gegen minyear=min(extdate) if size>0
bys idplant (minyear): replace minyear=minyear[1] if minyear==.

bys idplant: gegen maxyear=max(extdate) if size>0
bys idplant (maxyear): replace maxyear=maxyear[1] if maxyear==.

drop if minyear==.

*Refine exit using info on spells
merge 1:m idplant year_mcvl using ../data_mcvl/emp_spellscont.dta, keep(1 3) keepusing(spellend_date)
bys idplant: gegen maxend = max(spellend_date)
bys idplant year_mcvl: keep if _n == 1
drop _merge spellend_date

*Drop post-closing obs
drop if year_mcvl > yofd(maxyear) + 1

*Exclude pre-entry obs
drop if year_mcvl < yofd(minyear) - 1

*Entry and exit
gen entry = yofd(creation_date)==year_mcvl

bys idplant (year_mcvl): gen exit = size==0 & year_mcvl == yofd(maxyear) + 1
replace exit = 0 if maxend>maxyear
drop maxend

*Lagged size
bys idplant (year_mcvl): gen size_lag = size[_n-1]

*Non-continuing plants
gen nocont = 1 if entry==1 | exit == 1
bys idplant (nocont): replace nocont = nocont[1] if nocont==.

*Remove inconsistencies
*Drop Ceuta and Melilla; missing creation or creation after plant is in business
drop if provinceplant>50
drop if creation_date==. 
drop if yofd(creation_date) > yofd(minyear)
drop minyear maxyear
*Major change in 2017, exclude from the cyclicality analysis
drop if year_mcvl>=2017

gunique idplant if size!=0

*Capital- and worker-owned firms
keep if socialeco==1 | socialeco==2

*Create 2-digit sector of activity variable based on CNAE09  (76 categories)
quietly do sectorhom.do
drop CNAE*
*General regime and remaining activities in primary sector
drop if regime>111
drop if (sector1d==1 | sector2d == 97)
drop regime


*Standard labor relationships
drop if type1plant>0 
drop type1plant
drop if sector1d>=13

keep year_mcvl extdate idfirm idplant provinceplant* sector1d sector2d size size_lag size_wgt entry exit creation_date socialeco  nocont 

gen month_wobs = mofd(extdate)
format month_wobs %tm

*Cooperative variable 
gen coop=1 if socialeco>=2
recode coop .=0
label var coop "Cooperative"

*log Size 
gen lnsize = ln(size)

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
merge m:1 year provinceplant using ../supdata/inedataurprov.dta, keep(match) keepusing(urate urate_lag)
drop _merge
rename urate urate_prov
rename urate_lag urate_lag_prov

label var urate_lag_prov "Unemp. rate (prov)"
label var urate_cont_prov "Unemp. rate (prov)"

foreach v in lag_prov cont_prov  { 

gen urate_`v'_coop = urate_`v'*coop

}

label var urate_lag_coop "Unemp. rate x Coop"
label var urate_lag_prov_coop "Unemp. rate x Coop (prov)"

label var urate_cont_coop "Unemp. rate x Coop"
label var urate_cont_prov_coop "Unemp. rate x Coop (prov)"

*Time vars
gen trend= year_mcvl - 2005 + 1 
gen trend2=trend*trend

xi i.year_mcvl
rename _I* *


*Province vars
xi i.provinceplant, noomit
rename _I* *

*Sector vars
xi i.sector1d, noomit
rename _I* *

xi i.age_group, noomit
rename _I* *
drop age_group age_group_2

		
	preserve
	use 
	reghdfe    lnsize urate_lag_prov  urate_lag_prov_coop                  $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, replace ctitle(Benchmark) keep(urate_lag urate_lag_coop $fixed trend trend2) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore
	
	use ../data_ready/plantpanel.dta, clear
	
	bys idplant: gegen total=total(size)
	drop if total==0
	
	reghdfe    lnsize urate_lag_prov  urate_lag_prov_coop                   $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(All) keep(urate_lag urate_lag_coop $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	drop if socialeco>2
	
	reghdfe    lnsize urate_lag_prov  urate_lag_prov_coop                   $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(All) keep(urate_lag urate_lag_coop $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	reghdfe    lnsize urate_lag_prov_coop  urate_lag_prov_coop                $fixed trend trend2 [pw=size_wgt] if nocont!=1, absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Excl. Entry\& Exit) keep(urate_lag  urate_lag_coop  $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
		

	keep idplant year_mcvl entry exit coop urate*           sector1d_3 - sector1d_12 provincep_2 - provincep_50 size_wgt
	xi i.year_mcvl, noomit
    rename _I* *
	
	reg    entry coop urate_lag_prov  urate_lag_prov_coop                  sector1d_3 - sector1d_12 provincep_2 - provincep_50 year_mcvl_2006 - year_mcvl_2016 [pw=size_wgt], cluster(idplant) 
	outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Entry) keep(coop urate_lag urate_lag_coop)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	reg    exit coop urate_lag_prov  urate_lag_prov_coop                   sector1d_3 - sector1d_12 provincep_2 - provincep_50 year_mcvl_2006 - year_mcvl_2016 [pw=size_wgt] , cluster(idplant) 
	outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Exit) keep(coop urate_lag urate_lag_coop)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	
	/*
		gen lnsize_lag = ln(size_lag)
	gen Dlnsize = lnsize - lnsize_lag
	gen Durate  = urate_cont - urate_lag
	gen Durate_coop = Durate*coop
	
 	reghdfe    Dlnsize Durate Durate_coop                $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Dlnsize) keep(Durate Durate_coop  $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
