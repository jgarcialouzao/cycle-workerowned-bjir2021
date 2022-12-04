* STATA 14
* MCVL - Employment descriptives
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

	use ../data_ready/plantpanel.dta, clear

	keep year_mcvl idplant empgrowth entry exit lnsize_ch size age urate_growth urate_growth_prov urate_ch urate_ch_prov coop soceco_wide

	*Summary statistics
	unique idplant if size!=0
	
	keep if soceco_wide==11 | soceco_wide==21			
	
	unique idplant if size!=0

	tw (hist empgrowth if coop==0, bcolor(gray) lwidth(none) bin(48) percent) (hist empgrowth if coop==1, color(none) lwidth(  medthick ) lpattern(solid) lcolor(black) bin(48) percent), ///
	xlabel(-2(.25)2, angle(45)) xtitle("Net employment growth") legend(label(1 "Capitalist") label(2 "Cooperative"))  graphregion(color(white))
	graph save ../figures/DHSgrowth.gph,  replace
	
	preserve
	keep empgrowth lnsize_ch year_mcvl coop size
	
	*Lagged size
    bys idplant (year_mcvl): gen size_lag = size[_n-1]
	
	gen empgrowth = (size - size_lag)/size_lag

	gcollapse (mean) netempgrowth lnsize_ch size, by(year_mcvl coop)
	
	tw (connect netempgrowth year if coop==0, lcolor(black) mcolor(black))   (connect netempgrowth year if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2006(1)2017) xtitle("Year") ytitle("Net employment growth") ylabel(-0.15(0.05)0.1) legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/netempgrowth_yearly.gph, replace

	
	tw (connect empgrowth year if coop==0, lcolor(black) mcolor(black))   (connect empgrowth year if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2006(1)2017) xtitle("Year") ytitle("Net employment growth") ylabel(-0.15(0.05)0.1) legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/empgrowth_yearly.gph, replace
	
		tw (connect lnsize_ch year if coop==0, lcolor(black) mcolor(black))   (connect lnsize_ch year if coop==1, msymbol(square) mcolor(gray) lcolor(gray) lpattern(dash) ), ///
	xlabel(2006(1)2017) xtitle("Year") ytitle("ln(size) - ln(size_lag)") ylabel(-0.15(0.05)0.1) legend(lab(1 "Capitalist") lab(2 "Cooperative")) graphregion(color(white))
	graph save ../figures/lnsizech_yearly.gph, replace

	restore
	
	*K-firms vs Coops
	preserve
	keep if empgrowth!=.
	estpost tabstat size age empgrowth entry exit urate_growth*  if coop==0, statistics(mean sd) columns(statistics) listwise
	est store Kall
	estpost tabstat size age empgrowth entry exit urate_growth* if coop==1, statistics(mean sd) columns(statistics) listwise
	est store Coopall
	esttab Kall Coopall  using ../empreg/descriptives_kvc_DHS.tex, replace cells("mean(fmt(a3)) sd") label booktabs nonum gaps f 
	restore

		*K-firms vs Coops
	preserve
	keep if lnsize_ch!=.
	estpost tabstat size age lnsize_ch urate_ch*  if coop==0, statistics(mean sd) columns(statistics) listwise
	est store Kall
	estpost tabstat size age lnsize_ch urate_ch*  if coop==1, statistics(mean sd) columns(statistics) listwise
	est store Coopall
	esttab Kall Coopall  using ../empreg/descriptives_kvc_lnsizech.tex, replace cells("mean(fmt(a3)) sd") label booktabs nonum gaps f 
    restore
	
	
