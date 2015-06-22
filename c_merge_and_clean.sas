/*

AUTHOR:          F. Dimas Pena Romera
START DATE:      27/12/14
LAST MODIFIED:   08/01/15	
PURPOSE: Prepare compustat data for analysis in stata. Ohlson model and descriptives 
INPUT: dimmod.compucrsp was created in a_Compustat_Crsp_Universe script with the required data for the following analysis. 
OUTPUT: compcrsp.dta (stata file - ready for analysis)

*/
*merge compustat crsp universe with variables from ibes_permno, note that ibes_permno has duplicates that
we must deal with;
/*
proc sql;
create table ibescompu as select a.*, b.actual, b.anndats_act, b.sur, b.cusip, b.shout as ibesshout, b.price as ibesprice from dimmod.compcrsp a left join dimmod.sum b
on a.permno=b.permno and a.datadate=b.fpedats
where a.permno ne .;
quit;
*/


*logical checks 
* ------------------------------------------------------------------- *;
* Create basic variables.
* ------------------------------------------------------------------- *;
* Logical checks and replacing of missing with zero and vice-versa,
* after having looked at raw data.
* ------------------------------------------------------------------- *;

data compucrsp; set dimmod.compcrsp;   
if pxfye   <= 0 then pxfye    = .; *if price at end of fiscal year is negative then set to missing.;
if shsfye  <= 0 then shsfye   = .; *if shares outstanding and the end of fiscal year is negative then set to missing.;
if div     <  0 then div      = .; *if dividends negative then set to missing;
if ta      <= 0 then ta       = .; * if total assets negative then set to missing;
if tl      <= 0 then tl       = .; *if total liabilities negative then set to missing;
if rd       = . then rd       = 0; *if R&D exp is missing then assume its 0 (alternatively a dummy could be used);
if ce = 0 		then ce 	  = .; *if common equity is 0 then set to missing (distressed companies?);
run;


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
data compucrsp; set compucrsp;
sic = 0;
if dnum >= 1000 and dnum <= 1999 then sic = 1;
if dnum >= 2000 and dnum <= 2111 then sic = 2;
if dnum >= 2200 and dnum <= 2780 then sic = 3;
if dnum >= 2800 and dnum <= 2824 then sic = 4;
if dnum >= 2840 and dnum <= 2899 then sic = 4;
if dnum >= 2830 and dnum <= 2836 then sic = 5;
if dnum >= 2900 and dnum <= 2999 then sic = 6;
if dnum >= 1300 and dnum <= 1399 then sic = 6;
if dnum >= 3000 and dnum <= 3999 then sic = 7;
if dnum >= 3580 and dnum <= 3579 then sic = 8;
if dnum >= 3670 and dnum <= 3679 then sic = 8;
if dnum >= 7370 and dnum <= 7379 then sic = 8;
if dnum >= 4000 and dnum <= 4899 then sic = 9;
if dnum >= 4900 and dnum <= 4999 then sic = 10;
if dnum >= 5000 and dnum <= 5999 then sic = 11;
if dnum >= 6000 and dnum <= 6411 then sic = 12;
if dnum >= 6500 and dnum <= 6999 then sic = 13;
if dnum >= 7000 and dnum <= 7369 then sic = 14;
if dnum >= 7380 and dnum <= 8999 then sic = 14;
if sic = 1  then dsic1  = 1; else dsic1  = 0;
if sic = 2  then dsic2  = 1; else dsic2  = 0;
if sic = 3  then dsic3  = 1; else dsic3  = 0;
if sic = 4  then dsic4  = 1; else dsic4  = 0;
if sic = 5  then dsic5  = 1; else dsic5  = 0;
if sic = 6  then dsic6  = 1; else dsic6  = 0;
if sic = 7  then dsic7  = 1; else dsic7  = 0;
if sic = 8  then dsic8  = 1; else dsic8  = 0;
if sic = 9  then dsic9  = 1; else dsic9  = 0;
if sic = 10 then dsic10 = 1; else dsic10 = 0;
if sic = 11 then dsic11 = 1; else dsic11 = 0;
if sic = 12 then dsic12 = 1; else dsic12 = 0;
if sic = 13 then dsic13 = 1; else dsic13 = 0;
if sic = 14 then dsic14 = 1; else dsic14 = 0;
run;


* ------------------------------------------------------------------- *;
* OHLSON-specific variables.
* ------------------------------------------------------------------- *;
data compucrsp; set compucrsp;
netcap    = cppur - cpsale;
ione      = ni    - ibx   ;

mve       = pxfye*shsfye;

ionepct = .;
d_ione  = 0;
if ibx ne 0 then ionepct = abs(ione)/abs(ibx);
if ione < 0 or ione > 0 then d_ione = 1;
if ione = .             then d_ione = .;
run;



*I generate a sata file dimmod.comperged as my Compustat Crsp Universe;
proc export 
data= dimmod.compcrsp
dbms=dta
outfile="C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified\compcrsp.dta"
replace;
run;









/* ALL CODE BELOW IS COMMENTED OUT




* ------------------------------------------------------------------- *;
* Create lags and leads
* ------------------------------------------------------------------- *;

/*LAG VALUES 

proc sort data=compucrsp; by gvkey datadate;
data compucrsp; set compucrsp;

* ------------------------------------------------------------------- *;
* Create lags and leads
* ------------------------------------------------------------------- *;

/*LAG VALUES 

data compucrsp; set compucrsp;

iperm = gvkey;
year = fyear;



l1iperm = lag1(iperm);
l1year  = lag1(year) ;
l1year  = l1year + 1 ;
l1fyr   = lag1(fyr)  ;

l2iperm = lag2(iperm);
l2year  = lag2(year) ;
l2year  = l2year + 2 ;
l2fyr   = lag2(fyr)  ;

l3iperm = lag3(iperm);
l3year  = lag3(year) ;
l3year  = l3year + 3 ;
l3fyr   = lag3(fyr)  ;

l1ibx   = lag1(ibx)  ;
l2ibx   = lag2(ibx)  ;
l3ibx   = lag3(ibx)  ;
l1div   = lag1(div)  ;
l2div   = lag2(div)  ;
l3div   = lag3(div)  ;
l1ce    = lag1(ce)   ;
l2ce    = lag2(ce)   ;
l1mve   = lag1(mve)  ;

if (iperm = l1iperm) and (year = l1year) and (fyr = l1fyr)
then do;
  ibxm1   = l1ibx ;
  divm1   = l1div ;
  cem1    = l1ce  ;
  mvem1   = l1mve ;
end;
else do;
  ibxm1   = . ;
  divm1   = . ;
  cem1    = . ;
  mvem1   = . ;
end;

if (iperm = l2iperm) and (year = l2year) and (fyr = l2fyr)
then do;
  ibxm2   = l2ibx ;
  divm2   = l2div ;
  cem2    = l2ce  ;
end;
else do;
  ibxm2   = . ;
  divm2   = . ;
  cem2    = . ;
end;

if (iperm = l3iperm) and (year = l3year) and (fyr = l3fyr)
then do;
  ibxm3   = l3ibx ;
  divm3   = l3div ;
end;
else do;
  ibxm3   = . ;
  divm3   = . ;
end;

run;

proc sort data=compucrsp; by gvkey descending datadate;

data compucrsp; set compucrsp;
/*LEAD VALUES 

d1iperm = lag1(iperm);
d1year  = lag1(year) ;
d1year  = d1year - 1 ;
d1fyr   = lag1(fyr)  ;

d2iperm = lag2(iperm);
d2year  = lag2(year) ;
d2year  = d2year - 2 ;
d2fyr   = lag2(fyr)  ;

d3iperm = lag3(iperm);
d3year  = lag3(year) ;
d3year  = d3year - 3 ;
d3fyr   = lag3(fyr)  ;

d1ibx   = lag1(ibx)  ;
d2ibx   = lag2(ibx)  ;
d3ibx   = lag3(ibx)  ;
d1div   = lag1(div)  ;
d2div   = lag2(div)  ;
d3div   = lag3(div)  ;


* ------------------------------------------------------------------- *;

if (iperm = d1iperm) and (year = d1year) and (fyr = d1fyr)
then do;
  ibxd1   = d1ibx ;
  divd1   = d1div ;
end;
else do;
  ibxd1   = . ;
  divd1   = . ;
end;

if (iperm = d2iperm) and (year = d2year) and (fyr = d2fyr)
then do;
  ibxd2   = d2ibx ;
  divd2   = d2div ;
end;
else do;
  ibxd2   = . ;
  divd2   = . ;
end;

if (iperm = d3iperm) and (year = d3year) and (fyr = d3fyr)
then do;
  ibxd3   = d3ibx ;
  divd3   = d3div ;
end;
else do;
  ibxd3   = . ;
  divd3   = . ;
end;

* ------------------------------------------------------------------- *;
* Define dirty surplus items DIRT.
* ------------------------------------------------------------------- *;

dirt    = ce - cem1 - ni + div + netcap;

dirtpct = .;
d_dirt  = 0;
if ibx ne 0 then dirtpct = abs(dirt)/abs(ibx);
if abs(dirt) > 0.01     then d_dirt = 1;
if dirt = .             then d_dirt = .;

* ------------------------------------------------------------------- *;
* Define abnormal earnings.
* ------------------------------------------------------------------- *;

r	= 0.12;
xam1	= ibxm1 - (r*cem2);
xa	= ibx   - (r*cem1);
xad1	= ibxd1 - (r*ce  );

run;



* ------------------------------------------------------------------- *;
* Create various dummies
* ------------------------------------------------------------------- *;
data compucrsp; set compucrsp;
if div    > 0 then d_div    = 1; else d_div    = 0;
if ce    <= 0 then d_nce    = 1; else d_nce    = 0;
if ibx   <= 0 then d_nibx   = 1; else d_nibx   = 0;
* if f_ni1 <= 0 then d_nf_ni1 = 1; *  else d_nf_ni1 = 0;
if div   = .  then d_div    = .;
if ce    = .  then d_nce    = .;
if ibx   = .  then d_nibx   = .;
* if f_ni1 = .  then d_nf_ni1 = .;

* ------------------------------------------------------------------- *;
* Conform DFALL down based ONLY on basic OHLSON restrictions.
* Note that Compustat does not have either of the components of
* netcap = cppur - cpsale for banks, utilities, life insurance, or
* property and casualty cos.
* ------------------------------------------------------------------- *;
* Delete if missing mve, ce, ibx, div or netcap.
* ------------------------------------------------------------------- *;

if year   <= 1973 then delete;
if year   >= 1997 then delete;
if sic     = 0  then delete;
if sic     = .  then delete;
if mve     = .  then delete;
if ce      = .  then delete;
if ibx     = .  then delete;
if div     = .  then delete;
if netcap  = .  then delete;
run;

proc sort data=compucrsp; by gvkey descending datadate;








/*

















l1gvkey = lag1(gvkey);
l1fyear  = lag1(fyear) ;
l1fyear  = l1fyear + 1 ;
l1fyr   = lag1(fyr)  ;

l2gvkey = lag2(gvkey);
l2fyear  = lag2(fyear) ;
l2fyear  = l2fyear + 2 ;
l2fyr   = lag2(fyr)  ;

l3gvkey = lag3(gvkey);
l3fyear  = lag3(fyear) ;
l3fyear  = l3fyear + 3 ;
l3fyr   = lag3(fyr)  ;

l1ibx   = lag1(ibx)  ;
l2ibx   = lag2(ibx)  ;
l3ibx   = lag3(ibx)  ;
l1div   = lag1(div)  ;
l2div   = lag2(div)  ;
l3div   = lag3(div)  ;
l1ce    = lag1(ce)   ;
l2ce    = lag2(ce)   ;
l1mve   = lag1(mve)  ;

if (gvkey = l1gvkey) and (fyear = lf1year) and (fyr = l1fyr)
then do;
  ibxm1   = l1ibx ;
  divm1   = l1div ;
  cem1    = l1ce  ;
  mvem1   = l1mve ;
end;
else do;
  ibxm1   = . ;
  divm1   = . ;
  cem1    = . ;
  mvem1   = . ;
end;

if (gvkey = l2gvkey) and (fyear = l2fyear) and (fyr = l2fyr)
then do;
  ibxm2   = l2ibx ;
  divm2   = l2div ;
  cem2    = l2ce  ;
end;
else do;
  ibxm2   = . ;
  divm2   = . ;
  cem2    = . ;
end;

if (gvkey = l3gvkey) and (fyear = l3fyear) and (fyr = l3fyr)
then do;
  ibxm3   = l3ibx ;
  divm3   = l3div ;
end;
else do;
  ibxm3   = . ;
  divm3   = . ;
end;


/*LEAD VALUES 

d1gvkey = lag1(gvkey);
d1fyear  = lag1(fyear) ;
d1fyear  = d1fyear - 1 ;
d1fyr   = lag1(fyr)  ;

d2igvkey = lag2(gvkey);
d2fyear  = lag2(fyear) ;
d2fyear  = d2fyear - 2 ;
d2fyr   = lag2(fyr)  ;

d3gvkey = lag3(gvkey);
d3fyear  = lag3(fyear) ;
d3fyear  = d3fyear - 3 ;
d3fyr   = lag3(fyr)  ;

d1ibx   = lag1(ibx)  ;
d2ibx   = lag2(ibx)  ;
d3ibx   = lag3(ibx)  ;
d1div   = lag1(div)  ;
d2div   = lag2(div)  ;
d3div   = lag3(div)  ;

* --------------------------------------------------------------- *;

if (gvkey = d1gvkey) and (fyear = d1fyear) and (fyr = d1fyr)
then do;
  ibxd1   = d1ibx ;
  divd1   = d1div ;
end;
else do;
  ibxd1   = . ;
  divd1   = . ;
end;

if (gvkey = d2gvkey) and (fyear = d2fyear) and (fyr = d2fyr)
then do;
  ibxd2   = d2ibx ;
  divd2   = d2div ;
end;
else do;
  ibxd2   = . ;
  divd2   = . ;
end;

if (gvkey = d3gvkey) and (fyear = d3fyear) and (fyr = d3fyr)
then do;
  ibxd3   = d3ibx ;
  divd3   = d3div ;
end;
else do;
  ibxd3   = . ;
  divd3   = . ;
end;






* ------------------------------------------------------------------- *;
* Define dirty surplus items DIRT.
* ------------------------------------------------------------------- *;

dirt    = ce - cem1 - ni + div + netcap;

dirtpct = .;
d_dirt  = 0;
if ibx ne 0 then dirtpct = abs(dirt)/abs(ibx);
if abs(dirt) > 0.01     then d_dirt = 1;
if dirt = .             then d_dirt = .;

* ------------------------------------------------------------------- *;
* Define abnormal earnings.
* ------------------------------------------------------------------- *;

r	= 0.12;
xam1	= ibxm1 - (r*cem2);
xa	= ibx   - (r*cem1);
xad1	= ibxd1 - (r*ce  );


run;


/*

* collect earnings announcement from last quarter; 
proc sql;
create table ibescompu as select a.*, b.rdq from ibescompu a left join rawcomp.R_2015_fundq b
on a.gvkey=b.gvkey and a.datadate=b.datadate 
where not missing(a.gvkey)  and not missing(a.datadate);
quit;
