* STATA 14
* MCVL - Employment regression analysis
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\empreg_robustime.log, replace	

global fixed                "multi age_group*"
global sectorFEprovFEyearFE "sector1d_3 - sector1d_12 year_mcvl_2007 - year_mcvl_2017"
global sectorFEprovFEtrend  "sector1d_3 - sector1d_12 trend trend2"
global sectortimeFEprovFE   "sectortim_*  provincep_2 - provincep_50"
global sectorFEprovtimeFE   "sector1d_3 - sector1d_12 provtime_*"
global sectortrendFEprovFE  "trend_s* trend2_s*  provincep_2 - provincep_50"
global sectorFEprovtrend    "sector1d_3 - sector1d_12 trend_p* trend2_p*"


*Define program to analyze employment
program define regempcyclic

	use ../Data/plantpanel_final.dta, clear
	
	keep `2' coop urate* $fixed idplant year_* sector1d* sector2d  idplant year_* provincep* trend* size_wgt
		
	keep if `2'!=.

	*Business cycle proxy
	reghdfe     `2'   urate_`3' urate_`3'_coop                         $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust1.tex, replace ctitle(National UR) keep(urate_`3' urate_`3'_coop    ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	*FEDEA INDEX - add
	merge m:1 

	reghdfe     `2' fedea_`3'  fedea_`3'_coop                            $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust1.tex, append ctitle(FEDEA Index) keep(fedea_`3'  fedea_`3'_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	*URATE PROV - add
	merge m:1 
	
	reghdfe    `2' urate_`3'_prov  urate_`3'_prov_coop                 $fixed  trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust1.tex, append ctitle(Year FE) keep(urate_`3'_prov  urate_`3'_prov_coop    ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	
	gen year = year_mcvl - 1
	
	*Industry 6 categories, no more dissagregate info available
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	merge m:1 year industry using ../Data/empratesector.dta, keep(match) keepusing(emp)
    drop _merge 
	
	replace emp = emp*100
	gen emp_coop = emp*coop
	
	reghdfe     `2' emp emp_coop                            $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust1.tex, append ctitle(Sector ER) keep(emp emp_coop) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	drop industry emp emp_coop
	
	*Industry 3 categories, no more dissagregate info available within provinces (50)
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d>=4 

	rename provinceplant province
	
	merge m:1 year province industry using ../Data/emp2pop.dta, keep(match) keepusing(emp2pop)
    drop _merge 
	
	replace emp2pop = emp2pop*100
	gen emp2pop_coop = emp2pop*coop
	
	reghdfe     `2' emp2pop  emp2pop_coop                            $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust1.tex, append ctitle(SectorxProvince ER) keep(emp2pop  emp2pop_coop) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4)
	
	drop industry emp2pop


	*Time Effects	
	drop provincep_*
    drop sector1d_*

	reghdfe     `2'   urate_`3' urate_`3'_coop                         $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, replace ctitle(National UR) keep(urate_`3' urate_`3'_coop    ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	gen trend_coop = trend*coop
	gen trend2_coop = trend2*coop
	
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed trend* trend2* [pw=size_wgt], absorb(idplant) cluster(idplant)  keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(Province trend) keep(urate_`3' urate_`3'_coop) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	drop trend_*

   preserve
   quietly{
   forvalues n = 1/50 {
   gen trend_p`n'= year_mcvl - 2005 + 1 if provinceplant==`n'
   gen trend2_p`n'=trend_p`n'*trend_p`n'
   replace trend_p`n'=0 if trend_p`n'==.
   replace trend2_p`n'=0 if trend2_p`n'==.
   }
}
qui compress
keep `2' urate_`3'  urate_`3'_coop                  $fixed trend_p* trend2_p* idplant size_wgt
   
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed trend_p* trend2_p* [pw=size_wgt], absorb(idplant) cluster(idplant)  keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(Province trend) keep(urate_`3' urate_`3'_coop) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 

	preserve
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	drop sector1d

	quietly {
	forvalues n = 2/6 {
	gen trend_s`n'= year_mcvl - 2005 + 1 if industry==`n'
	gen trend2_s`n'=trend_s`n'*trend_s`n'
	replace trend_s`n'=0 if trend_s`n'==.
	replace trend2_s`n'=0 if trend2_s`n'==.
	}
}
qui compress
    keep `2' urate_`3'  urate_`3'_coop                     $fixed trend_s* trend2_s*  idplant size_wgt
	reghdfe     `2' urate_`3'  urate_`3'_coop                     $fixed trend_s* trend2_s* [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(Sector Trend) keep(urate_`3' urate_`3'_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 

	preserve
		gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	drop sector1d
	
	do provtoreg.do
	drop provinceplant

	quietly{
	forvalues n = 1/17 {
	forvalues s = 2/6 {
   gen trend_p`n's`s'= year_mcvl - 2005 + 1 if regionplant==`n' & industry==`s'
   gen trend2_p`n's`s'=trend_p`n's`s'*trend_p`n's`s'
   replace trend_p`n's`s'=0 if trend_p`n's`s'==.
   replace trend2_p`n's`s'=0 if trend2_p`n's`s'==.
   }
}
}
qui compress
	
	set emptycells drop
	set matsize 10000
	keep `2' urate_`3'  urate_`3'_coop                     $fixed trend_p* trend2_p* idplant size_wgt
	areg     `2' urate_`3'  urate_`3'_coop                     $fixed trend_p* trend2_p* [pw=size_wgt], absorb(idplant) cluster(idplant) 
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(SectorxProvince Trend) keep(urate_`3' urate_`3'_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 
	
	drop year_mcvl_*

	preserve
	do provtoreg.do
	quietly{
   forvalues n = 1/17 {
   forvalues y = 2005/2016 {
   gen PYFE`n'`y'= regionplant==`n' & year_mcvl == `y'
   }
   }
}
qui compress
	set emptycells drop
	set matsize 10000
	keep `2' urate_`3'  urate_`3'_coop                  $fixed PYFE* idplant size_wgt
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed  PYFE* [pw=size_wgt], absorb(idplant) cluster(idplant)  keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(ProvincexYear FE) keep(urate_`3' urate_`3'_coop) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 

	preserve
	*Use industry, no enough variation within sectorxyear pairs	
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	quietly {
	forvalues n = 2/6 {
	 forvalues y = 2006/2016 {
	gen SYFE`n'`y'= industry==`n' & year_mcvl == `y'
}
	}
}
qui compress
	keep `2' urate_`3'  urate_`3'_coop                  $fixed SYFE* idplant size_wgt
	set emptycells drop
	set matsize 10000
	reghdfe     `2' urate_`3'  urate_`3'_coop                     $fixed SYFE* [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(SectorxYear FE) keep(urate_`3' urate_`3'_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 
*/
	preserve
	*Use industry, no enough variation within sectorxregion-year pairs
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	drop sector1d
	do provtoreg.do

	quietly{
	forvalues n = 1/17 {
	forvalues s = 2/6 {
	forvalues y = 2006/2016 {
   gen PSYFE`n'`s'`y'= regionplant==`n' & industry==`s'  & year_mcvl == `y'

   }
}
}
}	
qui compress
keep `2' urate_`3'  urate_`3'_coop                     $fixed PSYFE* idplant size_wgt
	set emptycells drop
	set matsize 10000
	areg     `2' urate_`3'  urate_`3'_coop                     $fixed PSYFE* [pw=size_wgt], absorb(idplant) cluster(idplant) 
	outreg2 using ../Rawtables/`1'_robust2.tex, append ctitle(SectorxProvincexYear FE) keep(urate_`3' urate_`3'_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 

end

/*
	1: specification features
	2: analysis sample
	3: dep. variable
	4: unemployment rate
	5: time specification
*/

foreach ur in lag {

regempcyclic "reglnsize_ur`ur'" "lnsize" "`ur'" 

}
