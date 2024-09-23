* Plots and tables reported in data section.

clear all
set more off
cap log close
do globals

* Settings
global saveit 1
global wgt [aweight=lweight] 	

// sample weights:
// [pweight=lweight]  longitudinal
// [pweight=wpfinwgt] cross-sectional
	

	
****************************************	
** Descriptive stats: Main earner sample

use "${dir_samples}/mainearner", clear


** unemployment rate, transitions

* splitting by self-/not self-
preserve

gen ue = up + us
gen eu = pu + su 

* transition rates, by rotation group
collapse (sum) ue eu employed unemployed pep sep ${wgt}, by(panel rotation mdate self_sample self_status) 

bys panel rotation self_sample self_status (mdate): gen UE = ue/unemp[_n-1] if _n>1
bys panel rotation self_sample self_status (mdate): gen EU = eu/emplo[_n-1] if _n>1
bys panel rotation (mdate): drop if _n==1

gen urate = unemployed/(unemployed + employed)
gen prate = pep/(unemployed + employed)
gen srate = sep/(unemployed + employed)

* average across rotation group/panel
collapse UE EU ?rate, by(panel mdate self_sample self_status)

sum UE EU ?rate

collapse UE EU ?rate, by(self_sample self_status)
order self_sample self_status
list

if ${saveit} {	
	export excel ../tables/01_data.xlsx, sheet("_transitions",replace) first(var)    
}

restore


** Demographic descriptives: self-employed vs never self-employed

* time in sample
bys id: egen t_by_id = count(panel)

* education categories
gen hschgrad = education>1 if education!=.
gen collgrad = education>3 if education!=.
gen postgrad = education>4 if education!=.

* summary stats
preserve
	collapse (mean) t_by_id (count) N=age if idindex==1, by(self_sample self_status)
	order self_sample self_status
	list
	if ${saveit} {
		export excel ../tables/01_data.xlsx, sheet("_count_samples",replace) first(var)
	}
restore

preserve
	collapse (mean) age sex married race *grad ${wgt} if idindex==1, by(self_sample self_status)
	order self_sample self_status
	list self_sample self_status age sex married race
	if ${saveit} {
		export excel ../tables/01_data.xlsx, sheet("_desc_samples",replace) first(var)
	}
restore
	
drop hschgrad collgrad postgrad t_by_id


** Yearly income measures

* Restrict to analysis sample vs paid-employees
drop if self_sample==1 & self_status!=1

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


** Changes in earnings

// gen D_ern = ern/L.ern - 1 if ernvalid==1 & L.ernvalid==1
gen D_ern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1
gen D_hhinc_ma_12 = hhinc_ma_12/L12.hhinc_ma_12 - 1

table () (self_sample) ${wgt}, ///
	statistic(p10 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p25 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p50 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p75 D_ern_ma_12 D_hhinc_ma_12) ///
	statistic(p90 D_ern_ma_12 D_hhinc_ma_12) 
		
* earnings growth distribution plots
foreach v of varlist D_*_ma_12 {

	gen select = `v'>=-.5 & `v'<=.5
	
// 	ksmirnov `v' if select==1, by(self_sample)

	twoway ///
		(hist `v' if self_sample==0 & select==1, frac fcolor(gs13) lcolor(gs13)) ///
		(hist `v' if self_sample==1 & select==1, frac fcolor(none) lcolor(gs3)), ///
		legend(lab(1 "Never self-employed") lab(2 "Some self-employment") ring(0) pos(2) size(medlarge)) ///
		xtitle("Yearly growth rate", size(medlarge)) ///
		ytitle("Fraction", size(medlarge)) ///
		name(`v',replace)

	drop select
	
}

if ${saveit} {
	
	graph export ../plots/earn_growth_main_earner.png, replace name(D_ern_ma_12)
	graph export ../plots/earn_growth_household.png, replace name(D_hhinc_ma_12)
	
	foreach v of varlist D_ern_ma_12 D_hhinc_ma_12 {
		preserve
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
			save ${root}/temp/`v'
		restore
	}
	
}	

drop D_*_ma_12

	
** Distribution income and assets

table () (self_sample) ${wgt}, ///
	statistic(p10 ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12) ///
	statistic(p25 ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12) ///
	statistic(p50 ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12) ///
	statistic(p75 ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12) ///
	statistic(p90 ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12) 


* Could add auxern conditional on marriage as well. 
* Pattern is the same, but with less zeros.

if ${saveit} {
	foreach v of varlist ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12 {
		preserve
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
			save ${root}/temp/`v'
		restore
	}
}

* wealth measures
table () (self_sample) ${wgt}, ///
	statistic(p10 nlw niw lqw uscdbt) ///
	statistic(p25 nlw niw lqw uscdbt) ///
	statistic(p50 nlw niw lqw uscdbt) ///
	statistic(p75 nlw niw lqw uscdbt) ///
	statistic(p90 nlw niw lqw uscdbt) 


if ${saveit} {
    foreach v of varlist nlw niw lqw uscdbt {
	    preserve
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
			save ${root}/temp/`v'
		restore
	}
}


** Append all summary stats

if ${saveit} {
	clear all
	foreach v in ern_ma_12 auxern_ma_12 hhinc_ma_12 welfare_ma_12 nlw niw lqw uscdbt D_ern_ma_12 D_hhinc_ma_12 {
		append using ${root}/temp/`v'
		rm  ${root}/temp/`v'.dta
	}
	export excel ../tables/01_data.xlsx, sheet("_perc_comp",replace) first(var)
}


*******************************************
*** Descriptive stats: Self-employed sample 

use "${root}/samples/selfemployed", clear


** Descriptive stats by worker class

* industry/occupations
label values ind tbsind1l
// label values occ // Don't have the labels for those?

tab ind cluster_id, col
tab occ cluster_id, col

// ssc install catplot

catplot cluster_id ind, ///
	percent(cluster_id) asyvars ///
	var2opts(label(labsize(small))) ///
	ytitle("Percent of worker cluster", size(small)) ///
	legend(size(small) title("Worker cluster", size(small))) ///
	name(ind_worker_group,replace)
	
catplot cluster_id occ, ///
	percent(cluster_id) asyvars ///
	var2opts(label(labsize(small))) ///
	ytitle("Percent of worker cluster", size(small)) ///
	legend(size(small) title("Worker cluster", size(small))) ///
	name(occ_worker_group,replace)

if $saveit {
	graph export ../plots/share_ind_worker_group.png, replace name(ind_worker_group)
	graph export ../plots/share_occ_worker_group.png, replace name(occ_worker_group)
}


* demographics
gen hschgrad = education>1 if education!=.
gen collgrad = education>3 if education!=.
gen postgrad = education>4 if education!=.

table () cluster_id if idindex==1 ${wgt}, stat(mean age sex married race) 
table () cluster_id if idindex==1 ${wgt}, stat(mean hschgrad collgrad postgrad)

tab cluster_id if idindex==1

* household earnings
table () cluster_id, stat(mean thtotinc) stat(p50 thtotinc)

table () cluster_id if lfstat==1, stat(mean thtotinc) stat(p50 thtotinc)
table () cluster_id if lfstat==2, stat(mean thtotinc) stat(p50 thtotinc)
table () cluster_id if lfstat==3, stat(mean thtotinc) stat(p50 thtotinc)

if ${saveit} {
	
	preserve
		collapse (count) N=id if idindex==1, by(cluster_id)
		export excel ../tables/01_data.xlsx, ///
			sheet("_cluster_count",replace) first(var)
	restore
	
	preserve
		keep if idindex==1
		
		collapse ///
			(mean) age sex married race ///
			hschgrad collgrad postgrad ${wgt}, ///
			by(cluster_id)

		sort cluster_id
		order cluster_id
		
		export excel ../tables/01_data.xlsx, ///
			sheet("_cluster_demographic",replace) first(var)
			
	restore
	
	preserve
		replace ern = . if ernvalid!=1
		collapse (p50) ern thtotinc ${wgt}, by(cluster_id)
		
		sort cluster_id
		order cluster_id
		
		export excel ../tables/01_data.xlsx, ///
			sheet("_cluster_earnings",replace) first(var)
		
	restore
	
} 


** monthly transitions

* previous/next lfstat
qui xtset
gen tmp = L.lfstat if spell!=L.spell
bys panel id spell: egen prevlfstat = max(tmp)
drop tmp

qui xtset
gen tmp = F.lfstat if spell!=F.spell
bys panel id spell: egen nextlfstat = max(tmp)
drop tmp

gen sus = su==1 & nextlfstat==3
gen sup = su==1 & nextlfstat==2
gen pus = su==1 & nextlfstat==3
gen pup = pu==1 & nextlfstat==2


* transition rates, all workers
preserve

	collapse (sum) n? u? p? s? sus sup pus pup ///
		sep pep employed unemployed ${wgt}, ///
		by(panel rotation mdate) 

	bys panel rotation (mdate): gen UP = up/unemp[_n-1] 	if _n>1
	bys panel rotation (mdate): gen US = us/unemp[_n-1] 	if _n>1
	bys panel rotation (mdate): gen SP = sp/sep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen PS = ps/pep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen PU = pu/pep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen SU = su/sep[_n-1] 	if _n>1

	bys panel rotation (mdate): gen SUS = sus/sep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen SUP = sup/sep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen PUS = pus/pep[_n-1] 	if _n>1
	bys panel rotation (mdate): gen PUP = pup/pep[_n-1] 	if _n>1

	bys panel rotation (mdate): drop if _n==1

	gen newSfromU = us/(us + ps + ns)
	gen newSfromP = ps/(us + ps + ns)

	gen endStoU = su/(su + sp + sn)
	gen endStoP = sp/(su + sp + sn)
	
	gen newUfromS = su/(su + up)
	
	gen U = unempl/(unemployed + employed)
	gen P = pep/(unemployed + employed)
	gen S = sep/(unemployed + employed)
	
	* average across rotation group/panel
	collapse U P S UP US SP PS PU* SU* newS* endS* newU, by(panel mdate)
	bys panel: sum U P S UP US SP PS PU* SU* newS* endS* newU
	sum U P S UP US SP PS PU* SU* newS* endS* newU

	if ${saveit} {
		collapse ??
		export excel ../tables/01_data.xlsx, ///
			sheet("_trans_rates_self",replace) first(var)
	}

restore


** earnings/assets by labor form

qui xtset

* Moving average of valid earnings (within same spell)
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

// gen ern_ma_06 = ern if ernvalid==1
// gen ern_ma_12 = ern if ernvalid==1
//
// forv k = 1/5 {
// 	qui replace ern_ma_06 = ern_ma_06 + L`k'.ern if L`k'.ernvalid==1 & spell==L`k'.spell
// 	qui replace ern_ma_06 = . if L`k'.ernvalid!=1 | spell!=L`k'.spell
// }
//
// forv k =1/11 {
// 	qui replace ern_ma_12 = ern_ma_12 + L`k'.ern if L`k'.ernvalid==1 & spell==L`k'.spell
// 	qui replace ern_ma_12 = . if L`k'.ernvalid!=1 | spell!=L`k'.spell
// }
//
// replace ern_ma_06 = ern_ma_06/6 
// replace ern_ma_12 = ern_ma_12/12 

* earnings 
table () (lfstat) if ernvalid==1 ${wgt}, ///
	statistic(p10 ern ern_ma_06 ern_ma_12) ///
	statistic(p25 ern ern_ma_06 ern_ma_12) ///
	statistic(p50 ern ern_ma_06 ern_ma_12) ///
	statistic(p75 ern ern_ma_06 ern_ma_12) ///
	statistic(p90 ern ern_ma_06 ern_ma_12) 

if ${saveit} {
	foreach v of varlist ern ern_ma_06 ern_ma_12 {
		preserve
			collapse ///
				(p10) p10=`v' ///
				(p25) p25=`v' ///
				(p50) p50=`v' ///
				(p75) p75=`v' ///
				(p90) p90=`v' ///
				if ernvalid==1 ${wgt}, ///
				by(lfstat)
			gen variable = "`v'"
			order variable lfstat
			save ${root}/temp/`v', replace
		restore
	}
}
	
* wealth measures
table () (lfstat) if srefmon==4 & lfstat>0 ${wgt}, ///
	statistic(p10 nlw niw lqw uscdbt) ///
	statistic(p25 nlw niw lqw uscdbt) ///
	statistic(p50 nlw niw lqw uscdbt) ///
	statistic(p75 nlw niw lqw uscdbt) ///
	statistic(p90 nlw niw lqw uscdbt) ///
	nototals

table () (lfstat) if srefmon==4 & lfstat>0, nototals  
	
if ${saveit} {
	foreach v of varlist nlw niw lqw uscdbt {
		preserve
			collapse ///
				(p10) p10=`v' ///
				(p25) p25=`v' ///
				(p50) p50=`v' ///
				(p75) p75=`v' ///
				(p90) p90=`v' ///
				if srefmon==4 & lfstat>0 & lfstat<. ${wgt}, ///
				by(lfstat)
			gen variable = "`v'"
			order variable lfstat
			save ${root}/temp/`v', replace
		restore
	}
}


** Change in labor earnings

qui xtset

* Unconditional on employment state (must be employed)
gen dern_01 = ern/L01.ern - 1 if ernvalid==1 & L01.ernvalid==1 
gen dern_06 = ern/L06.ern - 1 if ernvalid==1 & L06.ernvalid==1 
gen dern_12 = ern/L12.ern - 1 if ernvalid==1 & L12.ernvalid==1 

gen dern_ma_06 = ern_ma_06/L06.ern_ma_06 - 1 if ernvalid==1 & L06.ernvalid==1 
gen dern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1 if ernvalid==1 & L12.ernvalid==1 

table () (lfstat) ${wgt} if lfstat>1, ///
	statistic(p10 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p25 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p50 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p75 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p90 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	nototals

drop dern_*

* Within same spell (=conditional on being in same employment state) 
gen dern_01 = ern/L01.ern - 1 if ernvalid==1 & L01.ernvalid==1 & spell==L01.spell
gen dern_06 = ern/L06.ern - 1 if ernvalid==1 & L06.ernvalid==1 & spell==L06.spell
gen dern_12 = ern/L12.ern - 1 if ernvalid==1 & L12.ernvalid==1 & spell==L12.spell

gen dern_ma_06 = ern_ma_06/L06.ern_ma_06 - 1 if ernvalid==1 & L06.ernvalid==1 & spell==L06.spell 
gen dern_ma_12 = ern_ma_12/L12.ern_ma_12 - 1 if ernvalid==1 & L12.ernvalid==1 & spell==L12.spell

table () (lfstat) ${wgt} if lfstat>1, ///
	statistic(p10 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p25 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p50 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p75 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	statistic(p90 dern_01 dern_06 dern_12 dern_ma_06 dern_ma_12) ///
	nototals

gen select = dern_ma_12>-0.5 & dern_ma_12<0.5
	
twoway ///
	(hist dern_ma_12 if lfstat==2 & select==1, frac fcolor(gs13) lcolor(gs13)) ///
	(hist dern_ma_12 if lfstat==3 & select==1, frac fcolor(none) lcolor(gs3)), ///
	legend(lab(1 "Paid-employment") lab(2 "Self-employment")) ///
	xtitle("12-month growth rate (always same labor form)") ///
	ytitle("Fraction") ///
	name(dern_ma_12,replace)
	
drop select	
	
if $saveit {
	foreach v of varlist dern_06 dern_ma_06 dern_12 dern_ma_12 {
		preserve
			collapse ///
				(p10) p10=`v' ///
				(p25) p25=`v' ///
				(p50) p50=`v' ///
				(p75) p75=`v' ///
				(p90) p90=`v' ///
				if lfstat>1 ${wgt}, ///
				by(lfstat)
			gen variable = "`v'"
			order variable lfstat
			save ${root}/temp/`v', replace
		restore
	}
}

drop dern_* 


** Earning change with "voluntary" change of status
** "Voluntary": direct SP or PS transition with no unemployment spell in-between. 

* average earnings over spell
bys id spell: egen lgthvalid = total(ernvalid)
bys id spell: egen ern_avgspell = mean(ern) if lfstat>1

qui xtset

foreach tr in sp ps {
	foreach q of numlist 6 12 {
		gen dern_`tr'_`q' = ern_avgspell/L.ern_avgspell - 1 if `tr'==1 & lgthvalid>=`q' & L.lgthvalid>=`q'
		gen sel_`tr'_`q' = dern_`tr'_`q'>=-1.0 & dern_`tr'_`q'<=1.0
	}
}


table () (lfstat) ${wgt} if lfstat>1, ///
	statistic(p10 dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12) ///
	statistic(p25 dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12) ///
	statistic(p50 dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12) ///
	statistic(p75 dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12) ///
	statistic(p90 dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12) ///
	nototals
 
if $saveit {
    foreach v of varlist dern_sp_6 dern_ps_6 dern_sp_12 dern_ps_12 {
	    preserve
			collapse ///
				(p10) p10=`v' ///
				(p25) p25=`v' ///
				(p50) p50=`v' ///
				(p75) p75=`v' ///
				(p90) p90=`v' ///
				${wgt}
			gen variable = "`v'"
			save ${root}/temp/`v', replace
		restore
	}
}	 
 
* density of change
twoway ///
	(hist dern_sp_6 if sel_sp_6==1, frac fcolor(gs13) lcolor(gs13)) ///
	(hist dern_ps_6 if sel_ps_6==1, frac fcolor(none) lcolor(gs3)), ///
	legend(lab(1 "SP") lab(2 "PS")) ///
	xtitle("Growth in average earnings (6+ months)") ///
	ytitle("Fraction") ///
	name(dern_06_trans,replace)

twoway ///
	(hist dern_sp_12 if sel_sp_12==1, frac fcolor(gs13) lcolor(gs13)) ///
 	(hist dern_ps_12 if sel_ps_12==1, frac fcolor(none) lcolor(gs3)), ///
	legend(lab(1 "SP") lab(2 "PS")) ///
	xtitle("Growth in average earnings (12+ months)") ///
	ytitle("Fraction") ///
	name(dern_12_trans,replace)

// if $saveit {	
// 	graph export ../plots/earn-growth-06-trans.png, replace name(dern_06_trans)
// 	graph export ../plots/earn-growth-12-trans.png, replace name(dern_12_trans)	
// }	
	
	
drop dern_* sel_*

/*

** Auxiliary earnings and transitions

* NB. Auxiliary earnings = labor earnings from other members in household.
table lfstat if lfstat>0 ${wgt} , c(p10 auxe p25 auxe p50 auxe p75 auxe p90 auxe)

* in change if falls into unemployment
bys id spell: egen auxern_avgspell = mean(auxern) if lfstat>0 
qui xtset

foreach i of numlist 4 12 {
	foreach j of numlist 0 4 {
		gen D_auxern_su_`i'_`j' = D.auxern_avgs if su==1 & L.lgths>=`i' & lgths>=`j'
		gen D_auxern_pu_`i'_`j' = D.auxern_avgs if pu==1 & L.lgths>=`i' & lgths>=`j'
		sum D_auxern_su_`i'_`j', d
		sum D_auxern_pu_`i'_`j', d
	}
}

drop D_auxern_*

*/

** Append all stats to save

if ${saveit} {	
	clear all
	foreach v in ern ern_ma_06 ern_ma_12 nlw niw lqw uscdbt dern_12 dern_ma_12 dern_sp_12 dern_ps_12 {
		append using ${root}/temp/`v'
		sort variable lfstat
		rm  ${root}/temp/`v'.dta
	}
	
	export excel ../tables/01_data.xlsx, sheet("_pctl_self",replace) first(var)
	
}


************************************************
** Descriptive stats on business characteristics

use ${root}/samples/selfemployed, clear

// use ${root}/samples/mainearner, clear
// keep if self_sample==1
// keep if self_status==1 | self_status==2

* All stats below use last available value before 
* end of spell/last available observation.

* deflate business assets
foreach v of varlist tvbva? tvbde? {
	replace `v' = `v'*pcepi_defl 
}

* business characteristics
forv i = 1/2 {
	gen val_bus_`i' = evbow`i'/100*tvbva`i' 
	gen deb_bus_`i' = evbow`i'/100*tvbde`i'
	gen equ_bus_`i' = evbow`i'/100*(tvbva`i' - tvbde`i')
	gen shr_bus_`i' = evbow`i'/100
	
}

gen val_bus = val_bus_1 + val_bus_2 		if lfstat==3
gen equ_bus = equ_bus_1 + equ_bus_2 		if lfstat==3 
gen deb_bus = deb_bus_1 + deb_bus_2 		if lfstat==3 
gen lev_bus = deb_bus/val_bus			if lfstat==3

ren inc inc_bus
ren sze sze_bus


* copy values down within spell (to fill available value)
foreach v of varlist ???_bus {
	bys id spell (mdate): replace `v' = `v'[_n-1] if `v'==. & lfstat==3
}

* labels
label var val_bus "business assets"
label var deb_bus "business debt"
label var equ_bus "business net worth"
label var inc_bus "incorporated business"
label var lev_bus "leverage business"
label var sze_bus "max. number of employees" 

label value sze_bus tempb1l
label value inc_bus eincpb1l

* summary stats
bys id spell (mdate): gen select = lgthspell==_n & lfstat==3

foreach v of varlist val_bus deb_bus equ_bus lev_bus {
	di _n(2)
	summ `v' if select==1, d
}

tab inc_bus if select==1 & inc_bus>-1
tab sze_bus if select==1 & sze_bus>-1

* summary stats by cluster ID
table cluster_id, stat(p50 val_bus deb_bus equ_bus lev_bus)

tab inc_bus cluster_id if select==1 & inc_bus>-1, col
tab sze_bus cluster_id if select==1 & sze_bus>-1, col

if ${saveit} {
	
	* By cluster ID
	preserve
		collapse /// 
			(p50) val_bus deb_bus equ_bus lev_bus ///
			if select==1, by(cluster_id)
		save ${root}/temp/bus_wealth, replace 
	restore
	
	preserve
		gen incorporated = inc_bus==1 if select==1 & inc_bus>-1
		gen workforce_larger_25 = sze_bus>=2 if select==1 & sze_bus>-1
		collapse (mean) incorporated workforce_larger_25, by(cluster_id)
		save ${root}/temp/bus_char, replace
	restore
	
	preserve
		use ${root}/temp/bus_wealth, clear
		merge 1:1 cluster_id using ${root}/temp/bus_char, nogen
		export excel ../tables/01_data.xlsx, ///
			sheet("_cluster_bus_stats",replace) first(var)
	restore
	
	* All together
	preserve
		collapse (p50) val_bus deb_bus equ_bus lev_bus if select==1
		gen id = 1
		save ${root}/temp/bus_wealth, replace 
	restore
	
	preserve
		gen incorporated = inc_bus==1 if select==1 & inc_bus>-1
		gen workforce_larger_25 = sze_bus>=2 if select==1 & sze_bus>-1
		collapse (mean) incorporated workforce_larger_25
		gen id = 1 
		save ${root}/temp/bus_char, replace
	restore
	
	preserve
		use ${root}/temp/bus_wealth, clear
		merge 1:1 id using ${root}/temp/bus_char, nogen
		drop id
		export excel ../tables/01_data.xlsx, sheet("_bus_stats",replace) first(var)
	restore
	
	rm ${root}/temp/bus_char.dta
	rm ${root}/temp/bus_wealth.dta
	
} 



*** NO LONGER USED

/*

* tag ending self-employment spells
qui xtset
gen leaveS = .
replace leaveS = 1 if lfstat==3 & nextlfstat==1
replace leaveS = 2 if lfstat==3 & nextlfstat==2 
replace leaveS = 0 if lfstat==3 & leaveS==.
label define leaveS 0"continuing" 1"to U" 2"to P", replace
label value leaveS  leaveS

* tag starting self-employment spells
qui xtset
gen enterS = .
replace enterS = 1 if lfstat==3 & prevlfstat==1
replace enterS = 2 if lfstat==3 & prevlfstat==2 
replace enterS = 0 if lfstat==3 & enterS==.
label define enterS 0"continuing" 1"from U" 2"from P", replace
label value enterS enterS

* value of business and leverage (leavers)
foreach v in val deb equ {
	di "`v'"
	table leaveS if lfstat==3 & spellind==lgthspell, ///
		c(mean `v'_bus p25 `v'_bus  p50 `v'_bus p75 `v'_bus n `v'_bus)
	di _n
}

* value of business and leverage (entrants)
foreach v in val deb equ {
	di "`v'"
	table enterS if lfstat==3 & spellind==1, ///
		c(mean `v'_bus p25 `v'_bus  p50 `v'_bus p75 `v'_bus n `v'_bus)
	di _n
}

* incorporation
tab leaveS inc_bus if lfstat==3 & spellind==lgthspell, row
tab enterS inc_bus if lfstat==3 & spellind==lgthspell, row

*  business value leavers
graph box equ_bus val_bus if lfstat==3 & spellind==lgthspell, ///
	over(leaveS) nooutside title("Business Wealth: Leavers") ///
	ytitle("2009$") note("")
if ${saveit} graph export ../plots/business_wealth_leave.pdf, replace

*  business value entrants
graph box equ_bus val_bus if lfstat==3 & spellind==lgthspell, ///
	over(enterS) nooutside title("Business Wealth: Entrants") ///
	ytitle("2009$") note("")
if ${saveit} graph export ../plots/business_wealth_enter.pdf, replace





*** Unemployment Duration by previous employment status

use ${root}/samples/duration, clear

* description
stdescribe
stsum, by(lfstatbef)
table lfstatbef, c(mean age mean sex mean race mean married)
tab educ lfstatbef, col
table lfstatbef, c(p10 nlw p25 nlw p50 nlw p75 nlw p90 nlw)
	
* previous wealth plot
graph box nlw, over(lfstatbef) nooutside ///
	title("Unemployed Wealth by Previous Employment Type") ///
	ytitle("liquid net worth (2009 dollars)") ///
	note("") 
if ${saveit} graph export ../plots/liquid_wealth_unemployed.pdf, replace

* duration by previous stat
sts test lfstatbef
sts test lfstatbef, wilcoxon
sts graph, adjustfor(onseam) by(lfstatbef) plotopts(lwidth(medthick medthick) lpattern("l" "_")) ///
	title("Survival Function Estimates") xtitle("weeks unemployed") ytitle("fraction unemployed") ///
	name(surv,replace) legend(label(1 "paid-") label(2 "self-") ring(0) pos(3) cols(1))
if ${saveit} graph export ../plots/survival.pdf, replace

* same, by wealth quartile
xtile netliq_qtile = nlw, nq(4) 
forv q = 1/4 {
	sts test lfstatbef if netliq_qtile==`q', wilcoxon
	sts graph if netliq_qtile==`q', adjustfor(onseam) by(lfstatbef) ///
		plotopts(lwidth(medthick medthick)) ///
		title({bf:`q'}, size(huge) ring(0) pos(1)) ///
		xtitle("weeks unemployed") ytitle("fraction unemployed") ///
		legend(label(1 "paid-") label(2 "self-") ring(0) pos(3) cols(1)) ///
		name(surv_q`q', replace) 
	if ${saveit} graph export ../plots/survival_q`q'.pdf, replace
}

* controls 
#delimit ;
global covars 
onseam 
age 
c.age#c.age 
i.race 
i.educ 
i.sex 
i.married
i.state
i.rhcalyr
;
#delimit cr

* PH models
stcox i.lfstatbef ${covars}, cluster(state) nohr
eststo m1 
stcox i.lfstatbef ${covars} i.occ, cluster(state) nohr
eststo m2
stcox i.lfstatbef ${covars} i.ind, cluster(state) nohr
eststo m3
stcox i.lfstatbef ${covars} i.ind i.occ, cluster(state) nohr
eststo m4

* same interacting with assets
forv q = 1/4 {
	gen sempq`q' = (lfstatbef==2)*(netliq_qtile==`q') if netliq_qtile!=. 
	label var sempq`q' "self- x Q`q' wealth"
}
stcox sempq? ${covars}, cluster(state) nohr strata(netliq_qtile)
eststo m5
stcox sempq? ${covars} i.ind, cluster(state) nohr strata(netliq_qtile)
eststo m6
stcox sempq? ${covars} i.occ, cluster(state) nohr strata(netliq_qtile)
eststo m7
stcox sempq? ${covars} i.ind i.occ, cluster(state) nohr strata(netliq_qtile)
eststo m8

* export tables to Tex
if ${saveit} {

	* no interaction with assets
	esttab m1 m2 m3 m4 using ../tables/ph_models.tex, booktabs replace ///
		keep(2.lose_emp_type 1.married 1.race 1.sex) se  ///
		indicate("age controls = age" "education controls = 1.education" ///
		"year = 2009.rhcalyr" "state = 1.state" ///
		"occupation = 1.occ" "industry = 1.ind") ///
		nomtitles nocons label 

	* interacting with assets	
	esttab m5 m6 m7 m8 using ../tables/ph_models_assets.tex, booktabs  replace ///
		keep(sempq1 sempq2 sempq3 sempq4 1.married 1.race 1.sex) se  ///
		indicate("age controls = age" "education controls = 1.education" ///
		"year = 2009.rhcalyr" "state = 1.state" ///
		"occupation = 1.occ" "industry = 1.ind") ///
		nomtitles nocons label 

}


** Self-employment entry

use ${root}/samples/selfentry, clear

global wlt thhtnw	// wealth measure
global def s 		// definition for entrepreneurship:
					// s=self-employed, c=hh has business equity 

* self-employed vs business owner
tab is_c is_s, cell
tab to_c to_s if !is_c & !is_c, cell

* some descriptives of entry
keep if !is_${def}
tab to_${def}
tab educ to_${def}, col
table to_${def}, c(mean age mean sex mean race mean married)
table to_${def}, c(mean been_s mean been_u mean thearn mean ${wlt} med ${wlt}) 

* wealth regressors
// replace ${wlt} = ${wlt}/100000
sum ${wlt}, d

* wealth quantile dummies, similar to Hurst Lusardi
xtile tmp = ${wlt}, nq(100)
gen  ${wlt}_qtl = .
replace ${wlt}_qtl = 1 if tmp<25
replace ${wlt}_qtl = 2 if tmp>24 & tmp<50
replace ${wlt}_qtl = 3 if tmp>49 & tmp<75 
replace ${wlt}_qtl = 4 if tmp>74 & tmp<95 
replace ${wlt}_qtl = 5 if tmp>94 & tmp<99 // trim top two percent
label var ${wlt}_qtl "Percentile Wealth"
label define ${wlt}_qtl 1"0-25th" 2"25th-50th" 3"50th-75th" 4"75th-95th" 5"95th-98th", replace 
label value ${wlt}_qtl ${wlt}_qtl
drop tmp

* controls
#delimit ;
global covars
i.been_u
i.been_s
age
c.age#c.age
i.educ
i.race
i.married
thearn
c.thearn#c.thearn
i.state
i.rhcalyr 
; 
#delimit cr

* wealth quantiles
// qui sum ${wlt}, d
// global pctl `r(p5)' `r(p10)' `r(p25)' `r(p50)' `r(p75)' `r(p90)' `r(p95)'

* probit models for wealth
// probit to_${def} ${wlt} ${covars}, vce(robust)
// margins, dydx(${wlt})
// margins, nose at(${wlt}=(${pctl})) plot
//
// probit to_${def} c.${wlt} c.${wlt}#c.${wlt} c.${wlt}#c.${wlt}#c.${wlt} ///
// 	${covars}, vce(robust)
// margins, dydx(${wlt})
// margins, nose at(${wlt}=(${pctl})) plot
//
// probit to_${def} c.${wlt} c.${wlt}#c.${wlt} c.${wlt}#c.${wlt}#c.${wlt} ///
// 	c.${wlt}#c.${wlt}#c.${wlt}#c.${wlt} ///
// 	${covars}, vce(robust)
// margins, dydx(${wlt})
// // margins, nose at(${wlt}=(${pctl})) plot

probit to_${def} i.${wlt}_qtl ${covars}, vce(robust)
margins ${wlt}_qtl


/*

** income change within spell

* spell infos
bys id spell: egen ern_valid_spell = total(erntrim)
gen ernsample = lgthspell_month==ern_valid_spell & lgthspell_month>=6 
qui tsset
gen seam = wave!=L.wave & id==L.id
gen year = yofd(dofm(mdate))

* take out trends, demographics, etc.
gen lern = log(ern) 
qui reg lern c.age c.age#c.age i.sex i.race i.education i.ind i.occ seam i.year if ernsample==1
predict lern_res if e(sample)==1, res

* AR1 process
reg lern_res L.lern_res if spell==L.spell & lfstat==2 
predict eps_w if e(sample)==1, res
reg lern_res L.lern_res if spell==L.spell & lfstat==3 
predict eps_y if e(sample)==1, res
sum eps_?

* variance of growth
gen g_ern = D.lern if spell==L.spell & ernsample==1
sum g_ern if lfstat==2 & ernsample==1, d // paid-employment
sum g_ern if lfstat==3 & ernsample==1, d // self-employment

* variance of residual growth
gen g_ern_res = D.lern_res if spell==L.spell & ernsample==1
sum g_ern_res if lfstat==2 & ernsample==1, d // paid-employment
sum g_ern_res if lfstat==3 & ernsample==1, d // self-employment


** income change between spells

/*
* Mincer regressions conditional on status
xtreg l_ern c.age c.age#c.age i.sex i.race i.education i.ind i.occ seam i.year if p_only==1 & ern_trim==1, fe
predict fe_p, u
xtreg l_ern c.age c.age#c.age i.sex i.race i.education i.ind i.occ seam i.year if s_only==1 & ern_trim==1, fe
predict fe_s, u
xtreg l_ern c.age c.age#c.age i.sex i.race i.education i.ind i.occ seam i.year if ps_shift==1 & ern_trim==1, fe
predict fe_sp, u
xtreg l_ern c.age c.age#c.age i.sex i.race i.education i.ind i.occ seam i.year if sp_shift==1 & ern_trim==1, fe
predict fe_ps, u

* plot distribution of worker fixed effects ("productivity")
preserve
	collapse fe_? fe_??, by(id)
	kdensity fe_p , nograph generate(x_fe dens_p)
	kdensity fe_s , nograph generate(x_ff dens_s) at(x_fe)
	kdensity fe_sp, nograph generate(x_fg dens_sp) at(x_fe)
	kdensity fe_ps, nograph generate(x_fh dens_ps) at(x_fe)
	label var x_fe "worker fixed effect"
	label var dens_p "Always paid-employed"
	label var dens_s "Always self-employed"
	label var dens_ps "Shifters PS"
	label var dens_sp "Shifters SP"
	twoway line dens_p dens_s dens_sp dens_ps x_fe, title("Density of worker fixed effect by transition category")
	graph export ../plots/worker_fixed_effect.pdf, replace
restore
*/

* average labor earnings over spell
gen ernsample2 = lgthspell_month==ern_valid_spell & lgthspell_month>=12 
bys id spell: egen ernavgspell = mean(ern) if ernsample2==1
qui tsset

* earnings before and after direct transitions
foreach trans in SS PP PS SP { 	
	
	* average earnings before and after shift
	gen tmp = `trans'_trans==1 & L.ernsample==1 & ernsample==1
	gen ernavg`trans'bef = L.ernavgspell if tmp==1
	gen ernavg`trans'aft = ernavgspell if tmp==1
	drop tmp
	
	* summarize to get 45 degree line
	qui sum ernavg`trans'bef
	local xmin = r(min) 
	local xmax = r(max)
	
	* scatter data
	twoway scatter ernavg`trans'aft ernavg`trans'bef || function y=x, range(`xmin' `xmax') || , /// (lfit ernavg`trans'aft ernavg`trans'bef, estopts(nocons))
		xtitle("earnings before transition") ytitle("earnings after transition") ///
		note("2009 dollars/month. Averaged over spell. 45 degree line.") legend(off) ///
		title({bf:`trans'}, size(huge) ring(0) pos(1)) name(`trans', replace)
			
}

*/

*/



