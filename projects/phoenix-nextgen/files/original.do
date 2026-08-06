clear
cd "C:\Users\ushat\Desktop\Natural Resource Econ\Paper"


// Dataset to group zip codes
import delimited "grouping.csv", clear

rename zcta5ce20 regionname
destring regionname, replace

// Delete duplicates, keeping highest group #
// Duplicates happened as when i draw out flight paths in mapping tool, multiple lines = same zip code multiple times
bysort regionname: egen group_max = max(group)
drop group
rename group_max group
duplicates drop regionname, force

save "zip_group_crosswalk.dta", replace




import delimited "Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv", clear

keep if state == "AZ"
keep if countyname == "Maricopa County" | countyname == "Pinal County"

//v10 = Jan 2000. v130 = Jan 2010, v250 = Oct 2020.
keep regionname city countyname v130-v250


// Merge groups with house value data
merge m:1 regionname using "zip_group_crosswalk.dta", keep(match master) nogenerate

// Un-matched becomes control group
replace group = 0 if group == .

// Label groups
label define grouplabel ///
    0 "Control" ///
    1 "Newly affected" ///
    2 "Lost noise" ///
    3 "Always affected"
label values group grouplabel

* Verify distribution looks reasonable
tab group


///////////////////////
// Data Manipulation //
///////////////////////

// Convert to panel data
reshape long v, i(regionname group) j(vnum)
rename v zhvi

// Turns v-numbers into dates
gen modate = ym(2000, 1) + (vnum - 10)
format modate %tm

xtset regionname modate


// post_shock    = on or after Jun 2014 (v185) — NextGen transition
// post_reversal = on or after Dec 2017 (v227) — FAA course correction
local shock_mo   = ym(2000,1) + (185 - 10)
local rev_mo     = ym(2000,1) + (227 - 10)

gen post_shock    = (modate >= `shock_mo')
gen post_reversal = (modate >= `rev_mo')


// DiD regression //
// _b[1.group#1.post_shock]    = avg per-home price change for group 1 after shock, relative to control
// _b[1.group#1.post_reversal] = additional adjustment after reversal
// With fe, ZIP fixed effects absorb time-invariant ZIP characteristics.
// Clustering by regionname accounts for correlation within zip codes
xtreg zhvi i.group##i.post_shock i.group##i.post_reversal, ///
    fe vce(cluster regionname)


//Counterfactual values
predict zhvi_hat, xbu
gen zhvi_counter = zhvi_hat

* Group 1
replace zhvi_counter = zhvi_counter + _b[1.group#1.post_shock] ///
    if group == 1 & post_shock == 1
replace zhvi_counter = zhvi_counter + _b[1.group#1.post_reversal] ///
    if group == 1 & post_reversal == 1

* Group 2
replace zhvi_counter = zhvi_counter + _b[2.group#1.post_shock] ///
    if group == 2 & post_shock == 1
replace zhvi_counter = zhvi_counter + _b[2.group#1.post_reversal] ///
    if group == 2 & post_reversal == 1

* Group 3
replace zhvi_counter = zhvi_counter + _b[3.group#1.post_shock] ///
    if group == 3 & post_shock == 1
replace zhvi_counter = zhvi_counter + _b[3.group#1.post_reversal] ///
    if group == 3 & post_reversal == 1

	
// Damage per home
* Average gap between counterfactual and actual by group, post-shock
gen damage_per_home = zhvi_counter - zhvi

preserve

keep if group != 0
collapse (mean) damage_per_home, by(group post_shock post_reversal)
list group post_shock post_reversal damage_per_home


restore






// Graph
collapse (mean) zhvi zhvi_counter, by(group modate)
local shock_mo  = ym(2000,1) + (185 - 10)
local rev_mo    = ym(2000,1) + (227 - 10)

twoway ///
    (line zhvi         modate if group==1, lcolor(cranberry)     lwidth(medium)) ///
    (line zhvi_counter modate if group==1, lcolor(cranberry)     lwidth(thin) lpattern(dash)) ///
    (line zhvi         modate if group==2, lcolor(navy)          lwidth(medium)) ///
    (line zhvi_counter modate if group==2, lcolor(navy)          lwidth(thin) lpattern(dash)) ///
    (line zhvi         modate if group==3, lcolor(forest_green)  lwidth(medium)) ///
    (line zhvi_counter modate if group==3, lcolor(forest_green)  lwidth(thin) lpattern(dash)) ///
    (line zhvi         modate if group==0, lcolor(gs8)           lwidth(medium)) ///
    , ///
    xline(`shock_mo' `rev_mo', lpattern(shortdash) lcolor(black)) ///
    xlab(, format(%tmMon-CCYY) angle(45)) ///
    xtitle("Month") ///
    ytitle("Average Home Value (ZHVI, $)") ///
    title("Phoenix NextGen: Actual vs. Counterfactual Home Values") ///
    subtitle("Solid = observed | Dashed = counterfactual (no NextGen)") ///
    legend(order( ///
        1 "Newly affected" ///
        2 "(CF)" ///
        3 "Lost noise" ///
        4 "(CF)" ///
        5 "Always affected" ///
        6 "(CF)" ///
        7 "Control") ///
		cols(1) size(small)) ///
    graphregion(color(white))

graph export "nextgen_actual_vs_counterfactual.png", replace