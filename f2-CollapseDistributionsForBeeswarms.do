********************
*** INTRODUCTION ***
********************
// This .do-file takes as input the recovered distributions
// And collapses them to certain buckets to facilitate plotting beeswarms
cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"

*****************************
*** COLLAPSE FOR PLOTTING ***
*****************************
use  "Inputdata/DistributionalData_finished.dta", clear
drop code pop

collapse (sum) weight, by(welfare year region)
bysort region year (welfare): egen pop = sum(weight)

// Millions
foreach dot in 1 10 20 25 50 100 {
// 7 regions
preserve
gen roundpop = round(pop,`dot'*10^6)
bysort region year  (welfare): gen cumweight = sum(weight)/pop*roundpop
gen double group = round(cumweight+`dot'*10^6/2-0.001,`dot'*10^6)
collapse welfare [aw=weight], by(year region  group)
gen regiontype = "7 regions"
gen dotsize = `dot'
gen dottype = "millions"
cap append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
// 4 regions 
preserve
replace region = "Rest of the world" if inlist(region,"Europe & Central Asia","Latin America & Caribbean","Middle East & North Africa","North America")
collapse (sum) weight, by(welfare year  region)
bysort region  year (welfare): egen pop = sum(weight)
gen roundpop = round(pop,`dot'*10^6)
bysort region  year (welfare): gen cumweight = sum(weight)/pop*roundpop
gen double group = round(cumweight+`dot'*10^6/2-0.001,`dot'*10^6)
collapse welfare [aw=weight], by(year region  group)
gen regiontype = "4 regions"
gen dotsize = `dot'
gen dottype = "millions"
cap append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
// World
preserve
collapse (sum) weight, by(welfare  year)
bysort year : egen pop = sum(weight)
gen roundpop = round(pop,`dot'*10^6)
bysort year  (welfare): gen cumweight = sum(weight)/pop*roundpop
gen double group = round(cumweight+`dot'*10^6/2-0.001,`dot'*10^6)
collapse welfare [aw=weight], by(year  group)
gen dotsize = `dot'
gen dottype = "millions"
gen regiontype = "World"
gen region = "World"
append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
}
// Shares
// Only need global pop
drop pop
bysort year : egen pop = sum(weight)
// Millions
foreach dot in 0.1 0.2 0.25 0.5 1 {
// 7 regions
preserve
bysort region  year (welfare): gen cumweight = sum(weight)/pop*100
bysort region  year (welfare): gen roundcumweight = round(cumweight,`dot') if _n==_N
bysort region  year (welfare): replace cumweight =  cumweight/cumweight[_N]*roundcumweight[_N]
gen double group = round(cumweight+`dot'/2-0.00001,`dot')
collapse welfare [aw=weight], by(year region  group)
gen dotsize = `dot'
gen dottype = "percent"
gen regiontype = "7 regions"
cap append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
// 4 regions
preserve
replace region = "Rest of the world" if inlist(region,"Europe & Central Asia","Latin America & Caribbean","Middle East & North Africa","North America")
bysort region  year (welfare): gen cumweight = sum(weight)/pop*100
bysort region  year (welfare): gen roundcumweight = round(cumweight,`dot') if _n==_N
bysort region  year (welfare): replace cumweight =  cumweight/cumweight[_N]*roundcumweight[_N]
gen double group = round(cumweight+`dot'/2-0.00001,`dot')
collapse welfare [aw=weight], by(year  region group)
gen dotsize = `dot'
gen dottype = "percent"
gen regiontype = "4 regions"
cap append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
// World
preserve
collapse (sum) weight, by(welfare  year)
bysort year : egen pop = sum(weight)
bysort year  (welfare): gen cumweight = sum(weight)/pop*100
gen double group = round(cumweight+`dot'/2-0.00001,`dot')
collapse welfare [aw=weight], by(year  group)
gen dotsize = `dot'
gen dottype = "percent"
gen regiontype = "World"
gen region = "World"
append using "Inputdata/Beeswarm_data.dta"
save "Inputdata/Beeswarm_data.dta", replace
restore
}
*/
// Fix cases where the input data was not precise enough to create the necessary number of rows
use "Inputdata/Beeswarm_data.dta", clear
sort year regiontype region dottype dotsize group
replace group = group/10^6 if dottype=="millions"
forvalues rep=1/6 {
expand 2 if abs(group[_n+1]-group-dotsize)>=dotsize/10 & year[_n+1]==year & regiontype[_n+1]==regiontype & region[_n+1]==region & dottype[_n+1]==dottype  & dotsize[_n+1]==dotsize
bysort year regiontype region dottype dotsize  group:  gen     new     = (_N!=1)
bysort year regiontype region dottype dotsize  group:  replace welfare = . if new==1 & _n!=1
bysort year regiontype region dottype dotsize  group:  replace group   = group[_n-1]+dotsize if new==1 & _n!=1
bysort year regiontype region dottype dotsize (group): replace welfare = (welfare[_n-1]*(group[_n+1]-group)+welfare[_n+1]*(group-group[_n-1]))/(group[_n+1]-group[_n-1]) if missing(welfare)
drop new
}
drop group

// Measurement error correction at the very bottom 
replace welfare = 0.5 if welfare<0.5

// Labelling
lab var dotsize "Dot size"
lab var dottype "Dot tyoe"
lab var regiontype "Region type"
lab var region "Region"
compress
export delimited using "Outputdata/Beeswarm_data.csv", replace
save "Inputdata/Beeswarm_data.dta", replace

