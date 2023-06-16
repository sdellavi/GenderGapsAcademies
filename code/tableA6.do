eststo clear
clear
set matsize 11000

cd "..."
global root ".../data"


global psych_journals JEPG PR PS TiCS PB JPSP ARP PNAS AP CD Cog CP DP

global math_journals AIM AJM AM AP AS ActaM CM CMP DMJ IM JAMS JASA JCP PNAS TAMS

global econ_journals AER ECTA JE JET JPE QJE REStud RAND JEP JEL REStat JF JME JPubE 


foreach field in psych econ math  {
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
	keep author Female Ambiguous year *_cumulative ///
		fellow_AAAS new_fellow_AAAS year_appointed_AAAS ever_fellow_AAAS AAAS_flags ///
		fellow_NAS new_fellow_NAS year_appointed_NAS ever_fellow_NAS primary_NAS years_firstpub
	cap drop single*
	cap drop first*
	* fill in missing for NAS
	foreach var in fellow_NAS new_fellow_NAS ever_fellow_NAS {
		replace `var' = 0 if missing(`var')
	}
	* condition on gendered
	drop if Ambiguous == 1

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
	replace NAS_sample = 0 if NAS_sample == 1 & year_appointed_NAS < 1960 & !missing(year_appointed_NAS)
	replace AAAS_sample = 0 if AAAS_sample == 1 & year_appointed_AAAS < 1960 & !missing(year_appointed_AAAS)

	* by decade * Female variable 
	gen Female_1960_1970 = Female * (year >= 1960 & year <= 1979)
	local list_decade 1980 1990 2000 2010
	foreach decade in `list_decade'{
		gen Female_`decade' = Female * (floor(year/10)*10== `decade')
	}

	* Controls * 3 20-year time intervals 
	** time interval dummy  
	gen decades_1960 = (year <= 1979)
	gen decades_1980 = (year < 2000 & year > 1979)
	gen decades_2000 = (year > 1999)
	cap drop multi*
	egen total_cite_cumulative = rowtotal(*_cite_cumulative)
	gen asinh_cite_total = asinh(total_cite_cumulative)
	
	* years since first publication 
	gen firstpub_10 = (years_firstpub < 20 & years_firstpub >= 10)
	gen firstpub_20 = (years_firstpub < 30 & years_firstpub >= 20)
	gen firstpub_30 = (years_firstpub >= 30)
	drop years_firstpub
	
	local loopjournals = "`field'_journals"
	foreach journal in $`loopjournals' {
		gen asinh_`journal'_cite = asinh(`journal'_cite_cumulative)
		drop `journal'_cite_cumulative
	} 
	drop total_cite_cumulative
	
	gen decade = . 
	local list_decade 1930 1940 1950 1960 1970 1980 1990 2000 2010 
	foreach decade in `list_decade'{
		replace decade = `decade' if floor(year/10)*10 == `decade'
	}
	
	** Store average female
	sum Female if year >= 2010 & year <= 2019
	global `field'_female = r(mean)
	
	rename nm_paper_cumulative nm_paper_cumulative_total
	
	foreach award in AAAS NAS {
		cap drop topcite
		gen topcite = . 
		levelsof decade, local(levels)
		foreach d in `levels'{
			_pctile asinh_cite_total if decade == `d' & `award'_sample == 1, p(90 95 99 99.5)
			return list
			
			replace topcite = 1 if asinh_cite_total < r(r1) & decade == `d'
			replace topcite = 2 if asinh_cite_total < r(r2) & asinh_cite_total >= r(r1) & decade == `d'
			replace topcite = 3 if asinh_cite_total < r(r3) & asinh_cite_total >= r(r2) & decade == `d'
			replace topcite = 4 if asinh_cite_total < r(r4) & asinh_cite_total >= r(r3) & decade == `d'
			replace topcite = 5 if asinh_cite_total >= r(r4) & decade == `d'
			
		}
		eststo `award'_1960_est: ///
			logit new_fellow_`award' Female_1960_1970 i.year ///
			c.asinh_cite_total c.*_cite c.*_cumulative i.topcite firstpub_* ///
			if `award'_sample & year < 1980 & year >= 1960, cluster(author)  difficult iterate(100)
		
		eststo `award'_1980_est: ///
			logit new_fellow_`award' Female_1980 Female_1990 i.year ///
			c.asinh_cite_total c.*_cite c.*_cumulative i.topcite firstpub_* ///
			if `award'_sample & year < 2000 & year >= 1980, cluster(author)  difficult iterate(100)
		
		eststo `award'_2000_est: ///
			logit new_fellow_`award' Female_2000 Female_2010 i.year ///
			c.asinh_cite_total c.*_cite c.*_cumulative i.topcite firstpub_* ///
		if `award'_sample & year < 2020 & year >= 2000, cluster(author) difficult iterate(100)
		
	}
	* ============================================================================== 
	local cite asinh_*_cite
	do code/regression_labels.do
		
	list_journal, field(`field')
	local list = r(list_journal)
	unab female: Female_1960_1970 Female_1980 Female_1990 Female_2000 Female_2010 
	
	local psych_start = "PS"
	local math_start = "AIM"
	local econ_start = "AER"
	foreach award in AAAS NAS {
		* output file for table 4
		esttab `award'_1960_est `award'_1980_est `award'_2000_est using tables/tableA6_`field'_`award'.csv, ///
		order(`female' asinh_cite_total `list' *.topcite) csv se(%9.3f) b(%9.3f) pr2 scalars(N) sfmt(%9.0fc) ///
		refcat(Female_1960 "Authors' Genders (Omitted: Male Author)" ///
		``field'_start'_cumulative "Cumulative Publications and Citations Received in `field' journals", nolabel) ///
		mgroups(1960-79 1980-99 2000-19, pattern(1 0 1 0 1 0)) ///
		title("Table IV") keep(`female' asinh_cite_total `list' *.topcite) label nostar nogaps nodepvars  replace
	}
	
	
}
	
