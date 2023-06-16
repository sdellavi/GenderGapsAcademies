***Set your own path for ...

cd "..."
global root ".../data"

local econ_AAAS = "Economics"
local math_AAAS = "Mathematics, Applied Mathematics, and Statistics"
local psych_AAAS = "Psychological Sciences"

local econ_NAS = "Economic Sciences"
local psych_NAS = "Psychological and Cognitive Sciences"


foreach field in psych math {
	foreach award in AAAS NAS {

		use "${root}/`award'/`award'_2020_2021.dta", clear
		if "`award'" == "NAS" & "`field'" == "math" {
			keep if inlist(primary, "Applied Mathematical Sciences", "Mathematics")
		}
		else {
			keep if primary == "``field'_`award''"
		}
		tempfile `award'
		save "``award''"
	}
	if "`field'" == "psych" {
		use "${root}\psych\output\fellows_matched_rectangular_citation.dta", clear
	}
	else if "`field'" == "math" {
		use "${root}\math\output\fellows_matched_rectangular_citation.dta", clear
	}
	drop if years_lastpub > 18 
	* merge back flags
	merge m:1 author using "${root}/`field'/output/AAAS_fellows_clean.dta", ///
		keepusing(AAAS_flags) keep(1 3) nogen
	merge m:1 author using "${root}/`field'/output/NAS_fellows_clean.dta", ///
		keepusing(primary_NAS) keep(1 3) nogen
	* merge deaths
	merge m:1 author using "${root}/`field'/output/urap_death.dta", keep(1 3) nogen
	destring death, replace force
	drop if (year > death)
	
	foreach award in AAAS NAS {
		merge 1:1 author year using "``award''", keep(1 3) keepusing(female_`award') 
		replace new_fellow_`award' = 1 if _m == 3
		replace Female = 1 if female_`award' == 1 & !missing(female_`award') & year > 2019
		replace Male = 1 if female_`award' == 0 & !missing(female_`award') & year > 2019
		drop _m
	}
	
	replace new_fellow_AAAS = 0 if ///
		(AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
		(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)
	
	replace new_fellow_NAS = 0 if primary_NAS == 0
	tempfile temp
	save "`temp'"
	
	foreach award in AAAS NAS {
		use "`temp'", clear
		keep if new_fellow_`award' == 1
		collapse (sum) Female Male, by(year)
		rename (Male Female) (Male_`award' Female_`award')
		save "``award''", replace
	}
	use "`temp'", clear
	
	egen total_cite_cumulative = rowtotal(*_cite_cumulative)
	
	* neither fellow or new fellow in it
	gen decade = . 
	gen cite_75 = .
	gen cite_95 = .
	local list_decade 1930 1940 1950 1960 1970 1980 1990 2000 2010 
	foreach decade in `list_decade'{
		replace decade = `decade' if floor(year/10)*10 == `decade'
	}
	levelsof decade, local(levels)
	foreach d in `levels'{
		qui sum total_cite_cumulative if decade == `d', d
		replace cite_75 = 1 if total_cite_cumulative >= r(p75) & decade == `d' 
		replace cite_95 = 1 if total_cite_cumulative >= r(p95) & decade == `d'
		
	}
	gen female_cite_75 = cite_75 * Female
	gen female_cite_95 = cite_95 * Female
	keep if ((fellow_NAS == 0 & fellow_AAAS == 0) | (min(year_appointed_NAS,year_appointed_AAAS) == year))
	
	* drop ungendered
	drop if Ambiguous == 1

	forval x = 5(5)15 {
		gen female_`x'pub = Female if nm_paper_cumulative >= `x'
	}
	rename Female female 
	drop female_NAS female_AAAS
	collapse (mean) female*, by(year)
	foreach award in AAAS NAS {
		merge 1:1 year using "``award''", nogen keep(1 2 3) update
		replace Male_`award' = 0 if missing(Male_`award')
		replace Female_`award' = 0 if missing(Female_`award')
	}
	tsset year
	drop if year > 2021
	
	foreach award in AAAS NAS {
		foreach var in Male Female {
			gen mvtotal_`var'_`award' = F2.`var'_`award' + F1.`var'_`award' +  `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award'
			replace mvtotal_`var'_`award' = F1.`var'_`award' +  `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award' if year == 2020
			replace mvtotal_`var'_`award' = `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award' if year == 2021
			
		}
		gen mvavg_`award' = mvtotal_Female_`award' / (mvtotal_Female_`award'  + mvtotal_Male_`award')
	}
	local psych_label_AAAS = ".41 2011"
 	local psych_label_NAS = ".55 2005"
	local math_label_AAAS = ".15 2010"
 	local math_label_NAS = ".25 2015"
	
	line mvavg_AAAS mvavg_NAS female female_5pub female_15pub year if year >= 1960, ///
	graphregion(color(white)) color(black purple blue red green) ///
		ytitle("Share Female") xtitle("Year") lpattern(longdash_dot solid dash solid longdash) ///
		lwidth(thick thick medium medium thin) ///
		legend(on order(1 "New AAAS fellows" 2 "New NAS fellows" ///
			3 "Active publishers" 4 "5+ publications" 5 "15+ publications")) ///
		xscale(r(1960 2022)) text(``field'_label_AAAS' "AAAS") text(``field'_label_NAS' "NAS")
	graph export figures/figure2_`field'.png, replace
	graph export figures/figure2_`field'.pdf, as(pdf) replace
	
		
	line mvavg_AAAS mvavg_NAS female female_cite_75 female_cite_95 year if year >= 1960, ///
		graphregion(color(white)) color(black purple blue red green) ///
		ytitle("Share Female") xtitle("Year") lpattern(longdash_dot solid dash solid longdash) ///
		lwidth(thick thick medium medium thin) ///
		legend(on order(1 "New AAAS fellows" 2 "New NAS fellows" ///
			3 "Active publishers" 4 "75th Percentile Citations" 5 "95th Percentile Citations")) ///
		xscale(r(1960 2022)) text(``field'_label_AAAS' "AAAS") text(``field'_label_NAS' "NAS")
	graph export figures/figureA1_`field'.png, replace
	graph export figures/figureA1_`field'.pdf, as(pdf) replace
	
	
}

* econ
local econ_AAAS = "Economics"
local econ_NAS = "Economic Sciences"
local field = "econ"
foreach award in AAAS NAS {

	use "${root}/`award'/`award'_2020_2021.dta", clear
		if "`award'" == "NAS" & "`field'" == "math" {
			keep if inlist(primary, "Applied Mathematical Sciences", "Mathematics")
		}
		else {
			keep if primary == "``field'_`award''"
		}
		tempfile `award'
		save "``award''"
}

use "${root}/econ/output/regression_dataset_NAS_AAAS.dta", clear
	
drop if years_lastpub > 18 
merge m:1 author using "${root}/econ/input/AAAS_secondary.dta", ///
	keepusing(author subfield*) keep(1 3)
replace AAAS_flags = 3 if subfield_pdf == "Economics"
replace AAAS_flags = 4 if subfield_website == "Economics"

drop _m

replace new_fellow_AAAS = 0 if ///
	(AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
	(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)

replace new_fellow_NAS = 0 if primary_NAS == 0
tempfile temp
save "`temp'"

foreach award in AAAS NAS {
	use "`temp'", clear
	keep if new_fellow_`award' == 1
	append using "``award''"
	replace Female = 1 if female_`award' == 1 & !missing(female_`award') & year > 2019
	replace Male = 1 if female_`award' == 0 & !missing(female_`award') & year > 2019
	
	collapse (sum) Female Male, by(year)
	rename (Male Female) (Male_`award' Female_`award')
	save "``award''", replace
}
use "`temp'", clear

egen total_cite_cumulative = rowtotal(*_cite_cumulative)
	
gen decade = . 
gen cite_75 = .
gen cite_95 = .
local list_decade 1930 1940 1950 1960 1970 1980 1990 2000 2010 
foreach decade in `list_decade'{
	replace decade = `decade' if floor(year/10)*10 == `decade'
}
levelsof decade, local(levels)
foreach d in `levels'{
	qui sum total_cite_cumulative if decade == `d', d
	replace cite_75 = 1 if total_cite_cumulative >= r(p75) & decade == `d' 
	replace cite_95 = 1 if total_cite_cumulative >= r(p95) & decade == `d'
	
}
gen female_cite_75 = cite_75 * Female
gen female_cite_95 = cite_95 * Female

* neither fellow or new fellow in it
keep if ((fellow_NAS == 0 & fellow_AAAS == 0) | (min(year_appointed_NAS,year_appointed_AAAS) == year))
	
* drop ungendered
drop if Ambiguous == 1
forval x = 5(10)15 {
	gen female_`x'pub = Female if nm_paper_cumulative >= `x'
}

rename Female female 
collapse (mean) female*, by(year)

foreach award in AAAS NAS {
	merge 1:1 year using "``award''", nogen keep(1 2 3)
	replace Male_`award' = 0 if missing(Male_`award')
	replace Female_`award' = 0 if missing(Female_`award')
}
tsset year

foreach award in AAAS NAS {
	foreach var in Male Female {
		gen mvtotal_`var'_`award' = F2.`var'_`award' + F1.`var'_`award' +  `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award'
		replace mvtotal_`var'_`award' = F1.`var'_`award' +  `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award' if year == 2020
		replace mvtotal_`var'_`award' = `var'_`award' + ///
			L4.`var'_`award' + L3.`var'_`award' + L2.`var'_`award' + L1.`var'_`award' if year == 2021
	}
	gen mvavg_`award' = mvtotal_Female_`award' / (mvtotal_Female_`award'  + mvtotal_Male_`award')
}


line mvavg_AAAS mvavg_NAS female female_5pub female_15pub year if year >= 1960, ///
	graphregion(color(white)) color(black purple blue red green) ///
	ytitle("Share Female") xtitle("Year") lpattern(longdash_dot solid dash solid longdash) ///
	lwidth(thick thick medium medium thin) ///
	legend(on order(1 "New AAAS members" 2 "New NAS members" ///
		3 "Active publishers" 4 "5+ publications" 5 "15+ publications")) ///
	xscale(r(1960 2022)) text(.35 2013 "AAAS") text(.2 2002 "NAS")
graph export figures/figure2_`field'.png, replace
graph export figures/figure2_`field'.pdf, as(pdf) replace


line mvavg_AAAS mvavg_NAS female female_cite_75 female_cite_95 year if year >= 1960, ///
	graphregion(color(white)) color(black purple blue red green) ///
	ytitle("Share Female") xtitle("Year") lpattern(longdash_dot solid dash solid longdash) ///
	lwidth(thick thick medium medium thin) ///
	legend(on order(1 "New AAAS members" 2 "New NAS members" ///		
		3 "Active publishers" 4 "75th+ Percentile Citations" 5 "95th+ Percentile Citations")) ///
	xscale(r(1960 2022)) text(.35 2013 "AAAS") text(.2 2002 "NAS")
graph export figures/figureA1_`field'.png, replace
graph export figures/figureA1_`field'.pdf, as(pdf) replace
