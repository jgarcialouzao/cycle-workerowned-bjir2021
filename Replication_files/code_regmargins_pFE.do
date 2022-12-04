* STATA 14
* MCVL - Working-time regression sensitivity to dep variable
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\bench_pFE.log, replace	


*Define control variables
global wlevel "agedev2 agedev3 female spanish educ_2 educ_3"
global jlevel "skill_2 skill_3 temp tenure tenure2"  /**/
global firmtrend  "lnsize age_grou* trend trend2"


	use ../Data/workerpanel_final.dta, clear

keep idplant idperson coop urate_lag urate_lag_coop   $wlevel $jlevel $sectorFEprovFEtrend ln*


reghdfe  lnryw_sim  coop urate_lag urate_lag_coop                    $wlevel $jlevel $firmtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../reg/plantfe.tex, replace title("Annual earnings") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

	
reghdfe  lnrdwft_sim  coop urate_lag urate_lag_coop                    $wlevel $jlevel $firmtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../reg/plantfe.tex, append title("Ft-equiv. daily wages") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

	
reghdfe  lnptime  coop urate_lag urate_lag_coop                    $wlevel $jlevel $firmtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../reg/plantfe.tex, append title("Hours") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

	
reghdfe  lndays  coop urate_lag urate_lag_coop                    $wlevel $jlevel $firmtrend, cluster(idplant) absorb(idplant) keepsing
	outreg2 using ../reg/plantfe.tex, append title("Days") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
