* STATA 14
* MCVL - Tax records
* Jose Garcia-Louzao

clear all
capture log close
capture program drop _all
set more 1
set seed 13



use ../mcvl_stata/MCVL_taxdata.dta, clear


*Keep relevant variables
keep year_mcvl idperson idfirm monetary_pay

gcollapse (sum) monetary_pay, by(idperson idfirm year_mcvl)


rename monetary_pay income_tax

save ../Data/taxincome20052017.dta, replace
