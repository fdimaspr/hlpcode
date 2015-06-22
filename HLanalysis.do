clear all

cd "C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified"
use compcrsp.dta, clear
cd "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting"


*note that because of the construction of the compsutat crsp universe we have no
*duplicates in gvkey fyear

duplicates drop gvkey fyear, force
destring(gvkey) , replace

*set data set as pannel to create lags and leads
xtset gvkey fyear, yearly


*logical checks 
* ------------------------------------------------------------------- *;
* Create basic variables.
* ------------------------------------------------------------------- *;
* Logical checks and replacing of missing with zero and vice-versa,
* after having looked at raw data.
* ------------------------------------------------------------------- *;

replace pxfye=. if pxfye <= 0 
*if price at end of fiscal year is negative then set to missing
replace shsfye=. if shsfye <= 0 
replace div=. if div < 0 
replace ta=. if  ta <= 0 
replace tl=. if tl <=0
replace rd=0 if rd==.
replace ce=. if ce==0
replace capx=0 if capx==.



*Industries;
* ------------------------------------------------------------------- *;
* Define industries by BBL98 p.43 classifications.
* 1.  sic = 1		Mining and construction
* 2.  sic = 2		Food
* 3.  sic = 3		Textiles, printing and publishing
* 4.  sic = 4		Chemicals
* 5.  sic = 5		Pharmaceuticals
* 6.  sic = 6		Extractive industries
* 7.  sic = 7		Durable manufacturers
* 8.  sic = 8		Computers
* 9.  sic = 9		Transportation
* 10. sic = 10 	Utilities
* 11. sic = 11	Retail
* 12. sic = 12	Financial institutions
* 13. sic = 13	Insurance and real estate
* 14. sic = 14	Services
* ------------------------------------------------------------------- *;

destring(dnum), replace

gen sic = 0
browse sic dnum 
replace sic=1   if dnum >= 1000 & dnum <= 1999 
replace sic= 2  if dnum >= 2000 & dnum <= 2111  
replace sic= 3  if dnum >= 2200 & dnum <= 2780  
replace sic= 4  if dnum >= 2800 & dnum <= 2824  
replace sic= 4  if dnum >= 2840 & dnum <= 2899  
replace sic= 5  if dnum >= 2830 & dnum <= 2836  
replace sic= 6  if dnum >= 2900 & dnum <= 2999  
replace sic= 6  if dnum >= 1300 & dnum <= 1399  
replace sic= 7  if dnum >= 3000 & dnum <= 3999  
replace sic=8  if dnum >= 3580 & dnum <= 3579  
replace sic=8  if dnum >= 3670 & dnum <= 3679  
replace sic=8  if dnum >= 7370 & dnum <= 7379  
replace sic=9  if dnum >= 4000 & dnum <= 4899  
replace sic=10  if dnum >= 4900 & dnum <= 4999 
replace sic=11  if dnum >= 5000 & dnum <= 5999 
replace sic=12  if dnum >= 6000 & dnum <= 6411 
replace sic=13  if dnum >= 6500 & dnum <= 6999 
replace sic=14  if dnum >= 7000 & dnum <= 7369 
replace sic=14  if dnum >= 7380 & dnum <= 8999 

gen sicname = ""
replace sicname= "Mining and construction"  if sic==1    
replace sicname= "Food"  if sic== 2    
replace sicname= "Textiles, printing and publishing"  if sic== 3    
replace sicname= "Chemicals"  if sic== 4    
replace sicname= "Pharmaceuticals"  if sic== 5    
replace sicname= "Extractive industries"  if sic== 6    
replace sicname= "Durable manufacturers"  if sic== 7    
replace sicname= "Computers"  if sic== 8    
replace sicname= "Transportation"  if sic== 9    
replace sicname= "Utilities"  if sic==10    
replace sicname= "Retail"  if sic==11    
replace sicname= "Financial institutions"  if sic==12    
replace sicname= "Insurance and real estate"  if sic==13    
replace sicname= "Services"  if sic==14   


* ------------------------------------------------------------------- *;
* OHLSON-specific variables.
* ------------------------------------------------------------------- *;

gen netcap   = cppur - cpsale
gen ione      = ni    - ibx   

gen mve       = pxfye*shsfye

gen ionepct = .
gen d_ione  = 0

replace ionepct=abs(ione)/abs(ibx) if ibx!=0
replace d_ione=1 if ione>0 | ione<0
replace d_ione=. if ione==.



* * ------------------------------------------------------------------- *;
* Relevant leads and lags
* --------------------------------------------------------------------- *;
gen cem1 = l.ce
gen mvem1=l.mve
gen ibxm1=l.ibx
gen divm1=l.div

* ------------------------------------------------------------------- *;
* Define dirty surplus items DIRT.
* ------------------------------------------------------------------- *;
browse gvkey fyear ce ibx ni netcap div


gen dirt    = ce - cem1 - ni + div + netcap
gen d_dirt=0
gen dirtpct=.

replace dirtpct=abs(dirt)/abs(ibx) if ibx!=0

replace d_dirt=1 if abs(dirt) > 0.01
replace d_dirt=. if dirt==.


* ------------------------------------------------------------------- *;
* Define abnormal earnings.
* ------------------------------------------------------------------- *;
gen r = 0.12
gen xa= ibx - (r*l.ce)
gen xad1=f.xa
gen xam1=l.xa

* ------------------------------------------------------------------- *;
* Create various dummies
* ------------------------------------------------------------------- *;
gen d_div = 1 if div>0
replace d_div=0 if div==0
replace d_div=. if div==.
assert div>=0

browse gvkey fyear ce 
gen d_nce = 1 if ce<=0
replace d_nce=0 if d_nce!=1
replace d_nce=. if ce==.


browse gvkey fyear ibx
gen d_nibx = 1 if ibx<=0
replace d_nibx=0 if d_nibx!=1
replace d_nibx=. if ibx==.


* ------------------------------------------------------------------- *;
* keep relevant variables
* ------------------------------------------------------------------- *;

keep gvkey fyear fyr conm pxfye shsfye mve mvem1 ce cem1 ibx ibxm1 ni ///
div divm1 netcap rd ta tl xam1 xa xad1 dirt dirtpct d_dirt ione ionepct ///
d_ione d_div d_nce d_nibx sic sicname capx /// 



* ------------------------------------------------------------------- *;
* Delete if missing mve, ce, ibx, div or netcap.
* ------------------------------------------------------------------- *;
drop if fyear ==.
drop if sic ==0
drop if sic ==.
drop if mve ==.
drop if ce ==.
drop if ibx ==.
drop if netcap ==. 
drop if div==.
drop if div ==0 
*note that I am dropping non-dividend paying firms!

* ------------------------------------------------------------------- *;
* Winsorize / Trim variables (Following HL2005 I trim by year at 1 and 99 pct)
* ------------------------------------------------------------------- *;

*I trim at top and bottom pctile.
foreach x in mve ce ibx div netcap xam xa xad1 ta {
winsor2 `x' , replace cuts(1 99) trim by(fyear)
}

foreach x in rd capx {
winsor2 `x' , replace cuts(0 99) trim by(fyear)
}
*rd and capx that I previously set to 0 when missing, I trim only at top pctile 

* ------------------------------------------------------------------- *;
* Delete again after trimming
* ------------------------------------------------------------------- *;
drop if fyear ==.
drop if sic ==.
drop if sic ==0
drop if mve ==.
drop if ce ==.
drop if ibx ==.
drop if netcap ==. 
drop if div ==.
drop if capx==.
drop if rd==.


* ------------------------------------------------------------------- *;
* Run Ohlson by year and store coefficients 
* ------------------------------------------------------------------- *;

gen c1=.
gen c2=.
gen c3=.
gen c4=.
gen Rsq=.
/*
gen Vc1=.
gen Vc2=.
gen Vc3=.
gen Vc4=.
*/

su fyear
local xmin r(min)
local xmax r(max)
scalar xmin = r(min)
scalar xmax = r(max)

forv fy = 1984(1)2014 {
reg mve ce ibx div netcap i.sic if fyear==`fy'
mat b_`fy'=e(b)
*mat li b_1998
replace c1=b_`fy'[1,1] if fyear==`fy'
replace c2=b_`fy'[1,2] if fyear==`fy'
replace c3=b_`fy'[1,3] if fyear==`fy'
replace c4=b_`fy'[1,4] if fyear==`fy'
replace Rsq=e(r2) if fyear==`fy'

/*
mat V_`fy'=e(V)
* mat li V_2014
replace Vc1=sqrt(V_`fy'[1,1]) if fyear==`fy'
replace Vc2=sqrt(V_`fy'[2,2]) if fyear==`fy'
replace Vc3=sqrt(V_`fy'[3,3]) if fyear==`fy'
replace Vc4=sqrt(V_`fy'[4,4]) if fyear==`fy'
*/

}


* ------------------------------------------------------------------- *;
* Table 3: Panel B + Extended years 
* ------------------------------------------------------------------- *;
preserve
duplicates drop fyear, force
drop if fyear > 1995
keep fyear c1 c2 c3 c4 Rsq
su c1 c2 c3 c4 Rsq
gen c3_c1=c3-c1
gen c4_c1=c4-c1
outsheet fyear c1 c2 c3 c4 Rsq c3_c1 c4_c1 using 84to95.csv , comma replace
restore

preserve
duplicates drop fyear, force
drop if fyear < 1996
su c1 c2 c3 c4 Rsq
gen c3_c1=c3-c1
gen c4_c1=c4-c1
outsheet fyear c1 c2 c3 c4 Rsq c3_c1 c4_c1 using 96to14.csv , comma replace
restore


/* Alternatively I could run the tests directly from stata - I check some 
examples and excel is performing the same tests.

drop if fyear>1995
duplicates drop fyear, force
keep fyear c1 c2 c3 c4 Rsq
su c1 c2 c3 c4 Rsq
gen c3_c1=c3-c1
gen c4_c1=c4-c1
ttest c1==0

ttest c4==0
ttest c4_c1==-1

ttest c1==0

*/

* ------------------------------------------------------------------- *;
* Descriptive evolution of payout policy
* ------------------------------------------------------------------- *;
browse gvkey fyear sic sicname ni ibx netcap div ta capx rd ce

save temp1, replace

use temp1, clear
* I drop missing and zero total asset observations that I will use as a deflator. 
drop if ta==.
drop if ta==0

* Generate variables scaled by total assets
gen payout= netcap + div

gen netcap_at= netcap/ta 
gen div_at= div/ta
gen payout_at= payout/ta
gen capex_at= capx/ta
gen rd_at= rd/ta

*Spit csv of descriptives by year for the variables VARS
local VARS mve ibx ce div netcap payout capx netcap_at div_at payout_at capex_at rd_at

preserve
keep fyear `VARS'
foreach x in `VARS' {
egen mean`x'=mean(`x'), by(fyear)
}
duplicates drop fyear, force
sort fyear
outsheet _all using meanyear.csv , comma replace
restore


*Spit csv of descriptives by industry
local VARS mve ibx ce div netcap payout capx netcap_at div_at payout_at capex_at rd_at
preserve

keep fyear sic sicname `VARS'
gen post=0
replace post=1 if fyear>=1996
foreach x in `VARS' {
egen mean`x'=mean(`x'), by(post sic)
}

duplicates drop post sic, force
sort post sic 
outsheet _all using meansicpost0.csv if post==0, comma replace
outsheet _all using meansicpost1.csv if post==1, comma replace
restore

  
*all these graphs are for dividend paying firms
preserve
graph drop _all

egen meannetcap=mean(netcap_at), by(fyear)
egen meandiv=mean(div_at), by(fyear)
egen meanpayout=mean(payout_at), by(fyear)
egen meancapx=mean(capex_at), by(fyear)
egen meanrd=mean(rd_at), by(fyear)

duplicates drop fyear, force
sort fyear
keep fyear meannetcap meandiv meanpayout meancapx meanrd
browse fyear meannetcap meandiv meanpayout meancapx meanrd



/*
twoway (line sp500 time, sort), ytitle(SP 500) xtitle(Quarterly Data) title(SP500) scheme(sj) xsize(2.7) ysize(1.7)
graph export "C:\Users\fdimaspr\Dropbox\UNC\Year 1\Econ 771 Metrics\Statahws\hw1\Sp500plot.png", as(png) replace
twoway (line nasdaq time, sort), ytitle(Nasdaq) xtitle(Quarterly Data) title(Nasdaq) scheme(sj) xsize(2.7) ysize(1.7)
*/

* I graph what has happened with average payout, netcap, div, and capx for the two sample periods considered


twoway (scatter meanpayout fyear) (lfit meanpayout fyear) if fyear>=1984 & fyear<=1995 , saving(meanpayoutPRE1, replace)  
twoway (scatter meanpayout fyear) (lfit meanpayout fyear) if fyear>=1996 & fyear<=2014 , saving(meanpayoutPOST1, replace) 


twoway (scatter meannetcap fyear) (lfit meannetcap fyear) if fyear>=1984 & fyear<=1995 , saving(meannetcapPRE1, replace)
twoway (scatter meannetcap fyear) (lfit meannetcap fyear) if fyear>=1996 & fyear<=2014, saving(meannetcapPOST1, replace)

twoway (scatter meandiv fyear) (lfit meandiv fyear) if fyear>=1984 & fyear<=1995 , saving(meandivPRE1, replace)
twoway (scatter meandiv fyear) (lfit meandiv fyear) if fyear>=1996 & fyear<=2014 , saving(meandivPOST1, replace)

twoway (scatter meancapx fyear)  (lfit meancapx fyear) if fyear>=1984 & fyear<=1995 , saving(meancapxPRE1, replace)
twoway (scatter meancapx fyear)  (lfit meancapx fyear) if fyear>=1996 & fyear<=2014 , saving(meancapxPOST1, replace)

twoway (scatter meanrd fyear)  (lfit meanrd fyear) if fyear>=1984 & fyear<=1995 , saving(meanrdPRE1, replace)
twoway (scatter meanrd fyear)  (lfit meanrd fyear) if fyear>=1996 & fyear<=2014 , saving(meanrdPOST1, replace)

gr combine meanpayoutPRE1.gph meanpayoutPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\Payoutovertime.png", as(png) replace

gr combine meandivPRE1.gph meandivPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\Divovertime.png", as(png) replace

gr combine meannetcapPRE1.gph meannetcapPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\Netcapovertime.png", as(png) replace

gr combine meancapxPRE1.gph meancapxPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\Capxovertime.png", as(png) replace


gr combine meanrdPRE1.gph meanrdPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\RDovertime.png", as(png) replace
restore




*all these graphs are for dividend paying firms additional requirement that non zero capx
preserve
graph drop _all
drop if capx==0
drop if capx==. 

egen meancapx=mean(capex_at), by(fyear)

duplicates drop fyear, force
sort fyear

twoway (scatter meancapx fyear)  (lfit meancapx fyear) if fyear>=1984 & fyear<=1995 , saving(meancapxPRE1, replace)
twoway (scatter meancapx fyear)  (lfit meancapx fyear) if fyear>=1996 & fyear<=2014 , saving(meancapxPOST1, replace)

gr combine meancapxPRE1.gph meancapxPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\Capxovertime2.png", as(png) replace

restore


*all these graphs are for dividend paying firms additional requirement that non zero rd
preserve
graph drop _all
drop if rd==0
drop if rd==. 

egen meanrd=mean(rd_at), by(fyear)

duplicates drop fyear, force
sort fyear

twoway (scatter meanrd fyear)  (lfit meanrd fyear) if fyear>=1984 & fyear<=1995 , saving(meanrdPRE1, replace)
twoway (scatter meanrd fyear)  (lfit meanrd fyear) if fyear>=1996 & fyear<=2014 , saving(meanrdPOST1, replace)

gr combine meanrdPRE1.gph meanrdPOST1.gph, ycommon col(2)
graph export "C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\RDovertime2.png", as(png) replace

restore

/*
drop if payout ==. 
drop if capx==.


/*
gen payout

gen netcap_ni= netcap/ni if ni>0 & ni !=.
gen netcap_ta= netcap/ta if ta>0 & ta !=.
gen div_ni = div/ni
gen payout=(netcap + div)/ni
