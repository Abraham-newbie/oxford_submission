

************************************ 
** Initialisization
************************************ 

		set type double
		capture log close
		
		

************************************ 
** Setting Globals
************************************ 
		
		
global root 		"C:\Users\abrah\Dropbox\oxford_submission" // Change directory accordingly
global raw_data 	"$root\Raw_data"
global clean_data 	"$root\Clean_data"
global output 	    "$root\Output"






*************************************************************
*Figure: Schooling Years vs Adjusted Schooling Years Histogram
**************************************************************
/*This figure shows hbar visualization of lays eys over country-region using world bank data from 2020 */

use "$clean_data\hci_data_september_2020.dta",clear


preserve



set scheme s1color
collapse (median)lays (median)eys ,by(Region)
sort lays
graph hbar (asis) eys lays ,over(Region, sort(lays)  label(labsize(small))) scale(*.7)    bar(1, color(erose)) bar(2, color(teal)) ///
blabel(total, format(%9.1f) position(inside) size(small))intensity(70) legend(order(1 "Expected Years of Schooling" 2 "Learning Adjusted Years of Schooling")) 


restore




graph export "$output/eys_lays.png",replace



*****************************************************************
*Scatter: Expected Years of School and Learning Adjusted Years of School
*****************************************************************

/*This figure shows a scatter visualization of eys lays over low-income countries*/


use "$clean_data\hci_data_september_2020.dta",clear

preserve
gsort Region -lays 
bysort Region: gen id =_n


replace WBCode ="" if !inlist(WBCode,"YEM","COM","GHA","KEN") &!inlist(WBCode,"LKA","PSE","YEM","BDI","LBR","NER","UKR","VNM")
/*selecting countries to label*/

*keep if inlist(IncomeGroup,"Lower middle income","Low income")
set scheme plotplain
twoway  ///
		(scatter eys	lays if Region=="Middle East & North Africa" &  inlist(IncomeGroup,"Lower middle income","Low income")  ,mlabel(WBCode) msymbol(circle) msize(vsmall ) mcolor(red)) ///
		(scatter eys	lays if Region=="Sub-Saharan Africa" &  inlist(IncomeGroup,"Lower middle income","Low income") ,mlabel(WBCode) msymbol(circle ) msize(vsmall ) mcolor(blue)) ///
		(scatter eys	lays if !inlist(Region,"Sub-Saharan Africa","Middle East & North Africa") &  inlist(IncomeGroup,"Lower middle income","Low income") ,mlabel(WBCode) msymbol(circle_hollow) msize(small) ) /// 
		  (lfit  eys	lays if inlist(Region,"Sub-Saharan Africa","Middle East & North Africa"),  lpattern(dash) lcolor( khaki ) )  , ///
		 scale(*.9) xtitle("Learning Adjusted Years of Schooling" " ",size(small)  )  ytitle("Expected Years of Schooling" "",size(small)) legend(order(1 "Middle East & North Africa" 2 "Sub-Saharan Africa" 3 "Low Income Countries (other)") position(0) bplacement(seast))  ///
	    xlabel(0(2)14) ylabel(0(2)14)

gen income_region = Region+IncomeGroup

collapse (mean)lays (mean)eys,by(income_region )

restore






graph export "$output/lays_vs_eys_low_income.png",replace



*****************************************************************
*Table: Gender variation in LAYS in 2020
****************************************************************



use "$clean_data/hci_data_female_september_2020.dta",clear
gen lays_adjustment_male = lays_male-eys_male
gen lays_adjustment_fem = lays_fem-eys_fem
/*I calculate LAYS adjustment as difference between lays and eys, i.e, how much does lays reduce eys by? 8 LAYS-7 EYS = -1*/

collapse (median) lays_male  (median) lays_fem (median) lays_adjustment_fem (median) lays_adjustment_male ,by(Region)

gen diff_lays= lays_male-lays_fem
gen diff_lays_adj=   lays_adjustment_male-lays_adjustment_fem


estpost tabstat lays_male  lays_fem  diff_lays  diff_lays_adj, by(Region) 
esttab,   cells("lays_male  lays_fem  diff_lays  diff_lays_adj" ) noobs nomtitle ///
nonumber varlabels(`e(labels)') drop(Total) varwidth(30) b(%9.1f) ///
 tex






*****************************************************************
*Scatter: Log GDP and lays using World Bank Data (2020)
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
/*This is to only label high gdp countries for clarity*/

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





********************************************************************
*Map: Mapping LAYS across countries in Africa using World Bank Data(2020)
*********************************************************************
use "$raw_data/map.dta", replace
drop hlo_m hlo_f hlo 
ren NAME_SORT CountryName

merge 1:1  CountryName using "$clean_data\hci_data_september_2020.dta"


	
set scheme plotplain
replace lays = round(lays,0.1)


spmap lays using "$raw_data/worldcoor2.dta" if CONTINENT=="Africa",  id(id)  clnum(3) fcolor(Blues2) 

 


graph export "$output/map_lays.png",replace





***************************************
* Line graph (lower secondary education completion) using World Bank Data(2020)
***************************************



preserve

use "$raw_data/enroll_learning.dta",clear
keep code country region
egen id=tag(country)
keep if id==1
save "$raw_data/region_match.dta",replace


restore



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



drop if completion_rate==.
collapse (median) completion_rate,by(region Year)
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
scale(*.9) xtitle( "",size(small)  )  ytitle("Completion rate % ",size(small)) legend(order( 1 "Europe & Central Asia" 2 "Latin America & Caribbean"  ///
         3 "Middle East & North Africa" 4 "North America" 5 "Sub-Saharan Africa") position(0) bplacement(seast) size(vsmall)) 



 


graph export "$output/completion_timeseries.png",replace





