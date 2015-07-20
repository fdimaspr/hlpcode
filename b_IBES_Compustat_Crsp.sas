/*

AUTHOR:          F. Dimas Pena Romera
START DATE:      27/12/14
LAST MODIFIED:   08/01/15	
PURPOSE: Earnings Suprises. Download IBES files for US forecasts and actuals (both detail and summary) plus the linking file. 
Compute consesus surprise (using median forecast prior to announcement) and surprise using last forecast available 
prior to announcement. Merge surpises to link file to get permnos. Output surprise file in dimmod.filename. 
  

INPUT: 
	1. location of raw ibes data and linkfile after rawibes. 
	2. location of destination merged file after dimmod. 

OUTPUT: 
	1. dimmod.filename = surprise file. 
*/


*include macros;
%include 'C:\Users\penarome\Desktop\Academic\Generic_code\Dimas\macros.sas';
%include 'C:\ado\plus\s\stata_wrapper.sas';

*I define my local permanent libraries in which I will modify and update outputs.;
libname dimmod 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified' ;
libname fig 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting';

*I define libraries in which to locate and extract rawdata. all these directories will be deleted at the end of the project;

libname rawcomp 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RCompustat_2015' ;
libname rawibes 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RIbes_2015' ;
libname rawcrsp 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RCrsp_2015';
/*
*-------------- DOWNLOAD required files from wrds and store them in rawibes; 

%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username="fdimaspr" password="481766Qr$";
rsubmit ;
libname ibes ' /wrds/ibes/sasdata' ;
option msglevel =i mprint source;
proc download data=ibes.DETU_EPSUS out=rawibes.DETU_EPSUS;
run ;
endrsubmit ;
*-----------------------------------------------------------------------------------------------------------------------------------
*/


*I previously created compustat crsp universe that includes anouncement dates from compustat quarterly. I link compcrsp universe to ibes ticker using iclinc;
* i consider links with score under 4 to be valid;
proc sql;
create table _announce as select a.gvkey, a.permno, a.fyear, a.datadate, a.rdq, b.ticker from dimmod.compcrsp a left join rawibes.iclinc b
on a.permno=b.permno
where (b.score le 4) and b.permno ne .;
quit;

PROC SORT DATA=_announce;
BY permno datadate rdq;
RUN;

*I attach announcement dates from ibes;
data temp;
set rawibes.NSTATSUM_EPSUS;
if measure="EPS" and fpi in ("1") and fiscalp=("ANN");
keep FPEDATS ANNDATS_ACT TICKER;
run;

PROC SORT DATA=_temp nodupkey;
BY TICKER FPEDATS ANNDATS_ACT;
RUN;

proc sql;
create table _announce2 as select a.*, b.ANNDATS_ACT as rdqibes from _announce a left join _temp b
on (a.ticker=b.ticker) and (a.datadate=b.FPEDATS);
quit;

*whenever announcement date is missing both from compustat and ibes, crease pseudo announcement date 90 days after fiscal year end;
*generate rdqfinal, compustat is priority, if compustat is missing then use ibes, if both missing then add 90 days to fiscalyearend;

data _announce3; set _announce2;
	if missing(rdq) and missing(rdqibes) then rdqps= intnx('day',datadate,+90,'beg');
run;

data dimmod.announce; set _announce3;
	format datadate rdq rdqibes rdqps rdqfinal date9.;
	if not(missing(rdq)) then rdqfinal=rdq;
	if missing(rdqfinal) then rdqfinal=rdqibes;
	if missing(rdqfinal) then rdqfinal=rdqps;
run;

*check duplicates;
PROC SORT DATA=dimmod.announce nodupkey;
BY permno fyear;
RUN;


* I generate a variable that includes next fiscal year end - i use stata for this for convenience - the fdadatade is the fiscal year end of year t+1, the 
relevant forecast in order to compute the forecast error;
%stata_wrapper; 
data test (keep=permno datadate fyear);
set dimmod.announce;
run;

%stata_wrapper(code) datalines;
xtset permno fyear, yearly
gen fdatadate=f.datadate
savasas _all using C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified\announcenext.sas7bdat , replace
;;;;

proc sql;
create table dimmod.announcenext as select a.*, b.fdatadate from dimmod.announce a left join dimmod.announcenext b
on (a.permno=b.permno) and (a.datadate=b.datadate);
quit;

data dimmod.announcenext; set dimmod.announcenext; 
if fdatadate eq . then fdatadate=intnx('month', datadate, +12, 'end') ;
format datadate fdatadate rdq rdqibes rdqps rdqfinal date9.;
run;

*dimmod.announcenext contains gvkey permno datadate fdatadate rdqfinal;

*I merge my dimmod.announcenext file to UNANDJUSTED DETAIL file by ibes ticker and fdatadate=fpedats. I then keep the nearest forecast prior to the announcement date (rdqfinal).
;

proc sql;
create table _fcastrdq as select a.*, b.rdqfinal, b.datadate, b.fdatadate, b.permno from rawibes.DETU_EPSUS a inner join dimmod.announcenext b
on (a.ticker=b.ticker) and (a.FPEDATS=b.fdatadate) 
where a.measure="EPS" and a.fpi in ("2") and a.report_curr=("USD");
quit;

data _fcastrdq; set _fcastrdq; 
if ANNDATS gt rdqfinal then delete; 
run;

PROC SORT DATA=_fcastrdq;
BY TICKER FPEDATS ANNDATS;
RUN;


proc print data=_fcastrdq (obs=100);
	var TICKER FPEDATS ANNDATS rdqfinal;
	run; 

data _fcastrdq;
set _fcastrdq;
by TICKER FPEDATS;
if last.FPEDATS;
run;

proc print data=_fcastrdq (obs=100);
	var TICKER FPEDATS ANNDATS rdqfinal;
	run; 

*merge back to all compustat crsp data;
proc sql;
create table _temp1 as select a.*, b.value, b.fdatadate, b.rdqfinal, b.ANNDATS from dimmod.compcrsp a inner join _fcastrdq b
on (a.permno=b.permno) and (a.datadate=b.datadate) ;
quit;

*collect closest shares outstanding to forecast date from crsp daily!;
proc sql;
create table _temp11 as select a.*, b.date, b.SHROUT from _temp1 a left join rawcrsp.dsf b
on (a.permno=b.permno) and (a.ANNDATS=b.date);
quit;





proc print data=_temp11 (obs=111);
	var permno datadate ni ibx shsfye SHOUT pxfye PRICE ACTUAL OPREPSX ACTUALFEARNINGS FCASTEARNINGS rdqfinal;
	run; 


















*I merge my dimmod.announcenext file to Statsum file by ibes ticker and fdatadate=fpedats. I then keep the nearest forecast prior to the announcement date (rdqfinal).
;

proc sql;
create table _fcastrdq as select a.*, b.rdqfinal, b.datadate, b.fdatadate, b.permno from rawibes.NSTATSUM_EPSUS a inner join dimmod.announcenext b
on (a.ticker=b.ticker) and (a.FPEDATS=b.fdatadate) 
where a.measure="EPS" and a.fpi in ("2") and a.fiscalp=("ANN");
quit;

data _fcastrdq; set _fcastrdq; 
if STATPERS gt rdqfinal then delete; 
run;

PROC SORT DATA=_fcastrdq;
BY TICKER FPEDATS STATPERS;
RUN;

proc print data=_fcastrdq (obs=100);
	var TICKER FPEDATS STATPERS rdqfinal;
	run; 

data _fcastrdq;
set _fcastrdq;
by TICKER FPEDATS;
if last.FPEDATS;
run;


*from the ibes actual file plus price anciliary file I collect actual values, stock price and shares outstanding in the date of the
statistical period? STATPERS is the time when the consensus forecasts are calcualted;
proc sql;
create table _temp as select a.*, b.PRICE, b.SHOUT, b.fy0edats, b.FY0A from _fcastrdq a left join rawibes.Nactpsum_epsUS b
on a.ticker=b.ticker and a.STATPERS=b.STATPERS;
quit;

*CALCULATE EARNINGS SURPRISE / FORECAST ERROR. 
THERE ARE MANY FORECASTS FOR EACH FISCAL YEAR, I WILL TAKE THE LAST FORECAST AS THE BASIS FOR CALCULATING EARNINGS SURPRISE;
*actual is actual earnings;
*MEDEST is the median of all the forecastes avaiable, which is the consensus forecasts, some researchers may use mean, but it shouldn't matter;
data _temp2;
set _temp;
if SHOUT le 0 then delete;
if SHOUT gt 0 then FCASTEARNINGS=MEDEST*SHOUT;
if SHOUT gt 0 then ACTUALFEARNINGS=ACTUAL*SHOUT;
keep FCASTEARNINGS ACTUALFEARNINGS ticker datadate fdatadate rdqfinal PRICE SHOUT ACTUAL MEDEST permno;
run;


*merge back to all compustat crsp data;
proc sql;
create table _temp11 as select a.*, b.* from dimmod.compcrsp a inner join _temp2 b
on (a.permno=b.permno) and (a.datadate=b.datadate) ;
quit;


proc print data=_temp11 (obs=111);
	var permno datadate ni ibx shsfye SHOUT pxfye PRICE MEDEST ACTUAL OPREPSX ACTUALFEARNINGS FCASTEARNINGS rdqfinal;
	run; 






if FCASTERR eq . then delete;
*I generate a sata file dimmod.comperged as my Compustat Crsp Universe;
proc export 
data= dimmod.compcrsp
dbms=dta
outfile="C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified\compcrsp.dta"
replace;
run;

*if STATPERS gt rdqfinal then delete; 
*PICK THE LAST FORECAST HERE, BUT BEFORE EARNINGS ANNOUNCEMENT;
	*step 1 deletes cases where actual announcement date exists and statpers exists, but announcement date is  is before 
	the statper date (suspicious observations);
data _sum;
set _sum;
if (ANNDATS_ACT ne .) and (STATPERS ne .) and (ANNDATS_ACT le STATPERS) THEN delete; 
run;
	*step 2 assumes that If ANNDATS_ACT is missing, then I assume that the last forecast for each TICKER-FPEDATS group
	is made before the earnings announcement date, which is generally the case;
PROC SORT DATA=_sum;
BY TICKER FPEDATS STATPERS;
RUN;
*SUR has the earnings surprises for each firm;
data _sum;
set _sum;
by TICKER FPEDATS;
if last.FPEDATS;
run;
*FPEDATS IS ESSENTIALLY THE DATADATE VARIABLE IN COMPUSTAT;
data _sum;
set _sum;
if sur eq . then delete;
run;

*link permno to tickers in surprise file duplicates generated;
proc sql;
create table _sum as select a.*, b.permno from _sum a left join rawibes.iclinc b
on a.ticker=b.ticker
where (b.score le 4) and b.permno ne .;
quit;

data dimmod._sum;
set _sum;
run;








/*
***************works till here, still figuring out ibes data ***********;



%ff30(data=dimmod.compcrsp,newvarname=industry,sic=sic,out=compmerged);


proc sql;
create table sur3 as select a.*, b.industry, b.rdq, b.datadate, b.fyr from sur2 a left join compmerged b
on a.permno=b.permno and a.fpedats=b.datadate
where a.permno ne .;
quit;


data sur3; 
set sur3;
if rdq eq anndats_act then consist=1;
run;

*keep all distinct announcement dates;

data anounce;
set sur3;
if rdq eq . then delete;
keep rdq;
run;

proc sort data=anounce nodupkey;
by rdq;
run;


data anounce1;
set anounce;
if _N_=1;
run;

data smallcrsp; set rawcrsp.dsf;
if year(date) eq 1983;
run;
data smallcrsp; set smallcrsp;
keep permno date;
run;

data vcrsp /view=vcrsp;
	set smallcrsp;
	keep date permno;
run; 

data evup2;
set vcrsp;
where date eq 19831026;
run;





proc sql;
create table evup1 as select a.rdq as eventdate, b.permno from anounce1 a left join rawcrsp.dsf b
on a.rdq=b.date
where not missing(permno) and not missing(prc);
quit;











proc sort data=sum ;
by ticker FPEDATS;
run;
