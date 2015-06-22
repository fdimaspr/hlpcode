
replace pxfye=. if pxfye <= 0 
*if price at end of fiscal year is negative then set to missing
replace shsfye=. if shsfye <= 0 
replace div=. if div < 0 
replace ta=. if  ta <= 0 
replace tl=. if tl <=0
replace rd=0 if rd==.
replace ce=. if ce==0
replace capx=0 if capx==.

