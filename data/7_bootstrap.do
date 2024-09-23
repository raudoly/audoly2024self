* Bootstrap computation of data moments to get confidence interval.

clear all
set more off
cap log close
do globals

global nreps = 500		// number of bootstrap repetitions
global wgt [aweight=lweight] 	// sample weights

* Sample weights variables in the data:
* lweight: longitudinal
* wpfinwgt: cross-sectional

set seed 19610412 		// to replicate

***********************
** Bootstrap iterations

forv bsrep = 1/$nreps {

qui{

* Bootstrap samples
use ${dir_samples}/selfemployed, clear
bsample, cluster(id) strata(cluster_id) idcluster(bootstrapid)

* Declare panel for bootstrap sample
xtset, clear
xtset bootstrapid mdate 

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
	collapse ??
	
	* append to bootstrap data set
	gen bsrep = `bsrep'

	if `bsrep'>1 {
		append using ${dir_bootstraps}/transition_rates
	}

	save ${dir_bootstraps}/transition_rates, replace
	
restore

* Net liquid wealth distribution
preserve

	merge m:1 lfstat using ${dir_bootstraps}/main_nlw_pctl

	foreach p of varlist p?0 p?5 {
		gen nlw_`p'_ecdf_ = nlw<=`p' if srefmon==4 & lfstat>0 & nlw!=.
	}
	
	gen nlw_share_leq0_ = nlw<=0 if srefmon==4 & lfstat>0 & nlw!=.

	collapse (mean) nlw_p* nlw_share_leq0_ ///
		(p10) nlw_p10_pctl_=nlw ///
		(p25) nlw_p25_pctl_=nlw ///
		(p50) nlw_p50_pctl_=nlw ///
		(p75) nlw_p75_pctl_=nlw ///
		(p90) nlw_p90_pctl_=nlw ///
		if srefmon==4 & lfstat>0 ${wgt}, by(lfstat)
	
	gen tmp = 1
	reshape wide nlw_*, i(tmp) j(lfstat)
	drop tmp

	gen bsrep = `bsrep'
	if `bsrep'>1 {
		append using ${dir_bootstraps}/nlw_pctl
	}
	save ${dir_bootstraps}/nlw_pctl, replace 

restore

* Liquid wealth distribution
preserve

	merge m:1 lfstat using ${dir_bootstraps}/main_lqw_pctl

	foreach p of varlist p?0 p?5 {
		gen lqw_`p'_ecdf_ = lqw<=`p' if srefmon==4 & lfstat>0 & lqw!=.
	}
	
	gen lqw_share_leq0_ = lqw<=0 if srefmon==4 & lfstat>0 & lqw!=.


	collapse (mean) lqw_p* lqw_share_leq0_ ///
		(p10) lqw_p10_pctl_=lqw ///
		(p25) lqw_p25_pctl_=lqw ///
		(p50) lqw_p50_pctl_=lqw ///
		(p75) lqw_p75_pctl_=lqw ///
		(p90) lqw_p90_pctl_=lqw ///
		if srefmon==4 & lfstat>0 ${wgt}, by(lfstat)
	
	gen tmp = 1
	reshape wide lqw_*, i(tmp) j(lfstat)
	drop tmp

	gen bsrep = `bsrep'
	if `bsrep'>1 {
		append using ${dir_bootstraps}/lqw_pctl
	}
	save ${dir_bootstraps}/lqw_pctl, replace 

restore


* Earnings distribution
preserve
	
	collapse  ///
		(p10) ern_p10_pctl_ = ern ///
		(p25) ern_p25_pctl_ = ern ///
		(p50) ern_p50_pctl_ = ern ///
		(p75) ern_p75_pctl_ = ern ///
		(p90) ern_p90_pctl_ = ern ///
		if ernvalid==1 ${wgt}, by(lfstat)

	gen tmp = 1
	reshape wide ern_*, i(tmp) j(lfstat)
	drop tmp

	gen bsrep = `bsrep'
	if `bsrep'>1 {
		append using ${dir_bootstraps}/ern_pctl
	}
	save ${dir_bootstraps}/ern_pctl, replace 

restore

* Log-earnings stats
gen lnern = ln(ern) if ernvalid==1

preserve
	qui corr lnern L12.lnern if spell==L12.spell & lfstat==2 ${wgt}
	local rho_p = r(rho)
	qui corr lnern L12.lnern if spell==L12.spell & lfstat==3 ${wgt}
	local rho_s = r(rho)
	
	collapse (mean) lnern_avg_=lnern (sd) lnern_std_=lnern if lfstat>1 ${wgt}, by(lfstat)
	
	gen lnern_rho_ = .
	replace lnern_rho_ = `rho_p' if lfstat==2
	replace lnern_rho_ = `rho_s' if lfstat==3
	
	gen tmp = 1
	reshape wide lnern_*, i(tmp) j(lfstat)
	drop tmp
	
	gen bsrep = `bsrep'
	
	if `bsrep'>1 {
		append using ${dir_bootstraps}/lnern_stats
	}
	
	save ${dir_bootstraps}/lnern_stats, replace 

restore

preserve
	collapse (mean) lnern_avg_=lnern (sd) lnern_std_=lnern if lfstat>1 ${wgt}, by(lfstat cluster_id)
	
	reshape wide lnern_???_, i(cluster_id) j(lfstat)
	ren lnern_???_? lnern_???_?_
	gen tmp = 1
	reshape wide lnern_???_*, i(tmp) j(cluster_id)
	drop tmp
	
	gen bsrep = `bsrep'
	
	if `bsrep'>1 {
		append using ${dir_bootstraps}/lnern_cluster_stats
	}
	
	save ${dir_bootstraps}/lnern_cluster_stats, replace 

restore


* Earning change with "voluntary" change of status
cap drop length_valid lnern_avgspell

bys bootstrapid spell: egen length_valid = total(ernvalid)
bys bootstrapid spell: egen lnern_avgspell = mean(lnern) if length_valid>=12

qui xtset

foreach v of varlist sp ps {
	preserve
		
		gen dlnern = lnern_avgspell - L.lnern_avgspell if `v'==1 
		keep if `v'==1
		collapse (mean) dlnern_avg_`v'=dlnern (p50) dlnern_p50_`v'=dlnern ${wgt}
		
		gen bsrep = `bsrep'

		if `bsrep'>1 {
			append using ${dir_bootstraps}/dlnern_`v'
		}
		
		save ${dir_bootstraps}/dlnern_`v', replace 
	
	restore
}

* Earnings distribution in each worker class
// gen lern = ln(ern) if ernvalid==1 
//
// preserve
//
// 	collapse ///
// 		(p10) lern_p10_=lern ///
// 		(p25) lern_p25_=lern ///
// 		(p50) lern_p50_=lern ///
// 		(p75) lern_p75_=lern ///
// 		(p90) lern_p90_=lern ///
// 		if ernvalid==1 & lfstat>1 ${wgt}, by(classID lfstat)
//	
// 	reshape wide lern_p??_, i(classID) j(lfstat)
// 	ren lern_p??_? lern_p??_?_
// 	gen tmp = 1
// 	reshape wide lern_p??_*, i(tmp) j(classID)
// 	drop tmp
//	
// 	gen bsrep = `bsrep'
// 	if `bsrep'>1 {
// 		append using ${dir_bootstraps}/bootstrap_lern_class
// 	}
// 	save ${dir_bootstraps}/bootstrap_lern_class, replace 
//	
// restore


* Job/business destruction rates by cluster
xtset

preserve

	collapse (mean) pu_=pu if L.lfstat==2 ${wgt}, by(cluster_id)

	gen tmp = 1	
	reshape wide pu_, i(tmp) j(cluster_id) 
	drop tmp

	gen bsrep = `bsrep'

	if `bsrep'>1 {
		append using ${dir_bootstraps}/pu_cluster
	}
	
	save ${dir_bootstraps}/pu_cluster, replace 

restore

preserve

	collapse (mean) su_=su if L.lfstat==3 ${wgt}, by(cluster_id)

	gen tmp = 1	
	reshape wide su_, i(tmp) j(cluster_id) 
	drop tmp

	gen bsrep = `bsrep'
	if `bsrep'>1 {
		append using ${dir_bootstraps}/su_cluster
	}
	
	save ${dir_bootstraps}/su_cluster, replace 

restore


}

di "Done with bootstrap `bsrep'."	

}


** Put bootstraps for all moments together and export

use ${dir_bootstraps}/transition_rates, clear

merge 1:1 bsrep using ${dir_bootstraps}/nlw_pctl, nogen
merge 1:1 bsrep using ${dir_bootstraps}/lqw_pctl, nogen
merge 1:1 bsrep using ${dir_bootstraps}/ern_pctl, nogen
merge 1:1 bsrep using ${dir_bootstraps}/lnern_stats, nogen
merge 1:1 bsrep using ${dir_bootstraps}/lnern_cluster_stats, nogen
merge 1:1 bsrep using ${dir_bootstraps}/dlnern_ps, nogen
merge 1:1 bsrep using ${dir_bootstraps}/dlnern_sp, nogen
merge 1:1 bsrep using ${dir_bootstraps}/pu_cluster, nogen
merge 1:1 bsrep using ${dir_bootstraps}/su_cluster, nogen

drop bsrep

export delimited using ../model/dat/bootstrap_reps, replace nolabel

