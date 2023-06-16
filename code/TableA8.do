eststo clear
clear
set matsize 11000

cd "..."
global root ".../data"

cap log close
log using "tables/pooled.log", replace


global psych_journals JEPG PR PS TiCS PB JPSP ARP PNAS AP CD Cog CP DP
global math_journals AIM AJM AM AP AS ActaM CM CMP DMJ IM JAMS JASA JCP PNAS TAMS
global econ_journals AER ECTA JE JET JPE QJE REStud RAND JEP JEL REStat JF JME JPubE 

cap erase tables/tableA8.txt
cap erase tables/tableA8.xls


foreach field in psych econ math {
	noisily display "Generating estimates for `field'..." _n

	if "`field'" == "psych" {
		use "${root}/psych/output/fellows_matched_rectangular_citation.dta", clear
	}
	else if "`field'" == "math" {	
		use "${root}/math/output/fellows_matched_rectangular_citation.dta", clear
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
	keep author Female Ambiguous year *_cumulative years_firstpub ///
		fellow_AAAS new_fellow_AAAS year_appointed_AAAS ever_fellow_AAAS AAAS_flags ///
		fellow_NAS new_fellow_NAS year_appointed_NAS ever_fellow_NAS primary_NAS 
	cap drop single* 
	cap drop first*

	* fill in missing for NAS
	foreach var in fellow_NAS new_fellow_NAS ever_fellow_NAS {
		replace `var' = 0 if missing(`var')
	}
	
	* condition on gendered
	drop if Ambiguous == 1
	
	rename (new_fellow_AAAS fellow_AAAS ever_fellow_AAAS) (new_fellow1 fellow1 ever_fellow1)
	rename (new_fellow_NAS fellow_NAS ever_fellow_NAS) (new_fellow2 fellow2 ever_fellow2)

	reshape long new_fellow fellow ever_fellow, i(author year) j(fellowship)

	order author year Female fellowship new_fellow fellow year_appointed_AAAS year_appointed_NAS 
	tostring fellowship, replace
	replace fellowship = "AAAS" if fellowship == "1" 
	replace fellowship = "NAS" if fellowship == "2"
	encode fellowship, gen(nfellowship)
	drop fellowship 
	rename (nfellowship) (fellowship)
	sort fellowship author year
		

	* generate filter for NAS primary fellows. For secondary fellows, we keep them in 
	* the risk set up to and including the year they are elected, but are not counted as
	* a fellow and then dropped after that year
	gen NAS_sample = (fellow == 0 | new_fellow == 1) if fellowship == 2
	replace new_fellow = 0 if primary_NAS == 0 & fellowship == 2
	replace NAS_sample = 0 if year > year_appointed_NAS & primary_NAS == 0 & fellowship == 2

	* same for AAAS 
	gen AAAS_sample = (fellow == 0 | new_fellow == 1) if fellowship == 1
	replace new_fellow = 0 if ((AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) |  (AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)) & fellowship == 1
	replace AAAS_sample = 0 if year > year_appointed_AAAS & ((AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) |  (AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)) & fellowship == 1


	* drop if already fellow before 1960
	replace NAS_sample = 0 if year_appointed_NAS < 1960 & !missing(year_appointed_NAS)
	replace AAAS_sample = 0 if year_appointed_AAAS < 1960 & !missing(year_appointed_AAAS)

	* by decade * Female variable 
	gen Female_1960_1970 = Female * (year >= 1960 & year <= 1979)
	local list_decade 1980 1990 2000 2010
	foreach decade in `list_decade'{
		gen Female_`decade' = Female * (floor(year/10)*10== `decade')
	}
	
	cap drop multi*
	egen total_cite_cumulative = rowtotal(*_cite_cumulative)
	gen asinh_cite_total = asinh(total_cite_cumulative)

	* Controls * 3 20-year time intervals 
	** time interval dummy  
	gen decades_1960 = (year <= 1979)
	gen decades_1980 = (year < 2000 & year > 1979)
	gen decades_2000 = (year > 1999)

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
	
	
	rename nm_paper_cumulative nm_paper_cumulative_total
	
	gen year_1960_1979 = (year >= 1960 & year <= 1979)
	gen year_1980_1999 = (year >= 1980 & year <= 1999)
	gen year_2000_2019 = (year >= 2000 & year <= 2019)
	
	cap drop topcite
	gen topcite = . 
	levelsof decade, local(levels)
	foreach d in `levels'{
		_pctile asinh_cite_total if decade == `d' & AAAS_sample == 1, p(90 95 99 99.5)
		return list
		
		replace topcite = 1 if asinh_cite_total < r(r1) & decade == `d' & AAAS_sample == 1
		replace topcite = 2 if asinh_cite_total < r(r2) & asinh_cite_total >= r(r1) & decade == `d' & AAAS_sample == 1
		replace topcite = 3 if asinh_cite_total < r(r3) & asinh_cite_total >= r(r2) & decade == `d' & AAAS_sample == 1
		replace topcite = 4 if asinh_cite_total < r(r4) & asinh_cite_total >= r(r3) & decade == `d' & AAAS_sample == 1
		replace topcite = 5 if asinh_cite_total >= r(r4) & decade == `d' & AAAS_sample == 1
		
		_pctile asinh_cite_total if decade == `d' & NAS_sample == 1, p(90 95 99 99.5)
		return list
		
		replace topcite = 1 if asinh_cite_total < r(r1) & decade == `d' & NAS_sample == 1
		replace topcite = 2 if asinh_cite_total < r(r2) & asinh_cite_total >= r(r1) & decade == `d' & NAS_sample == 1
		replace topcite = 3 if asinh_cite_total < r(r3) & asinh_cite_total >= r(r2) & decade == `d' & NAS_sample == 1
		replace topcite = 4 if asinh_cite_total < r(r4) & asinh_cite_total >= r(r3) & decade == `d' & NAS_sample == 1
		replace topcite = 5 if asinh_cite_total >= r(r4) & decade == `d' & NAS_sample == 1
		
	}
	
	logit new_fellow ///
			Female_1960_1970 Female_1980 Female_1990 Female_2000 Female_2010 ///
			(year_1960_1979 year_1980_1999 year_2000_2019)# ///
			(c.asinh_cite_total c.*_cite c.*_cumulative i.topcite firstpub_*)#fellowship year#fellowship /// 
			if (NAS_sample == 1 | AAAS_sample == 1) & year < 2020 & year >= 1960, cluster(author) difficult iterate(20)
	estimates store `field'_b
	outreg2 using tables/tableA8.xls, excel bdec(3) sdec(3) adec(5) append addstat(Log-Likelihood, e(ll), R2, e(r2_p), Sample Size, e(N), Degrees of Freedom of the Model, e(df_m))
			
	local cite asinh_*_cite


}


coefplot (psych_b, label(Psychology) msymbol(S)) (econ_b, label(Economics) msymbol(D)) (math_b, label(Math) msymbol(O)), vertical keep(Female_*) order(Female_1960_1970 Female_1980 Female_1990 Female_2000 Female_2010) coeflabels(Female_1960_1970 = "1960s to 1970s" Female_1980 = "1980s" Female_1990 = "1990s" Female_2000 = "2000s" Female_2010 = "2010s") graphregion(color(white)) yline(0) ytitle(Odds Ratio from Pooled Regressions)
graph export figures/figure3_pooled.png, replace



