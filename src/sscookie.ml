(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * sscookie.ml - 10/20/2000
 * Server side cookie, temporary file manipulation and
 * emulation of persistent connection to be used in CGI scripts.
 * It makes use of the sserver.ml program to send back cookies.
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)



(* Build a new random string 
   It is composed of n alphanumeric uppercase symbols (n*5 bits)
*)
let build_upper_string n =
  let ch = [|'A';'B';'C';'D';'E';'F';'G';'H';'I';'J';'K';'L';'M';
	     'N';'O';'P';'Q';'R';'S';'T';'U';'V';'W';'X';'Y';'Z';
             '1';'2';'3';'4';'5';'6' |]
  and s = Bytes.to_string (Bytes.create n)
  in
  Random.self_init ();
  String.map (fun c ->
    ch.(((Random.bits ()) lsr 5) land 31))
  s


(* Build a filename for temporary storage
   All files are in the SSCOOKIE subdirectory of the system temporary directory
*)
let build_filename dir name =
  Filename.concat 
    (Filename.concat 
       (Filename.concat
	  (Filename.dirname (Filename.temp_file "" "")) 
	  "SSCOOKIE") dir) name


(* Clean the cookie directory *)
let clean_cookies dir = 
  try 
    (* lock... *)
    let lock = Unix.openfile (build_filename dir "00lock") 
	[Unix.O_WRONLY;Unix.O_CREAT] 0o600
    in
    Unix.lockf lock Unix.F_LOCK 0;

    (* parse cookies and delete outdated ones *)
    let d = Unix.opendir (build_filename dir "") in
    (try while true do
      let name = Unix.readdir d in
      if name.[0]<>'0' && name.[0]<>'.' then 
	begin
	  let f = open_in_bin (build_filename dir name)
	  and fin = ref false 
	  and thiskey = ref ""
	  and thisexpires = ref None 
	  and thisheader = ref [] in
	  while not !fin do
	    (* parse headers *)
	    let s = input_line f in
	    let i = ref 0
	    and l = String.length s
	    and head = Buffer.create 16
	    and contents = Buffer.create 16 in
	    let skip_blank () = 
	      while !i<l && (s.[!i]=' ' || s.[!i]='\t') do incr i done;
	    in
	    skip_blank();
	    if !i=l || s.[!i]='\r' then fin:=true
	    else
	      begin
		while !i<l && s.[!i]!='\r' && s.[!i]!=':' do 
		  Buffer.add_char head (Char.lowercase_ascii s.[!i]); incr i 
		done;
		if !i<l && s.[!i]=':'  then
		  begin 
		    incr i; skip_blank ();
		    while !i<l && s.[!i]!='\r' do 
		      Buffer.add_char contents (Char.lowercase_ascii s.[!i]); incr i 
		    done;
		  end;
	      end;
	    match Buffer.contents head with
	      "expires" -> thisexpires:=Some (Buffer.contents contents)
	    | "key" -> thiskey:=(Buffer.contents contents)
	    | "file" -> ()
	    | _ -> thisheader:=(Buffer.contents head^": "^
				Buffer.contents contents)::(!thisheader)
	  done;

          (* clean if outdated *)
	  let clean = ref false in
	  (match !thisexpires with
	    None -> clean:=true
	  | Some s -> clean:=(Date.is_before 
				(Date.from_string s)
				(Date.get_date())) );
	  if !clean then Unix.unlink (build_filename dir name);

	end
    done with End_of_file -> ());
    Unix.closedir d;

    (* ...unlock *)
    Unix.lockf lock Unix.F_ULOCK 0;
    Unix.close lock;

  with _ -> ()




(* Create a new cookie and return a out_channel where to write its contents,
   together with an url where to gget back the cookie
*)
let create_cookie
    ?(mime=Http.MimeHTML)  (* mime type *)
    ?charset               (* character set *)
    ?date             (* date of the document as a string (see date.ml) *)
    ?expires          (* expiration date of the document *)
    dir =
  let rdate =
    (match date with
      None -> Date.to_string (Date.get_date()) | Some s -> s)
  and rexpires =
    (match expires with
      None -> let d = Date.get_date() in Date.add_minutes d 15; Date.to_string d
    | Some s -> s)
  and filename = build_upper_string 8
  and key = build_upper_string 120
  in

  (* force creation of the temp directory *)
  (try Unix.mkdir (build_filename "" "") 0o777  with Unix.Unix_error _ -> ());
  (try Unix.mkdir (build_filename dir "") 0o777 with Unix.Unix_error _ -> ());

  (* clean outdated cookies *)
  clean_cookies dir;
    
  (* lock... *)
  let lock = Unix.openfile (build_filename dir "00lock") 
      [Unix.O_WRONLY;Unix.O_CREAT] 0o644
  in
  Unix.lockf lock Unix.F_LOCK 0;

  (* put the readme file *)
  let readme = open_out_gen [Open_wronly;Open_binary;Open_creat;Open_trunc]
      0o644 (build_filename dir "00readme")
  in
  output_string readme "This directory contains server-side cookies.\nCookies are created when an OCaml program makes a call to the create_cookie function of the OCamlHTML library.\nThe cookie is retrieved using the CGI cookie server sserver shipped with the OCamlHTML library (using an URL returned by create_cookie).\nIt is also sserver's responsibility to clean outdated cookies.\n\nYou may safely destroy this directory.\n";
  close_out readme;

  (* create the temp file *)
  let o = open_out_gen [Open_wronly;Open_binary;Open_creat;Open_trunc]
      0o600  (build_filename dir filename)
  in
  
  (* headers *)
  Printf.fprintf o "Key: %s\r\n" key;
  Printf.fprintf o "Content-type: %s\r\n" (Http.string_of_mime mime);
  Printf.fprintf o "Date: %s\r\n" rdate;
  Printf.fprintf o "Expires: %s\r\n" rexpires;
  (match charset with None->()|Some s->Printf.fprintf o "Charset: %s\r\n" s);
  Printf.fprintf o "\r\n";
  flush o;
  
  (* ...unlock *)
  Unix.lockf lock Unix.F_ULOCK 0;
  Unix.close lock;
  
  (* build URL *)
  (o,"sserver?dir="^dir^"&name="^filename^"&key="^key)
				      


