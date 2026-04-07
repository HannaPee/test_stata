*------------------------------------------------------------------------------*
/*-----------------------------------------------------------------------------*
Simon Handreke
simon.handreke@iies.su.se
2026-04-02

Econometrics 2
Stata Intro/Refresher Session do-file 

NB: This is for illustrative purpose. 
    Not all the commands on the slides are in this do-file.
*-----------------------------------------------------------------------------*/

** housekeeping
clear all                   // remove anything old stored
set more off, permanently   // tell Stata not to pause
set linesize 255            // set line length for the log file
version                     // check the version of the command interpreter


* Set working directory to the current repo folder
cd "/Users/hannapersson/Documents/Metrics II/test_stata"
global wd "`c(pwd)'"


** capture
* log close // will return an error: no log file is open!
cap log close // close a log-file, if one is open
log using "stata_tutorial.log", replace


** number of observations
set obs 10
g N = _N
g n = _n
br // shows the data


** random numbers
clear // erases all old data
set obs 100
set seed 100
g uni = runiform() // uniform over [0, 1]
g norm = rnormal() // standard normal
g b = uni > 0.9 // 1 if random draw larger than 0.9, else 0
g b2 = inrange(uni, 0.4, 0.6) // 1 if 0.4 <= uni <= 0.6, else 0

** missing values
clear
set obs 100
g b = uniform()
g b1 = b > 0.5
g b2 = 1 if b > 0.5 // b1 and b2 are not the same! b2 will leave all obs with b <= 0.5 blank while b1 gives them a 0
sum b1 b2
sum b2 if !mi(b2) // alternatively: sum b2 if b2 != .
tab b1 b2
count if b1 > 1
count if b2 > 1


** egen
* generate simulated data
clear
set obs 100
gen age = floor(runiform(21, 40)) // floor rounds down to the nearest integrer 
gen gender = runiform() > 0.5
gen earnings = exp(rnormal())
gen age_1 = floor(runiform(5, 15))
gen age_2 = floor(runiform(0, 10))
gen country = floor(runiform(0, 10))

*g avg_age = mean(age) // does not work
egen avg_age = mean(age) // works

bys age: egen max_earnings = max(earnings)
bys age gender: egen med_earnings = median(earnings)
egen ca = rowmax(age_1 age_2) if !mi(age_1) & !mi(age_2)
egen id_group = group(age gender country)

egen sum_earn = sum(earnings)
g cumsum_earn = sum(earnings)


** collapse
*collapse (mean) earnings, by(age) // mean earnings by age (aggregated variable name earnings)
collapse (mean) mean_earnings = earnings (median) med_earnings = earnings, by(age) // mean and median earnings by age (aggregated variable names mean_earnings, med_earnings)
*collapse (count) earnings, by(age) // count the number of obs. with nomissing values


** macros
global indepvar_model1 = "age education race"
local indepvar_model1 = "age education race"
dis "Print: $indepvar_model1" // print local
dis "Print: `indepvar_model1'" // print global

foreach var of local indepvar_model1 {
  dis "`var'" // print each word
}


** regressions
clear 
set obs 100
set seed 100
gen x1 = rnormal()
gen x2 = runiform()
gen e1 = rnormal()
gen y = 2*x1 + e1
reg y x1 // run regression


** fixed effects and interactions
gen x = floor(runiform(0, 10))
gen z = rnormal(0, 10)

reg y i.x

areg y, absorb(x)
*ssc install reghdfe
*ssc install ftools
reghdfe y, absorb(x) // doesn't show FEs
reghdfe y, absorb(x, savefe) // FEs stored in variable

reg y c.x#c.z // treat x as continuous and only include interaction
reg y c.x##c.z
reg y i.x##c.z


** factor-variable operators
reg y ib4.x // reference/base: x == 4
reg y ib(#3).x // reference/base: the 3rd ordered value of x


** produce regression table
label variable x1 "Indep. Var. 1"
label variable x2 "Indep. Var. 2"
label variable y "Outcome"

* ssc install estout
eststo clear
eststo m1: reg y x1
eststo m2: reg y x2
* esttab m1 m2 using example.tex
esttab m*, se keep(x*) star(* 0.10 ** 0.05 *** 0.01) stat(N r2, label("N" "\$R^2\$")) label


** fitted values and residuals
reg y x1
predict y_fitted
predict y_resid, resid


** regression output
return list
ereturn list

gen r2 = e(r2)
local r2_tmp = e(r2)
gen beta1 = e(b)[1,1]
mat list e(b)


** save regression coefficients
*ssc install regsave
regsave using filename.dta, replace // save regression output in filename.dta
regsave using filename.dta, append autoid // appends to the file and adds an id to it
regsave // overwrites prior data


** program
clear 
set obs 100
set seed 100
gen x1 = runiform()
gen x2 = runiform()
gen y1 = runiform()
gen y2 = runiform()

cap program drop calculate_distance
program define calculate_distance
	syntax newvarlist(max = 1) [ , x1(varname) y1(varname) x2(varname) y2(varname)]
	g x_diff = `x1' - `y1'
	g y_diff = `x2' - `y2'
	g `varlist' = (x_diff^2 + y_diff^2)^0.5
	drop x_diff y_diff
end

calculate_distance z1, ///
	x1(x1) y1(y1) x2(x2) y2(y2)


** simulate
clear
cap program drop f1
program define f1
	cap drop _all
	set obs 100
	gen x = rnormal()
	gen y = 3*x + 1 + rnormal()
	reg y x
end

simulate _b, reps(100) seed(1234): f1 // _b is regression coefficient in Stata


** simple graphs
hist _b_x
scatter _b_cons _b_x


** same simulation with loop
clear
cap mkdir tmp // create the directory `tmp' if not exist
cap erase tmp/regsave_tmp.dta // remove `regsave_tmp.dta' file if exists

forvalue i = 1/100 {

	cap drop _all
	* simulate data
	set obs 100
	gen x = rnormal()
	gen y = 3 * x + 1 + rnormal()

	* regression
	qui reg y x // qui suppresses output
	
	* save regression coefs as dataset
	regsave
	gen sim = `i'
	gen varnum = var == "x"
	drop var stderr N r2
	qui reshape wide coef, i(sim) j(var)
	// qui save tmp/regsave_tmp`i'.dta, replace

	* append the estimates from each simulation into one dataset
	cap append using tmp/regsave_tmp.dta
	save tmp/regsave_tmp.dta, replace
	dis "The `i'-th simulation done."
}

hist coef1 // coef on xx
scatter coef0 coef1 


** graphs
sysuse auto.dta, clear
graph twoway (lfit price mpg) (scatter price mpg), ///
	graphregion(color(white))

sysuse sp500, clear
graph twoway ///
	(line close date, lcolor(gray)) ///
	(rcap low high date) ///
	if _n < 80, ///
	graphregion(color(white))
	
** schemes
graph twoway ///
	(line close date, lcolor(gray)) ///
	(rcap low high date) ///
	if _n < 80, ///
	scheme(economist)

** expand
expand 2, g(d)

** preserve & restore
preserve
collapse (mean) change
display change
collapse (count) change
display change
restore, not

clear
sysuse sp500
preserve
collapse (mean) change
display change
restore
collapse (count) change
display change

clear
sysuse sp500
preserve
collapse (mean) change
display change
restore, preserve
collapse (count) change
display change



// Push changes to directory 
! git branch -M main
! git push -u origin main


// Add do_file to repository 

! git status
! git add do_file.do
! git commit -m "Add do file_2"
! git push

log close
