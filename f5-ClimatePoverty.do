cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"

*******************
*** INTODUCTION ***
*******************
// This .do-file prepares all the data for the climate-poverty plot.
// All the input data files are from the paper: Wollburg, Philip ⓡ Stephane Hallegatte ⓡ Daniel Gerszon Mahler. 2023. "Is there a tradeoff between ending global poverty and containing global warming?" Washington, DC: World Bank.

// GDP data 
use code year gdppc gdp_impute using "Inputdata/GDP.dta", clear
lab var gdppc "GDP per capita (2017 PPP)"

// Merge with GHG data
merge 1:1 code year using "Input data/GHG.dta", nogen keepusing(ghgenergypc ghgpc_impute)
ren ghgenergypc ghgpc
lab var ghgpc "GHG per capita from energy (metric tons)"

// Merge with lined-up poverty numbers
preserve
pip, ppp_year(2017) fillgaps clear
keep if reporting_level=="national" | inlist(country_code,"ARG","SUR")
rename country_code code
gen povertyrate = headcount*100
keep povertyrate code year
lab var povertyrate "$2.15 poverty rate (%)"
isid code year
drop if year<=1990
tempfile poverty
save    `poverty'
restore
merge 1:1 code year using `poverty', nogen

// Merge with GHG scenarios
preserve
use "Input data\Results_GHGneed.dta", clear
ren *_dyn* **
ren ghgenergypc_eba_cba ghgpc_need 
ren ghgenergypc_e10_cba ghgpc_need_energy
replace ginichange=abs(ginichange)
reshape wide ghgpc_need ghgpc_need_energy, i(code year) j(gini)
rename *0 *
rename *17 *_equality
drop *energy_equality
lab var ghgpc_need "Greenhouse gasses per capita to meet poverty goal (metric tons)"
lab var ghgpc_need_energy "Greenhouse gasses per capita with increased energy efficiency (metric tons)"
lab var ghgpc_need_equality "Greenhouse gasses per capita to meet poverty goal under inequality reduction (metric tons)"
tempfile projections
save `projections'
restore
merge 1:1 code year using `projections', nogen 


// Merge with GDP scenarios
preserve
use "Input data\Results_GDP.dta", clear
keep code year gdppc_dyn
ren gdppc_dyn gdppc_need
lab var gdppc_need "GDP per capita to meet poverty goal (2017 PPP)"
tempfile gdp
save `gdp'
restore
merge 1:1 code year using `gdp', nogen 

// Replace data with missing whenenever imputed
replace gdppc               = . if gdp_impute==1
replace gdppc_need          = . if gdp_impute==1
replace ghgpc               = . if ghgpc_impute==1
replace ghgpc_need          = . if ghgpc_impute==1
replace ghgpc_need_equality = . if ghgpc_impute==1
replace ghgpc_need_energy   = . if ghgpc_impute==1
drop *impute

// Merge with data on growth needed to reach target
preserve
use "Input data/GrowthPoverty.dta", clear
keep if passthroughscenario=="base"
keep if povertyline==2.15
keep if povertytarget==3
keep if inlist(ginichange,0,-17)
replace ginichange = abs(ginichange)
keep code growth gini
reshape wide growth, i(code) j(gini)
rename *0 *
rename *17 *_equality
tempfile growth
rename growth* targetgrowth*
lab var targetgrowth "Growth to reach poverty target (%)"
lab var targetgrowth_equality "Growth to reach poverty target with inequality reduction (%)"
save `growth'
restore
merge m:1 code using `growth', nogen

// Merge with 2022 poverty rate
preserve
use "Input data/consumptiondistributions.dta", clear
gen povertyrate = consumption<2.15
drop if consumption_impute==1
collapse (sum) povertyrate, by (code)
replace povertyrate = povertyrate/10
gen povertytargetmet = povertyrate<3
keep code povertytargetmet povertyrate
lab var povertytargetmet "3% poverty target met in 2022"
lab var povertyrate "$2.15 poverty rate (%)"
gen year = 2022
tempfile povertytargetmet
save `povertytargetmet'
restore
merge 1:1 code year using `povertytargetmet', nogen update

// Create GDP targets
gen targetgdppc          = gdppc_need*(1+targetgrowth/100)            if year==2022
gen targetgdppc_equality = gdppc_need*(1+targetgrowth_equality/100)  if year==2022
drop targetgrowth*
lab var targetgdppc          "Target GDP per capita to reach poverty target (%)"
lab var targetgdppc_equality "Target GDP per capita to reach poverty target with inequality reduction (%)"
gsort code -targetgdppc
bysort code: replace targetgdppc          = targetgdppc[_n-1]          if !missing(targetgdppc[_n-1])
bysort code: replace targetgdppc_equality = targetgdppc_equality[_n-1] if !missing(targetgdppc_equality[_n-1])

replace gdppc = gdppc_need if year==2022
replace ghgpc = ghgpc_need if year==2022

sort code year
order code year poverty* gdp* ghg* target*
compress

ren *_need *_need_baseline
ren targetgdppc targetgdppc_baseline

// Save final data
export delimited using "Output data\povertyclimate.csv", replace
save "Input data\povertyclimate.dta", replace