Create a state diagram hash corresp and transpose

Thanks Paul for the recent hash solution.
  Added to my Archives

 Two solutions
    1. proc corresp
    2. proc transpose
    3. Paul Dorfman (faster HAS solution)
       Paul Dorfman
       sashole@bellsouth.net
       Made one small insinificant change , added upcase because I often interface with R and Python

       if scan (upcase(vname (u)), 2, "_") = upcase(subclass) then u = 1 ;

       I was curious how much effort it takes to get the same result by "conventional"
       means (i.e. without CORRESP and TRANSPOSE). Turns out, it's not insignificant
       (and still requires an extra pass to populate the PDV with the STATE variables at compile).
       For example (it can be improved performance-wise by using another hash keyed by
       SUBCLASS for lookup and some APP to zero the STATE var
       iables out on the first encounter of ID):


  At least two other ways (not shown)
    4. proc report
    5. proc summary idgroup

github
https://tinyurl.com/y88loatt
https://github.com/rogerjdeangelis/-let-pgm-utl-create-a-state-diagram-table-hash-corresp-and-transpose-

see StackOverflow
https://tinyurl.com/yam824ul
https://stackoverflow.com/questions/53733861/in-sas-how-to-transpose-a-table-producing-a-dummy-variable-for-each-unique-value

* creating a 0/1 state table;
* supplied data is unique on id x subclass;
* also the data is sorted on id subclass;

INPUT
=====

data have;
 input id$ class subclass$ ;
 cards4;
ID1 1 1a
ID1 1 1b
ID1 1 1c
ID1 1 2a
ID2 1 1a
ID2 1 1b
ID2 1 2a
ID2 1 2b
ID2 1 3a
ID3 1 1a
ID3 1 1d
ID3 1 2a
ID3 1 3a
ID3 1 3b
;;;;
run;quit;


PROCESS
=======

ods exclude all;
ods output observed=want;
proc corresp data=have observed dim=1;
tables id, subclass;
run;quit;
ods select all;

WORK.WANT total obs=4

  LABEL    _1A    _1B    _1C    _1D    _2A    _2B    _3A    _3B    SUM

   ID1      1      1      1      0      1      0      0      0       4
   ID2      1      1      0      0      1      1      1      0       5
   ID3      1      0      0      1      1      0      1      1       5

   Sum      3      2      1      1      3      1      2      1      14


options missing='0';
proc transpose data=have out=want prefix=state_;
  by id;
  id subclass;
  var class;
run;quit;

WORK.WANT total obs=3

  ID     STATE_1A    STATE_1B    STATE_1C    STATE_2A    STATE_2B    STATE_3A    STATE_1D    STATE_3B

  ID1        1           1           1           1           0           0           0           0
  ID2        1           1           0           1           1           1           0           0
  ID3        1           0           0           1           0           1           1           1


proc sql  ;
  select unique cats ("STATE_", subclass) into :u separated by " " from have ;
quit ;

/*

%put &u;
STATE_1a STATE_1b STATE_1c STATE_1d STATE_2a STATE_2b STATE_3a STATE_3b

*/

data _null_ ;
  dcl hash h () ;
  h.defineKey  ("ID") ;
  h.defineData ("ID") ;
  do q = 1 to countw ("&u") ;
    h.defineData (scan ("&u", q)) ;
  end ;
  h.definedone () ;
  do until (z) ;
    set have end = z ;
    array u &u ;
    q = h.find() ;
    do over u ;
      if q then u = 0 ;
      put u= subclass= ;
      if scan (upcase(vname (u)), 2, "_") = upcase(subclass) then u = 1 ;
    end ;
    h.replace() ;
  end ;
  h.output (dataset:"want") ;
run ;



OUTPUT
======

WORK.WANT total obs=3

  ID     STATE_1A    STATE_1B    STATE_1C    STATE_2A    STATE_2B    STATE_3A    STATE_1D    STATE_3B

  ID1        1           1           1           1           0           0           0           0
  ID2        1           1           0           1           1           1           0           0
  ID3        1           0           0           1           0           1           1           1



