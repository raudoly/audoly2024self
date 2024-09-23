* Prepare monthly panels:

* - First round of sample selection.
* - Recode/harmonize variables of interest.
* - Liquid assets definitions.

clear
cap log close
set more off
do globals.do

log using logfiles/prep_panels.txt, text replace

qui{


*** CORE PANELS ****************************
foreach pan of numlist 1996 2001 2004 2008 {

use ${root}/`pan'/dta/extract_core_`pan', clear

noi disp ""
noi disp ""
noi disp "CORE PANEL `pan'"
noi disp ""
noi tab wave
noi tab wave rotation, cell

** sample selection, first round

* drop children under 15 during interview
drop if eppintvw==5

* further sample selection based on age
tempvar agemax selec obscnt
bys lgtkey: egen `agemax' = max(tage)
bys lgtkey: gen `obscnt' = _n
gen `selec' = `agemax'>=25 & `agemax'<=60
noi tab `selec' if `obscnt'==1
keep if `selec'

** Attrition and gaps in survey 

* gaps
bys lgtkey (mdate): gen gaplength = max(wave-wave[_n-1]-1,0)
bys lgtkey (mdate): replace gaplength	= 0 if _n==1
bys lgtkey (mdate): gen postgap = sum(gaplength>0)
egen maxgaplength = max(gaplength), by(lgtkey)
noi tab maxgaplength if `obscnt'==1

* attrition
qui su wave 
local maxwave = r(max) 				// number of waves in this panel 
bys lgtkey (wave): gen lastwave	= wave[_N] 	// number of waves completed by the individual
gen attrite = lastwave<`maxwave' 		// indicator of right-censored record
 
if "`pan'"=="2004" {
	replace attrite = 0 if lastwave==8 // 04 panel cut for budget reasons, not genuine attrition
}
if "`pan'"=="2008" {
	replace attrite = 0 if lastwave==15 // something fishy happening in last wave (w 16) of 08 panel
}

noi tab attrite if `obscnt'==1

** earned income variables

* merge in cpi deflators
noi merge m:1 mdate using pcepi, keepusing(pcepi_defl)
drop if _merge<3
drop _merge

* deflate 
foreach v of varlist t*sum* tpearn th* {
	replace `v' = `v'*pcepi_defl
}

* create monthly business profits variable 
if "`pan'"=="2004" | "`pan'"=="2008" {
	gen weeksemp = 0
	forv i = 1/5 {
		replace weeksemp = weeksemp + (rwkesr`i'>0 & rwkesr`i'<4) // number of weeks person employed in each month
	}
	bys lgtkey wave: egen weeksempwave = total(weeksemp) // total number of weeks in employment in wave
	foreach v of varlist tprftb? {
		replace `v' = `v'*weeksemp/weeksempwave
		replace `v' = `v'*pcepi_defl							
	}
	drop weeksemp*
}

* NB: See the two following notes on computation of business earnings:
* https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/2004w1-Business-Income.html
* https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/core_notes_2008-General-User-Note.html	
		
** fix, harmonize some key demographic, labor force variables

* recode industry (reduces ejbind* to the same 15-group format as tbsind*)
if "`pan'"=="1996" | "`pan'"=="2001" {
	scalar Cencode90 = 1
	scalar Cencode00 = 0
}

if "`pan'"=="2004" | "`pan'"=="2008" {
	scalar Cencode90 = 0
	scalar Cencode00 = 1
}

rename ejbind1 ind
do consistent_major_industries_SIPP
rename mjrind ejbind1
drop ind

rename ejbind2 ind
do consistent_major_industries_SIPP
rename mjrind ejbind2
drop ind

* recode not in universe to missing for few jobs with no industry
foreach iv of varlist *ind1 *ind2 { 
	recode `iv' (-1=.)
}

* recode occupations (this uses outside do-files REMAPJOB and occ_create)
if "`pan'"=="1996" | "`pan'"=="2001" {
	scalar Cencode80 = 1
	scalar Cencode00 = 0
}

if "`pan'"=="2004" | "`pan'"=="2008" {
	scalar Cencode80 = 0
	scalar Cencode00 = 1
}

rename tjbocc1 ocsrc
if "`pan'"=="2004" | "`pan'"=="2008" {
	replace ocsrc = ocsrc/10
}
do REMAPJOB_SIPP_modified
do occ_create_SIPP_modified
rename ocdest_m tjbocc1
drop ocsrc ocdest

rename tjbocc2 ocsrc
if "`pan'"=="2004" | "`pan'"=="2008"	{
	replace ocsrc = ocsrc/10
	}
do REMAPJOB_SIPP_modified
do occ_create_SIPP_modified
rename ocdest_m tjbocc2
drop ocsrc ocdest

rename tbsocc1 ocsrc
if "`pan'"=="2004" | "`pan'"=="2008"{
	replace ocsrc = ocsrc/10
}
do REMAPJOB_SIPP_modified
do occ_create_SIPP_modified
rename ocdest_m tbsocc1
drop ocsrc ocdest

rename tbsocc2 ocsrc
if "`pan'"=="2004" | "`pan'"=="2008" {
	replace ocsrc = ocsrc/10
}
do REMAPJOB_SIPP_modified
do occ_create_SIPP_modified
rename ocdest_m tbsocc2
drop ocsrc ocdest

* further collapse number of categories
foreach ov of varlist t*occ* {
	recode `ov' (1/16=1) (17/36=2) (37/45=3) (46/50=4) (51/63=5) (64/79=6) 
}

* recode education
recode eeducate (-1/38 = 1) (39=2) (40=3) (41/44=4) (45/50=5)
rename eeducate education
label define educ_cat 1 "less than HS" 2 "HS graduate" 3 "some college" 4 "college graduate" 5 "post-graduate"
label values education educ_cat
noi tab education if `obscnt'==1

* recode race
recode erace (1=0)(2/4=1) // white vs non-white to cut number of categories
rename erace race
label define race_cat 0 "white" 1 "non-white"
label values race race_cat
noi tab race if `obscnt'==1

* recode gender 
rename esex sex
recode sex (1=0) (2=1)
label define gender 0 "man" 1 "woman"
label values sex gender
noi tab sex if `obscnt'==1

* recode marital status
rename ems married
recode married (1/2=1) (3/6=0) // married vs non-married
label define ms 0 "not married" 1 "married"
label values married ms
noi tab married if `obscnt'==1

* harmonize state codes
rename tfipsst state
recode state (23 50=61) (38 46 56=62) // tfipsst clusters (ME,VT) and (ND,SD,WY) together in some years, not others 

* some additional renaming
rename tage age

cap drop __00*
compress
save ${root}/`pan'/dta/core_`pan', replace

}



*** ASSET PANELS ***************************
foreach pan of numlist 1996 2001 2004 2008 {

use ${root}/`pan'/dta/extract_assets_`pan', clear

noi disp ""
noi disp "ASSET PANEL `pan':"
noi tab wave
noi tab wave rotation, cell

* attrition in asset topical modules
qui tab wave
local maxwave = r(r) 					// number of waves in this panel 
bys ssuid epppnum (wave): gen _nwave = _N 		// number of waves completed by the individual
gen attrite = _nwave<`maxwave' 				// indicator of right-censored record 
bys ssuid epppnum (wave): gen _first = _n==1
noi tab attrite if _first==1
drop _*

* pension assets missing for 1996 panel
if `pan'==1996 { 
	bys wave ssuid shhadid: egen thhthrif = total(taltb)
	drop taltb
}

* harmonize unsecured debt variable
if  `pan'<2008 { //
	ren rhhuscbt uscdbt
} 
else {
	ren thhuscbt uscdbt
}

drop if eppintvw==5

* illiquid wealth
gen niw = thhtheq + thhore +  thhvehcl + thhbeq

* pension wealth
gen npw = thhira + thhthrif

* liquid wealth
gen lqw = thhtwlth - niw - npw   
gen nlw = thhtnw - niw - npw 

* NB. Chetty's (2008) definition (what I understand from the text, 
* could not find definition in his do-files). People at the Census
* Bureau seem to agree with it

label var lqw "Wealth excl. business, home, vehicle equity, and pension wealth"
label var nlw "Net worth excl. business, home, vehicle equity, and pension wealth"
label var niw "Net business, home, vehicle equity"
label var npw "Pension wealth: IRA, 401K, etc."
label var uscdbt "Unsecured debt"

compress
save ${root}/`pan'/dta/assets_`pan', replace

}


}

log close
