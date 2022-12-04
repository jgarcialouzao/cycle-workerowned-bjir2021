* STATA 14
* MCVL - Unemp. rate, FEDEA Index
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13


use ../supdata/fedea_annual.dta, clear
	keep if year >= 2005 & year <=2016
	tw connect fedea year, lcolor(black) mcolor(black) graphregion(color(white)) xlabel(2005(1)2016) xtitle("Year") ytitle("Index")
	graph save ../figures/fedea.gph, replace
	
use ../supdata/ineurate.dta, clear
	keep if year >= 2005 & year <=2016
	tw connect urate year, lcolor(black) mcolor(black) graphregion(color(white)) xlabel(2005(1)2016) xtitle("Year") ytitle("Percent")
	graph save ../figures/urate.gph, replace
	

use ../supdata/inedataurprov.dta, clear
do labels/labelprovince
label values provinceplant provincelb
	keep if year >= 2005 & year <=2016
keep urate year provinceplant

	graph bar urate, over(provinceplant, sort(urate)) ylabel(0(5)30) ytitle("Percent") graphregion(color(white)) //needs some manual work
	graph save ../graphs/urateprov.gph, replace

/*
use ../supdata/fcoops_share.dta, clear
do labels/labelprovince
label values provinceplant provincelb

keep share year provinceplant

	graph bar share, over(provinceplant, sort(share))  ytitle("Percent") graphregion(color(white)) //needs some manual work
	graph save ../graphs/coopprov.gph, replace

	

	

