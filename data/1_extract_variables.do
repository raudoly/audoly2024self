* Extract relevant variables from raw data:
* 1/ a subset of all core waves to determine employment spells
* 2/ all asset data from the appropriate topical modules 

clear
set more off
do globals

qui{

foreach pan of numlist 1996 2001 2004 2008 { 

** define locals to deal with change of names and number of waves in each panel

if `pan'==1996 {
	
	local core_wave_name sip96w 
	local topi_wave_name sip96t
	local core_wave_numl 1/12
	local topi_wave_numl 3(3)12
	local weight_data sip96lw
	local weight_var lgtpnlwt
}
else if `pan'==2001 {

	local core_wave_name sip01w
	local topi_wave_name sip01t
	local core_wave_numl 1/9
	local topi_wave_numl 3(3)9
	local weight_data sip01lw
	local weight_var lgtpnwt3
}
else if `pan'==2004 {
	local core_wave_name sip04w
	local topi_wave_name sip04t
	local core_wave_numl 1/12
	local topi_wave_numl 3(3)6
	local weight_data sip04lw    
	local weight_var lgtpnwt4	
}
else {
	local core_wave_name sippl08puw
	local topi_wave_name sippp08putm
	local core_wave_numl 1/16
	local topi_wave_numl 4(3)10
	local weight_data lgtwgt2008w16 
	local weight_var lgtpn5wt
}


cd ${root}/`pan'/dta


** extract data from core waves

* variables to extract
#delimit ;
local var_sel
lgtkey
ssuid
epppnum 
rhcalyr 
rhcalmn
eentaid 
shhadid
eoutcome
rhcal*  
srefmon 
swave 
spanel
srotaton  
tage 
esex 
erace 
eeducate 
eclwrk* 
eeno* 
ebno* 
eemploc*
ejbind* 
tjbocc* 
tbsind* 
tbsocc* 
ejobcntr
ebuscntr
ersend*
erendb* 
estlemp* 
eunion*  
tempall* 
tempsiz* 
eppintvw 
wpfinwgt 
ems 
epdjbthn 
ersnowrk 
rnotake 
rwkesr* 
rmwklkg 
elkwrk 
*jdate* 
*bdate* 
arsend* 
t?msum?
tpearn 
apmsum* 
ejbhrs?
ehrsbs?
rwksperm 
rmwkwjb 
rmwksab 
epayhr* 
tpyrate* 
tmovrflg 
tfipsst 
*ptwrk 
*occtim* 
rpyper* 
ebiznow?
ehprtb?
eslryb*
eincpb?
tempb?
egrosb?
egrssb?
tprftb?
wpfinwgt
er??
er???
ehimth
ecrmth
ecdmth
thtotinc
thearn
thprpinc
thtrninc
thothinc
thunemp
ehprtb?
epartb??
euectyp5
estlemp*
ebiznow*
; 
#delimit cr


clear all

forv wave = `core_wave_numl' {
	if `pan'==1996 { // some variables not in 1996 panel
		append using "`core_wave_name'`wave'.dta"
	}
	else {
		append using "`core_wave_name'`wave'.dta", keep(`var_sel')
	}
}

if `pan'==1996 {
	tempvar key 
	egen `key' = group(ssuid epppnum) 	// generate individual identifier missing in 1996
	gen lgtkey = string(`key',"%08.0f")
	gen tmovrflg = . 			// variable missing in 1996 panel
	keep `var_sel'
}

rename (swave spanel srotaton) (wave panel rotation)

* merge in longitudinal weights
sort ssuid epppnum
noi merge m:1 ssuid epppnum using "`weight_data'", keepusing(`weight_var')
drop if _merge<3
drop _merge
rename `weight_var' lweight // longitudinal weight for whole panel

* save dataset of core waves
gen mdate = ym(rhcalyr, rhcalmn)
format mdate %tm
sort panel ssuid eentaid epppnum wave rhcalyr rhcalmn mdate
cap drop __00*
compress
save extract_core_`pan', replace


** extract asset data

* identification variable
#delimit ;
local id_var
ssuid
shhadid
eentaid
epppnum
spanel
swave
srotaton
eoutcome
eppintvw; 
#delimit cr

* asset variables of interest
#delimit ;
local wealth_var
thhtnw
thhtwlth
thhtheq
thhdebt
thhscdbt
thhmortg
thhscdbt
thhtheq
thhvehcl
thhbeq
thhira 
thhore
*usc*
ehmort
evb???
tvb???;
#delimit cr 

* apply sample selection 
if `pan'==1996 {
	local var_sel `id_var' `wealth_var' taltb 
	* thhthrif recode missing in 1996 panel, taltb is individual term
}
else {
	local var_sel `id_var' `wealth_var' thhthrif
}

clear all
 
forvalues wave = `topi_wave_numl' {
	append using "`topi_wave_name'`wave'", keep(`var_sel') 
}

* save asset data
rename (spanel swave srotaton) (panel wave rotation)
order panel ssuid eentaid epppnum wave 
sort panel ssuid eentaid epppnum wave
compress 
save extract_assets_`pan', replace

}

cd ${progs}


}

