(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * http.ml - 10/9/2000
 * HTTP header generation
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


(* HTTP Status messages *)
let http_messages =
  [
  (100,"Continue");
  (101,"Switching Protocols");
  (200,"OK");
  (201,"Created");
  (202,"Accepted");
  (203,"Non-Authoritative Information");
  (204,"No Content");
  (205,"Reset Content");
  (206,"Partial Content");
  (300,"Multiple Choices");
  (301,"Moved Permanently");
  (302,"Found");
  (303,"See Other");
  (304,"Not Modified");
  (305,"Use Proxy");
  (307,"Temporary Redirect");
  (400,"Bad Request");
  (401,"Unauthorized");
  (402,"Payment Required");
  (403,"Forbidden");
  (404,"Not Found");
  (405,"Method Not Allowed");
  (406,"Not Acceptable");
  (407,"Proxy Authentication Required");
  (408,"Request Time-out");
  (409,"Conflict");
  (410,"Gone");
  (411,"Length Required");
  (412,"Precondition Failed");
  (413,"Request Entity Too Large");
  (414,"Request-URI Too Large");
  (415,"Unsupported Media Type");
  (416,"Requested range not satisfiable");
  (417,"Expectation Failed");
  (500,"Internal Server Error");
  (501,"Not Implemented");
  (502,"Bad Gateway");
  (503,"Service Unavailable");
  (504,"Gateway Time-out");
  (505,"HTTP Version not supported") ]
    
let get_http_message i =
  let rec toto = function
      [] -> raise Not_found
    | (j,s)::b -> if i=j then Printf.sprintf "%03i %s" i s else toto b
  in toto http_messages


(* Some usefull mime types
*)
type mime_type = 
    MimeCustom of string*string  (* s1/s2 *)
  | MimeHTML                     (* text/html *)
  | MimeCSS                      (* text/css *)
  | MimeText                     (* text/plain *)
  | MimeGIF                      (* image/gif *)
  | MimePNG                      (* image/png *)
  | MimeJPEG                     (* image/jpeg *)
  | MimeBinary                   (* application/octet-stream *)

let string_of_mime = function
    MimeCustom (s,t) -> s^"/"^t
  | MimeHTML -> "text/html"
  | MimeCSS -> "text/css"
  | MimeText -> "text/plain"
  | MimeGIF  -> "image/gif"
  | MimePNG  -> "image/png"
  | MimeJPEG -> "image/jpeg"
  | MimeBinary -> "application/octet-stream"

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
  | MaxAge   of int (* in seconds *)
  | SMaxAge  of int (* in seconds *)
  | CacheCustom of string

(*
type transfert_encoding =
    Bits7 
  | Bits8
  | Binary
  | QuotedPrintable
  | Base64
*)

(* HTTP header for HTML page
*)
let http_header 
    ?(o=Stdlib.stdout)       (* destination *)
    ?(nph=false)      (* Non-parsed header *)
    ?status           (* http status message number (200 OK) *)
    ?(mime=MimeHTML)  (* mime type *)
    ?charset          (* character set for content *)
(*    ?transfert        (* transfert encoding for content *) *)
    ?target           (* target window *)
    ?(cookie=[])      (* cookies list (name,value,expiration date) *)
    ?cache            (* cache control *)
    ?length           (* length of document (for non text content *)
    ?date             (* date of the document as a string (see date.ml) *)
    ?expires          (* expiration date of the document *)
    ?location         (* URL to go after expiration *)
    ?last_modified    (* last modification date *)
    ?(custom=[])      (* custom headers: list of couple "a: b" *)
    () =
  
  if (nph)
  then
    Printf.fprintf o "HTTP/1.0 %s\r\n" 
      (get_http_message (match status with None->200|Some i->i))
  else 
    (match status with None -> ()
    | Some s -> Printf.fprintf o "Status: %s\r\n" (get_http_message s));
  
  Printf.fprintf o "Content-Type: %s%s\r\n" (string_of_mime mime)
    (match charset with
      None -> ""
    | Some s -> "; charset=\""^s^"\"");
  
  (match target with None -> ()
  | Some s -> Printf.fprintf o "Window-target: %s\r\n" s);

  let rec toto = function
      [] -> ()
    | (n,v,d)::l -> Printf.fprintf o "Set-cookie: %s=\"%s\";expires=\"%s\";\r\n" 
	  n v d; toto l
  in toto cookie;

  (match location with None -> ()
  | Some s -> Printf.fprintf o "Document-location: %s\r\n" s);

  let nocache = ref false in
  (match cache with None -> ()
  | Some s -> 
      Printf.fprintf o "Cache-Control: ";
      let rec toto = function
	  [] -> ()
	| a::[] -> Printf.fprintf o "%s" (titi a)
	| a::l  -> Printf.fprintf o "%s," (titi a); toto l
      and titi = function
	  Public -> "public"
  	| Private -> "private"
  	| PrivateCustom s -> "public=\""^s^"\""
  	| NoCache -> nocache:=true; "no-cache"
  	| NoCacheCustom s -> nocache:=true; "no-cache=\""^s^"\""
  	| NoStore -> "no-store"
  	| NoTransform -> "no-transform"
  	| MustRevalidate -> "must-revalidate"
  	| ProxyRevalidate -> "proxy-revalidate"
  	| MaxAge  i -> "max-age="^(string_of_int i)
  	| SMaxAge i -> "s-maxage="^(string_of_int i)
  	| CacheCustom s -> s
      in toto s;
      Printf.fprintf o "\r\n");
  if !nocache then Printf.fprintf o "Pragma: no-cache\r\n";
  
  (match expires with None -> ()
  | Some s -> Printf.fprintf o "Expires: %s\r\n" s);
  
  (match last_modified with None -> ()
  | Some s -> Printf.fprintf o "Last-Modified: %s\r\n" s);

  (match date with None -> ()
  | Some s -> Printf.fprintf o "Date: %s\r\n" s);

  (match length with None -> ()
  | Some s -> Printf.fprintf o "Content-Length: %i\r\n" s);

  (match location with None -> ()
  | Some s -> Printf.fprintf o "Document-location: %s\r\n" s);

  let rec toto = function
      [] -> ()
    | (a,b)::l -> Printf.fprintf o "%s: %s\r\n" a b; toto l
  in toto custom;

  Printf.fprintf o "\r\n"



(* HTTP header for redirection
*)
let http_redirect_header 
    ?(o=Stdlib.stdout)       (* destination *)
    ?(nph=false)      (* Non-parsed header *)
    ?status           (* http status message number (302 Found) *)
    ?target           (* target window *)
    ?(cookie=[])      (* cookies list *)
    loc               (* URL to redirect *)
    =
  if (nph)
  then
    Printf.fprintf o "HTTP/1.0 %s\r\n" 
      (get_http_message (match status with None->302|Some i->i))
  else 
    (match status with None -> ()
    | Some s -> Printf.fprintf o "Status: %s\r\n" (get_http_message s));
  
  Printf.fprintf o "Location: %s\r\n\r" loc;

  (match target with None -> ()
  | Some s -> Printf.fprintf o "Window-target: %s\r\n" s);
  
  let rec toto = function
      [] -> ()
    | (n,v,d)::l -> Printf.fprintf o "Set-cookie: %s=\"%s\";expires=\"%s\";\r\n" 
	  n v d; toto l
  in toto cookie;

  Printf.fprintf o "\r\n"


(* Send an Internal Server Error HTML page with the correct
   HTTP header
*)
let http_error 
    ?(o=Stdlib.stdout)         (* destination *)
    ?(nph=false)        (* Non-parsed header *)
    ?(status=500)       (* the status code, default is 500 *)
    ?mailto             (* a friendly mail adress where to repport error *)
    ?custom             (* some HTML code you'd like to include *)
    ()
    =
  http_header ~o:o ~nph:nph ~status:status ();
  Printf.fprintf o "<html><head><title>Error: \"%s\"</title></head>\r\n"
    (get_http_message status);
  Printf.fprintf o "<body><h1>Error \"%s\" encountered</h1>\r\n"
    (get_http_message status);
  Printf.fprintf o "<p>Sorry, you just encountered a internal server error.</p>";
  Printf.fprintf o "<p>This may due to a misuse of this web page, but if you think this is not the case, please fell free to contact the author%s.</p>"
    (match mailto with
      None -> ""
    | Some s -> " <a href=\"mailto:"^(Html.escape_html s)^"\">"
	^(Html.escape_html s)^"</a>");
  Printf.fprintf o "</body></html>"


(* Send a file by HTTP
   Build the correct header and use the specified transfert encoding
*)
let http_send_file
    ?(o=Stdlib.stdout)         (* destination *)
    ?(nph=false)        (* Non-parsed header *)
    ?(mime=MimeBinary)  (* mime type, default is MimeBinary which is neutral *)
    ?charset            (* character set *)
(*    ?transfert          (* transfert encoding to be used *) *)
    ?date               (* date of the document as a string (see date.ml) *)
    ?expires            (* expiration date of the document *)
    ?last_modified      (* last modification date *)
    filename            (* filename *)
    =
  let f = Unix.openfile filename [Unix.O_RDONLY] 0 in
  let l = Unix.lseek f 0 Unix.SEEK_END in
  ignore (Unix.lseek f 0 Unix.SEEK_SET);
  let ff = Unix.in_channel_of_descr f in
  http_header ~o:o ~nph:nph 
    ~mime:mime ?charset:charset (* ?transfert:transfert *) ~length:l 
    ?date:date ?expires:expires ?last_modified:last_modified ();
  let s = Bytes.create l in
  really_input ff s 0 l;
  output_string o (Bytes.to_string s);
  Unix.close f


