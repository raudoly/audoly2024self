* Construct employment spells and assign labor form status to
* workers. This is a slight modification of FPV's script to
* separate employed  workers into paid-employed and
* self-employed. 

clear all
prog drop _all
set more off
pause on
do globals


* The following program ("buildspells") reconstitutes the
* sequence of job spells of workers, with start and end dates
* when observed. It takes the raw panel year as its only
* argument.
prog def buildspells
syntax anything(name=pan)

	qui{
	
	use ${root}/`pan'/dta/core_`pan'
	
	
	*** PREPARE DATA TO FIND SPELLS
	
	* recode missing dates for consistency and convert to Stata format
	foreach dv of varlist t*date* {
		replace `dv' = . if `dv'<0
		gen yy = floor(`dv'/10000)
		gen mm = floor((`dv' - 10000*yy)/100)
		gen dd = floor(`dv' - 10000*yy - 100*mm)
		
		replace dd = 28 if mm==02 & dd>=29
		replace dd = 30 if dd==31 & (mm==4 | mm==6 | mm==9 | mm==11)
			
		drop `dv'
		gen double `dv'_r = mdy(mm,dd,yy)
		format `dv'_r %td
			
		drop yy mm dd
	}
		
	* create first and last day of current (reference) month
	* to do so, move all reference calendar months one month ahead into new variables mm and yy, 
	* so the first day of mm and yy is the last day of the reference calendar month
	tempvar mm yy
	gen `mm' = rhcalmn + 1 if rhcalmn<=11
	replace `mm' = 1 if rhcalmn==12
	gen `yy' = rhcalyr if rhcalmn<=11
	replace `yy' = rhcalyr+1 if rhcalmn==12
		
	gen double bmonth = mdy(rhcalmn,01,rhcalyr) 		// date of first day of current month
	gen double emonth = mdy(`mm',01,`yy') - 1		// date of last day of current month
	format bmonth emonth %td
			
	* fill in some missing end dates: sometimes eeno1 turns into eeno2 and only tejdate2 is recorded (or vice-versa), and same for business owners
	bys lgtkey (bmonth): replace tejdate1 = tejdate2[_n+1] if (tejdate1==. | tejdate1<tejdate2[_n+1]) & eeno1==eeno2[_n+1] & tejdate2[_n+1]<.
	bys lgtkey (bmonth): replace tejdate2 = tejdate1[_n+1] if (tejdate2==. | tejdate2<tejdate1[_n+1]) & eeno2==eeno1[_n+1] & tejdate1[_n+1]<.
	bys lgtkey (bmonth): replace tebdate1 = tebdate2[_n+1] if (tebdate1==. | tebdate1<tebdate2[_n+1]) & ebno1==ebno2[_n+1] & tebdate2[_n+1]<.
	bys lgtkey (bmonth): replace tebdate2 = tebdate1[_n+1] if (tebdate2==. | tebdate2<tebdate1[_n+1]) & ebno2==ebno1[_n+1] & tebdate1[_n+1]<.
	
	forv n = 1/2	{ 
		recode tejdate`n' . = -10
		recode tebdate`n' . = -10
		bys lgtkey eeno`n' (tejdate`n'): replace tejdate`n'= tejdate`n'[_N]
		bys lgtkey ebno`n' (tebdate`n'): replace tebdate`n'= tebdate`n'[_N]
		recode tejdate`n' -10 = .
		recode tebdate`n' -10 = .
	}

	* adjust labor earnings from self-employment
	if "`pan'"=="2004" | "`pan'"=="2008" { 		 
		replace tbmsum1 = tbmsum1 + tprftb1
		replace tbmsum2 = tbmsum2 + tprftb2
	}
	
	* NB. In 1996 and 2001, profits should already be
	* part of tbmsum*. The  question was rephrased
	* starting in 2004. There is a lot of uncertainty
	* around how comparable these earnings are in
	* practice.
	
	* See: https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/2004w1-Business-Income.html
	
	
	*** LABOR FORCE STATUS
	
	noi di "Constructing weekly LF status and transitions..."
	
	* keep variables necessary for consruction of spells and expand panel
	keep lgtkey eppintvw bmonth eeno* ebno* t*date* rmwk* rwk* panel postgap ///
		ejbind* tempsiz* tjbocc* tbsind* tbsocc* t*msum* eincpb* tempb*
		 
		
	expand rwksperm
	
	bys lgtkey bmonth: gen week = _n
	gen bweek = bmonth + (week-1)*7
	format bweek %td
	
	* labor force status
	gen lfstat = .
	
	forv w = 1/5 {
		replace lfstat = rwkesr`w' if week==`w'
	}
	
	lab val lfstat rwkesr1l
	drop rwkesr*
	
	gen employed = (lfstat==1 | lfstat==2)
	gen unemployed = (lfstat==3 | lfstat==4)
	gen nonpart = 1 - employed - unemployed
	
	* drop one week spells of non-employment
	bys lgtkey (bweek): replace employed = 1 if employed==0 & employed[_n-1]==1 & employed[_n+1]==1
	
	replace unemployed = 0 if employed==1
	replace nonpart = 0 if employed==1
	
	
	*** CLASSIFY EMPLOYED AS PAID- OR SELF-EMPLOYED
	
	foreach v of newlist pep sep ern ind occ sze inc {
		gen `v' = .
	}
	
	replace pep = 0 if employed==0 		
	replace sep = 0 if employed==0 	

	tempvar mnjb 
	gen `mnjb' = .
	
	
	** ROUND 1: person only has paid-employed or self-employed jobs AND job ids are valid AND dates are valid
	
	* jobs with valid dates and identifiers
	gen validdatej1 = employed==1 & eeno1>0 & (tsjdate1<=bweek+6 | tsjdate1==.) & (tejdate1>=bweek | tejdate1==.)
	gen validdateb1	= employed==1 & ebno1>0 & (tsbdate1<=bweek+6 | tsbdate1==.) & (tebdate1>=bweek | tebdate1==.) 
	gen validdatej2	= employed==1 & eeno2>0 & (tsjdate2<=bweek+6 | tsjdate2==.) & (tejdate2>=bweek | tejdate2==.)
	gen validdateb2 = employed==1 & ebno2>0 & (tsbdate2<=bweek+6 | tsbdate2==.) & (tebdate2>=bweek | tebdate2==.)
	
	* person is paid-employed
	replace `mnjb' = (validdatej1 | validdatej2) & !validdateb1 & !validdateb2
	replace pep = 1 if `mnjb'==1
	replace sep = 0 if `mnjb'==1
	replace ern = tpmsum1 + tpmsum2 if `mnjb'==1
	 
	* person is self-employed
	replace `mnjb' = (validdateb1|validdateb2) & !validdatej1 & !validdatej2
	replace pep = 0 if `mnjb'==1
	replace sep = 1 if `mnjb'==1
	replace ern = tbmsum1 + tbmsum2 if `mnjb'==1
	
	* diagnostic
	count if employed==1
	local den = r(N)
	count if employed==1 & pep==.
	local num = r(N)
	noi di "ROUND 1: employed status is valid for " 100*(1 - `num'/`den') " percent of observations with employed==1"

	
	** ROUND 2: person only has paid-employed or self-employed jobs AND job ids are valid 
	
	* person is paid-employed
	replace `mnjb' = employed==1 & pep==. & (eeno1>0|eeno2>0) & ebno1<1 & ebno2<1
	replace pep = 1 if `mnjb'==1
	replace sep = 0 if `mnjb'==1
	replace ern = tpmsum1 + tpmsum2 if `mnjb'==1
	
	* person is self-employed
	replace `mnjb' = employed==1 & pep==. & (ebno1>0|ebno2>0) & eeno1<1 & eeno2<1
	replace pep = 0 if `mnjb'==1
	replace sep = 1 if `mnjb'==1
	replace ern = tbmsum1 + tbmsum2 if `mnjb'==1
	
	* diagnostic
	count if employed==1
	local den = r(N)
	count if employed==1 & pep==.
	local num = r(N)
	noi di "ROUND 2: employed status is valid for " 100*(1-`num'/`den') " percent of observations with employed==1"
	
	
	** ROUND 3: person has both paid-employed and self-employed job, assign status with largest earnings
	
	* isolate spells with both paid- and self-employment
	sort lgtkey bweek
	gen both = employed==1 & pep==. & (eeno1>0|eeno2>0) & (ebno1>0|ebno2>0)
	bys lgtkey (bweek): gen indboth	= 1 if both==1 & both[_n-1]==0
	bys lgtkey (bweek): gen spellboth = sum(indboth) if both==1
	
	* compute earnings in each state over the spell
	bys lgtkey spellboth: egen ernpep = total((tpmsum1+tpmsum2)/rwksperm) if both==1
	bys lgtkey spellboth: egen ernsep = total((tbmsum1+tbmsum2)/rwksperm) if both==1
	
	* person is paid-employed
	replace `mnjb' = both==1 & pep==. & ernpep>=ernsep
	replace pep = 1 if `mnjb'==1
	replace sep = 0 if `mnjb'==1
	replace ern = tpmsum1 + tpmsum2 if `mnjb'==1
	
	* person is self-employed
	replace `mnjb' = both==1 & pep==. & ernpep<ernsep
	replace pep = 0 if `mnjb'==1
	replace sep = 1 if `mnjb'==1
	replace ern = tbmsum1 + tbmsum2 if `mnjb'==1
	
	* diagnostic
	count if employed==1
	local den = r(N)
	count if employed==1 & pep==.
	local num = r(N)
	noi di "ROUND 3: employed status is valid for " 100*(1-`num'/`den') " percent of observations with employed==1"

	* clean up
	drop indboth spellboth validdate*
	
	* NB. The few employment spells with no paid- or
	* self- status do not have information about
	* jobs/businesses. The respondents simply declare
	* themselves "employed". Their earnings and
	* employment status are left  missing.

	
	*** TRANSITIONS
	
	* construct transitions
	bys lgtkey (bweek): gen uptrans = unemployed[_n-1]*pep if _n>1
	bys lgtkey (bweek): gen ustrans = unemployed[_n-1]*sep if _n>1
	bys lgtkey (bweek): gen putrans = unemployed*pep[_n-1] if _n>1
	bys lgtkey (bweek): gen sutrans = unemployed*sep[_n-1] if _n>1	
	bys lgtkey (bweek): gen nptrans = nonpart[_n-1]*pep if _n>1
	bys lgtkey (bweek): gen nstrans = nonpart[_n-1]*sep if _n>1
	bys lgtkey (bweek): gen pntrans = nonpart*pep[_n-1] if _n>1
	bys lgtkey (bweek): gen sntrans = nonpart*sep[_n-1] if _n>1
	bys lgtkey (bweek): gen pstrans = sep*pep[_n-1] if _n>1
	bys lgtkey (bweek): gen sptrans = pep*sep[_n-1] if _n>1

	* Create spells indicators
	* Note. Not using transitions from unemployment to nonemployment. 
	tempvar trans 
	
	bys lgtkey (bweek): gen `trans' = uptrans==1 ///
		| ustrans==1 ///
		| putrans==1 ///
		| sutrans==1 ///
		| nptrans==1 ///
		| nstrans==1 ///
		| pntrans==1 ///
		| sntrans==1 ///
		| pstrans==1 ///
		| sptrans==1
	
	bys lgtkey (bweek): replace `trans' = 1 if _n==1
	bys lgtkey (bweek): gen spell = sum(`trans')
	bys lgtkey spell: gen lgthspell = _N
	
	* Characteristics of paid-employment spells
	forv i = 1/2 {
		bys lgtkey spell: egen ernspell`i' = total(tpmsum`i') if pep==1									
	}
	
	replace ind = ejbind1 	if pep==1 & ernspell1>=ernspell2
	replace ind = ejbind2 	if pep==1 & ernspell1<ernspell2
	replace occ = tjbocc1 	if pep==1 & ernspell1>=ernspell2
	replace occ = tjbocc2 	if pep==1 & ernspell1<ernspell2
	replace sze = tempsiz1 	if pep==1 & ernspell1>=ernspell2
	replace sze = tempsiz2 	if pep==1 & ernspell1<ernspell2
	replace inc = -1 // not valid for paid-employment spells
	
	drop ernspell?
	
	* Characteristics of self-employment spells
	forv i = 1/2 {
		bys lgtkey spell: egen ernspell`i' = total(tbmsum`i') if sep==1									
	}
	
	replace ind = tbsind1 	if sep==1 & ernspell1>=ernspell2
	replace ind = tbsind2 	if sep==1 & ernspell1<ernspell2
	replace occ = tbsocc1 	if sep==1 & ernspell1>=ernspell2
	replace occ = tbsocc2 	if sep==1 & ernspell1<ernspell2
	replace sze = tempb1 	if sep==1 & ernspell1>=ernspell2
	replace sze = tempb2 	if sep==1 & ernspell1<ernspell2
	replace inc = eincpb1 	if sep==1 & ernspell1>=ernspell2
	replace inc = eincpb2 	if sep==1 & ernspell1<ernspell2

	drop ernspell?
	
	* Clean up characteristics
	foreach v of varlist ind occ {
		bys lgtkey spell (`v'): replace `v' = `v'[1] if `v'==. & (pep==1|sep==1)
	}
	
	
	*** UNEMPLOYMENT SPELL DEFINITIONS
	
	tempvar nonemp
	gen `nonemp' = unemployed==1 | nonpart==1
	
	* Keep standard CPS definition
	gen unemployed_cps = unemployed 
	
	* Baseline: Unemployed if searches at any point during spell (see Chetty 2008)
	bys lgtkey spell: egen search_for_job = max(unemployed) if `nonemp'==1
	replace unemployed = 1 if `nonemp'==1 & lgthspell<=50 & search_for_job==1 
	replace nonpart = 0 if `nonemp'==1 & unemployed==1
	
	* Alternative: Unemployed if individual no longer unemployed after 
	* 50 weeks, even if did not report searching b/c some workers might
	* associate unemployment with benefits
	gen unemployed_no_search = unemployed
	
	bys lgtkey (bweek): gen from_e = pntrans==1 | sntrans==1 | putrans==1 | sutrans==1
	bys lgtkey (bweek): gen to_e = nptrans[_n+1]==1 | nstrans[_n+1]==1 | uptrans[_n+1]==1 | ustrans[_n+1]==1
	
	bys lgtkey spell: egen emp_bef = max(from_e) if `nonemp'==1
	bys lgtkey spell: egen emp_aft = max(to_e) if `nonemp'==1
	
	replace unemployed_no_search = 1 if `nonemp'==1 & lgthspell<=50 & emp_aft==1 & emp_bef==1
	
	* clean up
	drop search_for_job emp_aft emp_bef from_e to_e
	
	
	*** SAVE WEEKLY SPELLS PANEL
	
	sort lgtkey bweek

	* labor force status variable
	drop lfstat
	
	gen lfstat = 0 if nonpart==1
	
	replace lfstat = 1 if unemployed==1 
	replace lfstat = 2 if employed==1 & pep==1
	replace lfstat = 3 if employed==1 & sep==1
	
	label var lfstat "labor force status"
	label define lfstat 0 "non-participation" 1 "unemployed" 2 "paid-employed" 3 "self-employed" 
	label values lfstat lfstat
	
	* labelling
	lab var employed "employed"
	lab var unemployed "unemployed"
	lab var nonpart "not in labor force"
	lab var occ "occupation"
	lab var ind "industry"
	lab var ern "monthly earnings in main labor form"
	lab var sze "employment at job/business"
	lab var inc "incorporation status of business"
	lab var lgthspell "spell duration (weeks)"
		
	* drop variables not needed and save
	drop eppintvw rmwkwjb rmwksab rmwklkg rwksperm eeno? tpmsum? ebno? tbmsum? ///
		tbsind? postgap ejbind? tjbocc? tbsocc? eincpb* tempb* tempsiz*
		
	cap drop __00*
	
	compress
	save $root/`pan'/dta/spellspan`pan'_weekly.dta, replace
	
	}
	
end

* Execute program for panels 1996, 2001, 2004, 2008.

cap log cl
log using logfiles/prep_spells.txt, text replace

buildspells 1996
buildspells 2001
buildspells 2004
buildspells 2008

log close

