label variable Female "Fraction Female"
label variable Ambiguous "Fraction Unknown Gender"

cap label variable fellow_AAAS "Fellow of AAAS (1980-2019)"
cap label variable fellow_NAS "Fellow of NAS (1980-2019)"

if "`field'" == "psych" {
	label variable PS_cumulative "Psychological Science"
	label variable PR_cumulative "Psychological Review"
	label variable PB_cumulative "Psychological Bulletin"
	label variable TiCS_cumulative "Trends in Cognitive Sciences"
	label variable JEPG_cumulative "Journal of Experimental Psycology: General"
	label variable JPSP_cumulative "Journal of Personality and Social Psychology"
	label variable ARP_cumulative "Annual Review of Psychology"
	label variable AP_cumulative "American Psychologist"
	label variable Cog_cumulative "Cognition"
	label variable DP_cumulative "Development Psychology"
	label variable CD_cumulative "Child Development"
	label variable CP_cumulative "Cognitive Psychology"
	label variable PNAS_cumulative "Proceedings of the National Academy of Sciences"
}
else if "`field'" == "math" {
	label variable AIM_cumulative "Advances in Mathematics"
	label variable AJM_cumulative "American Journal of Mathematics"
	label variable AM_cumulative "Annals of Mathematics"
	label variable AP_cumulative "Annals of Probability"
	label variable AS_cumulative "Annals of Statistics"
	label variable ActaM_cumulative "Acta Mathematica"
	label variable CM_cumulative "Communications on Pure and Applied Math"
	label variable CMP_cumulative "Communications in Mathematical Physics"
	label variable DMJ_cumulative "Duke Mathematical Journal"
	label variable IM_cumulative "Inventiones Mathematicae"
	label variable JAMS_cumulative "Journal of the American Mathematical Society"
	label variable JASA_cumulative "Journal of the American Statistical Association"
	label variable JCP_cumulative "Journal of Computational Statistics"
	label variable PNAS_cumulative "Proceedings of the National Academy of Sciences"
	label variable TAMS_cumulative "Transactions of the American Math. Soc."
}
else if "`field'" == "econ" {
	label variable JE_cumulative "Journal of Econometrics"
	label variable JET_cumulative "Journal of Economic Theory"
	label variable JEP_cumulative "Journal of Economic Perspectives"
	
}

cap program drop list_journal
program list_journal, rclass
	syntax, field(str)
	
	*ordering
	if "`field'" == "psych" {
		unab list_journal: PS_cumulative asinh_PS_cite PR_cumulative asinh_PR_cite ///
			PB_cumulative asinh_PB_cite ///
			TiCS_cumulative asinh_TiCS_cite JEPG_cumulative asinh_JEPG_cite ///
			JPSP_cumulative asinh_JPSP_cite ARP_cumulative asinh_ARP_cite ///
			AP_cumulative asinh_AP_cite CD_cumulative asinh_CD_cite ///
			Cog_cumulative asinh_Cog_cite CP_cumulative asinh_CP_cite ///
			DP_cumulative asinh_DP_cite PNAS_cumulative asinh_PNAS_cite ///
			firstpub_10 firstpub_20 firstpub_30
	}
	else if "`field'" == "math" {
		unab list_journal: AIM_cumulative asinh_AIM_cite AJM_cumulative asinh_AJM_cite ///
			AM_cumulative asinh_AM_cite AP_cumulative  asinh_AP_cite ///
			AS_cumulative  asinh_AS_cite ActaM_cumulative  asinh_ActaM_cite ///
			CM_cumulative  asinh_CM_cite CMP_cumulative  asinh_CMP_cite ///
			DMJ_cumulative  asinh_DMJ_cite IM_cumulative  asinh_IM_cite ///
			JAMS_cumulative  asinh_JAMS_cite JASA_cumulative  asinh_JASA_cite ///
			JCP_cumulative  asinh_JCP_cite ///
			PNAS_cumulative  asinh_PNAS_cite TAMS_cumulative  asinh_TAMS_cite  ///
			firstpub_10 firstpub_20 firstpub_30
	
	}
	else if "`field'" == "econ" {
		unab list_journal: AER_cumulative asinh_AER_cite ECTA_cumulative asinh_ECTA_cite ///
			JPE_cumulative asinh_JPE_cite QJE_cumulative asinh_QJE_cite ///
			REStud_cumulative asinh_REStud_cite JE_cumulative asinh_JE_cite ///
			JET_cumulative asinh_JET_cite RAND_cumulative asinh_RAND_cite ///
			JEP_cumulative asinh_JEP_cite JEL_cumulative asinh_JEL_cite ///
			REStat_cumulative asinh_REStat_cite JF_cumulative asinh_JF_cite ///
			JME_cumulative asinh_JME_cite JPubE_cumulative asinh_JPubE_cite ///
			firstpub_10 firstpub_20 firstpub_30
	}
	return local list_journal = "`list_journal'"

end
