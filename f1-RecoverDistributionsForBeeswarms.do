********************
*** INTRODUCTION ***
********************
// This .do-file queries the Poverty and Inequality Platform (PIP) many times.
// It queries many different poverty lines for each country-year so as to implicitly recover full distributions
cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"

******************************
*** POVERTY LINES TO QUERY ***
******************************
// We want to query povertylines such that we can recover full annual distributions for each country
// It is not quite clear how many poverty lines are necessary
// Chose increments of 0.02 until 2, and then increase of 1% until 900
// This is not really based on much more than intutition that it will give sufficient information.
clear
set obs 10000
gen double povertyline = _n/50
replace povertyline = povertyline[_n-1]*1.01 if povertyline>2
drop if povertyline>1000
replace povertyline = round(povertyline,0.001)
tostring povertyline, replace force
gen povertyline5 = povertyline + " " + povertyline[_n+1] + " " + povertyline[_n+2] + " " + povertyline[_n+3] + " " + povertyline[_n+4]
keep if mod(_n-1,5)==0
drop povertyline


********************
*** QUERYING PIP ***
********************
qui levelsof povertyline5
foreach lvl in `r(levels)' {
disp as error "`lvl'"
qui pip, country(all) year(all) fillgaps povline(`lvl') clear
// Only keeping the national estimates (with Argentina and Suriname being the exceptions)
qui keep if reporting_level=="national" | inlist(country_code,"ARG","SUR")
// Don't care about the 1980s
drop if year<1990 | year>2019
// Only keep relevant variables
keep country_code poverty_line headcount year
// This line won't work for the first part of the loop but it will afterwards
cap append using "Inputdata/DistributionalData_raw.dta"
qui save  "Inputdata/DistributionalData_raw.dta", replace 
}

****************
*** CLEANING ***
****************
use "Inputdata/DistributionalData_raw.dta", clear
duplicates drop
sort country_code year poverty_line
rename country_code code
// Adding a 0 poverty line
sum poverty_line
expand 2 if abs(poverty_line-`r(min)')<0.001
sort code year poverty_line
bysort code year (poverty_line): replace poverty_line = 0 if _n==1
bysort code year (poverty_line): replace headcount   = 0 if _n==1 
// Adding $2.15 poverty to get main poverty estimates more precise
expand 2 if abs(poverty_line-2.14)<0.01
sort code year poverty_line
bysort code year poverty_line: replace headcount   = .     if _N==2 & _n==2
bysort code year poverty_line: replace poverty_line = 2.15 if _N==2 & _n==2
bysort code year (poverty_line): replace headcount = (headcount[_n-1]*(poverty_line[_n+1]-poverty_line)+headcount[_n+1]*(poverty_line-poverty_line[_n-1]))/(poverty_line[_n+1]-poverty_line[_n-1]) if missing(headcount)
// Checking that the headcount rate always is an increasing function of the poverty rate
bysort code year (poverty_line): gen weight = headcount-headcount[_n-1]
sum weight, d
// It's not always. In those cases repeat the previous headcount rate
bysort code year (poverty_line): replace headcount = headcount[_n-1] if _n!=1 & headcount<headcount[_n-1]
// Adjust weights for this
bysort code year (poverty_line): replace weight = headcount-headcount[_n-1]
// Should not be any negative weights now
sum weight, d
bysort code year (poverty_line): gen welfare = poverty_line[_n-1]+(poverty_line-poverty_line[_n-1])/2
drop if weight==0
drop if missing(weight) // First row for each country
drop poverty_line headcount
lab var code "Country code"
lab var year "Year"
lab var weight "Weight"
lab var welfare "Welfare (Daily, 2017 PPP USD)"
compress
save  "Inputdata/DistributionalData_clean.dta", replace

*****************************
*** ADD MISSING COUNTRIES ***
*****************************
// Find countries not included (uses a file from here: https://github.com/PovcalNet-Team/Class)
use "Inputdata/CLASS.dta", clear
keep code region_povcalnet region
duplicates drop
tempfile class
save    `class'
// Prepare population data
pip tables, table(pop) clear
keep if data_level=="national"
drop data_level
rename value pop
rename country_code code
drop if year>2019 | year<1990
tempfile pop
save    `pop'
// Merge on Bank and PovcalNet regions and population data
use  "Inputdata/DistributionalData_clean.dta", clear
merge m:1 code year using `pop', nogen
merge m:1 code using `class', nogen
// Will be populated later on 
expand 500 if missing(welfare)
bysort code year: gen pctl=_n if missing(welfare)
// Adjust weights to account for population
replace weight = weight*pop
// Temporarily save to be used later
tempfile AllLineUpData_temp
save    `AllLineUpData_temp'
// Collapse weight by welfare
drop pop code
collapse (sum) weight, by(year region_povcalnet welfare)
// Collapse to 500 points
levelsof region_povcalnet
foreach reg in `r(levels)' {
disp in red "`reg'"
levelsof year
foreach yr in `r(levels)' {
pctile welf_`reg'_`yr'=welfare [aw=weight] if year==`yr' & region_povcalnet=="`reg'", nq(501) gen(obs)
drop obs
}
}
keep if _n<=500
drop weight welfare year region_povcalnet
gen pctl = _n
reshape long welf_, i(pctl) j(region_povcalnet) string
rename welf_ welf_regavg
gen year = substr(region,5,4)
destring year, replace
replace region = substr(region,1,3)
isid region year pctl
tempfile regionalavg
save    `regionalavg'
use `AllLineUpData_temp'
merge m:1 region_povcalnet year pctl using `regionalavg', nogen
sort code year welfare pctl
replace weight = pop/500 if missing(welfare)
replace welfare = welf_regavg if missing(welfare)
drop welf_regavg pctl 
mdesc 
compress
save  "Inputdata/DistributionalData_finished.dta", replace