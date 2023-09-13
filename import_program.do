capture program drop import_almalaurea

program import_almalaurea
clear all

args anno tipo anni_dalla_laurea ateneo
*nota: si può sempre usare 1 2 3 4

// Import .csv  
import delimited using "${data_raw}\\`ateneo'\\`anno'\\`anno'_`tipo'_`3'.csv", varnames(2)

//Drop rows with redundant varnames
drop if collettivoselezionato == "Collettivo selezionato"
 
//Just for 2021 LM 3 bologna "Collettivo selezionato (1) "
if `1' == 2021 & "`2'" == "LM" & `3' == 3 & "`4'"=="bologna" {

drop if collettivoselezionato1 == "Collettivo selezionato (1) "

}

********************************************************************************
//Rename variables using external file.xlsx
foreach v of varlist _all  {
quietly renamefrom using "${data_raw}\Renamefrom\clean_names.xlsx", ///
filetype(excel) sheet(Classi_Laurea_`tipo') raw(actual) clean(clean) ///
keeplabel if(actual =="`v'") keepx
}

order _all, alphabetic
order v1 totale_`tipo', first

//Destring variables to be numeric
qui foreach var of varlist _all {
    if "`var'" != "v1" {
        replace `var' = subinstr(`var', ",", ".", .)
		replace `var' = subinstr(`var', "-", ".", .)
		replace `var' = subinstr(`var', "*", ".", .)
		destring `var', replace
    }
}

**nota1: "," cambiate in "." per far capire a Stata che quelli sono numeri (i.e. 0,95 in 0.95). 
**nota2: "-" nel dataset orig. indicano missing values, pertanto cambiati in "."
**nota3: "*" presenti nel dataset del 2015 indica che le statistiche non sono 
// calcolate perché riferite ad un collettivo poco numeroso (inferiore a 5 unità)
// - fonte note metodologiche 2015. Li ho trattati come missing values.

//Drop rows with (only) missing values 
foreach var of varlist _all  {
	if "`var'" != "v1" {
        local myvars `myvars' `var'
	}
}
* display "`myvars'"



egen miss = rowtotal(`myvars'), missing
drop if missing(miss)
drop miss

//Remove punctuation Stata doesn't like
foreach char in " " "," "-" "(" ")" "%" "/" "'" {
    replace v1 = subinstr(v1, "`char'", "", .)
}

//Problem of lenght in varnames
replace v1 = substr(v1, 1, 30)
replace v1=ustrtrim(v1)

//Removing digits at beginning of varnames in v1 (useful from 2020 back)
local n = _N
forvalues i = 1/`n'{
	forvalues num = 0/9{
		if substr(v1[`i'],1,1) == "`num'"{
		replace v1 = "Q_" + v1[`i'] in `i'
		display v1[`i']
}
}
}

//Problem: v1 has some names that are repeated (Donne, Uomini, Totale)
local n = _N
local j=0
forvalues i = 1/`n'{
	
  if v1[`i'] == "Donne" { 
  	local men_row=`i'-1
	local tot_row=`i'+1
  	if `j'==0 { 
		replace v1 = "Donne_tot" in `i'
		replace v1 = "Uomini_tot" in `men_row'
		local j= 1
		}
		
	else if `j'==1 {
		replace v1 = "Donne_tasso_occ" in `i'
		replace v1 = "Uomini_tasso_occ" in `men_row'
		
		if `1' == 2020 | `1' == 2021 | `1' == 2022 {
	replace v1 = "Tassodioccupazione" in `tot_row'
	}
	local j= 2
	
	}
	
	else if `j'==2 {
		replace v1 = "Donne_retr_med" in `i'
		replace v1 = "Uomini_retr_med" in `men_row'
		replace v1 = "Totale_retr_med" in `tot_row'
	}
	
	}
}

//Changing repeated names only in dataset L
if "`tipo'" == "L" { 
forvalues i = 1/`n'{

  local next_val = `i'+2
  local next_row = `i'+1

  if v1[`i'] == "Sisonoiscrittiaduncorsodilaure" { 
	replace v1 = "Iscritti_pri_liv" in `next_val'
	}

  else if v1[`i'] == "Sonoattualmenteiscritti"{
	replace v1 = "Att_iscritti_pri_liv" in `next_val'
	}

  else if v1[`i'] == "Nonlavoranononsonoiscrittiadun"{
	replace v1 = "Nolav_noiscritti_macerc" in `next_row'
	}	
}

//Expoloiting the fact that these repetitions happen in last observations
local m = _N/2

forvalues k = 1/`m'{
 if v1[`k'] == "Altromotivo" {
 replace v1 = "Altromotivo_1" in `k'
 }
else if v1[`k'] == "Motivipersonali" {
 replace v1 = "Motivipersonali_1" in `k'
 }
}
}

********************************************************************************
//Now dataset is ready to be transposed:
sxpose2, clear firstname varname  destring force
rename _varname ClasseLaurea

********************************************************************************
//Rename to have a common name across datasets **ULTIMA MODIFICA DEL 05.07

if `1'==2015 {
	rename Autonomoeffettivo Autonomo
}

else if `1'== 2022 {
	rename Attivitàinproprio Autonomo
	rename Borsaoassegnodistudioodiricerc Assegnodiricerca
}


if "`tipo'" == "L" {

if inlist(`1',2017,2016,2015) {
	rename Sonoattualmenteiscrittiaduncor Sonoattualmenteiscritti
	rename Sonoattualmenteiscrittiadunalt Att_iscritti_pri_liv
}
}

********************************************************************************

//Final details
generate Anno_intervista = `anno'
generate Anni_dalla_laurea = `anni_dalla_laurea'
generate Coorte =  `anno' - `anni_dalla_laurea'

generate TipoCorso = "`tipo'"
label var TipoCorso "Tipologia laurea (triennale, magistrale ciclo unico, professionalizzante)"

generate ClasseLaureaCodice = ""
label var ClasseLaureaCodice "Codice classe di laurea Corso di studi"

generate _pos = strrpos(ClasseLaurea, "_")

replace ClasseLaureaCodice = substr(ClasseLaurea, _pos + 1, .) if ClasseLaurea != "totale_`tipo'"
replace ClasseLaureaCodice = "totale_`tipo'" if ClasseLaurea == "totale_`tipo'"

drop _pos

//Order and save
order ClasseLaurea ClasseLaureaCodice TipoCorso Anno_intervista Anni_dalla_laurea Coorte

*compress
save "${data_clean}\\Temp\\`ateneo'\\`anno'\\`anno'_`tipo'_`3'", replace

end