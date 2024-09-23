* Various data checks for revision

clear all
set more off
do globals

global figfmt png
global wgt [aweight=lweight] 	



********************************************************
** Document evolution sample size by panel and over time
 
clear all
 
foreach pan of numlist 1996 2001 2004 2008 { 
	append using ${root}/`pan'/dta/spellspan`pan'_monthly, keep(panel mdate wave)
}

collapse (count) nobs=wave, by(panel mdate) 
sort panel mdate
xtset panel mdate

label define sipp_panel 1996 "1996" 2001 "2001" 2004 "2004" 2008 "2008"
label values panel sipp_panel

xtline nobs, ///
	overlay ///
	xtitle("") ///
	ytitle("Number of working-age individuals in sample") ///
	tlabel(,format(%tmCY)) ///
	legend(subtitle(Panel))
	
graph export ../plots/panel_observations.${figfmt}, replace


****************
** Hours missing 

foreach pan of numlist 1996 2001 2004 2008 {

use tpmsum? ejbhrs? tbmsum? ehrsbs? using ${root}/`pan'/dta/core_`pan', clear

di _newline(2)
di "=========================="
di "`pan' Panel:"
di "=========================="

qui{

* Job 1
noi di _newline
noi di "Job 1"
gen _validhours = ejbhrs1>0 | ejbhrs1==-8
gen _hours_cat = ""

replace _hours_cat = "Missing" if ejbhrs1==-1
replace _hours_cat = "Vary" if ejbhrs1==-8
replace _hours_cat = "Number" if ejbhrs1>0 & !missing(ejbhrs1)

noi tab _hours_cat if _validhours==1

drop _*

* Job 2
noi di _newline
noi di "Job 2"
gen _validhours = ejbhrs2>0 | ejbhrs2==-8
gen _hours_cat = ""

replace _hours_cat = "Missing" if ejbhrs2==-1
replace _hours_cat = "Vary" if ejbhrs2==-8
replace _hours_cat = "Number" if ejbhrs2>0 & !missing(ejbhrs2)

noi tab _hours_cat if _validhours==1

drop _*

* Business 1
noi di _newline
noi di "Business 1"
gen _validearn = tbmsum1>0
gen _validhours = ehrsbs1>0 | ehrsbs1==-8
gen _hours_cat = ""

replace _hours_cat = "Missing" if ehrsbs1==-1
replace _hours_cat = "Vary" if ehrsbs1==-8
replace _hours_cat = "Number" if ehrsbs1>0 & !missing(ehrsbs1)

noi tab _hours_cat if _validhours==1

drop _*

* Business 2
noi di _newline
noi di "Business 2"
gen _validearn = tbmsum2>0
gen _validhours = ehrsbs2>0 | ehrsbs2==-8
gen _hours_cat = ""

replace _hours_cat = "Missing" if ehrsbs2==-1
replace _hours_cat = "Vary" if ehrsbs2==-8
replace _hours_cat = "Number" if ehrsbs2>0 & !missing(ehrsbs2)

noi tab _hours_cat if _validhours==1

drop _*

}
}

************************************************
** Assignment of main labor form: paid- or self-


** Whole sample of weekly spells

foreach pan of numlist 1996 2001 2004 2008 {

use lgtkey bweek week pep sep both ernpep ernsep using ${root}/`pan'/dta/spellspan`pan'_weekly, clear
keep if pep==1 | sep==1

gen panel = `pan'
replace both = 0 if both==.

save ${root}/temp/_`pan', replace

}

drop _all
foreach pan of numlist 1996 2001 2004 2008 {
	
append using ${root}/temp/_`pan'
rm ${root}/temp/_`pan'.dta

}

* Stats for whole sample
tab both
tab panel both, row

* Stats for sample with some self-employment
bys panel lgtkey: egen selfsample = max(sep==1 | both==1)
keep if selfsample==1

tab both
tab panel both, row

* Earnings in overlapping spells
bys panel lgtkey (bweek): gen _start_both = 1 if both==1 & both[_n-1]==0
keep if _start_both==1

replace ernpep = 0 if ernpep<0
replace ernsep = 0 if ernsep<0

gen ernprop = .
replace ernprop = ernpep/(ernpep + ernsep) if pep==1
replace ernprop = ernsep/(ernpep + ernsep) if sep==1

gen lfstat = ""
count if pep==1
replace lfstat = "Paid-emp. (`r(N)' overlapping spells)" if pep==1 & ernprop!=.
count if sep==1
replace lfstat = "Self-emp. (`r(N)' overlapping spells)" if sep==1 & ernprop!=.

hist ernprop if ernpep>0 & ernsep>0, ///
	percent  width(.05)  ///
	xtitle("Share of earnings in labor form over spell") ///
	ytitle("Fraction of spells (%)") ///
	by(lfstat, note("")) ///
	name(share_earnings_both, replace)

graph export ../plots/share_earnings_all.${figfmt}, replace name(share_earnings_both)

** Same specifically main earners sample [at monthly level]

use ${root}/samples/mainearner, clear
replace both = 0 if both==.

tab lfstat both if (lfstat==2 | lfstat==3), row

* Earning shares for overlapping spells
xtset
gen _start_both = both==1 & L.both==0
keep if _start_both==1

replace ernpep = 0 if ernpep<0
replace ernsep = 0 if ernsep<0

gen ernprop = .

replace ernprop = ernpep/(ernpep + ernsep) if pep==1
replace ernprop = ernsep/(ernpep + ernsep) if sep==1

sum ernprop if ernpep>0 & ernsep>0, d

gen labform = ""
count if pep==1
replace labform = "Paid-emp. (`r(N)' overlapping spells)" if pep==1 & ernprop!=.
count if sep==1
replace labform = "Self-emp. (`r(N)' overlapping spells)" if sep==1 & ernprop!=.

hist ernprop if ernpep>0 & ernsep>0, ///
	percent  width(.05)  ///
	xtitle("Share of earnings in labor form over spell") ///
	ytitle("Fraction of spells (%)") ///
	by(labform, note(""))
	
graph export ../plots/share_earnings_main.${figfmt}, replace 


** Same specifically self-employment sample [at monthly level]

use ${root}/samples/selfemployed, clear
replace both = 0 if both==.

tab lfstat both if (lfstat==2 | lfstat==3), row

* Earning shares for overlapping spells
xtset
gen _start_both = both==1 & L.both==0
keep if _start_both==1

replace ernpep = 0 if ernpep<0
replace ernsep = 0 if ernsep<0

gen ernprop = .

replace ernprop = ernpep/(ernpep + ernsep) if pep==1
replace ernprop = ernsep/(ernpep + ernsep) if sep==1

sum ernprop if ernpep>0 & ernsep>0, d

gen labform = ""
count if pep==1
replace labform = "Paid-emp. (`r(N)' overlapping spells)" if pep==1 & ernprop!=.
count if sep==1
replace labform = "Self-emp. (`r(N)' overlapping spells)" if sep==1 & ernprop!=.

hist ernprop if ernpep>0 & ernsep>0, ///
	percent  width(.05)  ///
	xtitle("Share of earnings in labor form over spell") ///
	ytitle("Fraction of spells (%)") ///
	by(labform, note(""))
	
graph export ../plots/share_earnings_self.${figfmt}, replace 




***********
** UI Draws

clear all

foreach pan of numlist 1996 2001 2004 2008 {
	
	local to_keep panel wave rotation euectyp5 estlemp* ebiznow* eincpb*
	append using ${root}/`pan'/dta/core_`pan', keep(`to_keep')
	
	// keep if euectyp5>-1
	
	keep if estlemp1==2 | estlemp2==2 | ebiznow1==2 | ebiznow2==2
}

tab euectyp5 if (estlemp1==2 | estlemp2==2) & (ebiznow1<2 | ebiznow2<2)
tab euectyp5 if (estlemp1<2 & estlemp2<2) & (ebiznow1==2 | ebiznow2==2)
tab euectyp5 if (estlemp1<2 & estlemp2<2) & ((ebiznow1==2 & eincpb1==1) | (ebiznow2==2 & eincpb2==1)) 


*************************************************************
** Alternative definition of main earners: only married males

* select and stack panels
clear all

foreach pan of numlist 1996 2001 2004 2008 {
	append using ${root}/`pan'/dta/spellspan`pan'_monthly
}

drop if lfstat==. // about a thousand obs.

* indicator for monthly transitions
egen id = group(panel lgtkey) 
xtset id mdate
gen nu = L.lfstat==0 & lfstat==1
gen np = L.lfstat==0 & lfstat==2
gen ns = L.lfstat==0 & lfstat==3
gen un = L.lfstat==1 & lfstat==0
gen up = L.lfstat==1 & lfstat==2
gen us = L.lfstat==1 & lfstat==3
gen pn = L.lfstat==2 & lfstat==0
gen pu = L.lfstat==2 & lfstat==1
gen ps = L.lfstat==2 & lfstat==3
gen sn = L.lfstat==3 & lfstat==0
gen su = L.lfstat==3 & lfstat==1
gen sp = L.lfstat==3 & lfstat==2

* monthly spells
drop spell lgthspell
gen tmp = 0
bys id (mdate): replace tmp = 1 if _n==1
bys id (mdate): replace tmp = 1 if lfstat!=lfstat[_n-1] & _n>1
bys id (mdate): gen spell = sum(tmp)
bys id spell: gen lgthspell = _N
drop tmp

* keep married male earners
bys id (mdate): egen _is_married_male = max(sex==0 & married==1) // ok if gets married
keep if _is_married_male==1
drop _*

* keep male with largest assigned labor earnings in household over sample
bys panel ssuid shhadid epppnum: egen _indern = total(ern)  
bys panel ssuid shhadid: egen _hhern = total(ern)
bys panel ssuid shhadid: drop if _hhern==0 		// nobody works in household
bys panel ssuid shhadid: gen _ernshr = _indern/_hhern
bys panel ssuid shhadid: egen _maxernshr = max(_ernshr) 
bys panel ssuid shhadid mdate: egen auxern = total((_ernshr<_maxernshr)*ern)
bys id: egen sel = max(_maxernshr==_ernshr) 
	// keep if highest earners at any point in household 
	// to deal with multiple households case
bys id (mdate): gen idindex = _n==1
tab panel sel if idindex==1, nol row
keep if sel==1
drop _* sel

* drop individuals with mostly non-employment history
bys id: egen sel = mean(lfstat==0)
replace sel = sel<.5
tab panel sel if idindex==1, nol row
keep if sel==1
drop sel

* individuals with valid earnings 
_pctile ern if ern>0, nq(100)
gen ernvalid = ern>r(r1) & ern<r(r99)
bys id: egen sel = max(ernvalid)
tab panel sel if idindex==1, nol row
keep if sel==1
drop sel 

* flag self-employed sample
bys id: egen selfspl = max(lfstat==3)
label define labspl 0"never SE" 1"some SE", replace 
label values selfspl labspl

* Use 12-month average to be in line with standard earnings dynamics literature.
gen _ern = ern
replace _ern = 0 if ern==.

gen ern_ma_12 = 0
gen auxern_ma_12 = 0
gen welfare_ma_12 = 0
gen hhinc_ma_12 = 0

forv k = 0/11 {
	qui replace ern_ma_12 = ern_ma_12 + L`k'._ern
	qui replace auxern_ma_12 = auxern_ma_12 + L`k'.auxern
	qui replace welfare_ma_12 = welfare_ma_12 + L`k'.thothinc
	qui replace hhinc_ma_12 = hhinc_ma_12 + L`k'.thtotinc
}

replace ern_ma_12 = ern_ma_12/12
replace auxern_ma_12 = auxern_ma_12/12 
replace welfare_ma_12 = welfare_ma_12/12
replace hhinc_ma_12 = hhinc_ma_12/12

drop _ern

* Changes in earnings
// gen D_ern = ern/L.ern - 1 if ernvalid==1 & L.ernvalid==1
gen D_ern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1
gen D_hhinc_ma_12 = hhinc_ma_12/L12.hhinc_ma_12 - 1

table () (selfspl) ${wgt}, ///
	statistic(p10 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p25 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p50 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p75 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p90 D_ern_ma_12 D_hhinc_ma_12) 

* Summary stats
foreach v of varlist D_ern_ma_12 D_hhinc_ma_12 {
	preserve
		collapse (mean) avg=`v' ///
			(p10) p10=`v' ///
			(p25) p25=`v' ///
			(p50) p50=`v' ///
			(p75) p75=`v' ///
			(p90) p90=`v' ///
			${wgt}, ///
			by(selfspl)
		gen variable = "`v'"
		order variable selfspl
		save ${root}/temp/`v'
	restore
}

clear all
foreach v in D_ern_ma_12 D_hhinc_ma_12 {
	append using ${root}/temp/`v'
	rm  ${root}/temp/`v'.dta
}

export excel ../tables/01_data.xlsx, sheet("_dlnern_married_males",replace) first(var)


***************************************************************
** Alternative definition of self-employed: more than 24 months

* select and stack panels
clear all

foreach pan of numlist 1996 2001 2004 2008 {
	append using "${root}/`pan'/dta/spellspan`pan'_monthly"
}

drop if lfstat==. // about a thousand obs.

* indicator for monthly transitions
egen id = group(panel lgtkey)
 
xtset id mdate
gen nu = L.lfstat==0 & lfstat==1
gen np = L.lfstat==0 & lfstat==2
gen ns = L.lfstat==0 & lfstat==3
gen un = L.lfstat==1 & lfstat==0
gen up = L.lfstat==1 & lfstat==2
gen us = L.lfstat==1 & lfstat==3
gen pn = L.lfstat==2 & lfstat==0
gen pu = L.lfstat==2 & lfstat==1
gen ps = L.lfstat==2 & lfstat==3
gen sn = L.lfstat==3 & lfstat==0
gen su = L.lfstat==3 & lfstat==1
gen sp = L.lfstat==3 & lfstat==2

* monthly spells
drop spell lgthspell
gen tmp = 0
bys id (mdate): replace tmp = 1 if _n==1
bys id (mdate): replace tmp = 1 if lfstat!=lfstat[_n-1] & _n>1
bys id (mdate): gen spell = sum(tmp)
bys id spell: gen lgthspell = _N
drop tmp

* keep individual with largest assigned labor earnings in household over sample
bys panel ssuid shhadid epppnum: egen _indern = total(ern)  
bys panel ssuid shhadid: egen _hhern = total(ern)
bys panel ssuid shhadid: drop if _hhern==0 // nobody works in household
bys panel ssuid shhadid: gen _ernshr = _indern/_hhern
bys panel ssuid shhadid: egen _maxernshr = max(_ernshr) 
bys panel ssuid shhadid mdate: egen auxern = total((_ernshr<_maxernshr)*ern)
bys id: egen sel = max(_maxernshr==_ernshr) 
	// keep if highest earners at any point in household 
	// to deal with multiple households case
bys id (mdate): gen idindex = _n==1
tab panel sel if idindex==1, nol row
keep if sel==1
drop _* sel

* drop individuals with mostly non-employment history
bys id: egen sel = mean(lfstat==0)
replace sel = sel<.5
tab panel sel if idindex==1, nol row
keep if sel==1
drop sel

* individuals with valid earnings 
_pctile ern if ern>0, nq(100)
gen ernvalid = ern>r(r1) & ern<r(r99)
bys id: egen sel = max(ernvalid)
tab panel sel if idindex==1, nol row
keep if sel==1
drop sel 

* flag self-employed sample
bys id: egen selfspl = max(lfstat==3)
label define labspl 0"never SE" 1"some SE", replace 
label values selfspl labspl

* drop self-employed with less than twelve-months of history in self-employment
bys id: egen self_exp = total(lfstat==3)
drop if selfspl==1 & self_exp<24

* Use 12-month average to be in line with standard earnings dynamics literature.
gen _ern = ern
replace _ern = 0 if ern==.

gen ern_ma_12 = 0
gen auxern_ma_12 = 0
gen welfare_ma_12 = 0
gen hhinc_ma_12 = 0

forv k = 0/11 {
	qui replace ern_ma_12 = ern_ma_12 + L`k'._ern
	qui replace auxern_ma_12 = auxern_ma_12 + L`k'.auxern
	qui replace welfare_ma_12 = welfare_ma_12 + L`k'.thothinc
	qui replace hhinc_ma_12 = hhinc_ma_12 + L`k'.thtotinc
}

replace ern_ma_12 = ern_ma_12/12
replace auxern_ma_12 = auxern_ma_12/12 
replace welfare_ma_12 = welfare_ma_12/12
replace hhinc_ma_12 = hhinc_ma_12/12

drop _ern

* Changes in earnings
// gen D_ern = ern/L.ern - 1 if ernvalid==1 & L.ernvalid==1
gen D_ern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1
gen D_hhinc_ma_12 = hhinc_ma_12/L12.hhinc_ma_12 - 1

table () (selfspl) ${wgt}, ///
	statistic(p10 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p25 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p50 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p75 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p90 D_ern_ma_12 D_hhinc_ma_12) 

* Summary stats
foreach v of varlist D_ern_ma_12 D_hhinc_ma_12 {
	preserve
		collapse (mean) avg=`v' ///
			(p10) p10=`v' ///
			(p25) p25=`v' ///
			(p50) p50=`v' ///
			(p75) p75=`v' ///
			(p90) p90=`v' ///
			${wgt}, ///
			by(selfspl)
		gen variable = "`v'"
		order variable selfspl
		save ${root}/temp/`v'
	restore
}

clear all
foreach v in D_ern_ma_12 D_hhinc_ma_12 {
	append using ${root}/temp/`v'
	rm  ${root}/temp/`v'.dta
}

export excel ../tables/01_data.xlsx, sheet("_dlnern_self_exp_geq24",replace) first(var)


**********************************************
** Residualize earnings in volatility patterns

use "${dir_samples}/mainearner", clear

* Use 12-month average to be in line with standard earnings dynamics literature.
gen _ern = ern
replace _ern = 0 if ern==.

gen ern_ma_12 = 0
gen hhinc_ma_12 = 0

forv k = 0/11 {
	qui replace ern_ma_12 = ern_ma_12 + L`k'._ern
	qui replace hhinc_ma_12 = hhinc_ma_12 + L`k'.thtotinc
}

replace ern_ma_12 = ern_ma_12/12
replace hhinc_ma_12 = hhinc_ma_12/12

drop _ern

* Education categories
gen hschgrad = education>1 if education!=.
gen collgrad = education>3 if education!=.
gen postgrad = education>4 if education!=.

* Residualize earnings
gen lnern_ma_12 = ln(ern_ma_12)
gen lnhhinc_ma_12 = ln(hhinc_ma_12)

qui reg lnern_ma_12 c.age c.age#c.age c.age#c.age#c.age i.married i.race i.sex
qui predict lnern_ma_12_res, res

qui reg lnhhinc_ma_12 c.age c.age#c.age c.age#c.age#c.age i.married i.race i.sex
qui predict lnhhinc_ma_12_res, res

gen dlnern_ma_12 = lnern_ma_12 - L12.lnern_ma_12
gen dlnhhinc_ma_12 = lnhhinc_ma_12 - L12.lnhhinc_ma_12 
gen dlnern_ma_12_res = lnern_ma_12_res - L12.lnern_ma_12_res
gen dlnhhinc_ma_12_res = lnhhinc_ma_12_res - L12.lnhhinc_ma_12_res 

table () (selfspl) ${wgt}, ///
	statistic(p10 dlnern_ma_12 dlnhhinc_ma_12 dlnern_ma_12_res dlnhhinc_ma_12_res) ///
	statistic(p25 dlnern_ma_12 dlnhhinc_ma_12 dlnern_ma_12_res dlnhhinc_ma_12_res) ///
	statistic(p50 dlnern_ma_12 dlnhhinc_ma_12 dlnern_ma_12_res dlnhhinc_ma_12_res) ///
	statistic(p75 dlnern_ma_12 dlnhhinc_ma_12 dlnern_ma_12_res dlnhhinc_ma_12_res) ///
	statistic(p90 dlnern_ma_12 dlnhhinc_ma_12 dlnern_ma_12_res dlnhhinc_ma_12_res) 

********************************************************
** Within labor form volatility in paid employees sample
use ${dir_samples}/mainearner, clear

keep if self_sample==0
qui xtset

gen ern_ma_06 = ern if ernvalid==1
gen ern_ma_12 = ern if ernvalid==1

forv k = 1/5 {
	qui replace ern_ma_06 = ern_ma_06 + L`k'.ern 
	qui replace ern_ma_06 = . if spell!=L`k'.spell
}

forv k = 1/11 {
	qui replace ern_ma_12 = ern_ma_12 + L`k'.ern if spell==L`k'.spell
	qui replace ern_ma_12 = . if spell!=L`k'.spell
}

replace ern_ma_06 = ern_ma_06/6 
replace ern_ma_12 = ern_ma_12/12 

gen dern_ma_06 = ern_ma_06/L06.ern_ma_06 - 1 if ernvalid==1 & L06.ernvalid==1 & spell==L06.spell 
gen dern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1 if ernvalid==1 & L12.ernvalid==1 & spell==L12.spell

table () (lfstat) ${wgt} if lfstat>1, ///
	statistic(p10 dern_ma_06 dern_ma_12) ///
	statistic(p25 dern_ma_06 dern_ma_12) ///
	statistic(p50 dern_ma_06 dern_ma_12) ///
	statistic(p75 dern_ma_06 dern_ma_12) ///
	statistic(p90 dern_ma_06 dern_ma_12) ///
	nototals

* Summary stats
local v dern_ma_12
collapse (mean) avg=`v' ///
	(p10) p10=`v' ///
	(p25) p25=`v' ///
	(p50) p50=`v' ///
	(p75) p75=`v' ///
	(p90) p90=`v' ///
	${wgt}, ///
	by(self_sample)
gen variable = "`v'"
order variable self_sample

export excel ../tables/01_data.xlsx, sheet("_dlnern_employees",replace) first(var)


***************
** Age profiles

use ${dir_samples}/selfemployed, clear

preserve
collapse (mean) avg=ern (p50) p50=ern (p25) p25=ern (p75) p75=ern if ernvalid==1 ${wgt}, by(cluster_id age)
drop if age<=25
xtset cluster_id age
xtline avg, ///
	xtitle("Age") ///
	ytitle("Average monthly earnings in main labor form ($2009)") ///
	name(ern_by_cluster,replace) ///
	overlay
// twoway ///
// 	(rarea p25 p75 age if cluster_id==1, lcolor(black%0) fcolor(navy%20)) ///
// 	(rarea p25 p75 age if cluster_id==2, lcolor(black%0) fcolor(navy%20)) ///
// 	(rarea p25 p75 age if cluster_id==3, lcolor(black%0) fcolor(navy%20)) ///
// 	(rarea p25 p75 age if cluster_id==4, lcolor(black%0) fcolor(navy%20)) ///
// 	(connected p50 age if cluster_id==1) ///
// 	(connected p50 age if cluster_id==2) ///
// 	(connected p50 age if cluster_id==3) ///
// 	(connected p50 age if cluster_id==4)
restore

preserve	
collapse (mean) avg=ern (p50) p50=ern (p25) p25=ern (p75) p75=ern if ernvalid==1 ${wgt}, by(educ age)
drop if age<=25
xtset educ age
xtline avg, ///
	xtitle("Age") ///
	ytitle("Average monthly earnings in main labor form ($2009)") ///
	name(ern_by_educ,replace) ///
	overlay
restore

graph export ../plots/age_profile_cluster.${figfmt}, replace name(ern_by_cluster)
graph export ../plots/age_profile_educ.${figfmt}, replace name(ern_by_educ)

	
