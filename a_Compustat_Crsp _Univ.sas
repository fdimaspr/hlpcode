/*

AUTHOR:          F. Dimas Pena Romera
START DATE:      27/12/14
LAST MODIFIED:   08/01/15	
PURPOSE: Download selected COMPUSTAT VARIABLES from Compustat annual file, merge with crsp permno using wrds linkfile and  
for selected YEARS, merge with CRSP using merge link and SELECTED LINKS, spit Compustat-Crsp Universe  

INPUT: 
	1. location of raw compustat and linkfile after rawcomp. 
	2. location of destination merged file after dimmod. 
	3. location of descriptives (number of unique gvkeys linked per year in a csv file). 
	4. beg fyear and end fyear after.
	5. variables requested from compustat annual. 

OUTPUT: 
	1. dimmod.filename = compustat-crsp merged file with requested compustat variables. 
*/


*include macros;
%include 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\Scripts\macros.sas';


*I define my local permanent libraries in which I will modify and update outputs.;
libname dimmod 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified' ;
libname fig 'C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting';

*I define libraries in which to locate and extract rawdata. all these directories will be deleted at the end of the project;

libname rawcomp 'C:\Users\penarome\Desktop\Academic\RAW DATABASES\RCompustat_2015' ;


 
* get required data from compustat annual;

*	comp.fundq (if quarterly data, change variables as well, just add q to the variable);
*	Date range-- applied to FYEAR (Fiscal Year); 
%let fyear1= 1984;  
%let fyear2= 2014;

*  Selected data items (GVKEY, DATADATE, FYEAR and FYR are automatialy included);
*I also require;
%let vars= 
			substr(CUSIP,1, 8) as CUSIP, 
			fyear, 
			conm, 
			gvkey, 
			datadate, 
			fyr, 
			seq,

				PRCC_C	AS	pxfye	,
				CSHO	AS	shsfye	,
				NI	AS	ni	,
				IBCOM	AS	ibxd	,
				SSTK	AS	cpsale	,
				PRSTKC	AS	cppur	,
				DVC	AS	div	,
				CEQ	AS	ce	,
				AT	AS	ta	,
				XINT	AS	intexp	,
				XRD	AS	rd	,
				IB	AS	ibx	,
				XINT	AS	junk	,
				TXDI	AS	isdt	,
				ITCI	AS	isitc	,
				TXT	AS	itx	,
				CSHPRI	AS	shseps	,
				PSTKRV	AS	pfdred	,
				PSTKL	AS	pfdliq	,
				PSTK	AS	pfdpar	,
				LT	AS	tl	,
				TXDITC	AS	bsdt	,
				SPI	AS	spec,	
				CAPX;



			
			

proc sql ;
       create table compa as
       select distinct &vars
       from rawcomp.R_2015_funda
       where (fyear between &fyear1 and &fyear2) & (Consol='C') & (Datafmt='STD' and Popsrc='D' and Indfmt= 'INDL')
       order by gvkey, datadate;
quit;

*get sic codes from names file; 
proc sql ;
       create table compa as
       select distinct A. *, B.SIC as dnum
       from compa A, rawcomp.R_2015_names B
       where (A.GVKEY=B.GVKEY)
       order by gvkey, datadate;
quit;

*delete duplicates by gvkey datadate (none found);
proc sort data =compa nodupkey;
by gvkey datadate;
run;


*I generate variables for the beginning and end of fiscal year (these will be used to link with crsp);
 data compa;
   		set compa;
		format endfyr begfyr date9.;
		endfyr=datadate;
   		begfyr= intnx('month',endfyr,-11,'beg');
		run;


*I get the compu crsp merge table
*My compustat-crsp universe will be defined as the set of compustat firms with a valid link in the linktable. I limit linktypes to LU LC and LS (this captures 
most compustat-crsp links without duplicated entries). Also, compustat datadate (end of fiscal year) is required to be between the valid link ranges in linktable (more
linking options in the square below);

proc sql; 
	create table compa as select distinct
	a.*, b.lpermno as permno, b.linktype, b.linkprim, b.liid, b.usedflag, b.LINKDT, b.LINKENDDT
    from compa as a, rawcomp.R_2015_ccmxpf_linktable as b
	where (a.gvkey = b.gvkey) 
    and b.linktype in ('LU', 'LC', 'LS') 
	and (b.LINKDT <= a.endfyr or b.LINKDT = .B) 
	and (a.endfyr <= b.LINKENDDT or b.LINKENDDT = .E);  
	quit; 

	/************************************************************************************************************
  * The previous condition requires the end of fiscal year to fall within the link range.                    *
  *                                                                                                          *
  * A more relaxed condition would require any part of the fiscal year to be within the link range:          *
  * (b.LINKDT <= a.endfyr or missing(b.LINKDT) = 1) and (b.LINKENDDT >= a.begfyr or missing(b.LINKENDDT)= 1);*
  * or a more strict condition would require the entire fiscal year to be within the link range :            *
  * (b.LINKDT <= a.begfyr or missing(b.LINKDT) = 1) and (a.endfyr <= b.LINKENDDT or b.LINKENDDT= .E)         *
  *                                                                                                          *
  * If these conditions are used, we suggest using the result data set from the "collapsing" procedure -     *
  * which is shown in sample program ccm_lnktable.sas - to replace crsp.ccmxpf_linktable.                    *
  ************************************************************************************************************/
 
data compa; set compa;
	if missing(permno)=0;
	run; 
*no gvkey-permno-datadate duplicates

*!!!!!!!!I notice there are still some duplicated gvkey-datadate combinations. I sort firms on gvkey datadate liid and then drop duplicates. 
	This keeps the observation with the lowest liid value.; 

proc sort data=compa out=compa nodupkey;
	by gvkey datadate permno;
	run;

proc sort data=compa out=compa;
	by gvkey datadate liid;
	run;

proc sort data=compa out=compa nodupkey;
	by gvkey datadate;
	run;

*I generate dimmod.compmerged as our Compustat Crsp Univ;
proc sort data=compa out=dimmod.compcrsp;
by gvkey datadate;
run;

*I generate a sata file dimmod.comperged as my Compustat Crsp Universe;
proc export 
data= dimmod.compcrsp
dbms=dta
outfile="C:\Users\penarome\Desktop\Academic\UNCPP2HL\modified\compcrsp.dta"
replace;
run;



*clear temporary libraries;
libname rawcomp clear;

/*just to contrast whether my compustat-crsp universe is consistent with prior literature, I look at how many distinct gvkeys I get per year
	(numbers are very reasonable - minor differences with http://gridgreed.blogspot.com.es/2012/12/on-merging-crsp-and-compustat-data.html)
	I export to csv to get tables in excel;

proc sort data=dimmod.compcrsp out=dimmod.compcrsp;
	by fyear;
	run;

proc sql;
	create table fig.yearobs
	as select a.fyear, n(gvkey) as n
	from dimmod.compcrsp a
	group by fyear;
	quit;

proc export data=fig.yearobs (where=(fyear ge 1981))
     outfile='C:\Users\penarome\Desktop\Academic\UNCPP2HL\HLWriting\yearobs.csv'
     dbms=csv
     replace;
run;


	
