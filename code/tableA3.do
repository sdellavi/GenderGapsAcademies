eststo clear
clear
set matsize 11000

cd "..."
global root ".../data"


global psych_journals JEPG PR PS TiCS PB JPSP ARP PNAS AP CD Cog CP DP

global math_journals AIM AJM AM AP AS ActaM CM CMP DMJ IM JAMS JASA JCP PNAS TAMS

global econ_journals AER ECTA JE JET JPE QJE REStud RAND JEP JEL REStat JF JME JPubE 


foreach field in psych econ math {
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

	local loopjournals = "`field'_journals"
	foreach journal in $`loopjournals' {
		replace `journal'_cumulative = 0 if missing(`journal'_cumulative)
	}

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
	* do not count secondary NAS
	replace new_fellow_NAS = 0 if primary_NAS == 0
	replace fellow_NAS = 0 if primary_NAS == 0
	* keep fellows 1960+
	replace fellow_NAS = 0 if year_appointed_NAS < 1960

	* do not count secondary AAAS
	replace new_fellow_AAAS = 0 if  ///
		(AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
		(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)
	replace fellow_AAAS = 0 if  ///
		(AAAS_flags == 3 & year_appointed_AAAS >= 2000 & year_appointed_AAAS != .) | ///
		(AAAS_flags == 4 & year_appointed_AAAS < 2000 & year_appointed_AAAS != .)
	* keep fellows 1960+
	replace fellow_AAAS = 0 if year_appointed_AAAS < 1960

	* generate first initial variable
	split author, parse(" ")
	local nsplit = r(nvars)
	gen first_initial = (strlen(author1) == 2 & strpos(author1, ".")) | (strlen(author1) == 1)
	gen Ambig_first_initial = (Ambiguous == 1 & first_initial == 1)
	gen Ambig_full_name = (Ambiguous == 1 & first_initial != 1)
	drop author1-author`nsplit'

	* gen year range variable
	gen decade = "." /* drop if not in the range */
	replace decade = "1960-1979" if inrange(year, 1960, 1979)
	replace decade = "1980-1999" if inrange(year, 1980, 1999)
	replace decade = "2000-2019" if inrange(year, 2000, 2019)
	drop if decade == "."

	bysort author decade: gen id = (_n == 1) /* number of unique authors in each decade */
	bysort author year decade: gen id_total = (_n == 1)

	* summary stat locals 
	local fellowships fellow_AAAS fellow_NAS 
	if "`field'" == "psych" {
		local pubstat PS_cumulative PR_cumulative PB_cumulative ///
		TiCS_cumulative JEPG_cumulative JPSP_cumulative ARP_cumulative ///
		AP_cumulative CD_cumulative Cog_cumulative CP_cumulative DP_cumulative PNAS_cumulative ///
		PS_cite_cumulative PR_cite_cumulative PB_cite_cumulative  ///
		TiCS_cite_cumulative JEPG_cite_cumulative JPSP_cite_cumulative ARP_cite_cumulative ///
		AP_cite_cumulative CD_cite_cumulative Cog_cite_cumulative CP_cite_cumulative DP_cite_cumulative ///
		PNAS_cite_cumulative ///
		years_firstpub 
	}
	else if "`field'" == "math" {
		local pubstat AIM_cumulative AJM_cumulative AM_cumulative AP_cumulative ///
			AS_cumulative ActaM_cumulative CM_cumulative CMP_cumulative DMJ_cumulative ///
			IM_cumulative JAMS_cumulative JASA_cumulative JCP_cumulative ///
			PNAS_cumulative TAMS_cumulative ///
			 ///
			AIM_cite_cumulative AJM_cite_cumulative AM_cite_cumulative AP_cite_cumulative ///
			AS_cite_cumulative ActaM_cite_cumulative CM_cite_cumulative CMP_cite_cumulative DMJ_cite_cumulative ///
			IM_cite_cumulative JAMS_cite_cumulative JASA_cite_cumulative JCP_cite_cumulative ///
			PNAS_cite_cumulative TAMS_cite_cumulative ///
			years_firstpub
		
	} 
	else if "`field'" == "econ" {
		local pubstat AER_cumulative ECTA_cumulative JPE_cumulative QJE_cumulative ///
			REStud_cumulative JE_cumulative JET_cumulative ///
			RAND_cumulative JEP_cumulative JEL_cumulative REStat_cumulative ///
			JF_cumulative JME_cumulative JPubE_cumulative  ///
			///
			AER_cite_cumulative ECTA_cite_cumulative JPE_cite_cumulative ///
			QJE_cite_cumulative REStud_cite_cumulative JE_cite_cumulative JET_cite_cumulative ///
			RAND_cite_cumulative JEP_cite_cumulative JEL_cite_cumulative REStat_cite_cumulative ///
			JF_cite_cumulative JME_cite_cumulative JPubE_cite_cumulative ///
			years_firstpub
	}


	* ==============================================================================
	* summary statistics 
	levelsof decade, local(levels) 

	foreach decade in `levels'{	
		
		local years = substr("`decade'", 1, 4)+"_"+substr("`decade'", 6, 9)
		
		* gender summary statistics
		eststo f_`years': qui estpost tabstat Female Ambig_first_initial Ambig_full_name ///
		if decade == "`decade'", s(mean) c(statistics) listwise
		
		* fellowship specific summary statistics
		eststo tab1_`years': qui estpost tabstat `fellowships' ///
		if decade == "`decade'", s(mean) c(statistics) listwise
		
		* journal specific summary statistics
		eststo tab2_`years': qui estpost tabstat `pubstat' ///
		if decade == "`decade'", s(mean) c(statistics) listwise
		
		* journal specific summary statistics
		eststo tab3_`years': qui estpost tabstat id_total id ///
		if decade == "`decade'", s(sum) c(statistics) listwise
		
		local list_gender Male Female 
		
		foreach gender in `list_gender'{
					
			local g = lower("`gender'")
			
			eststo f_`years'_`g': qui estpost tabstat Female Ambig_first_initial Ambig_full_name ///
			if decade == "`decade'" & `gender' == 1, s(mean) c(statistics) listwise
			
			eststo tab1_`years'_`g': qui estpost tabstat `fellowships' ///
			if decade == "`decade'" & `gender' == 1, s(mean) c(statistics) listwise
			
			eststo tab2_`years'_`g': qui estpost tabstat `pubstat' ///
			if decade == "`decade'" & `gender' == 1, s(mean) c(statistics) listwise
			
			eststo tab3_`years'_`g': qui estpost tabstat id_total id ///
			if decade == "`decade'" & `gender' == 1, s(sum) c(statistics) listwise
			
		}
		
	}

	* ==============================================================================
	* output file 


	label variable Female "Percent Female"
	label variable Ambiguous "Percent Unknown Gender"
	label variable Ambig_first_initial "Percent Unknown First Initial Name"
	label variable Ambig_full_name "Percent Unknown Full First Name"
	label variable fellow_AAAS "Fellow of AAAS (1960-2019)"
	label variable fellow_NAS "Fellow of NAS (1960-2019)"
	if "`field'" == "psych" {
		foreach type in "" "_cite" {
			label variable PS`type'_cumulative "Psychological Science"
			label variable PR`type'_cumulative "Psychological Review"
			label variable PB`type'_cumulative "Psychological Bulletin"
			*label variable NBR_`type'_cumulative "Neuroscience & Biobehavioral Review"
			label variable TiCS`type'_cumulative "Trends in Cognitive Sciences"
			label variable JEPG`type'_cumulative "Journal of Experimental Psycology: General"
			label variable JPSP`type'_cumulative "Journal of Personality and Social Psychology"
			label variable ARP`type'_cumulative "Annual Review of Psychology"
			label variable AP`type'_cumulative "American Psychologist"
			label variable Cog`type'_cumulative "Cognition"
			label variable DP`type'_cumulative "Development Psychology"
			label variable CD`type'_cumulative "Child Development"
			label variable CP`type'_cumulative "Cognitive Psychology"
			label variable PNAS`type'_cumulative "Proceedings of the National Academy of Sciences"
		}
	}
	else if "`field'" == "math" {
		foreach type in "" "_cite" {
			label variable AIM`type'_cumulative "Advances in Mathematics"
			label variable AJM`type'_cumulative "American Journal of Mathematics"
			label variable AM`type'_cumulative "Annals of Mathematics"
			label variable AP`type'_cumulative "Annals of Probability"
			label variable AS`type'_cumulative "Annals of Statistics"
			label variable ActaM`type'_cumulative "Acta Mathematica"
			label variable CM`type'_cumulative "Communications on Pure and Applied Math"
			label variable CMP`type'_cumulative "Communications in Mathematical Physics"
			label variable DMJ`type'_cumulative "Duke Mathematical Journal"
			label variable IM`type'_cumulative "Inventiones Mathematicae"
			label variable JAMS`type'_cumulative "Journal of the American Mathematical Society"
			label variable JASA`type'_cumulative "Journal of the American Statistical Association"
			label variable JCP`type'_cumulative "Journal of Computational Statistics"
			label variable PNAS`type'_cumulative "Proceedings of the National Academy of Sciences"
			label variable TAMS`type'_cumulative "Transactions of the American Math. Soc."
		}
	}
	
	label variable id "Number of Authors"


	local numbers ",'(1),'(2),'(3),,'(4),'(5),'(6)"

	esttab f_1960_1979* f_1980_1999* f_2000_2019* using tables/tableA3_`field'.csv, ///
	main(mean %12.4fc) nodepvars noobs nostar unstack nonote nogaps nonumbers onecell eqlabels(none) ///
	title("TABLE I") ///
	mgroups(1960-1979 1980-1999 2000-2019, pattern(1 0 0 1 0 0 1 0 0)) ///
	mtitles("All" "Male" "Female" "All" "Male" "Female") posthead(`numbers') ///
	extracols(4 7) label replace 

	esttab tab1_1960_1979* tab1_1980_1999* tab1_2000_2019* using tables/tableA3_`field'.csv, ///
	main(mean %12.4fc) nodepvars noobs nostar unstack nonote nonumbers nogaps onecell nomtitle eqlabels(none) ///
	refcat(fellow_AAAS "Fellowships (at Election)", nolabel) ///
	extracols(4 7) label append
	
	
	local psych_start = "PS"
	local math_start = "AIM"
	local econ_start = "AER"
	
	if "`field'" == "psych" | "`field'" == "econ" {
		esttab tab2_1960_1979* tab2_1980_1999* tab2_2000_2019* using tables/tableA3_`field'.csv, ///
		unstack main(mean %12.2fc) nodepvars nostar nomtitle nonumbers nonote nogaps onecell ///
		refcat(``field'_start'_cumulative "Cumulative publications in Psychology journals" ///
			``field'_start'_cite_cumulative "Cum. citations in Psychology journals" ///
			years_firstpub "", nolabel) ///
		extracols(4 7) label append 
	}
	
	else if "`field'" == "math" {
		esttab tab2_1960_1979* tab2_1980_1999* tab2_2000_2019* using tables/tableA3_`field'.csv, ///
		unstack main(mean %12.2fc) nodepvars nostar nomtitle nonumbers nonote nogaps onecell ///
		refcat(AIM_cumulative "Cumulative publications in Math journals" ///
			/*AIM_cite_cumulative "Cum. citations in Math journals"*/ years_firstpub "", nolabel) ///
		extracols(4 7) label append 
	
	}
	esttab tab3_1960_1979* tab3_1980_1999* tab3_2000_2019* using tables/tableA3_`field'.csv, ///
	unstack main(sum) nodepvars nostar noobs nomtitle nonumbers nonote nogaps onecell ///
	refcat(id_total "", nolabel) ///
	extracols(4 7) label append 

	** rescale shares to percentages
	import delimited "tables/tableA3_`field'.csv", clear

	* define locals to convert to percentage
	local Female "Percent Female"
	local Ambiguous "Percent Unknown Gender"
	local Ambig_first_initial "Percent Unknown First Initial Name"
	local Ambig_full_name "Percent Unknown Full First Name"
	local fellow_AAAS "Fellow of AAAS (1960-2019)"
	local fellow_NAS "Fellow of NAS (1960-2019)"


	* Convert to percent 
	foreach var in v2 v3 v4 v6 v7 v8 v10 v11 v12 {

		replace `var' = subinstr(`var', ".", "", .) ///
			if strpos(v1, "`Female'") | strpos(v1, "`Ambiguous'") ///
			 | strpos(v1, "`Ambig_first_initial'") | strpos(v1, "`Ambig_full_name'") ///
			 | strpos(v1, "`fellow_AAAS'") | strpos(v1, "`fellow_NAS'") 
		replace `var' = substr(`var', 1, 5) + "." + substr(`var', 6, 9) ///
			if strpos(v1, "`Female'") | strpos(v1, "`Ambiguous'") ///
			 | strpos(v1, "`Ambig_first_initial'") | strpos(v1, "`Ambig_full_name'") ///
			 | strpos(v1, "`fellow_AAAS'") | strpos(v1, "`fellow_NAS'") 
	}

	export delimited "tables/tableA3_`field'.csv", replace
}
