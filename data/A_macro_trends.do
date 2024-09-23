* Validation: Labor market aggregates in the SIPP compared to BLS.

clear all
set more off
do globals

global figfmt png
global wgt [pweight=wpfinwgt] // sampling weights
global variables panel mdate unemp* sep pep lweight wpfinwgt 

* Download BLS data 
local fred_key ce9cb881e57e85672f27ccadae6cda4c
local series LNU02048984 LNU02027714 LNU03000000 LNU02000000

set fredkey `fred_key'
import fred `series', daterange(1996-01-01 2019-12-31) clear

gen s_cps = (LNU02048984 + LNU02027714)/LNU02000000
gen u_cps = LNU03000000/(LNU03000000 + LNU02000000)

gen mdate = mofd(daten)
format mdate %tm

keep mdate s_cps u_cps

save cps.dta, replace

* all monthly panels  
clear all

foreach pan of numlist 1996 2001 2004 2008 { 
	append using ${root}/`pan'/dta/spellspan`pan'_monthly, keep(${variables})
}

* Note: BLS series for incorporated self-employed starts in 2000. So there
* is no clear equivalent to my definition of self-employment (inc + uninc)
* before then.

* month level data and bring in BLS
collapse (sum) unemployed* sep pep ${wgt}, by(panel mdate) 
sort panel mdate

duplicates drop mdate, force // slight overlap between 2001 and 2004 panel

merge 1:1 mdate using cps, keepusing(u_cps s_cps) 
drop if _merge==2
tsset mdate

* benchmark variables
gen u_sipp = unemployed/(unemployed + sep + pep)
gen s_sipp = sep/(sep + pep)

gen u_sipp_nosearch = unemployed_no_search/(unemployed_no_search + pep + sep)
gen u_sipp_cps = unemployed_cps/(unemployed_cps + pep + sep)

* separate series for each panel
foreach pan of numlist 1996 2001 2004 2008 {
	
	foreach v of varlist u_sipp s_sipp {
		gen `v'_`pan' = `v' if panel==`pan'
		label var `v'_`pan' "SIPP"
	}
	
	gen u_sipp_nosearch_`pan' = u_sipp_nosearch if panel==`pan'
	label var u_sipp_nosearch_`pan' "SIPP - No search"
	
	gen u_sipp_cps_`pan' = u_sipp_cps if panel==`pan'
	label var u_sipp_cps_`pan' "SIPP - CPS"
	
}

label var u_cps "CPS"
label var s_cps "CPS"

* plots
tsline u_cps u_sipp_????, ///
	lcolor(stblue stred stred stred stred) ///
	xtitle("") ytitle("Unemployment rate") ///
	tlabel(,format(%tmCY)) ///
	ylabel(0.00(0.02)0.12) ///
	legend(order(1 2))  

graph export ../plots/benchmark_U.${figfmt}, replace

tsline u_cps u_sipp_???? u_sipp_nosearch_???? u_sipp_cps_????, ///
	lcolor( stblue ///
		stred stred stred stred ///
		stgreen stgreen stgreen stgreen ///
		styellow styellow styellow styellow) ///
	xtitle("") ytitle("Unemployment rate") ///
	tlabel(,format(%tmCY)) ///
	ylabel(0.00(0.02)0.12) ///
	legend(order(1 2 6 10))  
	
tsline s_cps s_sipp_????, ///
	lcolor(stblue stred stred stred stred) ///
	xtitle("") ytitle("Self-employment rate") ///
	tlabel(,format(%tmCY)) ///
	ylabel(0.08(0.02)0.16) ///
	legend(order(1 2)) 

graph export ../plots/benchmark_S.${figfmt}, replace

rm cps.dta
	



