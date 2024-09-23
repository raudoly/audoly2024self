* Create the following analysis samples:
* 1/ aggregate benchmarks: all panels, all observations
* 2/ main earners in each household
* 3/ self-employed

clear all
set more off
cap log close

do globals

cap mkdir ${root}/samples
cap mkdir ${root}/kmeans
cap mkdir ${root}/temp


******************************
** Aggregate benchmarks sample  

* Takes weekly data and creates data at monthly frequency. This is done by 
* keeping state in week 2 of each month (the first full week of the month), 
* similarly to the CPS.

* monthly data with job characteristics from weekly data
foreach pan of numlist 1996 2001 2004 2008 {
	
	* lf status based on second week of each month
	use "${root}/`pan'/dta/spellspan`pan'_weekly", clear
	keep if week==2 
	gen mdate = mofd(bweek)
	format mdate %tm
	tempfile lfstate
	save `lfstate'
			
	* monthly panel with main job characteristics
	use "${root}/`pan'/dta/core_`pan'", clear
	merge 1:1 panel lgtkey mdate using `lfstate', nogen
	
	* merge in assets variables
	merge m:1 panel ssuid epppnum wave using "${root}/`pan'/dta/assets_`pan'"
	drop if _merge==2 // drop using since not in sample
	drop _merge
	
	* deflate asset data to 2009 dollars
	foreach v of varlist lqw nlw niw uscdbt thhtnw thhtwlth {
		replace `v' = `v'*pcepi_defl 
	}

	compress
	save "${root}/`pan'/dta/spellspan`pan'_monthly", replace	
}


*************************
** Sample of main earners

* Main earners have i) reduced non-employment, ii) the highest share 
* of labor earnings over the survey, iii) report valid earnings. 

* select and stack panels
clear all

foreach pan of numlist 1996 2001 2004 2008 {
	append using "${root}/`pan'/dta/spellspan`pan'_monthly"
}

drop if lfstat==. // about a thousand obs.

* Indicator for monthly transitions
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

* Monthly spells
drop spell lgthspell
gen tmp = 0
bys id (mdate): replace tmp = 1 if _n==1
bys id (mdate): replace tmp = 1 if lfstat!=lfstat[_n-1] & _n>1
bys id (mdate): gen spell = sum(tmp)
bys id spell: gen lgthspell = _N
drop tmp

* Keep individual with largest assigned labor earnings in household over sample
bys panel ssuid shhadid epppnum: egen _indern = total(ern)  
bys panel ssuid shhadid: egen _hhern = total(ern)
bys panel ssuid shhadid: drop if _hhern==0 // nobody works in household
bys panel ssuid shhadid: gen _ernshr = _indern/_hhern
bys panel ssuid shhadid: egen _maxernshr = max(_ernshr) 
bys panel ssuid shhadid mdate: egen auxern = total((_ernshr<_maxernshr)*ern)

bys id: egen _select = max(_maxernshr==_ernshr) 
// keep if highest earners at any point in household 
// to deal with multiple households case

bys id (mdate): gen idindex = _n==1
tab panel _select if idindex==1, nol row
keep if _select==1
drop _* 

* Drop main earners with mostly non-employment history
bys id: egen _select = mean(lfstat==0)
replace _select = _select<.5
tab panel _select if idindex==1, nol row
keep if _select==1
drop _select

* Individuals with valid earnings 
_pctile ern if ern>0, nq(100)
gen ernvalid = ern>r(r1) & ern<r(r99)
bys id: egen _select = max(ernvalid)
tab panel _select if idindex==1, nol row
keep if _select==1
drop _select 

* Flag self-employed sample
bys id: egen self_sample = max(lfstat==3)
label define label_sample 0"never SE" 1"some SE", replace 
label values self_sample label_sample

* Incorporation status in self-employed sample 
bys id: egen _incorporated_sample = max(inc==1) if self_sample==1
bys id: egen _unincorporated_sample = max(inc==2) if self_sample==1

gen self_status = 0 if self_sample==1 

replace self_status = 1 if _unincorporated_sample==1 & _incorporated_sample==0 
replace self_status = 2 if _unincorporated_sample==0 & _incorporated_sample==1
replace self_status = 3 if _unincorporated_sample==1 & _incorporated_sample==1

label define label_status 0"No incorporation status" 1"Not incoporated" 2"Incorporated" 3"Both"
label values self_status label_status

tab self_status if idindex==1

* Further reduce education categories
gen _ed = . 
replace _ed = 1 if education<4
replace _ed = 2 if education>3 & education!=.
bys id: egen educ = max(_ed) // few ids with changing education level 

label def educ 1 "Not college graduate" 2 "At least college graduate"
label values educ educ 

* Main earner sample
drop _*
compress
qui xtset
save "${root}/samples/mainearner", replace


***********************
** Self-employed sample

* The estimation sample. Here I keep only individuals with
* at least a stint in self-employment over the sample period
* and who are always unincorporated when in self-employment

use "${root}/samples/mainearner", clear

* Drop individuals never self-employed
tab panel self_sample if idindex==1, nol row
keep if self_sample==1
drop self_sample

* Keep unincorporated self-employed
tab panel self_status if idindex==1, row
keep if self_status==1
drop self_status

* Discretize unobserved heterogeneity
frame copy default clustering
frame change clustering

* classification variables at individual level
pctile ern_pctl = ern if lfstat>1 & ernvalid==1, nquantile(10) genp(pctl)
export delimited pctl ern_pctl if pctl<. using "${root}/kmeans/ern_pctl.csv", replace

forv pctl = 10(10)90 {
	qui sum ern_pctl if pctl==`pctl'
	gen ernecdf_p`pctl' = ern<=r(mean) if lfstat>1 & ernvalid==1
}

gen lmattach = lfstat<2
collapse lmattach ernecdf_*, by(id)

export delimited using "${root}/kmeans/input_data.csv", replace

* Run clustering procedure [done in Matlab to try many random starting points] 
local matlab_options -nodisplay -nodesktop -singleCompThread -nosplash
!${matlab_command} `matlab_options' -r clustering

* Convert assignement to Stata for merge
import delimited ${root}/kmeans/sorted_clusters_4.csv, clear
save ${root}/kmeans/sorted_clusters_4, replace

import delimited ${root}/kmeans/assignment_4.csv, clear
merge m:1 cluster_id using ${root}/kmeans/sorted_clusters_4
drop _merge
drop cluster_id
ren sorted_cluster_id cluster_id
sort id
save ${root}/kmeans/assignment_4, replace

* Merge back cluster assignment
frame change default
frame drop clustering

merge m:1 id using ${root}/kmeans/assignment_4
drop _merge

* create class label
cap lab drop cluster_lab

lab define cluster_lab -1 "Missing"
lab define cluster_lab 1 "Low", add
lab define cluster_lab 2 "Medium-Low", add
lab define cluster_lab 3 "Medium-High", add
lab define cluster_lab 4 "High", add

// forv k = 1/4 {
// 	// qui summ ern if ernvalid==1 & classID==`k',d
// 	_pctile ern if ernvalid==1 & classID==`k' [pweight=lweight], p(50)
// 	local aux = strofreal(r(r1),"%9.0fc")
// 	lab define class_lab `k' "\$`aux'", add 
// }

lab var cluster_id "Worker cluster"
lab val cluster_id cluster_lab

* self-employed sample with cluster variable
drop _*
compress
qui xtset
save "${root}/samples/selfemployed", replace



/*

* The code below constructs two additional samples I no longer use: 
* - unemployment duration
* - self-employment entry


** Duration analysis sample

* stack weekly panels 
clear all
foreach pan of global panels {
	append using ${root}/`pan'/dta/spellspan`pan'_weekly
}

* edit transitions, new unemployment definition (should be done in prep_spells.do)
bys panel lgtkey (bweek): replace sutrans = 1 if _n>1 & sep[_n-1]==1 & unemployed==1  
bys panel lgtkey (bweek): replace putrans = 1 if _n>1 & pep[_n-1]==1 & unemployed==1 

* select obs with unemployment
bys panel lgtkey: egen sel = max(sutrans==1 | putrans==1)
keep if sel==1
drop sel

* create a continuous week index
sort bweek
gen wdate = 1 in 1
replace wdate = cond(bweek!=bweek[_n-1],wdate[_n-1]+1,wdate[_n-1]) if wdate==. 
gen mdate = mofd(bweek)
format mdate %tm
gen rhcalmn = month(bweek)
gen rhcalyr = year(bweek)
format rhcalyr %ty

* NB. I use the SIPP concept of week here. The data were expanded with the week
* per month concept in the SIPP. So these are not necessarily full 7-day weeks.

* merge in main sample
local covars state rhcalyr sex race married education age wave lqw* nlw* gaplength
merge m:1 panel lgtkey mdate using ${root}/samples/mainearner, keepusing(`covars')
drop if _merge!=3
drop _merge

* set panel
sort panel lgtkey 
egen id = group(panel lgtkey) 
xtset id wdate 

* drop spells with gaps
bys id spell: egen tmp = max(gaplength>0)
drop if tmp==1
drop tmp

* earmark censored spells (attrition or end of panel)
tempvar var1  var2
bys id: egen `var1' = max(wdate) 
gen `var2' = wdate==`var1' & unemployed & lgthspell<=50
bys id spell: egen has_censored = max(`var2')

* spells ending on seam
qui xtset
gen tmp = wave!=F.wave & spell!=F.spell
bys id spell: egen onseam = max(tmp)
drop tmp

* at least 13 weeks (~3 months) of employment history
qui xtset    \numberthis \label{eq:saving_s}

gen hist_ind = (sutrans==1|putrans==1) & L.lgthspell>=13
bys id spell: egen has_hist = max(hist_ind)
drop hist_ind

* occupation/industry in last spell
qui xtset
replace occ = L.occ if missing(occ) & (sutrans==1|putrans==1)
replace ind = L.ind if missing(ind) & (sutrans==1|putrans==1)

* asset info at start of spell 
foreach v of varlist lqw* nlw* {
	replace `v' = L.`v' if `v'==.  // cascade down last available assets
}

* indicator for spell origin
gen lfstatbef = .
replace lfstatbef = 1 if putrans==1
replace lfstatbef = 2 if sutrans==1
label define loss_type 1 "paid-" 2 "self-", replace
label values lfstatbef loss_type
label var lfstatbef "Previous employment"

* censor duration at 50 weeks
gen censored = 0
replace censored = 1 if lgthspell>50 & !missing(lgthspell) 
replace censored = 1 if has_censored==1
replace lgthspell = 50 if lgthspell>50 & !missing(lgthspell)

* unemployment duration panel
keep if putrans==1 | sutrans==1
stset lgthspell, failure(censored==0) // no id declared => spells treated independently
cap drop __00* 
compress
save ${root}/samples/duration, replace


** Self-employment entry

* Similar in spirit to Hurst Lusardi (2004). Use my sample and my definiton of 
* self-employment to look at whether probability of self-employment entry
* increases with wealth. Also experiment with reporting some business equity.
* Look at probability of entry from first asset topical module. 

use ${root}/samples/mainearner, clear 

* tag first asset topical module in each panel
gen spl = 0
gen bef = 0
gen aft = 0

foreach pan in 1996 2001 2004 {
	replace spl = 1 if panel==`pan' & wave==3 & srefmon==4
	replace bef = 1 if panel==`pan' & wave<=3 & spl==0
	replace aft = 1 if panel==`pan' & wave>3
}

replace spl = 1 if panel==2008 & wave==4 & srefmon==4
replace bef = 1 if panel==2008 & wave<=4 & spl==0
replace aft = 1 if panel==2008 & wave>4

* is self-employed or business owner
gen is_s = sep==1 					if spl==1
gen is_c = thhbeq!=0 & thhbeq!=.	if spl==1

* employment type history
bys id: egen been_u = max(unemployed|nonpart) if bef==1 | spl==1
	// could go back further in time with empl. history module...
bys id: egen been_s = max(sep) if bef==1 | spl==1 
bys id: egen been_c = max(thhbeq!=0 & thhbeq!=.) if bef==1 | spl==1  

* becomes self-employed
bys id: egen to_s = max(sep) if aft==1
bys id (mdate): replace to_s = to_s[_n+1] if spl==1 & id==id[_n+1]

* becomes business owner
bys id: egen to_c = max(thhbeq!=0 & thhbeq!=.) if aft==1
bys id (mdate): replace to_c = to_c[_n+1] if spl==1 & id==id[_n+1]

* sample to analyze entry into self-employment
keep if spl==1 & to_s!=. // currently self-employed excluded
keep panel state rhcalyr sex race married education age lqw* nlw* thearn ///
	thhtnw thhtwlth been_* ??_s ??_c
save ${root}/samples/selfentry, replace


*/
