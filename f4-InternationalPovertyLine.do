********************
*** INTRODUCTION ***
********************
// This .do-file prepares the data used for the visualization on how the international poverty line is defined.
// The input data "NationalPovertyLines.dta" is from the paper:
// Jolliffe, Dean Mitchell; Mahler, Daniel Gerszon; Lakner, Christoph; Atamanov, Aziz; Tetteh Baah, Samuel Kofi. 2022. Assessing the Impact of the 2017 PPPs on the International Poverty Line and Global Poverty. © Washington, DC: World Bank.

cd "C:\Users\WB514665\OneDrive - WBG\DECDG\SDG Atlas 2022\Ch1\playground-sdg-1"

use "Input data/NationalPovertyLines.dta", clear

rename incgroup incomegroup
rename impline povertyline
rename gdp_2017 gdp
drop year
gen loggdp = log10(gdp)
gen logpovertyline = log10(povertyline)
compress

export delimited using "Output data\povlines.csv", replace
