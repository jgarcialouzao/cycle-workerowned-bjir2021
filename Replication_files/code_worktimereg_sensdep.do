* STATA 14
* MCVL - Working-time regression sensitivity to dep variable
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\worktimeregsens.log, replace	


*Define control variables
global wlevel "agedev2 agedev3"
global jlevel "skill_2 skill_3 temp tenure tenure2"  /**/
global sectorFEprovFEtrend  "lnsize age_grou* provincep_2 - provincep_50 trend trend2"


	use ../Data/workerpanel_final.dta, clear
	
	gen industry = 1     if sector1d==2
	replace industry = 2 if sector1d==3
	replace industry = 3 if sector1d==4 
	replace industry = 4 if sector1d==5 
	replace industry = 5 if sector1d==6
	replace industry = 6 if sector1d>6

keep idplant idperson coop urate_lag urate_lag_coop   $wlevel $jlevel $sectorFEprovFEtrend days ptime_tv nojob industry

*Full-year
gen fyear = days==360
label var fyear "Worked full year"

*Full-time
gen ftime = (ptime_tv==100)
label var ftime "Full-time job"

gen ftdays = ((ptime_tv/100)*days)
gen lndaysft= ln(ftdays)


reghdfe  ftime  coop urate_lag urate_lag_coop                    $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senswrktime.tex, replace title("Full-time") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

reghdfe  fyear  coop urate_lag urate_lag_coop                    $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senswrktime.tex, append title("Full-year") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)

reghdfe  lndaysft  coop urate_lag urate_lag_coop                $wlevel $jlevel $sectorFEprovFEtrend i.industry, cluster(idplant) absorb(idperson) keepsing
	outreg2 using ../Rawtables/senswrktime.tex, append title("(ln) Full-time days") ///	
	addtext(No. Individuals, N, Worker controls, Yes, Sector FE, Yes, Province FE, Yes, Worker FE, Yes) label dec(4)
