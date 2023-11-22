(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * date.ml - 10/9/2000
 * Date manipulation (according to RFC 1123)
 *
 * only dates after 1900 are supported !
 * (there are some difficulties with the date scheme for early years)
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
*)


type date = { 
    mutable month :int;
    mutable day   :int;
    mutable year  :int;
    mutable hour  :int;
    mutable min   :int;
    mutable sec   :int; 
  }
      
(* returns (a,b) such that  x=a*y+b and 0<=b<y
   (OCaml's x mod y is implementation dependant if x<0)

   IS THIS CORRECT ???
*)
let safe_mod x y =
  assert (y>0);
  if (x>=0) 
  then (x/y,x mod y)
  else ((-x-1)/y+1,(y-((-x) mod y)) mod y)

(* year>=1900 *)
let days_in_year year =
  assert(year>=1900); (* I am not sure of the rules for early years *)
  if year mod 4=0 && (year mod 100!=0 || year mod 400=0) 
  then 366 else 365

(* 1=Jan...12=Dec *)
let days_in_month month year =
  let nb = [| 31;28;31;30;31;30;31;31;30;31;30;31 |]
  and (_,nn) = (safe_mod (month-1) 12) in
  if nn=1 && days_in_year year=366 then 29 else nb.(nn)


(* ensure that 0<=sec<60, 0<=min<60, 0<=hour<24, 
               1<=day<=days_in_month month, 1<=month<=12

   the semantics of the date chosen here is
      we begin in january the 1st t.year at 00:00:00
      then we add t.sec seconds
      then we add t.min minutes
      then we add t.hour hours
      then we add t.day days
      then we add t.month months
   remark that the order of the two last operations is important:
      1996+60days+2months is not like 1996+2month+60days !!!!!

   this poses no problem for the user who only calls add_... on a valid
   date 
*)
let normalize t = 
  (* add sec seconds *)
  let (ss,s) = safe_mod t.sec 60 in
  t.sec <- s;
  t.min <- t.min + ss;
  (* add min minutes *)
  let (ss,s) = safe_mod t.min 60 in
  t.min <- s;
  t.hour <- t.hour + ss;
  (* add hour hours *)
  let (ss,s) = safe_mod t.hour 24 in
  t.hour <- s;
  t.day <- t.day + ss;
  (* add day days *)
  while (t.day<=0) do
    t.year <- t.year - 1;
    t.day <- t.day + (days_in_year t.year)
  done;
  while (t.day>days_in_year t.year) do
    t.day <- t.day - (days_in_year t.year);
    t.year <- t.year + 1;
  done;
  while (t.day<=0) do
    t.month <- t.month - 1;
    t.day <- t.day + (days_in_month t.month t.year)
  done;
  while (t.day>days_in_month t.month t.year) do
    t.day <- t.day - (days_in_month t.month t.year);
    t.month <- t.month + 1;
  done;
  (* add month months *)
  let (ss,s) = safe_mod (t.month-1) 12 in
  t.month <- s+1;
  t.year <- t.year + ss
  

(* Converts a date into a string according to RFC 1123
   day, dd mmm yyyy hh:mm:ss GMT
*)
let to_string t =

  normalize t;

  let day_of_week = ref t.day in
  for i=1 to (t.month-1) do 
    day_of_week := !day_of_week + (days_in_month i t.year) 
  done;
  if t.year>=1900 
  then
    for i=1900 to t.year-1 do
      day_of_week := !day_of_week + (days_in_year i) 
    done
  else
    for i=t.year to 1899 do
      day_of_week := !day_of_week - (days_in_year i) 
    done;
  let days = [| "Sun";"Mon";"Tue";"Wed";"Thu";"Fri";"Sat" |] in
 
  Printf.sprintf "%s, %02d %s %04d %02d:%02d:%02d GMT"
    days.(snd (safe_mod !day_of_week 7))
    t.day
    (match t.month with
      1->"Jan" | 2->"Feb" | 3->"Mar" | 4->"Apr" | 5->"May" | 6->"Jun"
    | 7->"Jul" | 8->"Aug" | 9->"Sep" | 10->"Oct" | 11-> "Nov" | 12->"Dec"
    | _ -> raise (Invalid_argument "Invalid month in Html.to_string"))
    t.year t.hour t.min t.sec


(* Get current date
*)
let get_date () =
  let t = Unix.gmtime (Unix.gettimeofday ()) in
    { sec=t.Unix.tm_sec;
      min=t.Unix.tm_min;
      hour=t.Unix.tm_hour;
      day=t.Unix.tm_mday;
      month=t.Unix.tm_mon+1;
      year=t.Unix.tm_year+1900 
    }


(* Build a new date, with optional timezone
*)
let build_date ?(timezone=0) year month day hour min sec =
  let t = { 
    sec=sec;
    min=min;
    hour=hour+timezone;
    day=day;
    month=month;
    year=year;
  } in
  normalize t;
  t


(* Manipulates date
*)
let add_years t n = t.year <- t.year+n; normalize t;;
let add_months t n = t.month <- t.month+n; normalize t;;
let add_days t n = t.day <- t.day+n; normalize t;;
let add_hours t n = t.hour <- t.hour+n; normalize t;;
let add_minutes t n = t.min <- t.min+n; normalize t;;
let add_seconds t n = t.sec <- t.sec+n; normalize t;;


(* Parse a date
   It is supposed to work only for dates obtained from to_string !
*)
let from_string s =
  try
    let day   = int_of_string (String.sub s 5 2)
    and month = String.lowercase_ascii (String.sub s 8 3)
    and year  = int_of_string (String.sub s 12 4)
    and hour  = int_of_string (String.sub s 17 2)
    and min   = int_of_string (String.sub s 20 2)
    and sec   = int_of_string (String.sub s 23 2)
    
    and months = [|"jan";"feb";"mar";"apr";"may";"jun";"jul";"aug";
		   "sep";"oct";"nov";"dec"|]
    and m = ref (-1) in

    for i=0 to 11 do
      if month=months.(i) then m:=i
    done;
    if !m= -1 then failwith "ha";

    let t = {
      sec=sec;
      min=min;
      hour=hour;
      day=day;
      month= !m;
      year=year;
    } in
    normalize t;
    t

 with Invalid_argument _ | Failure _ -> 
    raise (Invalid_argument "Invalid sate string in Date.from_string.")


(* Compare dates
*)
let is_before d1 d2 =
  d1.year<=d2.year ||
  d1.year=d2.year && 
  (d1.month<=d2.month || 
  d1.month=d2.month  &&
  (d1.day<=d2.day || 
  d1.day=d2.day  &&
  (d1.hour<=d2.hour || 
  d1.hour=d2.hour  &&
  (d1.min<=d2.min || 
  d1.min=d2.min  &&
  d1.sec<=d2.sec))))

let is_same d1 d2 =
  d1.year=d2.year &&
  d1.month=d2.month &&
  d1.day=d2.day &&
  d1.hour=d2.hour &&
  d1.min=d2.min &&
  d1.sec=d2.sec



