*local atenei all bologna
*display "`atenei'"

foreach atenei in all bologna {

//Append datasets LM LMCU
use "${data_clean}\\Temp\\`atenei'\\2015\\2015_LM_5.dta", clear

append using "${data_clean}\\Temp\\`atenei'\\2015\\2015_LMCU_5.dta"

foreach j in LM LMCU {
forvalues i = 2016(1)2022 {
	forvalues y = 1(2)5 {
	append using "${data_clean}\\Temp\\`atenei'\\`i'\\`i'_`j'_`y'.dta"	
	*erase "${data_clean}\\Temp\\all\\`i'\\`i'_`j'_`y'.dta"
	}
	}
	forvalues b = 1(2)3 {
	append using "${data_clean}\\Temp\\`atenei'\\2015\\2015_`j'_`b'.dta"
	}
	*forvalues c = 1(2)5 {
	*erase "${data_clean}\\Temp\\all\\2022\\2022_`j'_`b'.dta"
	*}
}

//Final variables rename
renamefrom using "${data_raw}\Renamefrom\clean_names.xlsx", ///
filetype(excel) sheet(Final_LM) raw(actual) clean(clean) label(lbl) keepx

//Order like original dataset - each line section
order classe_laurea codice_classe tipo_corso anno_intervista anni_dalla_laurea coorte pop_* ///
formazione_* ///
cond_occ_* tasso_di_* ///
numero_di_occupati occupati_* tempo_* ///
professione_* contratto_* diffusione_* ore_settimanali_lavorate ///
settore_* area_* ///
retribuzione_mensile_* ///
miglioramento_* utilizzo_* adeguatezza_* richiesta_* efficacia_* soddisfazione* ///
utilità_* non_occupati_* ultima_iniziativa_* motivononricerca_*

//Sort
sort tipo_corso codice_classe anno_intervista anni_dalla_laurea
*sort anno codice_classe tipo_corso

//And save final dataset
compress
save "$data_clean\Data_2015_2022_LM_`atenei'", replace

//Save dataset balanced
append using "$data_clean\Missing\missing_2015_2022_`atenei'.dta"
save "$data_clean\Data_2015_2022_LM_balanced_`atenei'.dta", replace

********************************************************************************
//Append datasets L
use "${data_clean}\\Temp\\`atenei'\\2015\\2015_L_1.dta", clear

forvalues y = 2016(1)2022 {
append using "${data_clean}\\Temp\\`atenei'\\`y'\\`y'_L_1.dta"

forvalues i = 2015(1)2022{
	*erase "${data_clean}\\Temp\\`i'\\`i'_L_1.dta"
}
}

//Final variables rename
renamefrom using "${data_raw}\Renamefrom\clean_names.xlsx", ///
filetype(excel) sheet(Final_L) raw(actual) clean(clean) label(lbl) keepx

//Order like original dataset - each line section
order classe_laurea codice_classe tipo_corso anno_intervista anni_dalla_laurea coorte pop_* ///
post_* motivi_* proseg_* ///
formazione_* ///
cond_occ_* tasso_di_* ///
numero_di_occupati occupati_* tempo_* ///
professione_* contratto_* diffusione_* ore_settimanali_lavorate ///
settore_* area_* ///
retribuzione_mensile_* ///
miglioramento_* utilizzo_* adeguatezza_* richiesta_* efficacia_* soddisfazione* ///
non_occupati_* ultima_iniziativa_* motivononricerca_*

//Sort
sort tipo_corso codice_classe anno_intervista

//Save final dataset
compress
save "$data_clean\Data_2015_2022_L_`atenei'", replace

}
