(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * cgi.ml - 10/9/2000
 * CGI 
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


(* CGI argument type *)
type arg = 
    NoValue                             (* no value *)
  | Scalar of string                    (* simple value *)
  | File of string*string*string*string 
                 (* file: (filename,content,mimetype,encoding) *)

type arglist = (string,arg) Hashtbl.t


(* Char corresponding to a hexa digit -> digit
*)
let from_hex c = match c with
  '0'..'9' -> Char.code c - (Char.code '0')
| 'A'..'F' -> Char.code c - (Char.code 'A') + 10
| 'a'..'f' -> Char.code c - (Char.code 'a') + 10
| _ -> raise (Invalid_argument "Invalid hexa digit in Cgi.from_hex")
      


(* Transform a QUERY_STRING toot=tata&titi=tutu&tyty... into
   a list of pair [("toto",Some "tata"),("titi",Some "tutu"),("tyty",None),...]
   both & and ; delimiters are accepted
   %xx are transformed back into their 8-bit ASCII representation
   and + is transformed into a space
*)
let parse_cgi_args p =
  let l = ref []
  and i = ref 0
  and buf = Buffer.create 16
  and field = ref ""
  and len = String.length p in
  while !i<len do
    if p.[!i]='%' then
      begin
	try
          Buffer.add_char buf (Char.chr (from_hex p.[!i+1]*16+
					   from_hex p.[!i+2]));
	with _ -> raise (Invalid_argument "Invalid %xx argument in Cgi.get_query.")
            i := !i+2
      end
    else if p.[!i]='=' then 
      begin
	field := Buffer.contents buf;
	Buffer.clear buf
      end
    else if p.[!i]='&' || p.[!i]=';' then 
      begin
	if (String.length !field=0) 
	then l := (Buffer.contents buf,None)::(!l)
	else l := (!field,Some (Buffer.contents buf))::(!l);
	field := "";
        Buffer.clear buf
      end
    else if p.[!i]='+' then Buffer.add_char buf ' '
    else if p.[!i]!=' ' && p.[!i]!='\t' then Buffer.add_char buf p.[!i];
    incr i
  done;
  List.rev (
  if Buffer.length buf=0 then !l
  else if (String.length !field=0) then (Buffer.contents buf,None)::(!l)
  else (!field,Some (Buffer.contents buf))::(!l))

	
(* Just do the opposite of parse_cgi_args
   Takes a list of pair (name:string,value:None | Some of string) and build
   the QUERY_STRING name=value&....
   Both name and value are URL escaped with + and %xx characters

   useful to build an URL to a CGI script, but dont forget to html_escape
   it before putting in a html code:
     eg:  "<a herf=\""^html_escape ("http://.../myscript"^
           (path)^"?"^(build_cgi_args [...]))^"\">"

   FIXME: & delimiter is used as it is the most common; I have heard that
   ; is better, how about this ?
*)	
let build_cgi_args p =
  let buf = Buffer.create 16 in  
  let rec toto = function
      []   -> Buffer.contents buf
    | (n,v)::b ->
	Buffer.add_string buf (Html.escape_URL n);
	(match v with
	  None -> ()
	| Some vv ->	
	    Buffer.add_char   buf '=';
	    Buffer.add_string buf (Html.escape_URL vv));
	match b with
	  [] -> Buffer.contents buf
	| _  -> Buffer.add_char buf '&'; toto b
  in toto p



(* Only informatives: send Unknown if it is unknown
*)

let get_cgi_server_software () =
  try Sys.getenv "SERVER_SOFWARE" with Not_found -> "Unknown"

let get_cgi_server_name () =
  try Sys.getenv "SERVER_NAME" with Not_found -> "Unknown"

let get_cgi_server_protocol () =
  try Sys.getenv "SERVER_PROTOCOL" with Not_found -> "Unknown"

let get_cgi_revision () =
  try Sys.getenv "GATEWAY_INTERFACE" with Not_found -> "Unknown"


(* Raises Not_found if REQUEST_METHOD is set not to GET, POST or it is unset
*)
let get_cgi_method () =
  try
    match String.uppercase_ascii (Sys.getenv "REQUEST_METHOD") with
      "GET"  -> Html.Get
    | "POST"  -> 
	(try
	  let s   = String.lowercase_ascii (Sys.getenv "CONTENT_TYPE") 
	  and ss  = "multipart/form-data" in
	  if String.length s >= String.length ss
	      && String.sub s 0 (String.length ss) = ss
	  then Html.Multipart
	  else Html.Post
      	with Not_found -> Html.Post) 
    | _ -> Html.Get
  with Not_found -> Html.Get
      
let get_cgi_query () =
  try Sys.getenv "QUERY_STRING" with Not_found -> ""

let get_cgi_path_info () =
  try Sys.getenv "PATH_INFO" with Not_found -> ""

let get_cgi_path_translated () =
  try Sys.getenv "PATH_TRANSLATED" with Not_found -> ""

let get_cgi_script_name () =
  try Sys.getenv "SCRIPT_NAME" with Not_found -> ""

(* Not reliable  *)
let get_cgi_self_url () =
  try Sys.getenv "REQUEST_URI" with Not_found -> ""

(* Try to get the hostname, if unsuccessful, get the IP
*)
let get_cgi_remote_host () =
  try 
    Sys.getenv "REMOTE_HOST" 
  with Not_found ->
    try 
      Sys.getenv "REMOTE_ADDR" 
    with Not_found -> "Unknown host"

let get_cgi_remote_port () =
  try
    Some (int_of_string (Sys.getenv "REMOTE_PORT"))
  with Not_found -> None

let get_cgi_length () =
  try
    Some (int_of_string (Sys.getenv "CONTENT_LENGTH"))
  with Not_found -> None


(* For POST method only! *)
let get_cgi_content_type () =
  try Sys.getenv "CONTENT_TYPE" with Not_found -> "Unknown"


(* Get custom header
   
   the header name is converted into a environment variable
   by uppercasing, changing - into _ and appending HTTP_
*)
let get_cgi_header s =
  let ss = "HTTP_"^s in
  let ss = String.map (fun c -> 
    if c='-' then '_'
    else Char.uppercase_ascii c
    ) ss
  in
  try
    Some (Sys.getenv ss)
  with Not_found -> None


let get_cgi_accept () = get_cgi_header "Accept"

let get_cgi_user_agent () = get_cgi_header "User-agent"


(* build the URL for a script
   by default, script name, path and arguments are those the script
   was called with
*)
let build_cgi_url ?script ?path ?args () =
  (match script with None->get_cgi_script_name () | Some s->s)^
  (match path with None->get_cgi_path_info () | Some s->s)^
  (match 
    (match args with None->get_cgi_query () | Some s->build_cgi_args s)
  with ""->"" | s->"?"^s)



(* set if mime type string is accepted 
   uses get_cgi_accept and take care of globs 
*)
let is_cgi_accept mime =
  match get_cgi_accept () with
    None -> false
  | Some s ->
      let test_accept s =
      	try
	  let i = ref 0
	  and j = ref 0 in
	  if s.[!j]='*' then 
	    begin while mime.[!i]!='/' do incr i done; incr j end
	  else
	    while mime.[!i]!='/' do
	      if mime.[!i]!=s.[!j] then raise (Invalid_argument "ha");
	      incr i; incr j
	    done;
	  if s.[!j]!='/' then raise (Invalid_argument "ha");
	  incr i; incr j;
	  if s.[!j]='*' then true
	  else 
	    begin
	      while !i<String.length mime do
	      	if mime.[!i]!=s.[!j] then raise (Invalid_argument "ha");
	      	incr i; incr j
	      done;
	      !j = String.length s
	    end
      	with Invalid_argument _ -> false
      in
      let i = ref 0 in
      let rec toto () =
      	let buf = Buffer.create 16 in
      	while !i<String.length s && (s.[!i]=' ' || s.[!i]='\t') do incr i done;
	if !i=String.length s then false
	else 
	  begin
      	    while !i<String.length s && s.[!i]!=';' && s.[!i]!=',' 
		&& s.[!i]!=' ' && s.[!i]!='\t' 
	    do Buffer.add_char buf s.[!i]; incr i done;
	    while !i<String.length s && s.[!i]!=',' do incr i done;
	    if !i<String.length s then incr i;
	    if test_accept (Buffer.contents buf) then true
	    else toto ()
	  end
      in toto ()


(* parse a string s as a header line
      token: attr1; attr2=value1; attr3="value2" (comment)\r\n
  and return
     Some (token,[(attr1,None);(attr2,Some value1);(attr3,Some value2)])
  or None if the header is \r\n

  token, attr1, attr2, attr3 and value1 are lowercased 
  but value2 is not
*) 
let parse_header s =
  try
    let l = String.length s in
    let i = ref 0 in
    let skip_blank () = 
      while !i<l && (s.[!i]=' ' || s.[!i]='\t') do incr i done;
    in
    let is_sep = function ' '|'\t'|'='|';'->true| _ ->false
    and buf = Buffer.create 16
    and ll = ref []
    in
    (* Get token *)
    skip_blank ();
    while s.[!i]!=':' do 
      Buffer.add_char buf (Char.lowercase_ascii s.[!i]); incr i 
    done;
    let head = Buffer.contents buf in Buffer.clear buf;
    incr i;
    skip_blank ();
    while !i<l do
      (* get atttribute *)
      while !i<l && not (is_sep s.[!i]) do
	if s.[!i]='(' 
	then while s.[!i]!=')' do incr i; done
	else Buffer.add_char buf (Char.lowercase_ascii s.[!i]); incr i 
      done;
      let n = Buffer.contents buf in Buffer.clear buf;
      skip_blank ();
      if !i>=l || s.[!i]=';'
      then ll := (n,None)::(!ll) (* value-less attribute *)
      else 
	begin (* get the value of the attribute *)
	  if s.[!i]!='=' then raise (Invalid_argument "=");
	  incr i;
	  skip_blank ();
	  if s.[!i]='"' (* quoted: case sensitive *)
	  then
	    begin
	      incr i;
	      while s.[!i]!='"' do 
(*
   Disable the quoting semantics of backslash it is used as a normal
   character and not a quoting mechanism by most (maybee all) browsers!

   if s.[!i]='\\' then incr i;
*)
	    	Buffer.add_char buf s.[!i]; incr i 
	      done;
    	      incr i;
	    end
	  else           (* unquoted *)
	    while !i<l && not (is_sep s.[!i]) do 
	      if s.[!i]='(' 
	      then while s.[!i]!=')' do incr i; done
	      else Buffer.add_char buf (Char.lowercase_ascii s.[!i]); 
	      incr i 
	    done;
	  skip_blank ();
	  ll := (n, Some (Buffer.contents buf))::(!ll);
	  Buffer.clear buf;
	end;
      if !i<l then
	if s.[!i]=';' then begin incr i; skip_blank() end
	else raise (Invalid_argument "")
    done;
    (String.lowercase_ascii head,List.rev !ll)
  with 
    Invalid_argument _ -> failwith ("Invalid header line \""^s^"\" in Cgi.parse_header.")
	


(* Returns the cookies the CGI script was called with in a list of pair
   (name,value)
*)
let get_cgi_cookies () =
  try 
    let (_,l) = parse_header ("Cookie:"^(Sys.getenv "HTTP_COOKIE"))
    in l
  with Not_found -> []
    


(* Returns the parsed CGI arguments as a pair list 
   (key,value) where key is a string and value is None | Some of string
   Works for POST, GET and Multipart methods

   maxlength is used to raise an exception if the set arguments exceeds
   maxlength size in bytes 
*)
let get_cgi_args ?maxlength () = 
  match get_cgi_method () with
    Html.Get -> parse_cgi_args (get_cgi_query ())

  | Html.Post -> 

      (match get_cgi_length () with
	None -> 
	  failwith "CONTENT_LENGTH environment variable unset in Cgi.cgi_get_args."
      | Some i ->
	  (match maxlength with
	    None -> ()
	  | Some j -> if i>j 
	  then failwith "Data too large in Cgi.cgi_get_args.");
	  let s = Bytes.create i in
	  set_binary_mode_in stdin true;
	  (* hugh ! this may be BIG 
	     we should read this one block at a time
	  *)
	  really_input stdin s 0 i;
	  (parse_cgi_args (Bytes.to_string s))@(parse_cgi_args (get_cgi_query ()))
	  )


  | Html.Multipart ->
      (match (get_cgi_length(), 
	      parse_header 
		("Content-type:"^get_cgi_content_type())) 
      with
	(Some size,
	 ("content-type",("multipart/form-data",None)::("boundary",Some b)::_)) 
	->
	  (match maxlength with
	    None -> ()
	  | Some j -> if size>j then 
	      failwith "Data too large in Cgi.cgi_get_args.");

	  let s = Bytes.create size in
	  set_binary_mode_in stdin true;
	  
	  (* hugh ! this may be very very BIG !!! 
	     we should really really read this one block at a time 
	     because big file upload may occur
	  *)
	  really_input stdin s 0 size;
		let s_str = Bytes.to_string s in

	  let pos = ref 0
	  and buf = Buffer.create 16
	  and bb = "\r\n--"^(String.lowercase_ascii b)in (* boundary has -- before *)
	  let max = String.length bb in
	  let read_line () =
	    while !pos<size && s_str.[!pos]!='\r' do 
	      Buffer.add_char buf s_str.[!pos]; incr pos done;
	    let ss = Buffer.contents buf in
	    Buffer.reset buf;
	    pos:= !pos+2;
	    ss
	  and read_til_boundary () =
	    try
	      while true do
	    	while !pos+max<size && Char.lowercase_ascii s_str.[!pos]!=bb.[0]
	    	do Buffer.add_char buf s_str.[!pos]; incr pos done;
	    	if !pos+max>=size then
		  begin
		    if !pos<size
		    then Buffer.add_substring buf s_str !pos (size - !pos);
		    pos:=size;
		    raise Not_found
		  end
	    	else
		  begin
		    let i = ref 1 in
		    while !i<max && Char.lowercase_ascii s_str.[!pos+ !i]=bb.[!i] 
		    do incr i done;
		    if !i=max 
		    then
		      begin
			pos:= !pos+max+2;
			if !pos<size && s_str.[!pos-2]='-' && s_str.[!pos-1]='-'
			then pos:= size; (* last boundary ended by -- *)
			raise Not_found 
		      end;
		    incr pos
		  end
	      done;
	      ""
	    with Not_found ->
	      let ss = Buffer.contents buf in
	      Buffer.reset buf;
	      ss
	  in
	  ignore (read_line ());
	  let l = ref [] in
	  let rec toto () =
	    if !pos>=size 
	    then ()
	    else
	      begin
		let rec pp () =
		  match parse_header (read_line ()) with
		    ("content-disposition",
		     [("form-data",None);
		       ("name", Some name)])
		    ->
		      while read_line () <> ""  do () done;
		     l:=(name,Some (read_til_boundary ()))::(!l)
	      
		  | ("content-disposition",
		     [("form-data",None);
		       ("name", Some name);
		       ("filename", Some filename)])
		    ->
		      while read_line () <> ""  do () done;
		      l:=("filecontent",Some (read_til_boundary ()))
		       	::(name,Some filename)::(!l)

		  | _ -> pp ()
		in 
		pp ();
		toto ()
	      end
	  in toto ();
	  (List.rev !l)@(parse_cgi_args (get_cgi_query ()))

      |	_ -> failwith "Invalid mutipart form header in Cgi.cgi_get_args."
	    )   
  | Html.Mailto -> failwith "Internal error in Cgi.cgi_get_args."


(* after the specified number of seconds, abort and display an error WEB page 
   if 0, disable the previous timeout 
*)
let set_timeout i =
  if i=0 then Sys.set_signal Sys.sigalrm Sys.Signal_ignore
  else Sys.set_signal Sys.sigalrm 
      (Sys.Signal_handle (function _ -> 
	print_string "System timeout: operation aborted !\n";
	exit 0));
  ignore (Unix.alarm i)


