

cd "..."

use "data\AAAS.dta", clear

drop if primary == ""

gen pre_1990 = year < 1990
gen female_pre_1990 = Female * (pre_1990)
gen amb_pre_1990 = Ambiguous * (pre_1990)
gen id = _n
gen id_pre_1990 = id if pre_1990


collapse (count) fellow_total = id  fellow_pre_1990 = id_pre_1990 (sum) female_total = Female ambiguous_total = Ambiguous female_pre_1990 = female_pre_1990 ambiguous_pre_1990 = amb_pre_1990, by(subfield) 
sort subfield 

gen share_fem_pre_1990 = female_pre_1990 / (fellow_pre_1990 - ambiguous_pre_1990)
gen fellow_post_1990 = fellow_total - fellow_pre_1990
gen amb_post_1990 = ambiguous_total - ambiguous_pre_1990
gen fem_post_1990 = female_total - female_pre_1990
gen share_fem_post_1990 = fem_post_1990 / (fellow_post_1990 - amb_post_1990)
gen share_fem_total = female_total / (fellow_total - ambiguous_total)

keep subfield fellow_* share_fem_*
order subfield fellow_total share_fem_total fellow_pre_1990 share_fem_pre_1990 fellow_post_1990 share_fem_post_1990

*export excel "AAAS_field_share.xlsx", sheetreplace firstrow(variables) 

************************************************************************************

use "data\NAS.dta", clear

drop if primary == ""

gen pre_1990 = year < 1990
gen female_pre_1990 = Female * (pre_1990)
gen amb_pre_1990 = Ambiguous * (pre_1990)
gen id = _n
gen id_pre_1990 = id if pre_1990


collapse (count) fellow_total = id  fellow_pre_1990 = id_pre_1990 (sum) female_total = Female ambiguous_total = Ambiguous female_pre_1990 = female_pre_1990 ambiguous_pre_1990 = amb_pre_1990, by(primary) 
sort primary 

gen share_fem_pre_1990 = female_pre_1990 / (fellow_pre_1990 - ambiguous_pre_1990)
gen fellow_post_1990 = fellow_total - fellow_pre_1990
gen amb_post_1990 = ambiguous_total - ambiguous_pre_1990
gen fem_post_1990 = female_total - female_pre_1990
gen share_fem_post_1990 = fem_post_1990 / (fellow_post_1990 - amb_post_1990)
gen share_fem_total = female_total / (fellow_total - ambiguous_total)

keep primary fellow_* share_fem_*
order primary fellow_total share_fem_total fellow_pre_1990 share_fem_pre_1990 fellow_post_1990 share_fem_post_1990

drop if primary == "Park" | primary == "les" | primary == "ent, and Security,Primary: Human Environmental Sciences" | primary == "lis" | primary == "o"


*export excel "tables/NAS_field_share.xlsx", sheetreplace firstrow(variables)



************************************************************************************
use "data\NAS.dta", clear

drop if primary == ""
drop if primary == "Park" | primary == "les" | primary == "ent, and Security,Primary: Human Environmental Sciences" | primary == "lis" | primary == "o"

gen pre_1990 = year < 1990
gen female_pre_1990 = Female * (pre_1990)
gen amb_pre_1990 = Ambiguous * (pre_1990)
gen id = _n
gen id_pre_1990 = id if pre_1990

gen subfield_AAAS = primary
replace subfield_AAAS = "Anthropology and Archaeology" if primary == "Anthropology"
replace subfield_AAAS = "Astronomy, Astrophysics, and Earth Sciences" if primary == "Astronomy"
replace subfield_AAAS = "Biochemistry, Biophysics, and Molecular Biology" if primary == "Biochemistry"
replace subfield_AAAS = "Biochemistry, Biophysics, and Molecular Biology" if primary == "Biophysics and Computational Biology"
replace subfield_AAAS = "Computer Sciences" if primary == "Computer and Information Sciences"
replace subfield_AAAS = "Economics" if primary == "Economic Sciences"
replace subfield_AAAS = "Engineering and Technology" if primary == "Engineering Sciences"
replace subfield_AAAS = "Evolution and Ecology" if primary == "Environmental Sciences and Ecology"
replace subfield_AAAS = "Evolution and Ecology" if primary == "Evolutionary Biology"
replace subfield_AAAS = "Mathematics, Applied Mathematics, and Statistics" if primary == "Mathematics"
replace subfield_AAAS = "Medical Sciences" if primary == "Medical Genetics, Hematology, and Oncology"
replace subfield_AAAS = "Medical Sciences" if primary == "Medical Physiology and Metabolism"
replace subfield_AAAS = "Microbiology and Immunology" if primary == "Microbial Biology"
replace subfield_AAAS = "Microbiology and Immunology" if primary == "Immunology and Inflammation"
replace subfield_AAAS = "Neurosciences" if primary == "Cellular and Molecular Neuroscience"
replace subfield_AAAS = "Neurosciences" if primary == "Systems Neuroscience"
replace subfield_AAAS = "Psychological Sciences" if primary == "Psychological and Cognitive Sciences"
replace subfield_AAAS = "Computer Sciences" if primary == "Computer and Information Sciences"




collapse (count) fellow_total = id  fellow_pre_1990 = id_pre_1990 (sum) female_total = Female ambiguous_total = Ambiguous female_pre_1990 = female_pre_1990 ambiguous_pre_1990 = amb_pre_1990, by(subfield_AAAS) 
sort subfield_AAAS

rename * *_NAS
rename subfield_AAAS_NAS subfield_AAAS

save "data/NAS_totals_comp.dta", replace


*** AAAS / NAS combined
use "data\AAAS.dta", clear

drop if subfield == ""

gen pre_1990 = year < 1990
gen female_pre_1990 = Female * (pre_1990)
gen amb_pre_1990 = Ambiguous * (pre_1990)
gen id = _n
gen id_pre_1990 = id if pre_1990


collapse (count) fellow_total = id  fellow_pre_1990 = id_pre_1990 (sum) female_total = Female ambiguous_total = Ambiguous female_pre_1990 = female_pre_1990 ambiguous_pre_1990 = amb_pre_1990, by(subfield) 
sort subfield 

rename * *_AAAS

merge 1:1 subfield_AAAS using "data/NAS_totals_comp.dta"

gen fellowship = "Both" if _merge == 3
replace fellowship = "AAAS Only" if _merge == 1
replace fellowship = "NAS Only" if _merge == 2
drop _merge


qui ds, has(type numeric)
local varlist `r(varlist)'
local toexclude "subfield_AAAS"
local varlist : list varlist - toexclude

foreach var of local varlist {
	replace `var' = 0 if (`var' == .)
}

keep subfield_AAAS fellow_total* fellow_pre_1990* female_total* female_pre_1990* ambiguous_total* fellowship ambiguous_pre_1990*

egen fellow_total = rowtotal(fellow_total*)
egen fellow_pre_1990 = rowtotal(fellow_pre_1990*)
egen female_total = rowtotal(female_total* )
egen female_pre_1990 = rowtotal(female_pre_1990*)
egen ambiguous_total = rowtotal(ambiguous_total*)
egen ambiguous_pre_1990 = rowtotal(ambiguous_pre_1990*)

keep subfield_AAAS fellow_total fellow_pre_1990 female_total female_pre_1990 ambiguous_total ambiguous_pre_1990 fellowship fellow_total_AAAS fellow_total_NAS

gen share_fem_pre_1990 = female_pre_1990 / (fellow_pre_1990 - ambiguous_pre_1990)
gen fellow_post_1990 = fellow_total - fellow_pre_1990
gen amb_post_1990 = ambiguous_total - ambiguous_pre_1990
gen fem_post_1990 = female_total - female_pre_1990
gen share_fem_post_1990 = fem_post_1990 / (fellow_post_1990 - amb_post_1990)
gen share_fem_total = female_total / (fellow_total - ambiguous_total)

keep subfield_AAAS fellow_total fellow_total_AAAS fellow_total_NAS share_fem_total
order subfield_AAAS fellow_total fellow_total_AAAS fellow_total_NAS share_fem_total
rename (subfield_AAAS fellow_total fellow_total_AAAS fellow_total_NAS share_fem_total) /// 
(field Total_Fellow Total_Fellow_AAAS Total_Fellow_NAS Share_Female)

sort Total_Fellow

export excel "tables/AAAS_NAS_field_share_v2.xlsx", sheetreplace firstrow(variables)












