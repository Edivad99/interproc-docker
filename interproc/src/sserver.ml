(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * This cookie server is triggered by an url built by 
 * Sscookie.content_from_string.
 * It sends back to the content of the file, or an error message if it is
 * unavailable.
 * It is also this server's responsability to clean outdated cookies.
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)

open Http;;
open Html;;
open Cgi;;
open Date;;
open Sscookie;;

let error () =
  http_header ();
  html_begin "Sserver Error";
  h1 "Server-Side Cookie Error";
  p "The temporary document you have requested is no longer available, or is invalid. Please try again.";
  html_end ();;


let main() = 
  let dir = ref ""
  and file = ref ""
  and key = ref ""
  and ok = ref false
  in

  List.iter (function 
      ("dir",Some s) -> dir:=s
    | ("name",Some s) -> file:=s
    | ("key",Some s) -> key:=String.lowercase_ascii s
    | _ -> ())
    (get_cgi_args());
  
  try 

    (* lock... *)
    let lock = Unix.openfile (build_filename !dir "00lock") 
	[Unix.O_WRONLY;Unix.O_CREAT] 0o600
    in
    Unix.lockf lock Unix.F_LOCK 0;

    (* parse cookie *)
    let f = open_in_bin (build_filename !dir !file)
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
    
    (* if this is the one, send it *)
    if !key = !thiskey then
      begin
	let len = (in_channel_length f)-(pos_in f) in
	ok:=true;
	Printf.printf "Status: 200 OK\r\n";
	List.iter (function s -> Printf.printf "%s\r\n" s) !thisheader;
	Printf.printf "Content-length: %i\r\n" len;
	print_string "\r\n";
	let c = Bytes.create len in
	really_input f c 0 len;
	print_string (Bytes.to_string c);
      end
    else error ();

    (* ...unlock *)
	close_in f;
    Unix.lockf lock Unix.F_ULOCK 0;
    Unix.close lock;

    clean_cookies !dir; 

  with _ -> error();;


main();;
