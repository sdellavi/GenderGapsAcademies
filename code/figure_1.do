**** Encodes the AAAS_flags variable
cd "..."


*** Opening corrected AAAS file
*** Set your own path for ...
use "data/AAAS_flags_fig1_fields.dta", clear
keep fellow year Male Female subfield_correct
gen fellowship = "AAAS"
append using "data/NAS_fig1_fields.dta"
drop Ambiguous
replace fellowship = "NAS" if fellowship == ""


rename Male Male_old
rename Female Female_old
gen Ambiguous = (Male == 0 & Female == 0) | (Male == . & Female == .)
rename Ambiguous Ambiguous_old
* Dropping obs with no election year
drop if year == .


**Merging new code names
**Merge m:1 bc of AAAS fellows in multiple pdf fields and NAS fellows that have the same name (father and son)
merge m:1 fellow using "data/gender_name.dta"
*** "You only revert it back if now it's ambiguous, but previously it was not'"
gen mismatch = 1 if Ambiguous == 1 & Ambiguous_old == 0
replace Male = Male_old if mismatch == 1 & Male_old != .
replace Female = Female_old if mismatch == 1 & Female_old != .
replace Ambiguous = 1 if Male == 0 & Female == 0
replace Ambiguous = 0 if Male == 1 | Female == 1
drop Male_old Female_old Ambiguous_old mismatch _merge
rename (Male Female) (Male_old Female_old)

*** Merge with hand gendering for 2020/2021
merge m:1 fellow using "data/gender_cleaned_core_fields.dta"
assert _merge != 2
keep if _merge == 1 | _merge == 3
* Go back to old in the cases where we are currently missing
replace Male = Male_old if Male_old != . & Male == .
replace Female = Female_old if Female_old != . & Female == .
drop Male_old Female_old

*** Checking ambiguous
preserve
replace Ambiguous = 0 if Male == 1 | Female == 1
replace Ambiguous = 1 if Male == 0 & Female == 0
keep if Ambiguous == 1 & year > 1956
sort fellowship year subfield
restore


*** Hand fixing a couple names
replace Female = 0 if fellow == "Chris Shannon"
replace Male = 1 if fellow == "Chris Shannon"
replace Female = 0 if fellow == "Marion Clawson"
replace Male = 1 if fellow == "Marion Clawson"
replace Female = 1 if fellow == "Barbel Elisabeth Inhelder"
replace Male = 0 if fellow == "Barbel Elisabeth Inhelder"
replace Female = 0 if fellow == "Jean Piaget"
replace Male = 1 if fellow == "Jean Piaget"
replace Female = 0 if fellow == "Lorrin Andrews Riggs"
replace Male = 1 if fellow == "Lorrin Andrews Riggs"
replace Female = 0 if fellow == "Chia-Chiao Lin"
replace Male = 1 if fellow == "Chia-Chiao Lin"




*** Calculating share female
drop if year == .
collapse (sum) Male Female, by(year subfield_correct fellowship)



*** Code for figure
* Small detour to keep the field name
egen panelid = group(subfield_correct fellowship), label
preserve
keep panelid subfield_correct fellowship
duplicates drop
tempfile temp
save `temp'
restore
tsset panelid year
tsfill
merge m:1 panelid using `temp', update
drop _merge

*** Final spec (4 lag, present, 2 forward)
sort panelid year
foreach var of varlist Male-Female {
	replace `var' = 0 if missing(`var')
}
egen total_fem_5y = filter(Female), coef(1 1 1 1 1 1 1) lags(-2/4)
egen total_man_5y = filter(Male), coef(1 1 1 1 1 1 1) lags(-2/4)
* Adding padding for future
replace total_fem_5y  = (L4.Female + L3.Female + L2.Female + L1.Female + Female + F1.Female) if year == 2020
replace total_man_5y  = (L4.Male + L3.Male + L2.Male + L1.Male + Male + F1.Male) if year == 2020
replace total_fem_5y  = (L4.Female + L3.Female + L2.Female + L1.Female + Female) if year == 2021
replace total_man_5y  = (L4.Male + L3.Male + L2.Male + L1.Male + Male) if year == 2021
* Computing final share
gen total_5y = total_fem_5y + total_man_5y
gen share_f_5y = total_fem_5y / total_5y
drop total_fem_5y total_man_5y total_5y



encode subfield_correct, gen(subfield_correct_id)
label drop _merge panelid
label list
drop Male Female subfield_correct panelid
reshape wide share_f, i(year fellowship)  j(subfield_correct_id)
rename share_f* share_f_*
reshape wide share_f*, i(year) j(fellowship, string)


drop if year < 1960


*** Testing graphs

*** AAAS 
graph twoway  ///
	(connected share_f__5y4AAAS year, lpattern(solid) color(red) msymbol(s)) ///
	(connected share_f__5y6AAAS year, lpattern(solid) color(orange) msymbol(t)) ///
	(line share_f__5y1AAAS year, lpattern(dash) color(green*0.8)) ///
	(connected share_f__5y5AAAS year, lpattern(solid) color(blue) msymbol(o)) ///
	(line share_f__5y2AAAS year, lpattern(shortdash) color(blue*0.8)) ///
	(line share_f__5y3AAAS year, lpattern(dash_dot) color(black*0.8)), ///
	graphregion(color(white)) ytitle("Share Female") xtitle("year") ///
	legend(on order(1 "Economics" 2 "Psychology" 3 "Anthropology" 4 "Mathematics" 5  "Cellular Biology" ///
	 6 "Chemistry") rows(2)) ysc(r(0 0.6)) ylabel(0(0.1)0.6)
	
graph export figures/fig1_AAAS.png, replace
graph export figures/fig1_AAAS.pdf, as(pdf) replace

*** NAS 
graph twoway  ///
	(connected share_f__5y4NAS year, lpattern(solid) color(red) msymbol(s)) ///
	(connected share_f__5y6NAS year, lpattern(solid) color(orange) msymbol(t)) ///
	(line share_f__5y1NAS year, lpattern(dash) color(green*0.8)) ///
	(connected share_f__5y5NAS year, lpattern(solid) color(blue) msymbol(o)) ///
	(line share_f__5y2NAS year, lpattern(shortdash) color(blue*0.8)) ///
	(line share_f__5y3NAS year, lpattern(dash_dot) color(black*0.8)), ///
	graphregion(color(white)) ytitle("Share Female") xtitle("year") ///
	legend(on order(1 "Economics" 2 "Psychology" 3 "Anthropology" 4 "Mathematics" 5  "Cellular Biology" ///
	 6 "Chemistry") rows(2)) ysc(r(0 0.6)) ylabel(0(0.1)0.6)
	 
graph export figures/fig1_NAS.png, replace
graph export figures/fig1_NAS.pdf, replace

	
	
	
	
	
	
	
	
	
	
	