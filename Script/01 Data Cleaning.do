
************************************ 
** Initialisization
************************************ 

        set type double
        capture log close
        
        

************************************ 
** Setting Globals
************************************ 
        
        
global root         "C:\Users\abrah\Dropbox\oxford_submission" // Change directory accordingly
global raw_data     "$root\Raw_data"
global clean_data   "$root\Clean_data"
global output       "$root\Output"



*****************************************************************
* Lightly Cleaning world bank human capital data (sept 2020)
*****************************************************************
import excel "$raw_data\hci_data_september_2020.xlsx", ///
 sheet("HCI 2020 - MaleFemale") cellrange(A1:M175) firstrow clear
ren LearningAdjustedYearsofSchoo lays
ren ExpectedYearsofSchool eys
ren HarmonizedTestScores hlo
save "$clean_data\hci_data_september_2020.dta",replace




***************************************************************************
* Cleaning world bank human capital data (sept 2020) and combining across sexes
***************************************************************************
*cleaning data for males
import excel "$raw_data\hci_data_september_2020.xlsx", ///
sheet("HCI 2020 - Male") cellrange(A1:M175) firstrow clear

ren LearningAdjustedYearsofSchoo lays
ren ExpectedYearsofSchool eys
ren HarmonizedTestScores hlo


quietly ds CountryName WBCode Region, not

local varlist `r(varlist)'
foreach var of local varlist{
ren `var' `var'_male

}


save "$clean_data\hci_data_male_september_2020.dta",replace

*cleaning data for females
import excel "$raw_data\hci_data_september_2020.xlsx", ///
 sheet("HCI 2020 - Female") cellrange(A1:M175) firstrow clear
ren LearningAdjustedYearsofSchoo lays
ren ExpectedYearsofSchool eys
ren HarmonizedTestScores hlo


quietly ds CountryName WBCode Region, not

local varlist `r(varlist)'
foreach var of local varlist{
ren `var' `var'_fem
}

save "$clean_data\hci_data_female_september_2020.dta",replace




/*combining male and female data across region-country-year*/


use "$clean_data\hci_data_male_september_2020.dta",clear
merge 1:1 CountryName Region WBCode using "$clean_data\hci_data_female_september_2020.dta"
assert _merge==3

ds, has(type string) // only search strings
foreach var in `r(varlist)' {
    replace `var' = "" if `var' == "-" 
}

destring _all,replace


save "$clean_data\hci_data_male_female_september_2020.dta"
