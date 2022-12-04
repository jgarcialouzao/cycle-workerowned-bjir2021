* STATA 14
* MCVL - Wage regression analysis: Sensitivity to censoring
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat //%5.4f

log using logs\wregcens.log, replace	


*Define control variables
global wlevel "agedev2 agedev3"
global jlevel "skill_2 skill_3 temp tenure*"  /**/
global sectorFEprovFEtrend  "lnsize age_grou* provincep_2 - provincep_50 trend trend2"


	use ../Data/workerpanel_final.dta, clear
	gen year_mcvl = year_w
	
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6

	
	keep idperson idplant idfirm coop lnr* urate* age* newcomer_coop $wlevel $jlevel $sectorFEprovFEtrend provinceplant year_mcvl year_w days ptime_tv industry
	
	merge m:1 idperson idfirm year_mcvl using ../Data/taxincome20052017.dta, keep(1 3) keepusing(income_tax)
	drop _merge
	drop if year_mcvl==2017
	gen month_wobs = mofd(mdy(12,1,year_mcvl))
	fmerge m:1 month_wobs  using ../../SuppData/cpi2016m.dta, keep(match) keepusing(cpi2016)
	drop _merge
	
	replace income_tax = income_tax/(cpi2016/100)
	
	gen lnryw_tax = ln(income_tax)
	
	gen rdwft_tax = income_tax / (days*(ptime_tv/100))
	gen lnrdwft_tax = ln(rdwft_tax)
	
	

	**Regressions	
	
		*Annual earnings
	reghdfe  lnryw_sim  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, replace title("Imputed") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
		
	reghdfe  lnryw_orig  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, append title("Censored") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

	reghdfe  lnryw_tax  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, append title("Tax records") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	
	*Full-time equiv daily wages
	reghdfe  lnrdwft_sim  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, append title("Imputed") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
		
	reghdfe  lnrdwft_orig  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, append title("Censored") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

	reghdfe  lnrdwft_tax  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senstivity_w.tex, append title("Tax records") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
	




