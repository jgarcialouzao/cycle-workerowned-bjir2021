* STATA 14
* MCVL - Sample selection for the analysis of employment growth
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13


log using logs\plantpanel.log, replace	

*Goal: select plants to create a panel 
use ../mcvl_stata/fpanel.dta, clear

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

/*
gen soceco_wide=11 if kfirm_we==1
replace soceco_wide=21 if coop_worker_we==1
replace soceco_wide=22 if coop_partner_we==1
replace soceco_wide=31 if ls_worker_we==1
replace soceco_wide=32 if ls_partner_we==1
replace soceco_wide=41 if soleprop_we==1
label define socecolb 11 "Cap. firm (we)"  21 "Coop. (we) employee" 22 "Coop. (we) partner"  ///
					  31 "Labor soc. (we) employee" 32 "Labor.soc (we) partner" 41 "Sole prop.", modify
label values soceco_wide socecolb
*/

drop coop_we coop_worker_we coop_partner_we ls_we ls_worker_we ls_partner_we kfirm_we //soleprop_we

*first/last year with positive employment
bys idplant: gegen minyear=min(extdate) if size>0
bys idplant (minyear): replace minyear=minyear[1] if minyear==.

bys idplant: gegen maxyear=max(extdate) if size>0
bys idplant (maxyear): replace maxyear=maxyear[1] if maxyear==.

drop if minyear==.

*Refine exit using info on spells
merge 1:m idplant year_mcvl using ../mcvl_stata/contempspells.dta, keep(1 3) keepusing(spellend_date)
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

gunique idplant if size!=0 

*Multi-establishment firms
bys idfirm year_mcvl: gen nobs = _N
gen multi = 1 if nobs>1
recode multi .=0
drop nobs

save ../Data/plantpanel_initial.dta, replace

log close


