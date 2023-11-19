(** CGI-Interface for the interproc analyzer *)

(* This file is part of the Interproc analyzer, released under GPL license.
   Please read the COPYING file packaged in the distribution.

   Copyright (C) Mathias Argoud, Ga�l Lalire, Bertrand Jeannet 2007.
*)

type option = 
  | Rational
  | Floating

val main : opt:option -> unit
