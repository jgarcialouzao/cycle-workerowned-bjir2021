* STATA 14
* MCVL - Newcomer cycliclicality
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat //%5.4f

log using logs\worktimeregall.log, replace	

timer clear 1
timer on 1	
*Define control variables
global wlevel "agedev2 agedev3 female spanish educ_2 educ_3"
global jlevel "skill_2 skill_3 temp tenure*"  /**/
global sectorFEprovFEtrend  "lnsize multi age_grou* provincep_2 - provincep_50 trend trend2"
global periodall                  "year_mcvl>=2005 & year_mcvl<=2017"

*Define program to analyze days of work
	use ../Data/workerpanel_final.dta, clear
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	keep idperson idplant coop `2' urate* age* newcomer* $wlevel $jlevel $sectorFEprovFEtrend provinceplant ln* industry
	
	**Regressions
	
	*Worker fixed-effects
	reghdfe lnryw_sim coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                 agedev2 agedev3 newcomer*  $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/newcomer.tex, replace title("Annual earnings") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnrdwft_sim coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                  agedev2 agedev3 newcomer* $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/newcomer.tex, append title("Ft-equiv. daily wages") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnptime coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                   agedev2 agedev3 newcomer* $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/newcomer.tex, append title("Hours") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lndays coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                   agedev2 agedev3 newcomer* $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/newcomer.tex, append title("Days") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	
	/*
	*Plant fixed effects
	reghdfe lnryw_sim coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                 agedev2 agedev3  $jlevel $sectorFEprovFEtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../daysreg/newcomer_pfe.tex, replace title("Annual earnings") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, No, Plant FE, Yes) label dec(4)
	
	reghdfe lnrdwft_sim coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                  agedev2 agedev3  $jlevel $sectorFEprovFEtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../daysreg/newcomer_pfe.tex, append title("Ft-equiv. daily wages") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, No, Plant FE, Yes) label dec(4)
	
	
	reghdfe lnptime coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                   agedev2 agedev3  $jlevel $sectorFEprovFEtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../daysreg/newcomer_pfe.tex, append title("Hours") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, No, Plant FE, Yes) label dec(4)
	
	reghdfe lndays coop urate_lag urate_lag_nc  urate_lag_coop urate_lag_coopnc                   agedev2 agedev3  $jlevel $sectorFEprovFEtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../daysreg/newcomer_pfe.tex, append title("Days") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, No, Plant FE, Yes) label dec(4)
		*/	
	/*
	di "----------------------------"
	di "Testing cyclicality differences between K and Coops"
	test urate_`4'==(coop + urate_`4'_coop)
	di "----------------------------"
	*/






