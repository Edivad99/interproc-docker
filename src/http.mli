(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * http.mli - 10/9/2000
 * HTTP protocol
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


(* Get the cannonical HTTP status message associated to a status number *)
val get_http_message : int -> string


(* MIME types *)

type mime_type =
    MimeCustom of string * string
  | MimeHTML
  | MimeCSS
  | MimeText
  | MimeGIF
  | MimePNG
  | MimeJPEG
  | MimeBinary

val string_of_mime : mime_type -> string


(* Arguments for Cache-control *)

type cache_control =
    Public
  | Private
  | PrivateCustom of string
  | NoCache
  | NoCacheCustom of string
  | NoStore
  | NoTransform
  | MustRevalidate
  | ProxyRevalidate
  | MaxAge of int
  | SMaxAge of int
  | CacheCustom of string


(* HTTP header for a HTML page *)
val http_header :
  ?o:out_channel ->
  ?nph:bool ->
  ?status:int ->
  ?mime:mime_type ->
  ?charset:string ->
  ?target:string ->
  ?cookie:(string * string * string) list ->
  ?cache:cache_control list ->
  ?length:int ->
  ?date:string ->
  ?expires:string ->
  ?location:string ->
  ?last_modified:string -> ?custom:(string * string) list -> unit -> unit


(* HTTP redirection *)
val http_redirect_header :
  ?o:out_channel ->
  ?nph:bool ->
  ?status:int ->
  ?target:string -> ?cookie:(string * string * string) list -> string -> unit


(* Send an Internal Server Error HTML page (with correct HTTP header) *)
val http_error :
  ?o:out_channel ->
  ?nph:bool -> ?status:int -> ?mailto:string -> ?custom:'a -> unit -> unit


(* Send a file by HTTP *)
val http_send_file :
  ?o:out_channel ->
  ?nph:bool ->
  ?mime:mime_type ->
  ?charset:string ->
  ?date:string -> ?expires:string -> ?last_modified:string -> string -> unit
