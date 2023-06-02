********************
*** INTRODUCTION ***
********************
// This .do-file creates the data for the two cards in chapter 1
cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"

******************
*** FIRST CARD ***
******************
wbopendata, indicator(SI.POV.NAHC;SI.POV.MDIM) clear
keep country* yr* indicator*
reshape long yr, i(country* indicator*) j(year)
rename yr value
drop if missing(value)
gen indicator = "mon" if indicatorcode=="SI.POV.NAHC"
replace indicator = "mul" if  indicatorcode=="SI.POV.MDIM"
drop indicatorname indicatorcode
compress
reshape wide value, i(country* year) j(indicator) string
drop if missing(valuemon, valuemul)
bysort countrycode (year): keep if _n==_N
sort valuemul
gen n = _n

 export delimited using "Outputdata\Card1.csv", replace

gen dif = valuemul-valuemon
sum dif,d

twoway rspike valuemon valuemul n || ///
scatter valuemon n || ///
scatter valuemul n

*******************
*** SECOND CARD ***
*******************
wbopendata, indicator(per_allsp.cov_pop_tot) clear
keep country* incomelevel* yr*
reshape long yr, i(country* income*) j(year)
rename yr value
drop if year<1990

bysort countrycode (year): ipolate value year, gen(value_interpolated)
drop if missing(value_interpolated)

tab year incomelevel,m
drop if year<2000
gen decade = round(year-5,10)

bysort countrycode decade: egen average_value = mean(value)
keep countrycode incomelevel average_value decade
duplicates drop
ren average_value value
bysort countrycode: drop if _N==1
tab income

collapse value, by(incomelevel decade)
 export delimited using "Outputdata\Card2.csv", replace
