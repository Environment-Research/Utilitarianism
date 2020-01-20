************************************************************************
* Must have run the "run_analysis.jl" file before running this.
* Will create main figures from text.
************************************************************************

clear all 
set more off
**Insert results directory here
cd "C:\Users\Admin\Desktop\IAM_GitTest\FranksCode\results\My Results"

*Define global titles & colors to use throughout figures
global newfiles utilitarian
global oldfiles uniform

global newway Utilitarianism
global oldway "Uniform Carbon Tax"

global USc blue
global Russiac bluishgray
global OthAsiac cranberry
global OHIc cyan
global Mideastc stone
global LatAmc purple
global Japanc orange
global Indiac green
global Eurasiac brown
global EUc black
global Chinac red
global Africac gold

**Common to both runs:
foreach v in Population PerCapitaConsumption Emissions LandUse{
	clear
	import delimited using "rice_BAU\\`v'.csv"
	gen year = 2005+10*([_n]-1)
	rename x1   USA_`v'BAU
	rename x2   EU_`v'BAU
	rename x3   Japan_`v'BAU
	rename x4   Russia_`v'BAU
	rename x5   Eurasia_`v'BAU
	rename x6   China_`v'BAU
	rename x7   India_`v'BAU
	rename x8   MidEast_`v'BAU
	rename x9   Africa_`v'BAU
	rename x10  LatAm_`v'BAU
	rename x11  OHI_`v'BAU
	rename x12  OthAsia_`v'BAU
	tempfile `v'
	save ``v''
}

use `Population'
foreach v in PerCapitaConsumption Emissions LandUse{
	merge 1:1 year using ``v''
	drop _merge
	save BAU, replace
}

**Specific to both runs:
foreach method in $newfiles $oldfiles{
	clear
	use BAU
	save `method', replace
	foreach v in Emissions PerCapitaConsumption MitigationRate GDP{
		clear 
		import delimited using "rice_`method'\\`v'.csv"
		gen year = 2005+10*([_n]-1)
		rename x1   USA_`v'
		rename x2   EU_`v'
		rename x3   Japan_`v'
		rename x4   Russia_`v'
		rename x5   Eurasia_`v'
		rename x6   China_`v'
		rename x7   India_`v'
		rename x8   MidEast_`v'
		rename x9   Africa_`v'
		rename x10  LatAm_`v'
		rename x11  OHI_`v'
		rename x12  OthAsia_`v'
		tempfile `v'`method'
		save ``v'`method'', replace
		use `method'
		merge 1:1 year using ``v'`method''
		drop _merge
		save `method', replace
	}
	clear
	import delimited using "rice_`method'\\Temperature.csv"
	gen year = 2005+10*([_n]-1)
	order year temp
	merge 1:1 year using `method'
	drop _merge	
	
	local regions USA EU Japan Russia Eurasia China India MidEast Africa LatAm OHI OthAsia
		foreach r in `regions'{
		preserve
		keep year temp `r'*
		gen region = "`r'"
		rename `r'_Emissions EInd
		rename `r'_LandUseBAU ETree
		rename `r'_MitigationRate MIU
		rename `r'_PerCapitaConsumption CPC
		rename `r'_PopulationBAU Pop
		rename `r'_GDP GDP 
		rename `r'_EmissionsBAU BAU
		rename `r'_PerCapitaConsumptionBAU CPCBAU
		gen ETot = 3.66*(EInd + ETree)
	tempfile temp`r'
	save `temp`r''
	restore
	}
keep year
drop year
	foreach r in `regions'{
		append using "`temp`r''"
	}
**Need to drop last year for calculations of all future abatement or energy use... 
drop if year ==2595
label var temp "Temperature Increase from Pre-Industrial"
label var EInd "Industrial Emissions"
label var ETot "Emissions in GtC (rather than Co2)"
label var CPC "Consumption Per cap."
label var CPCBAU "Consumption Per cap. in BAU"
label var Pop "Population"
label var MIU "Mitigation Rate"
label var GDP "GDP net of Damages"
label var BAU "Business as Usual Emissions"
order year region temp EInd MIU CPC Pop CPCBAU ETot BAU ETree

egen regionid = group(region)
xtset regionid year

sort regionid year
recode year (2015 = 2020)
local change ETot EInd temp BAU CPC CPCBAU MIU
foreach c in `change'{
replace `c' = .5*`c' + .5*`c'[_n+1] if year==2020
}

bysort year: egen AggEmissions = sum(ETot)
label var AggEmissions "Global Emissions"
sort region year
bysort region: gen E2005 = 100*(ETot/ETot[1])

save `method', replace
}


************************************************
***  Make pie graph
************************************************
clear
use $oldfiles, clear
keep if year > 2015
preserve
replace ETot = .5*ETot if year==2020
collapse (rawsum) ETot, by(region regionid)
gen sort = -1*regionid
sum ETot
local total = r(mean)*r(N)
sort sort
local labeler 
forvalues i = 1(1)12{
if 100*ETot[`i']/`total' >=10 {
local lh = string(round(100*ETot[`i']/`total'))+"%" 
local labeler `labeler' plabel( `i' "`lh'",  c(white) size(medlarge)) 
}
}
#delimit ;
graph pie ETot, sort(sort) `labeler' over(region) name(pie_oneprice) graphr(c(white) lc(white)) plotregion(lc(white)) title("{bf:g.}  $oldway", color(black)) legend(pos(3) col(1) region(lcolor(white)))
pie(1, color($USc ))
pie(2, color($Russiac ))
pie(3, color($OthAsiac ))
pie(4, color($OHIc ))
pie(5, color($Mideastc ))
pie(6, color($LatAmc ))
pie(7, color($Japanc ))
pie(8, color($Indiac ))
pie(9, color($Eurasiac ))
pie(10, color($EUc ))
pie(11, color($Chinac ))
pie(12, color($Africac ));
#delimit cr
use $newfiles, clear
keep if year > 2015
replace ETot = .5*ETot if year==2020
collapse (rawsum) ETot, by(region regionid)
gen sort = -1*regionid
sum ETot
local total = r(mean)*r(N)
sort sort
local labeler 
forvalues i = 1(1)12{
if 100*ETot[`i']/`total' >=10 {
local lh = string(round(100*ETot[`i']/`total'))+"%" 
local labeler `labeler' plabel( `i' "`lh'",  c(white) size(medlarge)) 
}
}
#delimit ;
graph pie ETot, sort(sort) `labeler' over(region) name(pie_fullyoptimal) graphr(c(white) lc(white)) plotregion(lc(white)) title("{bf:i.}  $newway", color(black))  legend(pos(3) col(1) region(lcolor(white)))
pie(1, color($USc ))
pie(2, color($Russiac ))
pie(3, color($OthAsiac ))
pie(4, color($OHIc ))
pie(5, color($Mideastc ))
pie(6, color($LatAmc ))
pie(7, color($Japanc ))
pie(8, color($Indiac ))
pie(9, color($Eurasiac ))
pie(10, color($EUc ))
pie(11, color($Chinac ))
pie(12, color($Africac ));
#delimit cr
graph combine pie_oneprice pie_fullyoptimal, commonscheme graphr(c(white) lc(white)) name(pie_combined) col(1)
grc1leg pie_oneprice pie_fullyoptimal, imargin(tiny) commonscheme graphr(c(white) lc(white)) name(pie_combined1) col(1) pos(3)
restore

************************************************
** Make emissions path graphs, for Figure 1
************************************************'
**First need to bring in NDCs
preserve
collapse year, by(region)
replace year=2030
gen INDC =.
label var INDC "Nationally Determined Contribution"
gen INDC2005 =.
label var INDC2005 "NDC as share of 2005 emissions"
gen INDCupper=.
gen INDClower=.
replace INDC =5630 if region=="India" 
replace INDC2005=270  if region=="India" 
replace INDCupper =308 if region=="India" 
replace INDClower=235  if region=="India" 
replace INDC =5630 if region=="India" 
replace INDC2005=270  if region=="India" 
replace INDC =15200 if region=="China" 
replace INDC2005=199  if region=="China" 
replace INDC =4810 if region=="USA" 
replace INDC2005=66.6  if region=="USA" 
replace INDC =3462.4 if region=="EU" 
replace INDC2005=66.1  if region=="EU" 
replace INDC =3100 if region=="Africa" 
replace INDC2005=196.8  if region=="Africa"
tempfile NDC
save `NDC'
restore

global lastyear 2200
use $oldfiles, clear
gen $oldfiles = 1
append using $newfiles

preserve

append using `NDC'
local l1 a
local l2 b
local l3 c
local l4 d
local l5 e

local i = 0
sort year
foreach region in USA EU India China Africa{
#delimit ;
twoway (connected E2005 year if $oldfiles == ., lc(forest_green) ms(i)) (connected E2005 year if $oldfiles == 1, lc(maroon) lp(shortdash) ms(i)) 
(scatter INDC2005 year, mc(black) msize(large)) (rcap INDCupper INDClower year, blcolor(gray)) if region=="`region'"&year <=2105&year>=2015, 
xtitle("") ytitle("Emissions (% of 2005)" ) 
legend(col(3) order(1 "$newway" 2 "$oldway" 3 "INDC") size(small) ) 
graphr(c(white) lc(white)) ylab(,angle(0) ) xlab(2020 "2020" 2050 "2050" 2100 "2100") 
name(etot_`region') title("{bf:`l`++i''.}  `region'", color(black));
#delimit cr
}
grc1leg etot_USA etot_EU etot_India etot_China etot_Africa, commonscheme ycommon graphr(c(white) lc(white)) name(etot_combined) col(5) xsize(12) ysize(4) 
drop if year==2030

************************************************
** Make area graph
************************************************

forvalues r = 1(1)12{
gen et_for_area_`r' = ETot if regionid <= `r'
}
local stacker
forvalues r = 12(-1)1{
local stacker `stacker' et_for_area_`r'
}
collapse (rawsum) `stacker', by(year $oldfiles)
gen zero = 0
local stacker
forvalues r = 12(-1)1{
if `r'==12{
	local color $USc
}
if `r'==11{
	local color $Russiac
}
if `r'==10{
	local color $OthAsiac
}
if `r'==9{
	local color $OHIc
}
if `r'==8{
	local color $MidEastc 
}
if `r'==7{
	local color $LatAmc
}
if `r'==6{
	local color $Japanc
}
if `r'==5{
	local color $Indiac
}
if `r'==4{
	local color $Eurasiac
}
if `r'==3{
	local color $EUc
}
if `r'==2{
	local color $Chinac
}
if `r'==1{
	local color $Africac
}
local stacker `stacker' (rarea et_for_area_`r' zero year, lw(none) bcolor(`color'))
}
#delimit ;
twoway `stacker' if $oldfiles == 1& year<=2155&year>=2015, xlab(2050 "2050" 2100 "2100" 2150 "2150")
xtitle(" ") ytitle("Carbon Emissions (Gt CO2)") 
graphr(c(white) lc(white)) legend(pos(3) 
order(
1 "USA"
2 "Russia"
3 "Other Asia"
4 "Other High Income"
5 "Middle East"
6 "Latin America"
7 "Japan"
8 "India"
9 "Eurasia"
10 "EU"
11 "China"
12 "Africa"
)
col(1) region(lc(white))) 
name(area_oneprice)
ylab(,angle(0))
title("{bf:f.}  $oldway", color(black));

twoway `stacker' if $oldfiles == .& year<=2155&year>=2015, xlab(2050 "2050" 2100 "2100" 2150 "2150")
xtitle(" ") ytitle("Carbon Emissions (Gt CO2)") 
graphr(c(white) lc(white)) legend(pos(3) 
order(
1 "USA"
2 "Russia"
3 "other Asia"
4 "other high income"
5 "Middle East"
6 "Latin America"
7 "Japan"
8 "India"
9 "Eurasia"
10 "EU"
11 "China"
12 "Africa"
)
col(1) region(lc(white))) 
ylab(,angle(0))
name(area_fullyoptimal)
title("{bf:h.}  $newway", color(black));

# delimit cr
graph combine area_oneprice area_fullyoptimal, colfirst ycommon xsize(12) ysize(12) col(1)  graphr(c(white) lc(white))  name(area_combined)
grc1leg area_oneprice area_fullyoptimal, imargin(small) commonscheme graphr(c(white) lc(white)) name(area_combined1) pos(3) colfirst ycommon xcommon xsize(12) ysize(12) col(1)


grc1leg area_combined1 pie_combined1, graphr(c(white) lc(white)) name(fig1_bottom) pos(3) commonscheme imargin(tiny)
graph close _all
graph combine etot_combined fig1_bottom, col(1)  graphr(c(white) lc(white)) name(Figure1)
sleep 10000
graph export "Figure1.svg", replace
graph export "Figure1.pdf", replace
restore


***********Figure 2********************
*******************************************************************************
* Figure 2
*******************************************************************************
preserve
gen CPCGains = 100*(CPC/CPCBAU -1)
global lastyearCPC 2080
#delimit ;
twoway (line CPCGains year if $oldfiles ==. & region=="Africa" & year>2016 & year<$lastyearCPC , lc($Africac ) lw(thick))
(line CPCGains year if $oldfiles ==. & region=="India" & year>2016 & year<$lastyearCPC , lc($Indiac ) lw(thick) lp(dash))
(line CPCGains year if $oldfiles ==. & region=="OthAsia" & year>2016 & year<$lastyearCPC , lc($OthAsiac ) lw(thick) lp(dash)), 
yline(0, lc(black) lp(longdash))
xtitle("")
ytitle("")
yscale(range(-.15 1.5))
ylabel(0(.5)1.5,angle(0) format(%3.1f))
xlab(2025(25)2075) 
legend(off)
title("{bf: b.} $newway")
name("FlexibleNearTerm");

twoway (line CPCGains year if $oldfiles ==1 & region=="Africa" & year>2016 & year<$lastyearCPC , lc($Africac ) lw(thick))
(line CPCGains year if $oldfiles ==1 & region=="India" & year>2016 & year<$lastyearCPC , lc($Indiac ) lw(thick) lp(dash))
(line CPCGains year if $oldfiles ==1 & region=="OthAsia" & year>2016 & year<$lastyearCPC , lc($OthAsiac ) lw(thick) lp(dash)), 
yline(0, lc(black) lp(longdash))
yscale(range(-.15 1.5))
xlab(2025(25)2075)
text(0 2020 "BAU", size(small) placement(ne))
xtitle("")
ytitle("{bf: Consumption Gains (%)}")
ylabel(0(.5)1.5,angle(0) format(%3.1f)) 
legend(off)
title("{bf: a.} $oldway")
name("CostMinNearTerm");
#delimit cr

graph combine CostMinNearTerm FlexibleNearTerm, rows(1) name(NearTermCombined) 

replace MIU = 100*MIU
#delimit ;
twoway (line MIU year if region=="Africa" & year>2010 & year<2080 & $oldfiles !=1, lcolor($Africac) lwidth(thick))
(line MIU year if region=="Japan" & year<2080 & year>2010 & $oldfiles !=1, lcolor($Japanc) lpattern(dash))
(line MIU year if region=="China" & year<2080 & year>2010 & $oldfiles !=1, lcolor($Chinac) lwidth(thick))
(line MIU year if region=="USA" & year<2080 & year>2010 & $oldfiles !=1, lcolor($USc) lpattern(dash))
(line MIU year if region=="EU" & year<2080 & year>2010 & $oldfiles !=1, lcolor($EUc) lpattern(dash) lwidth(thick))
(line MIU year if region=="India" & year<2080 & year>2010 & $oldfiles !=1, lcolor($Indiac) lpattern(dash) lwidth(thick))
(line MIU year if region=="OthAsia" & year<2080 & year>2010 & $oldfiles ==1, lcolor($OthAsiac) lpattern(dash) lwidth(thick)),
title( "{bf: d.} $newway")
ytitle("")
ylab(#6, angle(0))
xlab(2025(25)2075)
yline(0, lc(black) lp(dot))
yline(100, lc(black) lp(dot))
xtitle("")
yscale(range(0 100))
legend(rows(1) pos(6) symysize(1) symxsize(4) size(small) label(1 "Africa") label(6 "India") label(2 "Japan") label(3 "China") label(4 "USA") label(5 "EU") label(7 "OthAsia") order(4 3 2 5 1 6 7))
name(DecarbonFlex);
#delimit cr

#delimit ;
twoway (line MIU year if region=="Africa" & year>2010 & year<2080 & $oldfiles ==1, lcolor($Africac) lwidth(thick))
(line MIU year if region=="Japan" & year<2080 & year>2010 & $oldfiles ==1, lcolor($Japanc) lpattern(dash))
(line MIU year if region=="China" & year<2080 & year>2010 & $oldfiles ==1, lcolor($Chinac) lwidth(thick))
(line MIU year if region=="USA" & year<2080 & year>2010 & $oldfiles ==1, lcolor($USc) lpattern(dash))
(line MIU year if region=="EU" & year<2080 & year>2010 & $oldfiles ==1, lcolor($EUc) lpattern(dash) lwidth(thick))
(line MIU year if region=="India" & year<2080 & year>2010 & $oldfiles ==1, lcolor($Indiac) lpattern(dash) lwidth(thick))
(line MIU year if region=="OthAsia" & year<2080 & year>2010 & $oldfiles ==1, lcolor($OthAsiac) lpattern(dash) lwidth(thick)),
title("{bf: c.} $oldway ")
ytitle("{bf: Decarbonization Rate (%)}")
ylab(#6, angle(0))
xlab(2025(25)2075)
xscale(range(2019 2075))
yscale(range(0 100))
xtitle("")
text(0 2020 "BAU", size(small) placement(ne))
text(100 2020 "Zero Industrial Emissions", placement(se) size(small))
yline(0, lc(black) lp(dot))
yline(100, lc(black) lp(dot))
legend(rows(1) pos(6) symysize(1) symxsize(5) size(small) label(1 "Africa") label(6 "India") label(2 "Japan") label(3 "China") label(4 "USA") label(5 "EU") label(7 "OthAsia") order(4 3 2 5 1 6 7))
name(DecarbonUniform);
#delimit cr

grc1leg DecarbonUniform DecarbonFlex, rows(1) pos(6) name(DecarbonCombined)

graph combine NearTermCombined DecarbonCombined, cols(1)
graph export "Figure2.svg", replace
graph export "Figure2.pdf", replace

restore


****************************************************************
* Figure 3 section
****************************************************************
**Bubble plots first
preserve 
keep if year==2125 | year==2115
recode $oldfiles (.=0)
sort regionid $oldfiles year
scalar n = _N+2
set obs `=scalar(n)'
replace Pop=1000 if Pop==.
replace Pop=2000 if [_n]==[_N]
replace region = "1 Bn." if Pop==1000
replace region = "2 Bn." if Pop==2000
recode year (.=2125)
gen leg = 0
replace leg = 1 if region=="1 Bn." | region=="2 Bn."
replace $oldfiles = 1 if leg==1
sort regionid year $oldfiles
gen CPCfrac = 100*(CPC/CPC[_n+1]-1) if $oldfiles==0
gen CPCfrac2 = 100*(CPC/CPCBAU - 1) if $oldfiles!=1
bysort region $oldfiles: egen CPC2100 = mean(CPCfrac)
bysort region $oldfiles: egen CPCBAU2100 = mean(CPCfrac2)
keep if year==2125
replace CPCfrac = CPC2100
replace CPCfrac2 = CPCBAU2100
bysort $oldfiles: egen totPop = total(Pop)
gen fracpop = Pop/totPop
list region fracpop if $oldfiles==1
replace CPCfrac = 1.07 if region=="1 Bn."
replace CPCfrac = 1.11 if region=="2 Bn."
replace CPCfrac2 = 5.07 if region=="1 Bn."
replace CPCfrac2 = 5.24 if region=="2 Bn."
gen logCPC = log(CPCBAU)
replace logCPC = 4.8 if leg==1

#delimit ;
twoway (scatter CPCfrac logCPC if CPCfrac>0 & leg!=1, msymbol(i) mlabel(region) mlabpos(center) mlabcolor(green) mlabsize(vsmall))
(scatter CPCfrac logCPC if CPCfrac<0, msymbol(i) mlabel(region) mlabpos(center) mlabcolor(red))
(scatter CPCfrac logCPC [aweight=fracpop], msymbol(Oh) mcolor(gray)),
xlabel(3.5(.5)5, labsize(small))
xscale(range(3.1 5))
xtitle("Log Per Capita Consumption", size(small))
ytitle("Consumption Increase (as %)", size(small))
yscale(range(-.15 1.3))
ylab(0(.5)1,angle(0) labsize(small)  format(%2.1f))
title("{bf: b.} Regional Gains in 2120")
yline(0, lc(black) lp(dash))
text(1.2 4.8 "2 Bn", size(tiny))
text(1.07 4.8 "1 Bn", size(tiny))
text(1.3 4.8 "Circles Proportional" "to 2120 Population", size(tiny))
text(0 3.15 "Cost-Minimzation", placement(ne) size(vsmall))
text(-.15 4.6 "Richer Populations", size(vsmall))
text(-.15 5 "{&rarr}", size(small))
text(-.15 3.25 "Poorer Populations", placement(e) size(vsmall))
text(-.15 3.23 "{&larr}", size(small) placement(w))
legend(off)
name(Cross2120);

twoway (scatter CPCfrac2 logCPC if CPCfrac2>0 & leg!=1, msymbol(i) mlabel(region) mlabpos(center) mlabcolor(green) mlabsize(vsmall))
(scatter CPCfrac2 logCPC if CPCfrac2<0, msymbol(i) mlabel(region) mlabpos(center) mlabcolor(red) mlabsize(vsmall))
(scatter CPCfrac2 logCPC [aweight=fracpop], msymbol(Oh) mcolor(gray)),
xlabel(3.5(.5)5, labsize(small))
yscale(range(0 6))
xscale(range(3.1 5))
xtitle("Log Per Capita Consumption", size(small))
ytitle("Consumption Increase (as %)", size(small))
ylab(0(1)6,angle(0) labsize(small)  format(%2.1f))
title("{bf: d.} Regional Gains in 2120")
yline(0, lc(black) lp(dash))
text(5.6 4.8 "2 Bn", size(tiny))
text(5.07 4.8 "1 Bn", size(tiny))
text(6 4.8 "Circles Proportional" "to 2120 Population", size(tiny))
text(0 3.15 "BAU", placement(ne) size(vsmall))
legend(off)
name(Cross2120BAU);

#delimit cr
restore

**Now Density Plots
preserve
keep if year<2220
recode $oldfiles (.=0)
sort regionid year $oldfiles
gen CPCfrac = 100*(CPC/CPC[_n+1]-1) if $oldfiles==0 & region==region[_n+1]
gen CPCfracBAU  = 100*(CPC/CPCBAU -1) 
drop if year==2005
egen totPop = total(Pop)
gen fracpop = Pop/totPop
gen LogCPC = log(CPCBAU)

#delimit ;
twoway (kdensity CPCfrac [aweight=fracpop], lw(thick) lc(black)),
xline(0, lp(dash) lc(black))
xscale(range(-3.5 1.8))
ytitle("Fraction of All People-Years", size(small))
ylab(,angle(0) labsize(vsmall))
xlab(,labsize(small))
text(1.4 0.2 "Many Benefit", placement(e) color(green) size(small))
text(1.4 -.2 "Few Sacrifice", placement(w) color(red) size(small))
xtitle("Consumption Increase (as %)", size(small))
title("{bf: a.} All People Through 2200")
name(DensityGains);

twoway (kdensity CPCfracBAU [aweight=fracpop], lw(thick) lc(black)),
xline(0, lp(dash) lc(black))
ytitle("Fraction of All People-Years", size(small))
xlab(,labsize(small))
ylab(,angle(0) labsize(vsmall))
xtitle("Consumption Increase (as %)", size(small))
title("{bf: c.} All People Through 2200")
name(DensityGainsBAU);
#delimit cr

restore

#delimit ;
graph combine DensityGains Cross2120, 
ysize(6) xsize(10) title("Versus Uniform Price")
name(TophalfFig3);
graph combine DensityGainsBAU Cross2120BAU,
ysize(6) xsize(10) title("Versus BAU")
name(BottomhalfFig3);
#delimit ;
graph combine TophalfFig3 BottomhalfFig3, cols(1)
ysize(10) xsize(9)
title("Gains From Utilitarianism");
graph export "Fig3.pdf", replace;
graph export "Fig3.svg", replace;
#delimit cr


***********Figure 4*******************
global lastyear 2200
sort year
#delimit ;
twoway (connected temp year if $oldfiles == . & region=="Africa" & year<$lastyear & year>2015, lc(forest_green) ms(i)) (connected temp year if $oldfiles == 1 & region=="Africa" & year<$lastyear & year>2015, lc(maroon) lp(longdash) ms(i)), title("{bf: a.}  Temperature", c(black)) name(temperature) xtitle("") ytitle("Temperature Increase (C)" "(relative to pre-industrial)") legend(col(2) order(1 "$newway" 2 "$oldway")) graphr(c(white) lc(white)) ylab(, nogrid angle(0) format(%3.1f)) xlab(2020 "2020" 2050 "2050" 2100 "2100" 2150 "2150" 2200 "2200");
#delimit cr
graph export "Figure4.svg", replace
graph export "Figure4.pdf", replace

