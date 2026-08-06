clear
cd "E:\Project\Natural Resource Econ\Paper"


*==============================================================================
* 1. BUILD THE ZIP -> GROUP CROSSWALK
*==============================================================================

import delimited "grouping.csv", clear

// Rename for data merge
rename zcta5ce20 regionname
destring regionname, replace



// Originally, I opted to store zip codes and their groups by the maximum number,
// distorting my data. This helps tag the ambiguity for robustness checks later.

// Count DISTINCT group assignments per zip before collapsing
bysort regionname group: gen byte tag_g = (_n == 1)
bysort regionname: egen n_distinct_groups = total(tag_g)

tab n_distinct_groups
list regionname group if n_distinct_groups > 1, sepby(regionname)

// Flag ambiguous zips so they can be excluded later as a robustness check
bysort regionname: egen byte ambiguous = max(n_distinct_groups > 1)

bysort regionname: egen group_max = max(group)
drop group tag_g n_distinct_groups
rename group_max group
duplicates drop regionname, force

save "zip_group_crosswalk.dta", replace


*==============================================================================
* 2. LOAD ZILLOW DATA AND MERGE
*==============================================================================

import delimited "Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv", clear

keep if state == "AZ"
keep if countyname == "Maricopa County" | countyname == "Pinal County"


// I had the dates wrong in my original paper, this simply corrected my information.

// v10  = Jan 2000
// v130 = Jan 2010  (panel starts)
// v250 = Jan 2020  (panel ends)  <- 121 monthly observations
keep regionname city countyname v130-v250

merge m:1 regionname using "zip_group_crosswalk.dta", keep(match master) nogenerate

// Zips with no corridor match were never under a flight path -> control group.
replace group = 0 if group == .
replace ambiguous = 0 if ambiguous == .

label define grouplabel ///
    0 "Control" ///
    1 "Newly affected" ///
    2 "Lost noise" ///
    3 "Always affected"
label values group grouplabel

tab group


*==============================================================================
* 3. RESHAPE TO PANEL AND BUILD TIME VARIABLES
*==============================================================================

// Data goes from one column per month to one row per zip-month
reshape long v, i(regionname group ambiguous) j(vnum)
rename v zhvi

// Convert Zillow's column index into a Stata monthly date
gen modate = ym(2000, 1) + (vnum - 10)
format modate %tm

xtset regionname modate


// One of my largest oversights of the paper was not using the log form for my
// dependent variable. This skewed information in the original project as it
// did not account for some zip codes having a higher average house price, meaning
// wealthier areas would see greater changes when in reality a % increase or
// decrease makes much more sense.
gen ln_zhvi = ln(zhvi)


// Once again, dates were wrong. This fixes the issue outlined earlier.
local shock_mo = ym(2014, 9)   // Sept 2014 - NextGen implementation
local rev_mo   = ym(2017, 8)   // Aug 2017  - D.C. Circuit vacates the order

gen post_shock    = (modate >= `shock_mo')
gen post_reversal = (modate >= `rev_mo')

// Regressors for a new trend-break model. post_t is months elapsed since the
// shock, and rev_t is months since the reversal. This is an improvement as it
// allows each group to have its own post-shock slope instead of a sharp jump
// shown in the original project.
gen post_t = max(0, modate - (`shock_mo' - 1))
gen rev_t  = max(0, modate - (`rev_mo'   - 1))


*==============================================================================
* 4. REMOVED: ORIGINAL LEVELS DiD
*==============================================================================

// Original regression:                                                                             
//		xtreg zhvi i.group##i.post_shock i.group##i.post_reversal, ///          
//			fe vce(cluster regionname)                                          

// The original model did not account for time controls. This was shown best
// in my original graph with steep jumps at the shock and reversal. They were
// such sharp jumps because the lack of time control had overall economic recovery
// from the 2008 recession shown and overpowering my study.

// A second problem was, as mentioned earlier, using monetary instead of a logarithmic
// value in my regression. When the outcome was logged and fixed effects were added,
// results went from (newly affected +$18,486, p=0.004) to (+1.2%, p=0.784).

*==============================================================================
* 5. REMOVED: COUNTERFACTUAL SIMULATION AND DAMAGE PER HOME
*==============================================================================

// Original:
//   predict zhvi_hat, xbu                                                   
//   gen zhvi_counter = zhvi_hat                                             
//   replace zhvi_counter = zhvi_counter + _b[1.group#1.post_shock] ...

// Sign error, I needed to subtract instead of add. It applies the effect twice
// in the opposite direction. This section also became redundant once I used
// the trend-break model instead, as it produces the counterfactual by doing
// slope x elapsed months, including a standard error.

*==============================================================================
* 6. ADDED: EVENT STUDY - TESTING PARALLEL TRENDS
*==============================================================================

// The event study model is what has me test for parallel trends, something
// I noted in my original project but I did not know then how to properly measure.
// The event study changes my project from having one post-treatment dummy with
// an indicator for each year in relation to the initial shock. 
// I use one year before the shock as my baseline due to this change being
// sudden and unannounced. If the public were given notice, this would shift to
// around 2-3 years before the policy change.

// The event study model shows a % change in what the baseline should be. Parellel
// trends is checked by analyzing the pre-shock dates, since the model would hold
// if the coefficients pre-treatment are at or around 0. The coefficients moving
// post-shock show how the treated group diverged from the control.

// Event year: 0 = the twelve months beginning Sept 2014, -1 = the year before
gen eyear = floor((modate - `shock_mo')/12)

// For some reason, Stata only accepts positive i or ib variables. This is my 
// way of fixing that issue. I use the shifted variable only for the regression 
// in order to not distort my chart.
gen eyear_f = eyear + 6

// Run separately for each treated group against control so each comparison is
// clean and interpretable.
foreach g of numlist 1 2 3 {

    preserve
    keep if group == 0 | group == `g'
    gen byte treat = (group == `g')

	// ib5 represents the year before the shock.
    // i.modate absorbs factors such as the recession, the recovery, seasonality,
	// and interest rates.
    // eyear_f main effects drop as collinear with i.modate, which is expected.
    // The eyear_f#treat interactions show the entire story.
    xtreg ln_zhvi ib5.eyear_f##i.treat i.modate, fe vce(cluster regionname)

	// This F-test shows whether each group is reliable for further testing.
	// Only the newly affected group is.
    test 1.eyear_f#1.treat 2.eyear_f#1.treat ///
         3.eyear_f#1.treat 4.eyear_f#1.treat

    estimates store es_g`g'

    restore
}


*==============================================================================
* 7. ADDED: TREND-BREAK DiD - THE MAIN SPECIFICATION
*==============================================================================

// The original project used methods that aligned more closely with "did prices
// jump after this shock?" while the trend-break DiD asks "did prices grow at
// a slower pace after the shock?" something I tried to show in counterfactual
// data.
                                                                      
// The event study estimates each year separately, spending all         
// statistical power on eleven coefficients. The trend break estimates one 
// slope per group using all 121 months, so it can detect a gradual          
// divergence the year-by-year version could not resolve.                   

// The rev_t attempts to show if divergence stops when the noise stops. If so,
// policy change becomes the only reasonable explanation as to why.

// i.group#c.post_t allows state to choose the group to drop via collinearity,
// and it dropped group 3 instead of group 0, resulting in misleading labels.
// Building the interactions manually guarantees control is the omitted base, 
// because control simply never gets a variable. Nothing is left for Stata to 
// drop arbitrarily.
forvalues g = 1/3 {
    gen post_g`g' = post_t * (group == `g')
    gen rev_g`g'  = rev_t  * (group == `g')
    label var post_g`g' "Post-shock trend, group `g' vs control"
    label var rev_g`g'  "Post-reversal trend change, group `g' vs control"
}

// fe = fixed effects
// i.modate = month fixed effects
// vce(cluster regionname) = measure within each zip code
xtreg ln_zhvi post_g1 post_g2 post_g3 rev_g1 rev_g2 rev_g3 i.modate, ///
    fe vce(cluster regionname)

estimates store main

// post_g1 = differential monthly log growth, newly affected v control.
// Multiplying by 12 gives an annual rate of ~-1.4%/yr.
// rev_g1 = change in differential after Aug 2017. Net post-reversal trend
// is post_g1 + rev_g1.

// If post_g1 < 0 and rev_g1 > 0 and they roughly cancel, the divergence began
// with the noise and ended with it. That is the result the model was built to
// detect.

// Net post-reversal trend for each group, with a standard error
lincom post_g1 + rev_g1
lincom post_g2 + rev_g2
lincom post_g3 + rev_g3


*------------------------------------------------------------------------------
* 7b. ADDED: THE KEY CONTRAST — LOST NOISE vs ALWAYS AFFECTED
*------------------------------------------------------------------------------

// I should have done this originally, as they both were under the pre-2014 flight
// paths. Naturally it makes more sense to see how they diverge after the change.

test post_g2 = post_g3
test rev_g2  = rev_g3

// Same contrast estimated directly, restricted to the two corridor groups
preserve
keep if group == 2 | group == 3
gen byte lost = (group == 2)
gen lost_post = post_t * lost
gen lost_rev  = rev_t  * lost

xtreg ln_zhvi lost_post lost_rev i.modate, fe vce(cluster regionname)
restore


*==============================================================================
* 8. ADDED: ROBUSTNESS CHECKS
*==============================================================================

// Alternative reversal date
preserve
local rev_alt = ym(2018, 3)
replace rev_t = max(0, modate - (`rev_alt' - 1))
forvalues g = 1/3 {
    replace rev_g`g' = rev_t * (group == `g')
}
xtreg ln_zhvi post_g1 post_g2 post_g3 rev_g1 rev_g2 rev_g3 i.modate, ///
    fe vce(cluster regionname)
restore

// Drop the ambigious zips
preserve
keep if ambiguous == 0
xtreg ln_zhvi post_g1 post_g2 post_g3 rev_g1 rev_g2 rev_g3 i.modate, ///
    fe vce(cluster regionname)
restore

// Placebo shock. A significant effect here means my model picked up on changes
// outside the policy I wanted to measure.
preserve
keep if modate < `shock_mo'
local placebo = ym(2012, 9)
gen placebo_t = max(0, modate - (`placebo' - 1))
forvalues g = 1/3 {
    gen placebo_g`g' = placebo_t * (group == `g')
}
xtreg ln_zhvi placebo_g1 placebo_g2 placebo_g3 i.modate, ///
    fe vce(cluster regionname)
restore


*==============================================================================
* 9. ADDED: EVENT STUDY PLOT AND LEAD FIGURE
*==============================================================================

// Replacement of the actual vs counterfactual chart. Its staircase jump came
// from missing time controls as mentioned previously.

// The event-study plot shows the coefficients with confidence intervals w/r/table
// time. Ultimately, this is a better way of showing results.

// Run this command prior to generating the plot:
// ssc install coefplot, replace

coefplot es_g1, ///
    keep(*.eyear_f#1.treat) ///
    baselevels ///
    vertical ///
    yline(0, lpattern(solid) lcolor(gs8)) ///
    xline(5.5, lpattern(dash) lcolor(black)) ///
    ciopts(recast(rcap)) ///
    recast(connected) ///
    coeflabels(1.eyear_f#1.treat = "-5" ///
               2.eyear_f#1.treat = "-4" ///
               3.eyear_f#1.treat = "-3" ///
               4.eyear_f#1.treat = "-2" ///
               5.eyear_f#1.treat = "-1" ///
               6.eyear_f#1.treat = "0"  ///
               7.eyear_f#1.treat = "+1" ///
               8.eyear_f#1.treat = "+2" ///
               9.eyear_f#1.treat = "+3" ///
              10.eyear_f#1.treat = "+4" ///
              11.eyear_f#1.treat = "+5") ///
    ytitle("Gap vs control (log points)") ///
    xtitle("Years relative to Sept 2014") ///
    title("Newly affected zips vs control") ///
    note("Baseline: year before the shock. Bars are 95% CIs.") ///
    graphregion(color(white))

graph export "event_study_newly_affected.png", replace width(2000)
