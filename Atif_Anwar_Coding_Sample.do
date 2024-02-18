/* 
Name: Atif Anwar_Sample Code.do
Last Updated: Dec 2023
Author: Atif Anwar 
Description: This do file reads NFHS 5th round, cleans the data, prepares the final dataset for 
analysis and creates required figures/graphs.
*/

********************************************************    SETUP AND PRELIMINARY COMMANDS         
*******************************************************************************

 
	clear all			// Start with a clean slate

	
	* Setting up the project working folder 
    global projdir "D:\sample code\ra_task\"
	
	*Log Files
	global logfiles "$projdir\logfiles"

    *Raw Data Folder
    global raw "$projdir\raw_data"
	
	*Intermediate Data Folder (for storing preliminary data files)
	global intermediate "$projdir\intermediate_data"

    *Folder where the Final Data set is stored
    global final "$projdir\final_data"

    *Folder for Output (tables and graphs) 
    global output "$projdir\final_output"

    *Setting Working Directory
    cd "$projdir"
	
	*Open log file
	log using "$logfiles\sample_code.txt"
	

use "$raw\ct\IAIR7EFL.DTA", clear // Women Dataset

** Restricting the sample to currently pregnant 
keep if v213==1
save "$final\sample_women_dataset.dta",replace

use "$final\sample_women_dataset.dta" , clear

*******************************************************************************
***     DATA   CLEANING	                          
*******************************************************************************	

////// GENERATING VARIABLES

/// Outcome Variables
* 1. Unintended Pregnancy - ut_preg = 1 =True
recode v225 (1 = 0 "Planned") (2/3= 1 "Unintended"), gen(ut_preg)
lab var ut_preg "Pregnacy Planning Status"

* 2. Unwanted Prganancy
recode v225 (1/2= 0 "Wanted") (3=1 "Unwanted") ,gen(unwanted)
lab var unwanted "Unwanted Pregnancy"
tab unwanted [iw=wt]



/// CONTROLS

* MASS MEDIA EXPOSURE
tab v157 // newspaper
tab v158 // radio
tab v159 // tv
tab s113 // cinema hall

gen newspaper=. 
replace newspaper = 0 if v157==0 
replace newspaper = 1 if v157==1 | v157 ==2 
tab newspaper

gen radio=. 
replace radio = 0 if v158==0 
replace radio = 1 if v158==1 | v158 ==2 
tab radio

gen tv=. 
replace tv = 0 if v159==0 
replace tv = 1 if v159==1 | v159 ==2 
tab tv

gen mass_media=0
replace mass_media = 1 if newspaper==1 | radio==1 | tv==1 | s113 == 1 & !missing(newspaper, radio, tv, s113)
tab mass_media
lab var mass_media "Mass Media Exposure"
lab define mass_media 0 "No" 1 "Yes" //// Yes means exposed to atleast one of the 4 for atleast once a week/month(for cinema)
lab values mass_media mass_media



* WOMEN AUTONOMY
*creating dummy variable 0 and 1 for decision making "Y"
*Health care
gen dm_health_care = 1 if v743a == 1 | v743a == 2
replace dm_health_care = 0 if v743a == 4 | v743a == 5 | v743a == 6

*large purchases
gen dm_large_pur = 1 if v743b == 1 | v743b == 2
replace dm_large_pur = 0 if v743b == 4 | v743b == 5 | v743b == 6

*family visits
gen dm_fam_visit = 1 if v743d == 1 | v743d == 2
replace dm_fam_visit = 0 if v743d == 4 | v743d == 5 | v743d == 6

**Creating an overall Y variable by combining all three binary dummies WITH participate in all three decisions
gen decision_making = 0
* Assign 1 to individuals who have all three factors equal to 1 and remove NA values
replace decision_making = 1 if dm_health_care == 1 & dm_large_pur == 1 & dm_fam_visit == 1 & !missing(dm_health_care, dm_large_pur, dm_fam_visit)
tab decision_making

lab var decision_making "Decision making"
label define d1 0 "No" 1 "Yes"
label values decision_making d1


* Religion
tab v130 // 
* Looks like a lot of diversity , defining Anyone other than Hindu or Muslims as Others
recode v130 (1=1 "Hindu") (2=2 "Muslims") (3/9 96=3 "Others"), gen(religion)
lab var religion "Religion"

* Caste
tab s116 // 1- SC 2- ST 3- OBC 4- None of them 8 - Don't know (Defined others as Higher caste have the luxury to hide caste)

recode s116 (1=1 "SC") (2=2 "ST") (3=3 "OBC") (4 8=4 "Others"), gen(caste)
label var caste "Caste"

tab caste


* Age in group 
tab v013 // 

recode v013 (1=1 "15-19") (2=2 "20-24") (3=3 "25-29") (4=4 "30-34") (5=5 "35-39") (6/7=6 "40-49"), gen(age_group)
lab var age_group "Mother's Age"

tab age_group

* Education 
tab v106 // Highest Education level - No Educ Primary  Secondary Higher
ren v106 education
lab var education "Highest Education level "

lab define educ 0 "No Education" 1 "Primary" 2 "Secondary" 3 "Higher"
lab values education educ

* Wealth Quintile 
tab v190 // Wealth Index - Poorest Poorer Middle Richer Richest
lab var v190 "Wealth Quintiles"
lab define wealth 1 "Poorest" 2 "Poorer" 3 "Middle" 4 "Richer" 5 "Richest"
lab values v190 wealth
ren v190 wealth
/// Miscellanous 
* State to create Region
tab v024 

gen region = 1 if inlist(v024, 1, 2, 3, 4, 5, 6, 7, 8, 37) // North
replace region = 2 if inlist(v024, 22, 23, 9) // Central
replace region = 3 if inlist(v024, 10, 20, 21, 19) // East (Bihar, Jharkhand, Odisha, West Bengal)
replace region = 4 if inlist(v024, 11, 12, 13, 14, 15, 16, 17, 18) // Northeast
replace region = 5 if inlist(v024, 24, 25, 27, 30) // West
replace region = 6 if inlist(v024, 28, 29, 31, 32, 33, 34, 36, 35) // South 
tab region

lab var region "Region"
label define region1 1 "North"  2 "Central" 3 "East" 4"Northeast" 5 "West" 6 "South" 
label values region region1


*DHS recommends using specific given weights after dividing it by 1 million
* Women Weights
tab v005 // given weight
gen wt = v005/1000000

* Currently Pregnant
tab v213 [aw=wt]
* Current Pregnancy Wanted
tab v225 
label define v2251 1 "Planned"  2 "Mistimed" 3 "Unwanted" 
label values v225 v2251
asdoc tab v225 [iw=wt], save(currentlypregnant.doc) replace

* Wanted Pregnancy when became pregnant
tab m10 

* Type of Place of residence Urban/Rural
tab v025
ren v025 sector


/// Generating Birth Orders

recode bord_01 (1 =1 "One") (2=2 "Two") (3 =3 "Three") (4/12 =4 "Four"), gen(br_odr)

gen br_odr =.
replace br_odr = 1 if bord_01 ==1
replace br_odr = 2 if bord_01 ==2
replace br_odr = 3 if bord_01 ==3
replace br_odr = 4 if bord_01 >=4 

lab var br_odr "Birth Order"
label define br_odr1 1 "One"  2 "Two" 3 "Three" 4 "Four or More"
label values br_odr br_odr1


*********************************Graphs ************
* Graph 1
* Unplanned Pregnancy by Wealth Quintiles and Education Levels

gen ut_preg2 = 100 * ut_preg


graph bar ut_preg2 [pweight = wt] , over(caste) blabel(bar, format(%4.2f)) ytitle(Percent) ytitle(Percent) note(  (A)            Caste, size(large)) saving(caste)
graph export unplanned_caste.png, width(700) height(550) replace

graph bar ut_preg2 [pweight = wt] , over(religion) blabel(bar, format(%4.2f)) ytitle(Percent) note(  (B)            Religion , size(large)) saving(religion)
graph export unplanned_religion.png, width(700) height(550) replace

* Combining the two into one 
gr combine caste.gph religion.gph, ycommon title(Percentage of Unplanned Pregnancy by Caste and Religion , span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)
graph export caste_religion_des.png, width(750) height(550) replace

// Graph 2
* Unplanned Pregnancy and Wealth Quintile by Education levels

splitvallabels caste
graph hbar ut_preg2 [pweight = wt], ///
over(caste, label(labsize(small))) ///
over(religion, label(labsize(small))) ///
ytitle("Percent", size(small)) ///
blabel(bar, format(%4.1f))   ///
intensity(20) saving(rel_caste) 

splitvallabels wealth
graph hbar ut_preg2 [pweight = wt], ///
over(wealth, label(labsize(small))) ///
over(religion, label(labsize(small))) ///
ytitle("Percent", size(small)) ///
blabel(bar, format(%4.1f)) ///
intensity(20) saving(rel_weal)

gr combine rel_caste.gph rel_weal.gph, ycommon title(Percentage of Unplanned Pregnancy in each religion by Caste and Wealth, span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)
graph export rel_caste_wealth.png, width(750) height(550) replace



splitvallabels education
graph hbar ut_preg2 [pweight = wt], ///
over(education, label(labsize(small))) ///
over(religion, label(labsize(small))) ///
ytitle("Percent", size(small)) ///
title("Percentage of Unplanned Pregnancy in each Religion by Caste" ///
, span size(medium)) ///
blabel(bar, format(%4.1f))  note(Source: Author's Calculation using NFHS-5:2019-21) ///
intensity(20) saving(educ)
graph export unplanned_rel_caste.png, width(750) height(550) replace




graph export unplanned_rel_wealth.png, width(750) height(550) replace


****** Table 1 ****** 
//  Wealth, Education, Mass Media Exposure, Age group, birth order, Caste , religion,  region , sector


* Generated Separate tables for each var over Current Pregnacy Planning Status and Generated a table using latextablegenerator

table (wealth) () (ut_preg)  [iw=wt], nototals  statistic(percent, across(ut_preg)) statistic(frequency)

table (wealth) () (v225)  [iw=wt], nototals  statistic(percent, across(v225)) statistic(frequency)
  
table (education) () (v225)  [iw=wt], nototals statistic(percent, across(v225)) statistic(frequency)  

table (mass_media) () (v225)  [iw=wt], nototals  statistic(percent, across(v225)) statistic(frequency)  

table (age_group)  () (v225) [iw=wt], nototals statistic(percent, across(v225)) statistic(frequency)  

table (br_odr) () (v225) [iw=wt],nototals  statistic(percent, across(v225)) statistic(frequency)
 
table (caste) () (v225)  [aw=wt], nototals  statistic(percent, across(v225)) statistic(frequency)  

table (religion) () (v225) [iw=wt],nototals statistic(percent, across(v225)) statistic(frequency)  


table (region) () (v225) [iw=wt], nototals  statistic(percent, across(v225))  statistic(frequency) 

table (sector) () (v225) [iw=wt], nototals statistic(percent, across(v225))  statistic(frequency)

table (sector) () (v225) [iw=wt], nototals statistic(percent, across(v225))  statistic(frequency)

table (decision_making) () (v225) [iw=wt], nototals statistic(percent, across(v225))  statistic(frequency) //no signifant change so not adding decision_making as control


************************************************REGRESSIONS ********************* 

* OLS Model
regress unwanted i.wealth i.age_group i.education i.mass_media i.br_odr i.caste i.religion i.region i.sector  [pw = wt]

eststo m1

* Logit on Unwanted Pregnancy
logit unwanted i.wealth i.age_group i.education i.mass_media i.br_odr i.caste i.religion i.region i.sector  [pw = wt] // model 3 (Unwanted Pregnacy with controls for Individual, household and regional characteristics)
eststo m2: margins , dydx(*) post

* Logit on Unintended Pregnancy
logit ut_preg i.wealth i.age_group i.education i.mass_media i.br_odr i.caste i.religion i.region i.sector  [pw = wt] // model 3 (Unintended Pregnacy with controls for Individual, household and regional characteristics)

eststo m3: margins , dydx(*) post


//Exporting Margins in latex
esttab m1 m2 m3 using margins2.tex, replace ///
b(3) star(* 0.10 ** 0.05 *** 0.01) label ///
 title(Marginal Effects of Pregnancy Status) ///
    refcat() nonotes collabels(none) nobaselevels compress longtable mtitle("Mistimed" "Unwanted" "Unintended") stats(N)



////  Margins Plot 

// no sector but only the wealth#education 
margins wealth
marginsplot, ytitle(Probability of Unintended Pregnancy) saving(1)
graph export marginsplotwealth.png, replace



margins education

marginsplot, ytitle(Probability of Unintended Pregnancy) saving (2)

gr combine 1.gph 2.gph, ycommon title(Margins Plot of Wealth and Education for Unplanned Pregnancy , span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)
graph export marginwealeduc.png, width(750) height(550) replace

margins wealth#education
marginsplot, ytitle(Probability of Unintended Pregnancy) title(Margins Plot of Wealth and Education Intersection for Unplanned Pregnancy , span size(medium))
graph export intersection.png, width(750) height(550) replace

// 

tab v626a

recode v626a (1 2 =1 "Unmet Need") (4 7=0 "No Unmet Need"), gen(unmet_need)
lab var unmet_need "Unmet Need for Contraception"


table (wealth) () (unmet_need) [iw=wt], statistic(percent, across(unmet_need))  statistic(frequency)

collect export "D:\Sem 3\Cross-section & Panel data\Term paper\unmet_wealth.xlsx", as(xlsx) sheet(Sheet1) cell(A1) replace


// Figure 4 : Wealth and Unmet Needs 
gen unmet_need2 = 100 * unmet_need



graph bar unmet_need2 [pweight = wt] , over(wealth) blabel(bar, format(%4.2f)) ytitle(Percent) title(Percentage of Unmet Needs of Contraception by Wealth Quintile, span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)
graph export unmet_need.png, width(750) height(550) replace

graph bar unmet_need2 [pweight = wt] , over(caste) blabel(bar, format(%4.2f)) ytitle(Percent) title(Percentage of Unmet Needs of Contraception by Wealth Quintile, span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)

graph bar unmet_need2 [pweight = wt] , over(religion) blabel(bar, format(%4.2f)) ytitle(Percent) title(Percentage of Unmet Needs of Contraception by Wealth Quintile, span size(medium)) note(Source: Author's Calculation using NFHS-5:2019-21)

log close
	exit

