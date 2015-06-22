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
%include 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\Scripts\macros.sas';

*I define my local permanent libraries in which I will modify and update outputs.;
libname dimmod 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified' ;
libname fig 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting';

*I define libraries in which to locate and extract rawdata. all these directories will be deleted at the end of the project;

libname rawcomp 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RCompustat_2015' ;
libname rawibes 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RIbes_2015' ;
/*
*-------------- DOWNLOAD required files from wrds and store them in rawibes; 

%wrds;
rsubmit ;
libname ibes ' /wrds/ibes/sasdata' ;
option msglevel =i mprint source;
proc download data=ibes.Nactpsum_epsUS out=rawibes.Nactpsum_epsUS;
run ;
proc download data=ibes.NSTATSUM_EPSUS out=rawibes.NSTATSUM_EPSUS;
run ;
proc download data=ibes.NDET_EPSUS out=rawibes.NSTATSUM_EPSUS;
run ;
*Create Permno-IBES ticker link
%include '/wrds/ibes/samples/iclink.sas'; *create ibes ticker - crsp permno link file in home direct;
proc download data=home.iclink out=rawibes.iclinc;
run ;
endrsubmit ;
*-----------------------------------------------------------------------------------------------------------------------------------
*/


*keep forecasts for earnings per share and only annual forecasts (Note that annual forecasts are FPI==1 versus quarterly forecasts with FPI==6 or others);
data sum;
set rawibes.NSTATSUM_EPSUS;
if measure="EPS" and fpi in ("1");
run;
*get in stock price, which will be used as deflator below,
ticker is the unique firm identifier, STATPERS is the time when the consensus forecasts are calcualted;
proc sql;
create table sum as select a.*, b.PRICE, b.SHOUT from sum a left join rawibes.Nactpsum_epsUS b
on a.ticker=b.ticker and a.STATPERS=b.STATPERS;
quit;

*CALCULATE EARNINGS SURPRISE / FORECAST ERROR. 
THERE ARE MANY FORECASTS FOR EACH FISCAL YEAR, I WILL TAKE THE LAST FORECAST AS THE BASIS FOR CALCULATING EARNINGS SURPRISE;
*actual is actual earnings;
*MEDEST is the median of all the forecastes avaiable, which is the consensus forecasts, some researchers may use mean, but it shouldn't matter;
data sum;
set sum;
if price gt 0 then SUR=(actual-MEDEST)/price;
run;
*PICK THE LAST FORECAST HERE, BUT BEFORE EARNINGS ANNOUNCEMENT;
	*step 1 deletes cases where actual announcement date exists and statpers exists, but announcement date is  is before 
	the statper date (suspicious observations);
data sum;
set sum;
if (ANNDATS_ACT ne .) and (STATPERS ne .) and (ANNDATS_ACT le STATPERS) THEN delete; 
run;
	*step 2 assumes that If ANNDATS_ACT is missing, then I assume that the last forecast for each TICKER-FPEDATS group
	is made before the earnings announcement date, which is generally the case;
PROC SORT DATA=sum;
BY TICKER FPEDATS STATPERS;
RUN;
*SUR has the earnings surprises for each firm;
data sum;
set sum;
by TICKER FPEDATS;
if last.FPEDATS;
run;
*FPEDATS IS ESSENTIALLY THE DATADATE VARIABLE IN COMPUSTAT;
data sum;
set sum;
if sur eq . then delete;
run;

*link permno to tickers in surprise file duplicates generated;
proc sql;
create table sum as select a.*, b.permno from sum a left join rawibes.iclinc b
on a.ticker=b.ticker
where (b.score le 4) and b.permno ne .;
quit;


data dimmod.sum;
set sum;
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
