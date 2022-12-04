* STATA 14
* MCVL - Employment regression analysis
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\empreg.log, replace	

global fixed                "multi age_group*"
global sectorFEprovFEtrend  "sector1d_3 - sector1d_12 provincep_2 - provincep_50 trend trend2"

*Define program to analyze employment
	use ../Data/plantpanel_final.dta, clear
		
	keep lnsize coop urate*  $fixed idplant year_mcvl provinceplant size* sector1d provincep_2 - provincep_50 trend*
			
	keep if lnsize!=.
	
	*Industry 6 categories, no more dissagregate info available
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	*Regressions
	regress lnsize coop urate_lag  urate_lag_coop                  $fixed i.industry provincep_* trend trend2 [pw=size_wgt] , cluster(idplant) 
	outreg2 using ../Rawtables/benchmodel_emp.tex, replace ctitle(OLS) keep(coop urate_lag  urate_lag_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, No) label dec(4) 

	reghdfe    lnsize coop urate_lag  urate_lag_coop                  $fixed trend trend2 [pw=size_wgt] , absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/benchmodel_emp.tex, append ctitle(Within) keep(coop urate_lag  urate_lag_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	egen long id = group(idplant)
	xtset id year_mcvl
	gen lnsize_coop = lnsize*coop
	
	xtabond2 lnsize urate_cont urate_cont_coop l.lnsize l.lnsize_coop multi age_* trend trend2 [pw=size_wgt], gmm(l.lnsize l.lnsize_coop)  nodiffsargan nomata
    outreg2 using ../Rawtables/benchmodel_emp.tex, append ctitle(Dynamic) keep(coop urate_cont  urate_cont_coop ) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	*Expansion vs recession
	gen recession = year_mcvl >= 2008 & year_mcvl <= 2013
	
	reghdfe    `2' coop urate_`3'  urate_`3'_coop                     $fixed [pw=size_wgt] if recession==1, absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/benchmodel_emp.tex, append ctitle(Recession) keep(coop urate_`3' urate_`3'_coop $fixed trend trend2) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

    reghdfe    `2' coop urate_`3'  urate_`3'_coop                     $fixed [pw=size_wgt] if recession==0, absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/benchmodel_emp.tex, append ctitle(Expansion) keep(coop urate_`3' urate_`3'_coop $fixed trend trend2) ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 


