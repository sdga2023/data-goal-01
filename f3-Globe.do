********************
*** INTRODUCTION ***
********************
// This .do-file takes as input the recovered distributions
// And collapses them in 2019 to create the data for the introductor globes
cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"


**************************************
*** COUNTRY DOTS IN 2019 FOR GLOBE ***
**************************************
use  "Inputdata/DistributionalData_finished.dta", clear
keep if year==2019
keep code weight welfare
gen poor = 0
replace poor = weight if welfare<2.15
ren weight pop
collapse (sum) pop poor, by(code)

replace pop  = round(pop/10^6)
replace poor = round(poor/10^6)

// Grey out countries not in PIP
preserve
pip, fillgaps year(2019) clear
keep country_code
rename country_code code
duplicates drop
tempfile inpip
save `inpip'
restore
merge 1:1 code using `inpip'
rename _merge greyout
replace greyout = 0 if greyout==3
label drop _merge
compress
ren code iso3c
ren pop population_in_millions
ren poor poor_in_millions
export delimited using "Outputdata/IntroductoryGlobe.csv", replace

