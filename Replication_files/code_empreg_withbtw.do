* STATA 14
* MCVL - Employment regression analysis - within/between
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f


global fixed                "multi age_group*"
global sectorFEprovFEtrend  "sector1d_3 - sector1d_12 provincep_2 - provincep_50 trend trend2"

*Define program to analyze employment
	use ../Data/plantpanel_final_wpartners.dta, clear
		
	keep lnsize coop urate*  $fixed idplant idfirm year_mcvl provinceplant size* sector1d provincep_2 - provincep_50 trend* type1plant
			
	keep if lnsize!=.
	
	*Industry 6 categories, no more dissagregate info available
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	*Regressions
	replace coop = . if type1plant==930
	replace urate_lag_coop = . if coop==.
	
	reghdfe    lnsize coop urate_lag  urate_lag_coop                  $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/benchmodel_emp_withbtw.tex, replace ctitle(Benchmark) keep(coop urate_lag  urate_lag_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	replace coop = 1 if type1plant==930
	replace urate_lag_coop = urate_lag*coop if coop==1
	
	reghdfe    lnsize coop urate_lag  urate_lag_coop                  $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/benchmodel_emp_withbtw.tex, append ctitle(Pooled) keep(coop urate_lag  urate_lag_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
		
	preserve
	drop if coop==1 & type1plant==0
	
	reghdfe    lnsize coop urate_lag  urate_lag_coop                  $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/benchmodel_emp_withbtw.tex, append ctitle(Between) keep(coop urate_lag  urate_lag_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	restore 
	
	preserve
	drop if coop == 0
	gen we = type1plant==0
	gen urate_lag_we = urate_lag*we
	
	reghdfe    lnsize we urate_lag  urate_lag_we                 $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/benchmodel_emp_withbtw.tex, append ctitle(Within) keep(coop urate_lag  urate_lag_we ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
restore
