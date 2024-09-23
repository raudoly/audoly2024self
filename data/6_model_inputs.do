* Compute model inputs from the data: moments targeted in
* estimation and model parameters directly estimated from
* the data.

clear all
set more off
cap log close
do globals

cap mkdir ${dir_bootstraps}

global wgt [aweight=lweight] // sample weights
					
* Sample weights variables in the data:
* lweight: longitudinal
* wpfinwgt: cross-sectional

use ${dir_samples}/selfemployed


** Moments targeted in estimation

* Transition rates
preserve
	collapse (sum) n? u? p? s?  ///
		sep pep employed unemployed ${wgt}, ///
		by(panel rotation mdate) 

	bys panel rotation (mdate): gen _up = up/unemp[_n-1] if _n>1
	bys panel rotation (mdate): gen _us = us/unemp[_n-1] if _n>1
	bys panel rotation (mdate): gen _sp = sp/sep[_n-1] if _n>1
	bys panel rotation (mdate): gen _ps = ps/pep[_n-1] if _n>1
	bys panel rotation (mdate): gen _pu = pu/pep[_n-1] if _n>1
	bys panel rotation (mdate): gen _su = su/sep[_n-1] if _n>1

	bys panel rotation (mdate): drop if _n==1
	
	drop ??
	ren _?? ??

	* average across rotation group/panel
	collapse ??, by(panel mdate)
	
	* average transition rates
	summ ??
	collapse ??
	
	export delimited ../model/dat/transition_rates, replace nolabel
restore

* Net liquid wealth distribution
preserve
	gen nlw_share_leq0 = nlw<=0 if srefmon==4 & lfstat>0 & nlw!=.
	collapse ///
		(mean) nlw_share_leq0 ///
		(p10) p10=nlw ///
		(p25) p25=nlw ///
		(p50) p50=nlw ///
		(p75) p75=nlw ///
		(p90) p90=nlw ///
		 if srefmon==4 & lfstat>0 ${wgt}, by(lfstat)
	export delimited ../model/dat/nlw_pctl, replace nolabel
	save ${dir_bootstraps}/main_nlw_pctl, replace // input to bootstrap
restore

* Liquid wealth distribution
preserve
	gen lqw_share_leq0 = lqw<=0 if srefmon==4 & lfstat>0 & lqw!=.
	collapse ///
		(mean) lqw_share_leq0 ///
		(p10) p10=lqw ///
		(p25) p25=lqw ///
		(p50) p50=lqw ///
		(p75) p75=lqw ///
		(p90) p90=lqw ///
		if srefmon==4 & lfstat>0 ${wgt}, by(lfstat)
	export delimited ../model/dat/lqw_pctl, replace nolabel
	save ${dir_bootstraps}/main_lqw_pctl, replace // input to bootstrap
restore


* Income distribution
preserve
	collapse ///
		(p10) p10=ern ///
		(p25) p25=ern ///
		(p50) p50=ern ///
		(p75) p75=ern ///
		(p90) p90=ern ///
		if ernvalid==1 ${wgt}, by(lfstat)
	export delimited ../model/dat/ern_pctl, replace nolabel
	save ${dir_bootstraps}/main_ern_pctl, replace // input to bootstrap
restore

// table lfs if ernvalid==1 ${wgt}, c(p10 ern p25 ern p50 ern p75 ern p90 ern)

* income distributions, starters out of unemployment
// foreach v of varlist us up {
// 	preserve
// 		keep if `v'==1
// 		collapse ///
// 			(p10) p10=ern ///
// 			(p25) p25=ern ///
// 			(p50) p50=ern ///
// 			(p75) p75=ern ///
// 			(p90) p90=ern ///
// 			if ernvalid==1 ${wgt}
// 		export delimited ../model/dat/ern_pctl_`v', replace nolabel
// 		save ${dir_bootstraps}/main_ern_pctl_`v', replace // input to bootstrap
// 	restore
// }

// table if ernvalid==1 & us==1 ${wgt}, c(p10 ern p25 ern p50 ern p75 ern p90 ern)
// table if ernvalid==1 & up==1 ${wgt}, c(p10 ern p25 ern p50 ern p75 ern p90 ern)

* Log-earnings stats
gen lnern = ln(ern) if ernvalid==1

preserve
	qui corr lnern L12.lnern if spell==L12.spell & lfstat==2 ${wgt}
	local rho_p = r(rho)
	qui corr lnern L12.lnern if spell==L12.spell & lfstat==3 ${wgt}
	local rho_s = r(rho)
	
	collapse (mean) avg=lnern (sd) std=lnern if lfstat>1 ${wgt}, by(lfstat)
	
	gen rho = .
	replace rho = `rho_p' if lfstat==2
	replace rho = `rho_s' if lfstat==3
		
	export delimited ../model/dat/lnern_stats, replace nolabel
restore

preserve
	collapse (mean) avg=lnern (sd) std=lnern if lfstat>1 ${wgt}, by(lfstat cluster_id)
	export delimited ../model/dat/lnern_cluster_stats, replace nolabel
restore


// table lfs ${wgt} if lfstat>1, c(p10 GR6 p25 GR6 p50 GR6 p75 GR6 p90 GR6)

* earning change with "voluntary" change of status
cap drop length_valid lnern_avgspell

bys id spell: egen length_valid = total(ernvalid)
bys id spell: egen lnern_avgspell = mean(lnern) if length_valid>=12

qui xtset

foreach v of varlist sp ps {
	preserve
		gen dlnern = lnern_avgspell - L.lnern_avgspell if `v'==1 
		keep if `v'==1
		collapse (mean) avg=dlnern (p50) p50=dlnern ${wgt}
		list
		export delimited ../model/dat/dlnern_`v', replace nolabel
	restore
}


* Destruction rate: cluster x labor form
qui xtset

reg pu i.cluster_id if L.lfstat==2 ${wgt}
reg su i.cluster_id if L.lfstat==3 ${wgt}

table cluster_id if L.lfstat==2 ${wgt}, stat(mean pu)
table cluster_id if L.lfstat==3 ${wgt}, stat(mean su)

table cluster_id if L.lfstat==2 ${wgt}, stat(mean ps)
table cluster_id if L.lfstat==3 ${wgt}, stat(mean sp)

table cluster_id if L.lfstat==1 ${wgt}, stat(mean up us)

preserve
	collapse (mean) pu if L.lfstat==2 ${wgt}, by(cluster_id)
	export delimited ../model/dat/pu_cluster, replace nolabel
restore

preserve
	collapse (mean) su if L.lfstat==3 ${wgt}, by(cluster_id)
	export delimited ../model/dat/su_cluster, replace nolabel
restore


** Model inputs drawn from data directly

* Number of individuals by cluster
preserve
	collapse (count) N=id if idindex==1, by(cluster_id)
	export delimited ../model/dat/cluster_cnt, replace nolabel
restore

* Median earnings by cluster 
preserve
	collapse (p50) ern if ernvalid==1 ${wgt}, by(cluster_id)
	export delimited ../model/dat/cluster_ern_all, replace nolabel
restore

table cluster_id, stat(p50 thtotinc) 

preserve
	collapse (p50) inc=thtotinc ${wgt}, by(cluster_id)
	export delimited ../model/dat/cluster_inc_all, replace nolabel
restore

* Bounds for asset grids
preserve
	keep if srefmon==4 & lfstat>0
	collapse (p20) amin=nlw (p90) amax=nlw ${wgt}, by(cluster_id)
	export delimited ../model/dat/cluster_nlw, replace nolabel
restore

preserve
	keep if srefmon==4 & lfstat>0
	collapse (p05) amin=lqw (p90) amax=lqw ${wgt}, by(cluster_id)
	export delimited ../model/dat/cluster_lqw, replace nolabel
restore


* Household income function
gen lninc = ln(thtotinc - thunemp) // UI payments are simulated in model
// cap drop sel? b? r2 r2_a N 

gen selU = .
gen selP = .
gen selS = .

gen b0 = .
gen b1 = .

gen r2 = .
gen r2_a = .
gen N = .

forv k = 1/4 {
	
	replace selU = cluster_id==`k' & lfstat==1 
	replace selP = cluster_id==`k' & lfstat==2 & ernvalid==1
	replace selS = cluster_id==`k' & lfstat==3 & ernvalid==1

	reg lninc if selU==1 ${wgt}		
	replace b0 = _b[_cons] if selU==1
	replace r2 = e(r2) if selU==1
	replace r2_a = e(r2_a) if selU==1 
	replace N = e(N) if selU==1

	reg lninc lnern if selP==1 ${wgt}
	replace b0 = _b[_cons] if selP==1
	replace b1 = _b[lnern] if selP==1
	replace r2 = e(r2) if selP==1
	replace r2_a = e(r2_a) if selP==1 
	replace N = e(N) if selP==1

	reg lninc lnern if selS==1 ${wgt}
	replace b0 = _b[_cons] if selS==1
	replace b1 = _b[lnern] if selS==1
	replace r2 = e(r2) if selS==1
	replace r2_a = e(r2_a) if selS==1 
	replace N = e(N) if selS==1

	preserve 
		keep if lfstat>0 & lfstat<.
		collapse b0 b1 r2 r2_a N, by(lfstat cluster_id)
		export delimited ../model/dat/inc_function, replace nolabel
		export excel ../tables/01_data.xlsx, sheet("_hh_inc_function",replace) first(var)
	restore

}


