*STATA 14
*Cell-by-cell Tobit Model - based on Card et al (2013)
*Jose Garcia-Louzao

capture program drop _all
set more 1
set seed 13

log using logs\celltobit.log, replace	


program define celltobit 
	forvalues s=1/3 {
	forvalues a=1/4 {

	tobit lnrdailyw age female fixedterm ftime meanw_noT meanmaxcs_noT oneobs size_50 size size2 /*month_2 - month_12*/ if year_w==`1' & skill_group==`s' & age_group==`a',  ul(`2')
	predict xb`1'skill`s'age`a',  xb
	gen se`1'skill`s'age`a'=_b[/sigma]

	replace xb=xb`1'skill`s'age`a' 	 if year_w==`1'  &  skill_group==`s' & age_group==`a'
	replace se=se`1'skill`s'age`a'   if year_w==`1'  &  skill_group==`s' & age_group==`a'

	drop xb`1'skill`s'age`a' se`1'skill`s'age`a'
	
	}
	}
end

/*
1: t: year
2: max cap (log)
*/

	**Correct censoring
timer clear 2
timer on 2	

use ../data_ready/workerpanel_monthly_short.dta, clear

	*Gen log real daily wage
	gen lnrdailyw = round(ln(rdailyw), .00001)
	gen maxcap	  = round(ln(rdailymaxk), .00001)
	
	gen year_w = yofd(dofm(month_wobs))

	*Keep variables needed to estimate Tobit models
	keep month_wobs year_w idperson lnrdailyw maxcens maxcap age female ptime skill contract size*

	*Create age_groups
	gen age_group=.
	replace age_group=1 if age<=29
	replace age_group=2 if age>=30 & age<=39
	replace age_group=3 if age>=40 & age<=49
	replace age_group=4 if age>=50
	
	*Skill groups
	gen skill_group = .
	replace skill_group = 1 if skill_tv>=8
	replace skill_group = 2 if skill_tv  == 4 | skill_tv  == 5 | skill_tv  == 6 | skill_tv ==7
	replace skill_group = 3 if skill_tv  == 1 | skill_tv  == 2 | skill_tv  == 3
	drop skill_tv 
	
    *Fixed-term contract - fijos discontinuous treated as fixed-term due to intermitent nature
    gen fixedterm = 1 if contract>=300
	recode fixedterm .=0
	drop contract
	
	*Part-time coeff
	gen ftime = 1 if ptime==100
	recode ftime .=0
	drop ptime
	
	*Size effects
	gen size2=size^2
	gen size_50 = 1 if size>=50
	recode size_50 .=0	
	
	** For each individual construct individual specific components for the Tobit regressions - following Card, Heining and Kline (2013)
	bys idperson: gegen nobs=count(month_wobs)
	gen oneobs = 1 if nobs==1
	recode oneobs .=0
	
	*Generate average individual wage in other periods except the censored	
	bys idperson: gegen meanw=mean(lnrdailyw)	
	gen meanw_noT=(meanw - lnrdailyw/nobs)*nobs/(nobs-1)
	gegen meanpop=mean(lnrdailyw)	
	replace meanw_noT=meanpop if oneobs==1
	drop meanpop
	
	*Generate fraction of other month-year that the individual's wage is max censored
	bys idperson: gegen meanmaxcens=mean(maxcens)
	gen meanmaxcs_noT=(meanmaxcens - maxcens/nobs)*nobs/(nobs-1)
	gegen meanpop=mean(maxcens)
	replace meanmaxcs_noT = meanpop if oneobs==1
	drop meanpop
	
	*Gen month dummies
	*gen month=month(dofm(month_wobs))
	*xi i.month
	*rename _I* *
	
	keep month_wobs idperson lnrdailyw age female fixedterm ftime meanw_noT meanmaxcs_noT oneobs size_50 size size2 year_w age_group skill_group maxcap maxcens month*
	
	gen xb=.
	gen se=.
	
	**Run tobit models
	*do ../code_w/celltobit.do
	*celltobit  year maxcap
	celltobit   2005 4.72098
	celltobit   2006 4.71595
	celltobit   2007 4.72185
	celltobit   2008 4.70762
	celltobit   2009 4.74000 
	celltobit   2010 4.73217
	celltobit   2011 4.71069
	celltobit   2012 4.69650
	celltobit   2013 4.73133
	celltobit   2014 4.78164
	celltobit   2015 4.78915
	celltobit   2016 4.79909
	celltobit   2017 4.82863
	
	*Impute censored observations	
 	gen k = ( maxcap - xb )/se
	gen k_norm = normal(k)
	set seed 13
	gen u = runiform()
	
	gen     e = invnormal( k_norm + u*(1 - k_norm) ) if k_norm<.9999
	*few observations have k_norm==1 => e_max  is non-defined, i.e. missing value generated
	*assing 3.71902. Value of invnormal(.9999) following Card et al. (2013)
	replace e = 3.71902  if  k_norm>=.9999
	
	gen     lnrdailyw_sim = .
	replace lnrdailyw_sim = xb + se*e     if maxcens==1
	replace lnrdailyw_sim = lnrdailyw     if maxcens==0
	
	timer off 2
	timer list 2
	
	
	keep idperson month_wobs lnrdailyw*
	  
	save ../data_ready/lnrdailywcorr.dta, replace

	
log close
