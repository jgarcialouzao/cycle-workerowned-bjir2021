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
	

	use ../Data/plantpanel.dta, clear


	bys idplant: gegen total=total(size)
	drop if total==0
		    
	reghdfe    lnsize urate_lag  urate_lag_coop                     $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(All) keep(urate_lag urate_lag_coop $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	reghdfe    lnsize urate_lag  urate_lag_coop                   $fixed trend trend2 [pw=size_wgt] if nocont!=1, absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Excl. Entry\& Exit) keep(urate_lag  urate_lag_coop  $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
		*/

	/*	
	*Industry 6 categories, no more dissagregate info available
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6	
	keep idplant year_mcvl entry exit coop urate*           industry provincep_2 - provincep_50 size_wgt
	xi i.year_mcvl, noomit
    rename _I* *
	
	reg    entry coop urate_lag  urate_lag_coop                     i.industry provincep_2 - provincep_50 year_mcvl_2007 - year_mcvl_2016 [pw=size_wgt], cluster(idplant) 
	*outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Entry) keep(coop urate_lag urate_lag_coop)  ///
	*addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 

	reg    exit coop urate_lag  urate_lag_coop                     i.industry provincep_2 - provincep_50 year_mcvl_2007 - year_mcvl_2016 [pw=size_wgt] , cluster(idplant) 
	*outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Exit) keep(coop urate_lag urate_lag_coop)  ///
	*addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 


/*
	gen lnsize_lag = ln(size_lag)
	gen Dlnsize = lnsize - lnsize_lag
	gen Durate  = urate_cont - urate_lag
	gen Durate_coop = Durate*coop
	gen lnsize_lag_coop = lnsize_lag*coop
	
 	reghdfe    Dlnsize Durate Durate_coop                lnsize_lag lnsize_lag_coop urate_lag urate_lag_coop $fixed trend trend2 [pw=size_wgt], absorb(idplant) cluster(idplant) keepsing
    *outreg2 using ../empreg/reglnsize_allplants.tex, append ctitle(Dlnsize) keep(Durate Durate_coop  $fixed trend trend2)  ///
	*addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
