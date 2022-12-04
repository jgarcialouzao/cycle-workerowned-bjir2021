* STATA 14
* MCVL - Employment regression analysis
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13
set cformat %5.4f

log using logs\empreg_subgr.log, replace	


global fixed                "multi age_group*"
global sectorFEprovFEtrend  "trend trend2"

*Define program to analyze employment
program define regempcyclic

	use ../Data/plantpanel_final.dta, clear
	
	keep `2' coop urate* fedea* $fixed $sectorFEprovFEtrend   idplant idfirm size* year_* provinceplant* sector1d age nocont
	

	*Regressions		
	reghdfe    `2' urate_`3'  urate_`3'_coop                 $fixed trend trend2 [pw=size_wgt] if nocont!=1, absorb(idplant) cluster(idplant) keepsing
    outreg2 using ../Rawtables/`1'_subgr.tex, replace ctitle(Excl. Entry \& Exit) keep(urate_lag  urate_lag_coop  $fixed trend trend2)  ///
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4)
	
	gen flag = 1 if multi==0
	bys idfirm (flag): replace flag = flag[1] if flag==.
	
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed $sectorFEprovFEtrend [pw=size_wgt] if flag == 1 , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_subgr.tex, append ctitle(Single unit firm) keep(urate_`3'  urate_`3'_coop   $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
drop flag

gen bigcity= 1 if provinceplant==8 | provinceplant==28 | provinceplant==41 | provinceplant==46
recode bigcity .=0
	reghdfe     `2' urate_`3' urate_`3'_coop                  $fixed $sectorFEprovFEtrend [pw=size_wgt] if bigcity==1  , absorb(idplant) cluster(idplant) keepsing //provinceplant!=1 & provinceplant!=20 & provinceplant!=48 & provinceplant!=31 
	outreg2 using ../Rawtables/`1'_subgr.tex, append ctitle(Excl. Basque Country \& Navarra) keep(urate_`3'  urate_`3'_coop   $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	
	reghdfe     `2' urate_`3' urate_`3'_coop                  $fixed $sectorFEprovFEtrend [pw=size_wgt] if sector1d!=3  , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_subgr.tex, append ctitle(Excl. construction) keep(urate_`3'  urate_`3'_coop   $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	
	gen flag = 1 if size>50
	bys idplant (flag): replace flag = flag[1] if flag==.
	
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed $sectorFEprovFEtrend [pw=size_wgt] if flag == 1 , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_subgr.tex, append ctitle(Firms' size + 50) keep(urate_`3'  urate_`3'_coop   $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	drop flag
	
	gen flag = 1 if age>5
	bys idplant (flag): replace flag = flag[1] if flag==.
	
	reghdfe     `2' urate_`3'  urate_`3'_coop                  $fixed $sectorFEprovFEtrend [pw=size_wgt] if flag == 1 , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../Rawtables/`1'_subgr.tex, append ctitle(Firms' age + 10) keep(urate_`3'  urate_`3'_coop   $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4) 
	drop flag

 
 /*
 	reghdfe     `2' urate_`3' urate_`3'_coop                  $fixed $sectorFEprovFEtrend if year_mcvl>=2007  , absorb(idplant) cluster(idplant) keepsing
	outreg2 using ../empreg/`1'_robust2.tex, append ctitle(Excl. Basque Country & Navarra) keep(urate_`3'_prov  urate_`3'_prov_coop  $fixed $sectorFEprovFEtrend ) /// 
	addtext(No. Plants, No., Sector FE, Yes, Region  FE, No, Plant FE, Yes) label dec(4)
*/				
end

foreach ur in lag {

regempcyclic "reglnsize_ur`ur'" "lnsize" "`ur'" 

}

