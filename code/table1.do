* parsimonious set of controls

eststo clear
clear
set matsize 11000

cd "..."
global root ".../data"

global psych_journals JEPG PR PS TiCS PB JPSP ARP PNAS AP CD Cog CP DP

global math_journals AIM AJM AM AP AS ActaM CM CMP DMJ IM JAMS JASA JCP PNAS TAMS

global econ_journals AER ECTA JE JET JPE QJE REStud RAND JEP JEL REStat JF JME JPubE 

qui foreach field in psych econ math  {
	noisily display "Generating estimates for `field'..."
	if "`field'" == "psych" {
		use "${root}\psych\output\fellows_matched_rectangular_citation.dta", clear
	}
	else if "`field'" == "math" {	
		use "${root}\math\output\fellows_matched_rectangular_citation.dta", clear
	}
	
	else if "`field'" == "econ" {
		use "${root}/econ/output/regression_dataset_NAS_AAAS.dta", clear
	}
	
	drop if years_lastpub > 18 & year !=.
	drop if year > 2019
	
	if "`field'" == "psych" | "`field'" == "math" {
		* merge back flags
		merge m:1 author using "${root}/`field'/output/AAAS_fellows_clean.dta", ///
			keepusing(AAAS_flags) keep(1 3) nogen
			
		merge m:1 author using "${root}/`field'/output/NAS_fellows_clean.dta", ///
			keepusing(primary_NAS) keep(1 3) nogen
			
		* merge deaths
		merge m:1 author using "${root}/`field'/output/urap_death.dta", keep(1 3) nogen
		destring death, replace force
		drop if (year > death)
	}
	else {
		merge m:1 author using "${root}/econ/input/AAAS_secondary.dta", ///
			keepusing(author subfield*) keep(1 3)
		replace AAAS_flags = 3 if subfield_pdf == "Economics"
		replace AAAS_flags = 4 if subfield_website == "Economics"

		drop _m
		
	}
	
	keep author Female Ambiguous year *_cumulative years_firstpub years_lastpub ///
		fellow_AAAS new_fellow_AAAS year_appointed_AAAS ever_fellow_AAAS AAAS_flags ///
		fellow_NAS new_fellow_NAS year_appointed_NAS ever_fellow_NAS primary_NAS 
	cap drop single*
	cap drop first*
	* fill in missing for NAS
	foreach var in fellow_NAS new_fellow_NAS ever_fellow_NAS {
		replace `var' = 0 if missing(`var')
	}

	* generate filter for NAS primary fellows. For secondary fellows, we keep them in 
	* the risk set up to and including the year they are elected, but are not counted as
	* a fellow and then dropped after that year
	gen NAS_sample = (fellow_NAS == 0 | new_fellow_NAS == 1)

	replace new_fellow_NAS = 0 if primary_NAS == 0
	replace NAS_sample = 0 if year > year_appointed_NAS & primary_NAS == 0
	
	* same for AAAS 
	gen AAAS_sample = (fellow_AAAS == 0 | new_fellow_AAAS == 1)
	replace new_fellow_AAAS = 0 if ///
		(AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
		(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)
	replace AAAS_sample = 0 if year > year_appointed_AAAS & ///
		((AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
		(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .))
	* drop if already fellow before 1960
	drop if NAS_sample == 1 & year_appointed_NAS < 1960 & !missing(year_appointed_NAS)
	drop if AAAS_sample == 1 & year_appointed_AAAS < 1960 & !missing(year_appointed_AAAS)


	* Controls * 3 20-year time intervals 
	** time interval dummy  
	gen decades_1960 = (year <= 1979)
	gen decades_1980 = (year < 2000 & year > 1979)
	gen decades_2000 = (year > 1999)
	cap drop multi*
	egen total_cite_cumulative = rowtotal(*_cite_cumulative)
	
	gen decade = . 
	local list_decade 1930 1940 1950 1960 1970 1980 1990 2000 2010 
	foreach decade in `list_decade'{
		replace decade = `decade' if floor(year/10)*10 == `decade'
	}
	
	rename nm_paper_cumulative nm_paper_cumulative_total
	
	gen year_1960_1979 = (year >= 1960 & year <= 1979)
	gen year_1980_1999 = (year >= 1980 & year <= 1999)
	gen year_2000_2019 = (year >= 2000 & year <= 2019)
	replace Female = Female * 100
	replace Ambiguous = Ambiguous * 100
	tempfile temp 
	save "`temp'"
	foreach range in 1960_1979 1980_1999 2000_2019 {
		use "`temp'" if year_`range'
		count 
		global `field'_`range'_1: display r(N)
		distinct author
		global `field'_`range'_2: display r(ndistinct)
		local i = 3 
		foreach var in nm_paper_cumulative_total total_cite_cum /// 
			Female Ambiguous years_firstpub {
			sum `var'
			global `field'_`range'_`i': display %5.2f r(mean)
			local i = `i' + 1
		}
		
					
		use "`temp'" if year_`range' & new_fellow_AAAS == 1
		count 
		global `field'_`range'_8: display r(N)
		unique author if year_`range'
		local i = 9
		foreach var in nm_paper_cumulative_total total_cite_cum /// 
			Female Ambiguous unm unm_female years_firstpub {
			if !inlist("`var'", "unm", "unm_female") {
				sum `var'
				global `field'_`range'_`i': display %5.2f r(mean)
			}
			else {
				
				global `field'_`range'_`i' = "--"
			}
			local i = `i' + 1
		}
		
		use "`temp'" if year_`range' & new_fellow_NAS == 1
			
		count 
		global `field'_`range'_17: display r(N)
		unique author if year_`range'
		local i = 18
		foreach var in nm_paper_cumulative_total total_cite_cum /// 
			Female Ambiguous unm unm_female years_firstpub {
			if !inlist("`var'", "unm", "unm_female") {
				qui sum `var'
				global `field'_`range'_`i': display %5.2f r(mean)
			}
			else {
				global `field'_`range'_`i' = "--"
			}
			local i = `i' + 1
		}
		
	}
}
* We take the values for unmatched fellows from TableA4. See tableA4.do
file open write_file using "tables/table1.csv", write text replace
forval i = 1/25 {
	if `i' == 8  {
		file write write_file _n
	}
	foreach field in psych econ math {
		foreach range in 1960_1979 1980_1999 2000_2019 {
			file write write_file "${`field'_`range'_`i'},"
			if  "`field'" == "math" & "`range'" == "2000_2019" {
				file write write_file _n
			}
		}
	}
}
file close write_file
