(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * date.mli - 10/9/2000
 * CGI interface
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


type date = {
  mutable month : int;
  mutable day : int;
  mutable year : int;
  mutable hour : int;
  mutable min : int;
  mutable sec : int;
} 
val safe_mod : int -> int -> int * int
val days_in_year : int -> int
val days_in_month : int -> int -> int
val normalize : date -> unit
val to_string : date -> string
val get_date : unit -> date
val build_date :
  ?timezone:int -> int -> int -> int -> int -> int -> int -> date
val add_years : date -> int -> unit
val add_months : date -> int -> unit
val add_days : date -> int -> unit
val add_hours : date -> int -> unit
val add_minutes : date -> int -> unit
val add_seconds : date -> int -> unit
val from_string : string -> date
val is_before : date -> date -> bool
val is_same : date -> date -> bool
