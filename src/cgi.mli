(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * cgi.mli - 10/9/2000
 * CGI interface
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)

open Html

(* Transform a QUERY_STRING toot=tata&titi=tutu&tyty... into
   a list of pair [("toto",Some "tata"),("titi",Some "tutu"),("tyty",None),...]
   both & and ; delimiters are accepted
   %xx are transformed back into their 8-bit ASCII representation
   and + is transformed into a space
*)
val parse_cgi_args: string -> (string*(string option)) list
	
(* Just the opposite of parse_cgi_args
   Takes a list of pair (name:string,val:None | Some of string) and build
   the QUERY_STRING name=val&....
   Both name and val are URL escaped with + and %xx characters

   useful to build an URL to a CGI script, but dont forget to html_escape
   it before putting in a html code:
     eg:  "<a herf=\""^html_escape ("http://.../myscript/"^
           (path)^"?"^(build_cgi_args [...]))^"\">"

*)	
val build_cgi_args: (string*(string option)) list -> string


(* Only informatives: send Unknown if it is unknown *)
val get_cgi_server_software: unit -> string
val get_cgi_server_name:     unit -> string
val get_cgi_server_protocol: unit -> string

(* Raises Not_found if REQUEST_METHOD is set not to GET, POST or it is unset *)
val get_cgi_method: unit -> Html.form_method

(* Should always be set (returns "" in the unlikely event it is not) *)
val get_cgi_query:           unit -> string
val get_cgi_path_info:       unit -> string
val get_cgi_path_translated: unit -> string
val get_cgi_script_name:     unit -> string

(* Not reliable  *)
val get_cgi_self_url: unit -> string

(* Try to get the hostname, if unsuccessful, get the IP *)
val get_cgi_remote_host: unit -> string

val get_cgi_remote_port: unit -> (int option)

(* Only set in Post method *)
val get_cgi_length:       unit -> (int option)
val get_cgi_content_type: unit -> string

(* Get custom HTTP header
   
   the header name is converted into a environment variable
   by uppercasing, changing - into _ and appending HTTP_
*)
val get_cgi_header: string -> (string option)

(* Examples of widespread HTTP header *)
val get_cgi_accept:     unit -> (string option)
val get_cgi_user_agent: unit -> (string option)

(* Returns true if the mime type is accepted (use get_cgi_accept) *)
val is_cgi_accept: string -> bool

(* Returns the parsed CGI arguments as a pair list 
   (key,val) where key is a string and val is None | Some of string
   Works for POST, GET and multipart POST methods

    maxlength is used to raise an exception if the set arguments exceeds
   maxlength size in bytes 
*)
val get_cgi_args: ?maxlength:int -> unit -> (string*(string option)) list


(* build the URL for a script
   by default, script name, path and arguments are those the script
   was called with
*)
val build_cgi_url: ?script:string -> ?path:string ->
                   ?args:(string*string option) list -> unit -> string

(* Returns the cookies the CGI script was called with in a list of pair
   (name,value)
*)
val get_cgi_cookies: unit -> (string*string option) list


(* after the specified number of seconds, abort and display an error WEB page 
   if 0, disable the previous timeout 
*)
val set_timeout: int -> unit

