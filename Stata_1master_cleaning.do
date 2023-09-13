macro drop _all

local directory "`c(pwd)'"
display "`directory'"

// Declare root dir
global root					"`directory'"

// Declare global dirs
global code					${root}\Code
global data					${root}\Data
global data_raw				${data}\Raw
global data_clean			${data}\Clean
global log					${root}\Log

********************************************************************************
********************************************************************************
capture log close
log using "$log\Cleaning", text replace 

//Import program
do "$code\import_program.do"

/*Program "import_almalaurea" - arguments:

1st: anno raccolta dati
2nd: tipologia laurea ("L" "LM o "LMCU")
3rd: anni dalla laurea (1,3,5 per LM O LMCU / 1 per L)
4th: ateneo (all / bologna)
*/

//Run code years 2015-2022 for LM LMCU
forvalues i = 2015(1)2022 {
	foreach j in "LM" "LMCU" {
	forvalues y = 1(2)5 {
	foreach a in all bologna {	
	import_almalaurea `i' `j' `y' `a'
}
}
}
}

//Run code years 2015-2021 for L
forvalues i = 2015(1)2022 {
	foreach a in all bologna {
	import_almalaurea `i' L 1 `a'
}
}

//Append and save final dataset
do "$code\append.do"

log close
