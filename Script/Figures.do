

************************************ 
** Initialisization
************************************ 

		set type double
		capture log close
		
		

************************************ 
** Setting Globals
************************************ 
		
		
global root 		"C:\Users\abrah\Dropbox\RA Task Oxford" // Change directory accordingly
global raw_data 	"$root\Raw_data"
global clean_data 	"$root\Clean_data"
global output 	    "$root\Output"









***********************************
* Density plot of enrollment
************************************


use "$raw_data\enroll_learning.dta", replace



preserve




set scheme plotplain
twoway kdensity pri if region=="Sub-Saharan Africa", xtitle("Primary Enrollment Rate") ytitle(Density)  color(black*.05) lcolor(black)  lwidth(medthick) ///  
|| kdensity pri if region=="Middle East & North Africa" , color(black*.05) lcolor(blue)  lwidth(medthick) || kdensity pri if region=="Europe & Central Asia"  , color(black*.05) lcolor(red)  lwidth(medthick)  || ///
 kdensity pri if region=="East Asia & Pacific" ,  scale(*.9) ///
 lwidth(medthick)  legend(order(1 "Sub-Saharan Africa" 2 "Middle East & North Africa" 3 "Europe & Central Asia" 4 "East Asia & Pacific") col(1) pos(1) ring(0))   

restore


graph export "$output/enrollment_density.png",replace



***********************************
* Histogram of Average Enrollment
************************************

use "$raw_data\enroll_learning.dta", replace
preserve

egen max_hlo= max(hlo)


keep if year==2010
collapse (mean)pri (mean) hlo (mean)max_hlo,by(region)
set scheme plottig
gen hlo_scale = hlo/625*100

set scheme s1color
graph hbar pri hlo_scale ,over(region, label(labsize(vsmall))  relabel(`r(relabel)')) scale(*.5)  blabel(bar,size(vsmall)) ///
blabel(total, format(%9.1f)  position(inside) )intensity(70) asyvars legend(order(1 "Primary Enrollment Rate" 2 "Scaled HLO"))  bar(1, color(erose)) bar(2, color(teal)) ///
yscale(r(0(30)112))


restore




graph export "$output/enrollment_scaled_hlo.png",replace




*****************************************************************
* Lightly Cleaning world bank human capital data (sept 2020)
*****************************************************************
import excel "$raw_data\hci_data_september_2020.xlsx", ///
 sheet("HCI 2020 - MaleFemale") cellrange(A1:M175) firstrow clear
ren LearningAdjustedYearsofSchoo lays
ren ExpectedYearsofSchool eys
ren HarmonizedTestScores hlo
save "$clean_data\hci_data_september_2020.dta",replace





*************************************************************
*Figure: Schooling Years vs Adjusted Schooling Years Histogram
**************************************************************


use "$clean_data\hci_data_september_2020.dta",clear


preserve



set scheme s1color
collapse (mean)lays (mean)eys ,by(Region)
sort lays
graph hbar (asis) eys lays ,over(Region, sort(lays) label(labsize(small))) scale(*.7)    bar(1, color(erose)) bar(2, color(teal)) ///
blabel(total, format(%9.1f) position(inside) size(small))intensity(70) legend(order(1 "Expected Years of Schooling" 2 "Learning Adjusted Years of Schooling")) 


restore




graph export "$output/eys_lays.png",replace



*****************************************************************
*Scatter: Expectes Years of School and Learning Adjusted Years of School
*****************************************************************
use "$clean_data\hci_data_september_2020.dta",clear

preserve
gsort Region -lays
bysort Region: gen id =_n


replace WBCode ="" if !inlist(WBCode,"YEM","COM","GHA","KEN") &!inlist(WBCode,"LKA","PSE","YEM","BDI","LBR","NER","UKR","VNM")


*keep if inlist(IncomeGroup,"Lower middle income","Low income")
set scheme plotplain
twoway  ///
		(scatter eys	lays if Region=="Middle East & North Africa" &  inlist(IncomeGroup,"Lower middle income","Low income") ,mlabel(WBCode) msymbol(circle) msize(vsmall ) mcolor(red)) ///
		(scatter eys	lays if Region=="Sub-Saharan Africa" &  inlist(IncomeGroup,"Lower middle income","Low income") ,mlabel(WBCode) msymbol(circle ) msize(vsmall ) mcolor(blue)) ///
		(scatter eys	lays if !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa") &  inlist(IncomeGroup,"Lower middle income","Low income") ,mlabel(WBCode) msymbol(circle_hollow) msize(small) ) /// 
		  (lfit  eys	lays if inlist(Region,"Sub-Saharan Africa","Middle East & North Africa"),  lpattern(dash) lcolor( khaki ) ) , ///
		 scale(*.9) xtitle("Learning Adjusted Years of Schooling" " ",size(small)  )  ytitle("Expected Years of Schooling" "",size(small)) legend(order(1 "Middle East & North Africa" 2 "Sub-Saharan Africa" 3 "Low Income Countries (other)") position(0) bplacement(seast))  ///
	    xlabel(0(2)14) ylabel(0(2)14)

gen income_region = Region+IncomeGroup

collapse (mean)lays (mean)eys,by(income_region )

restore






graph export "$output/lays_vs_eys_low_income.png",replace




*****************************************************************
*Scatter: Learning Adjusted Years of School for Male vs Female
****************************************************************




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






use "$clean_data\hci_data_male_september_2020.dta",clear
merge 1:1 CountryName Region WBCode using "$clean_data\hci_data_female_september_2020.dta"
assert _merge==3

ds, has(type string) // only search strings
foreach var in `r(varlist)' {
	replace `var' = "" if `var' == "-" 
}

destring _all,replace




preserve
sort Region lays_fem lays_male
bysort Region: gen id =_n


replace WBCode ="" if id>2 & !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

replace WBCode = "" if id>5 &  inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

count if WBCode!=""

drop if WBCode=="HND" /*dropped for purely aesthetic reasons - to avoid mlabel overlap*/

*keep if id<=4 | inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

set scheme plotplain
twoway  ///
		(scatter lays_fem	lays_male if Region=="Middle East & North Africa",  mlabel(WBCode)  msymbol(circle) mlabsize(small) msize(vsmall ) mcolor(red)) ///
		(scatter lays_fem	lays_male if Region=="Sub-Saharan Africa", mlabel(WBCode) msymbol(circle) mlabsize(small) msize(vsmall ) mcolor(blue)) ///
		(scatter lays_fem	lays_male if !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa") , mlabel(WBCode) mlabsize(small)  msymbol(circle) msize(vsmall ) ) , ///
		  xlabel(0(2)14) ylabel(0(2)14)  scale(*.6) xtitle( "Learning Adjusted Years of Schooling (Male) ",size(small)  )  ytitle("Learning Adjusted Years of Schooling  (Female)",size(small)) legend(order(1 "Middle East & North Africa" 2 "Sub-Saharan Africa") position(0) bplacement(seast))  ///
	    
restore






graph export "$output/lays_vs_lays_sex.png",replace

*****************************************************************
*Make Table here
****************************************************************


*****************************************************************
*HLO - with country fixed effects
*****************************************************************



use "$clean_data\hci_data_september_2020.dta",clear








preserve

set scheme plotplain
twoway kdensity lays if Region=="Sub-Saharan Africa", xtitle("Learning Adjusted Years of Schooling") ytitle(Density)  color(black*.05) lcolor(black)  lwidth(medthick) ///  
||kdensity lays if IncomeGroup=="Low income"  &  Region!="Sub-Saharan Africa" , color(black*.05) lcolor(red)  lwidth(medthick)  || ///
 kdensity lays if IncomeGroup=="Upper middle income" &  Region!="Sub-Saharan Africa"|| ///
 kdensity lays if IncomeGroup=="Lower middle income" &  Region!="Sub-Saharan Africa",  ///
 lwidth(medthick)  scale(*.9)  legend(order(1 "Sub-Saharan Africa" 2 "Low Income" 3 "Upper middle income" 4 "Lower middle income"  ) col(1) pos(1) ring(0))   

restore

graph export "$output/prim_enroll_rate_density.png",replace



*****************************************************************
*SCATTER lays vs Human Capital Index
*****************************************************************






use "$clean_data\hci_data_september_2020.dta",clear


preserve
sort Region lays
bysort Region: gen id =_n


replace WBCode ="" if id>2 & !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

replace WBCode = "" if id>1 &  inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

count if WBCode!=""

drop if WBCode=="HND" |  WBCode=="PAK" /*dropped for purely aesthetic reasons - to avoid mlabel overlap*/


set scheme plotplain
twoway  ///
		(scatter lays	HUMANCAPITALINDEX2020 if Region=="Middle East & North Africa",  mlabel(WBCode)  msymbol(circle)  mlabsize(small) msize(vsmall ) mcolor(red)) ///
		(scatter lays	HUMANCAPITALINDEX2020 if Region=="Sub-Saharan Africa", mlabel(WBCode) msymbol(circle)  mlabsize(small) msize(vsmall ) mcolor(blue)) ///
		(scatter lays	HUMANCAPITALINDEX2020 if !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa") , mlabel(WBCode) mlabsize(small)  msymbol(circle) msize(vsmall ) ) ///
		  (lfit  lays	HUMANCAPITALINDEX2020,  lpattern( dash ) lcolor( khaki ) ) , ///
		    scale(*.6) xtitle( "Learning Adjusted Years of Schooling  ",size(small)  )  ytitle("Human Capital Index 2020",size(small)) legend(order(1 "Middle East & North Africa" 2 "Sub-Saharan Africa") position(0) bplacement(seast))  ///
	    
restore


graph export "$output/lays_HUMANCAPITALINDEX2020.png",replace







*****************************************************************
* Fixed effects Learning Adjusted Years
*****************************************************************

*Replication from Angrist et. al.


set scheme plotplainblind

    use "$raw_data/enroll_learning.dta",replace 

	
	** country-fixed effects by region
	tsset code_num year
	levelsof region_num, local(region)
	foreach region in `region' {
	areg hlo year i.code_num if region_num == `region', absorb(code_num)
	predict hlo_`region' if region_num == `region', xb
	}
	egen hlo2 = rowmean(hlo_*)
	collapse hlo2 hlo, by(region year)
	replace hlo2 = round(hlo2, .1)
	
	#delimit ;
	graph twoway 
        lfit hlo2 year if region == "North America", lwidth(.5) ||
		lfit hlo2 year if region == "East Asia & Pacific", lwidth(.5) ||
		lfit hlo2 year if region == "Europe & Central Asia", lwidth(.5)||
		lfit hlo2 year if region == "Latin America & Caribbean", lpattern(dash) lwidth(.5) ||
		lfit hlo2 year if region == "Middle East & North Africa", lwidth(.5)  ||
		lfit hlo2 year if region == "Sub-Saharan Africa", lwidth(.5) lpattern(dash) ||
		scatter hlo2 year if region == "North America" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(black) mlabpos(12) || 
		scatter hlo2 year if region == "East Asia & Pacific" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(gray) mlabpos(6) ||
		scatter hlo2 year if region == "Europe & Central Asia" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(blue*.8) mlabpos(9) ||
		scatter hlo2 year if region == "Latin America & Caribbean" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(green) mlabpos(12) ||
		scatter hlo2 year if region == "Middle East & North Africa" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(pink*.8) mlabpos(12) ||
		scatter hlo2 year if region == "Sub-Saharan Africa" & year == 2000, mlabel(hlo2) msymbol(p) mcolor(orange) mlabpos(6) ||
	    scatter hlo2 year if region == "North America" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(black) mlabpos(12) || 
		scatter hlo2 year if region == "East Asia & Pacific" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(gray) mlabpos(3) ||
		scatter hlo2 year if region == "Europe & Central Asia" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(blue*.8) mlabpos(6) ||
		scatter hlo2 year if region == "Latin America & Caribbean" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(green) mlabpos(12) ||
		scatter hlo2 year if region == "Middle East & North Africa" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(pink*.8) mlabpos(12) ||
		scatter hlo2 year if region == "Sub-Saharan Africa" & year == 2015, mlabel(hlo2) msymbol(p) mcolor(orange) mlabpos(6) ||
	
	,legend(order(1 "North America"  2 "East Asia and Pacific" 3 "Europe & Central Asia"  4 "LAC"  5 "Middle East & North Africa" 6 "Sub-Saharan Africa")) 
	ytitle("Harmonized Learning Outcome")  scale(*.6)  
    xtitle("Year")   
    yscale(r(200(100)700))

    ylabel(200(100)700)    
	name(figure2b, replace)
	;

	#delimit cr

	// combined


graph export "$output/hlo_year.png",replace










*****************************************************************
*Scatter: Log GDP Hlo *using data from paper 
*****************************************************************





import delimited "$raw_data\world_bank_gdp.csv", /// ()
clear

keep v1 v2 v65


drop if inlist(v2,"World Development Indicators","2022-06-30","Country Code")
ren v1 CountryName
ren v2 WBCode
ren v65 GDP_2020



merge 1:1 CountryName  WBCode using "$clean_data\hci_data_september_2020.dta"
keep if _merge==3
gsort Region -GDP_2020
bysort Region: gen id =_n


bysort Region: replace WBCode ="" if id>2 & !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa")

bysort Region: replace WBCode = "" if id>3 &  inlist(Region,"Middle East & North Africa")

bysort Region: replace WBCode = "" if id>9 &  inlist(Region,"Sub-Saharan Africa") & !inlist(WBCode,"BDI","MOZ","MDG","CAF")

count if WBCode!=""
gen log_GDP_2020 = log(GDP_2020)

set scheme plotplain
twoway  ///
        (lfit lays	log_GDP_2020,  lpattern( dash ) lcolor( khaki ) ) ///
		(scatter lays	log_GDP_2020  if Region=="Middle East & North Africa", mlabel(WBCode)   color(%30) msymbol(circle) mlabsize(small) msize(small ) mcolor(red)) ///
		(scatter lays	log_GDP_2020  if Region=="Sub-Saharan Africa",  mlabel(WBCode) color(%30) msymbol(circle) mlabsize(small) msize(small ) mcolor(blue)) ///
		(scatter lays	log_GDP_2020  if !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa") ,  color(%30) mlabel(WBCode) mcolor(gray) mlabsize(small)  msymbol(circle) msize(small ) ) , ///
		    scale(*.7) xtitle( "Log GDP per capita 2020",size(small)  )  ytitle("Learning Adjusted Years of Schooling",size(small)) legend(order( 2 "Middle East & North Africa" 3 "Sub-Saharan Africa") position(0) bplacement(seast))  ///


graph export "$output/GDP_lays.png",replace



***************************************
*Average years of schooling of the cohort of 25‐ to 29‐year‐olds, unadjusted and 
*adjusted for learning (using the LAYS adjustment) 
***************************************
use "$raw_data/map.dta", replace
drop hlo_m hlo_f hlo 
ren NAME_SORT CountryName

merge 1:1  CountryName using "$clean_data\hci_data_september_2020.dta"


	
set scheme plotplain
replace lays = round(lays,0.1)


spmap lays using "$raw_data/worldcoor2.dta" if CONTINENT=="Africa",  id(id)  clnum(3) fcolor(Blues2) 

 


graph export "$output/map_lays.png",replace





***************************************
* Line graph (time-series) LAYS and EYS over the years
***************************************



preserve

use "$raw_data/enroll_learning.dta",clear
keep code country region
egen id=tag(country)
keep if id==1
save "$raw_data/region_match.dta",replace


restore



set scheme plotplain



import excel "$raw_data\Data_Extract_From_Education_Statistics_-_All_Indicators.xlsx", ///
 firstrow clear

ds, has(type string) // only search strings
foreach var in `r(varlist)' {
	replace `var' = "" if `var' == ".." 

}


egen id=tag(CountryName CountryCode)
keep if id==1
reshape long YR, i(CountryCode CountryName) j(Year)
drop id 
destring _all,replace
ren YR completion_rate
keep if completion_rate!=.
ren CountryCode code 
ren CountryName country



merge m:1 code country using "$raw_data/region_match.dta"
keep if _merge==3




collapse (mean) completion_rate,by(region Year)
sort region Year
replace completion_rate= round(completion_rate, .1)

twoway  ///
		(line completion_rate	Year if region=="Europe & Central Asia") ///
		(line completion_rate	Year if region=="Latin America & Caribbean") ///
		(line completion_rate	Year if region=="Middle East & North Africa") ///
		(line completion_rate	Year if region=="North America") ///
		(line completion_rate	Year if region=="Sub-Saharan Africa")  ///
	(scatter completion_rate Year if region == "Europe & Central Asia"& Year == 2004, mlabel(completion_rate) msymbol(p) mcolor(black) mlabpos(12))  ///
		(scatter completion_rate  Year if region == "Latin America & Caribbean" & Year == 2000, mlabel(completion_rate) msymbol(p) mcolor(gray) mlabpos(12)) ///
		(scatter completion_rate Year if region == "Middle East & North Africa" & Year == 2002, mlabel(completion_rate) msymbol(p) mcolor(blue*.8) mlabpos(12) ) ///
		(scatter completion_rate Year if region == "North America" & Year == 2000, mlabel(completion_rate) msymbol(completion_rate) mcolor(green) mlabpos(12))  ///
		(scatter completion_rate Year if region == "Sub-Saharan Africa" & Year == 2000, mlabel(completion_rate) msymbol(p) mcolor(orange) mlabpos(12)) ///
			(scatter completion_rate Year if region == "Europe & Central Asia"& Year == 2014, mlabel(completion_rate) msymbol(p) mcolor(black) mlabpos(12))  ///
		(scatter completion_rate  Year if region == "Latin America & Caribbean" & Year == 2017, mlabel(completion_rate) msymbol(p) mcolor(gray) mlabpos(12)) ///
		(scatter completion_rate Year if region == "Middle East & North Africa" & Year == 2018, mlabel(completion_rate) msymbol(p) mcolor(blue*.8) mlabpos(12) ) ///
		(scatter completion_rate Year if region == "North America" & Year == 2015, mlabel(completion_rate) msymbol(completion_rate) mcolor(green) mlabpos(12))  ///
		(scatter completion_rate Year if region == "Sub-Saharan Africa" & Year == 2019, mlabel(completion_rate) msymbol(p) mcolor(orange) mlabpos(12)) ,   ///
		 yscale(r(10(10)100)) ylabel(10(10)100)    ///
scale(*.7) xtitle( "",size(small)  )  ytitle("Completion rate % (lower secondary education)",size(small)) legend(order( 1 "Europe & Central Asia" 2 "Latin America & Caribbean"  ///
         3 "Middle East & North Africa" 4 "North America" 5 "Sub-Saharan Africa") position(0) bplacement(seast)) 



 


graph export "$output/completion_timeseries.png",replace





