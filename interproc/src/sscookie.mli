(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * sscookie.mli - 10/9/2000
 * Server side cookie, temporary file manipulation and
 * emulation of persistent connection to be used in CGI scripts.
 * It makes use of the sserver.ml program to send back cookies.
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


(* Builds a filename for temporary storage *)
val build_filename : string -> string -> string

(* Creates a new cookie in a specified directory 
   returns an out-channel where you should write the contents of the cookie
   and the URL that is used to get back the cookie (it calls the sserver
   CGI server program)
*)
val create_cookie :
  ?mime:Http.mime_type ->
  ?charset:string ->
  ?date:string -> ?expires:string -> string -> out_channel * string

(* Call this from your client from time to time to remove outdated coockies
   on your application's cookie directory
*)
val clean_cookies : string -> unit

