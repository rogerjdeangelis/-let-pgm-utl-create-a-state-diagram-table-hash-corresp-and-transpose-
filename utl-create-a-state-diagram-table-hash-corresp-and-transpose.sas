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
       
       Added Solutions on end

    4. Mark Keintz (Array Solution)
       mkeintz@wharton.upenn.edu
    5. Marks solution with minor changes
    6. Pauls two datastep array solution
       sashole@bellsouth.net
    7. Single Pure SQL array solution (fastest in Teradata or xadata?)
    8. proc report

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




*
 _ __   _____      __ __      ____ _ _   _ ___
| '_ \ / _ \ \ /\ / / \ \ /\ / / _` | | | / __|
| | | |  __/\ V  V /   \ V  V / (_| | |_| \__ \
|_| |_|\___| \_/\_/     \_/\_/ \__,_|\__, |___/
                                     |___/
;

Eight Solutions


1. proc corresp
2. proc transpose
3. Paul Dorfman (faster HASH solution)
   sashole@bellsouth.net

Added Solutions on end

4. Mark Keintz (Array Solution)
   mkeintz@wharton.upenn.edu
5. Marks solution with minor changes
6. Pauls two datastep array solution
   sashole@bellsouth.net
7. Single Pure SQL array solution (fastest in Teradata or xadata?)
8. proc report

*__  __            _      _     _
|  \/  | __ _ _ __| | __ / |___| |_
| |\/| |/ _` | '__| |/ / | / __| __|
| |  | | (_| | |  |   <  | \__ \ |_
|_|  |_|\__,_|_|  |_|\_\ |_|___/\__|

;


data have ;
input ID :$3. class subclass :$2. @@ ;
 cards ;
ID1 1 1A   ID1 1 1B   ID1 1 1C   ID1 1 2A
ID2 1 1A   ID2 1 1B   ID2 1 2A   ID2 1 2B   ID2 1 3A
ID3 1 1A   ID3 1 1D   ID3 1 2A   ID3 1 3A   ID3 1 3B
run ;

proc sql noprint ;
  select unique cats ("STATE_", subclass), subclass
    into
    :u separated by " ", :values separated by " "
  from have;
quit ;

data want (drop=class subclass);
  do until (last.id);
    set have;
    by id;
    array st {*} &u ;
    if first.id then do _n_=1 to &sqlobs;
      st{_n_}=0;
    end;
    st{findw("&values",subclass,' ','e')}=1;
  end;
run;


*__  __            _      ____
|  \/  | __ _ _ __| | __ |  _ \ ___   __ _  ___ _ __
| |\/| |/ _` | '__| |/ / | |_) / _ \ / _` |/ _ \ '__|
| |  | | (_| | |  |   <  |  _ < (_) | (_| |  __/ |
|_|  |_|\__,_|_|  |_|\_\ |_| \_\___/ \__, |\___|_|
                                     |___/
;

I changed the 'unique' to 'max' and 'group by', generally
'distinct' and 'unique' can be much slower and have memory issues.


It might be a little faster to keep the SQL and
datastep in one address space. Especially if there is
proceedures or datasteps between the SQL and
the datastep array. You are less likely to be paged out
and if you are the address space should be contiuos
in virtual storage?
Also it is nice to keep the meta data next to the array?

However DOSUBL does need optimization, ie a smart compiler.
The black sheep 'DOSUBL' has great potential when
implemented properly. 'DOSUBL' is not a clone of
'call execute'.

Thanks for reminding me of the findw 'E' option.

Dpeeding up searches with the findw 'e' option
http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm

e or E
counts the words that are scanned until the specified word is found, instead
of determining the character position of the specified word in the string.
Fragments of a word are not counted.


data have log;
input ID :$3. class subclass :$2. @@ ;
 cards ;
ID1 1 1A   ID1 1 1B   ID1 1 1C   ID1 1 2A
ID2 1 1A   ID2 1 1B   ID2 1 2A   ID2 1 2B   ID2 1 3A
ID3 1 1A   ID3 1 1D   ID3 1 2A   ID3 1 3A   ID3 1 3B
run ;

%symdel u cc /nowarn;
Data want (drop=class subclass) log(keep=status id rename=id=last_id);

  if _n_=0 then do; %let rc=%sysfunc(dosubl('
      proc sql  ;
        select cats ("STATE_", max(subclass)), max(subclass)
          into
          :u separated by " ", :values separated by " "
        from have
        group by subclass
      ; quit;
      %let sobs=&sqlobs;
      '));
   end;

   if symgetn('sobs') = 0 then do;

       status = "State table not created";
       output want;
       output log;
       stop;

     end;

     else do;


      do until (last.id);
        set have end=dne;
        by id;
        array st {*} &u ;
        if first.id then do _n_=1 to &sqlobs;
          st{_n_}=0;
        end;
        st{findw("&values",subclass,' ','e')}=1;

        if last.id then output want;

      end;
        if dne then do;
          status = "State table created    ";
          output log;
        end;

   end;
run;quit;

OUTPUT
------

Up to 40 obs from LOG total obs=1

Obs          STATUS         LAST_ID

 1     State table created    ID3


*____             _
|  _ \ __ _ _   _| |   __ _ _ __ _ __ __ _ _   _
| |_) / _` | | | | |  / _` | '__| '__/ _` | | | |
|  __/ (_| | |_| | | | (_| | |  | | | (_| | |_| |
|_|   \__,_|\__,_|_|  \__,_|_|  |_|  \__,_|\__, |
                                           |___/
;

data have log;
input ID :$3. class subclass :$2. @@ ;
 cards ;
ID1 1 1A   ID1 1 1B   ID1 1 1C   ID1 1 2A
ID2 1 1A   ID2 1 1B   ID2 1 2A   ID2 1 2B   ID2 1 3A
ID3 1 1A   ID3 1 1D   ID3 1 2A   ID3 1 3A   ID3 1 3B
run ;


* get meta data without ssql;
data _null_ ;
  set have end = z ;
  array mm $32767 mid mst (2 * "") ;
  if not findw (mid, id) then mid = catx (" ", mid, ID) ;
  if not findw (mst, cats ("STATE_", subclass)) then mst = catx (" ", mst, cats ("STATE_", subclass)) ;
  if z ;
  call symputx ("id", mid) ;
  call symputx ("st", mst) ;
run ;

* nice fast minimal code data step solution;
/* process */
data want (keep = ID state_:) ;
  set have end = z ;
  array tt [%sysfunc (countw ("&id")), %sysfunc (countw ("&st"))] _temporary_ ;
  tt [findw ("&id", strip (ID), "", "E"), findw ("&st", catx ("_", "STATE", subclass), "", "E")] = 1 ;
  array st &st ;
  if z then do _n_ = 1 to dim (tt, 1) ;
    ID = scan ("&id", _n_) ;
    do _i_ = 1 to dim (tt, 2) ;
      st = ^^ tt [_n_, _i_] ;
    end ;
    output ;
  end ;


*          _
 ___  __ _| |   __ _ _ __ _ __ __ _ _   _
/ __|/ _` | |  / _` | '__| '__/ _` | | | |
\__ \ (_| | | | (_| | |  | | | (_| | |_| |
|___/\__, |_|  \__,_|_|  |_|  \__,_|\__, |
        |_|                         |___/
;

Data want (drop=class subclass) log(keep=status id rename=id=last_id);

  if _n_=0 then do; %let rc=%sysfunc(dosubl('
      proc sql noprint ;
        select cats ("STATE_", max(subclass)), max(subclass)
          into
          :u separated by " ", :values separated by " "
        from have
        group by subclass
      ; quit;
      %let sobs=&sqlobs;
      '));
   end;


      proc sql  ;
        select max(subclass)  into :cls1-
        from have
        group by subclass
      ; quit;
      %let clsn=&sqlobs;


 proc datasets lib=work;
   delete want;
 run;quit;

 %symdel clsn cls1 / nowarn;

 proc sql;
    select
       max(subclass)
    into
       :cls1-
    from
        have
    group
        by subclass;

    %let clsn=&sqlobs;

    create
       table want as

    select
       id
      ,%do_over(cls,phrase=case when max((subclass)="?")=1 then 1 else 0 end as state_?,between=comma)
    from
       have
    group
       by id
;quit;


*                          _
 _ __ ___ _ __   ___  _ __| |_
| '__/ _ \ '_ \ / _ \| '__| __|
| | |  __/ |_) | (_) | |  | |_
|_|  \___| .__/ \___/|_|   \__|
         |_|
;

options missing='0';
proc report data=have nowd missing out=want(drop=_break_)
  /* always in alpha order */
  rename=(
      _c2_ = state_1A
      _c3_ = state_1B
      _c4_ = state_1C
      _c5_ = state_1D
      _c6_ = state_2A
      _c7_ = state_2B
      _c8_ = state_3A
      _c9_ = state_3B));
cols id subclass, (class);
define id / group;
define subclass / across;
define class/ sum;
run;quit;
options missing='.';









