* STATA 14
* MCVL - Employment descriptives
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\stats_wrk.log, replace	


	*Worker statistics
	use ../data_ready/workerpanel_final.dta, clear
		
	gunique idperson if coop==0
	gunique idperson if coop==1
	
	keep idperson year_w coop ryearw_sim rdailywft_sim lnryw_sim  lnrdwft_sim days ptime_tv  nojob  lnptime lndays age female spanish educ_2 educ_3 tenure seniority  newcomer* temp skill_2 skill_3

	gen fyear = days==360
	gen ftime = (ptime_tv==100)

	
	gen ftdays = ((ptime_tv/100)*days)
	
	*Summary statistics	
	preserve
	
	gcollapse (mean) rdailywft_sim ryearw_sim days ptime_tv ftime fyear nojobs ftdays temp newcomer_job, by(year_w coop)

	tw (connect ryearw year_w if coop==0, lcolor(black) mcolor(black))   (connect ryearw year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Euros") legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/ryearw.gph, replace
	
	tw (connect rdailywft  year_w if coop==0, lcolor(black) mcolor(black))   (connect rdailywft  year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Euros") legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/rdwft.gph, replace

	tw (connect ptime_tv year_w if coop==0, lcolor(black) mcolor(black))   (connect ptime_tv year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Percentage of hours")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/year_ptime_avg.gph, replace
	
	tw (connect days year_w if coop==0, lcolor(black) mcolor(black))   (connect days year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Days") legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/year_days.gph, replace
	
	replace ftime = ftime*100
	replace fyear = fyear*100
	replace temp = temp*100
	replace newcomer = newcomer*100
	
	tw (connect ftime year_w if coop==0, lcolor(black) mcolor(black))   (connect ftime year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Percent")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/ftime.gph, replace
	
	tw (connect fyear year_w if coop==0, lcolor(black) mcolor(black))   (connect ftime year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Percent")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/fyear.gph, replace

	tw (connect temp year_w if coop==0, lcolor(black) mcolor(black))   (connect temp year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Percent")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/tempcontract.gph, replace
	
	tw (connect newcomer_job year_w if coop==0, lcolor(black) mcolor(black))   (connect newcomer_job year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Percent")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/newcomer_job.gph, replace
		
	tw (connect ftdays year_w if coop==0, lcolor(black) mcolor(black))   (connect ftdays year_w if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2005(1)2016) xtitle("Year") ytitle("Full-time days")  legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/ftdays.gph, replace





	restore
	

	
	

	estpost tabstat lnryw_sim  lnrdwft_sim lnptime lndays age female spanish educ_2   educ_3  tenure  temp skill_2 skill_3 if coop==0, statistics(mean sd) columns(statistics) listwise
	est store Kall
	estpost tabstat lnryw_sim  lnrdwft_sim lnptime lndays age female  spanish educ_2  educ_3  tenure  temp skill_2 skill_3 if coop==1, statistics(mean sd) columns(statistics) listwise
	est store Coopall
	esttab Kall Coopall  using ../desc/worker_descriptives_kvc.tex, replace cells("mean(fmt(a3)) sd") label booktabs nonum gaps f 


log close
