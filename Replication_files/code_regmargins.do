* STATA 14
* MCVL - Marginsregression analysis
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat //%5.4f

log using logs\margins.log, replace	

timer clear 1
timer on 1	
*Define control variables
global wlevel "agedev2 agedev3 female spanish educ_2 educ_3 "
global jlevel "skill_2 skill_3 temp tenure*"  /**/
global sectorFEprovFEtrend  "lnsize multi age_grou* provincep_2 - provincep_50 trend trend2"

*Define program to analyze wages
*program define regwcyclic

	use ../Data/workerpanel_final.dta, clear
	
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6
	
	keep idperson idplant coop lnryw_sim lnrdwft_sim lnptime lndays urate* age* newcomer_coop $wlevel $jlevel $sectorFEprovFEtrend provinceplant industry year_w
	/*
	**Regressions
	reghdfe lnryw_sim coop urate_lag urate_lag_coop                agedev2 agedev3 $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins.tex, replace title("`Annual earnings'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnrdwft_sim coop urate_lag urate_lag_coop                 agedev2 agedev3 $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins.tex, append title("`Ft-equiv. daily wages'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnptime coop urate_lag urate_lag_coop                  agedev2 agedev3 $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins.tex, append title("`Hours'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lndays  coop urate_lag urate_lag_coop                  agedev2 agedev3 $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins.tex, append title("`Days'") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	*/
	
	reghdfe lnryw_sim coop urate_lag urate_lag_coop                agedev2 agedev3 $jlevel provincep_2 - provincep_50 i.year_w i.industry trend*,, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins_yfe.tex, replace title("`Annual earnings'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnrdwft_sim coop urate_lag urate_lag_coop                 agedev2 agedev3 $jlevel provincep_2 - provincep_50 i.year_w  i.industry trend*,, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins_yfe.tex, append title("`Ft-equiv. daily wages'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lnptime coop urate_lag urate_lag_coop                  agedev2 agedev3 $jlevel provincep_2 - provincep_50 i.year_w  i.industry trend*,, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins_yfe.tex, append title("`Hours'") ///
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	reghdfe lndays  coop urate_lag urate_lag_coop                  agedev2 agedev3 $jlevel provincep_2 - provincep_50 i.year_w  i.industry trend*, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/margins_yfe.tex, append title("`Days'") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
*end

/*
1: speficiation features
2: analysis sample: wage earners 
3: dep. variable
4: unemployment rate 
5: time specification
*/

timer off 1
timer list 1

/*
foreach dep in rdwft_sim ryw_sim {
foreach ur in lag {

	regwcyclic "wearners`dep'_ur`ur'_`time'_period`p'" "ln`dep'" "`ur'" 

	}
}

