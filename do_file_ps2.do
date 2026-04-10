///// Metrics 2 PS 2 ///////

** housekeeping
clear all                   // remove anything old stored
set more off, permanently   // tell Stata not to pause
set linesize 255            // set line length for the log file
version                     // check the version of the command interpreter

* Set working directory to the current repo folder
cd "C:\Users\42610\OneDrive - Handelshögskolan i Stockholm\Documents\Metrics_II_PS2"
global wd "`c(pwd)'"

* Create folders if they do not exist
cap mkdir figures
cap mkdir output
cap mkdir logs

** Create a RED.ME file, and choose the name (in this case test_stata)

! echo #  metrics_ii_ps2 >> README.md

**Initialize git code 

! git init

** Add READ.ME file and comit 

! git add README.md
! git commit -m "first upload"
! git branch -M main

** Define the directory where we wanto add this file 

! git remote add origin https://github.com/HannaPee/Metrics-II-PS2.git

! git push -u origin main

** capture
cap log close // close a log-file, if one is open
log using "metrics_ii_ps2.log", replace


******** Question 2 ***********

*** b *** 

** generate data** 

clear all 

set obs 100 
set seed 260410

gen tau = rnormal(1,1)
gen e_i = rnormal()
gen i = _n 
gen X = i > 50 
gen Y_1 = tau + 5*X + e_i
gen Y_0 = 5*X + e_i  
gen tau_i = Y_1 - Y_0


preserve 
collapse (mean) tau_i
display tau_i // this will be same as if we drectly looked at the mean of tau in the sample 
restore 

*** c *** 
cap program drop f1
program define f1, rclass
    syntax [, frac(real 0.25) strata]

	cap drop D 
	cap drop Y 
	cap drop u 
	
    gen D = 0

    if "`strata'" == "" {
        gen u = runiform()
        sort u
        local n_treat = round(_N * `frac')
        replace D = 1 in 1/`n_treat'
        drop u
    }
    else {
        gen u = runiform()
        sort X u
        by X: replace D = 1 if _n <= round(_N * `frac')
        drop u
    }

    gen Y = tau*D + 5*X + e_i

    quietly reg Y D

    return scalar tauhat = _b[D]
    return scalar se = _se[D]

    test D = 1
    return scalar p = r(p)
end

* run simulations* 

tempfile sim1 sim2 sim3

* 1. frac = 0.25, no stratification

preserve
simulate tauhat=r(tauhat) se=r(se) p=r(p), reps(1000) seed(1): f1, frac(0.25)
gen frac = 0.25
gen strata = 0
save `sim1'
restore

* 2. frac = 0.5, no stratification
preserve
simulate tauhat=r(tauhat) se=r(se) p=r(p), reps(1000) seed(1): f1, frac(0.5)
gen frac = 0.5
gen strata = 0
save `sim2'
restore

* 3. frac = 0.25, with stratification
preserve
simulate tauhat=r(tauhat) se=r(se) p=r(p), reps(1000) seed(1): f1, frac(0.25) strata
gen frac = 0.25
gen strata = 1
save `sim3'
restore

* combine simulations* 

use `sim1', clear
append using `sim2'
append using `sim3'

twoway ///
    (kdensity tauhat if frac==0.25 & strata==0, lcolor(blue)) ///
	(kdensity tauhat if frac==0.5 & strata==0, lcolor(green)) ///
    (kdensity tauhat if frac==0.25 & strata==1, lcolor(red)), ///
    legend(label(1 "frac=0.25") label(2 "frac=0.5") label(3 "stratified")) 
  

graph export "figures/density_sim.pdf", replace

* Distribution parameters* 
gen reject = p < 0.05
	
table frac strata, ///
    statistic(sd tauhat) ///
    statistic(mean se) ///
    statistic(mean reject)




























