(** CGI-Interface for the interproc analyzer *)

(* This file is part of the Interproc analyzer, released under GPL license.
   Please read the COPYING file packaged in the distribution.

   Copyright (C) Mathias Argoud, Gaël Lalire, Bertrand Jeannet 2007.
*)

open Html
open Http
open Cgi
open Sscookie
open Date
open Options


(* ********************************************************************** *)
(* analyze *)
(* ********************************************************************** *)
let myescape_html s =
  let buf = Buffer.create 16 in
  let i = ref 0 in
  while !i < String.length s do
    if s.[!i]='<' then
      begin
        if (String.sub s (!i+1) 11)="span style=" then
          begin
            let index_end = String.index_from s (!i + 12) '>' in
            Buffer.add_string buf (String.sub s !i (index_end + 1 - !i));
            i := index_end + 1;
          end
        else if (String.sub s (!i+1) 6)="/span>" then
          begin
            Buffer.add_string buf "</span>";
            i := !i + 7;
          end
        else
          begin
            Buffer.add_string buf "&lt;";
            incr i;
          end
      end
    else
      begin
        if s.[!i]='>' then Buffer.add_string buf "&gt;"
        else if s.[!i]='&' then Buffer.add_string buf "&amp;"
        else if s.[!i]='"' then Buffer.add_string buf "&quot;"
        else Buffer.add_char buf s.[!i];
        incr i;
      end;
  done;
  Buffer.contents buf

let analyze (progtext:string) =
  let e = Date.get_date () in
  Date.add_minutes e 15;
  Html.h1 "Analysis Result";
  Html.link "javascript:history.back()" "Go back and modify";
  Printf.fprintf stdout "<span style=\"display:inline-block;margin-left:15px;\"></span>";
  Html.link ".." "Reset";

  let buffer = Buffer.create (String.length progtext) in
  let (output:Format.formatter) = Format.formatter_of_buffer buffer in
  begin try
    Options.displaytags := Options.htmltags;
    (* Parsing the program *)
    let lexbuf = Lexing.from_string progtext in
    let prog = Frontend.parse_lexbuf output lexbuf in
    (* Computing solution *)
    Frontend.analyze_and_display output prog;
    ()
  with
  | Exit -> ()
  | Failure s ->
      Html.h2 "Source";
      Html.pre progtext;
      Html.p (Html.escape_html s)
  end;

  Html.h2 "Result";
  print_string "<pre>\r\n";
  print_string (myescape_html (Buffer.contents buffer));
  Buffer.clear buffer;
  print_string "</pre>\r\n";
  Html.h2 "Source";
  Html.pre progtext;
  ()

let mainpage () =
  try
    let args = Cgi.get_cgi_args () in
    let (text,args) = match args with
      | ("file",Some "")::("filecontent",Some "")::("example",Some "none")::("text",Some text)::args->(text,args)
      | ("file",_)::("filecontent",Some text)::("example",Some "none")::("text",_)::args->(text,args)
      | ("file",_)::("filecontent",_)::("example",Some filename)::("text",_ )::args->
        let file = open_in filename in
        let buffer = Buffer.create 1024 in
        begin
          try
            while true do
              let line = input_line file in
              Buffer.add_string buffer line;
              Buffer.add_string buffer "\r\n";
            done
          with
          | End_of_file -> close_in file
        end;
        let text = Buffer.contents buffer in (text,args)
      | _ -> raise Exit
    in
    Options.iteration_guided := false;

    List.iter (begin function
    | ("abstraction",Some name) -> Options.domain := List.assoc name Options.assocnamedomain;
    | ("analysis", Some text) ->
      Options.analysis := [];
      String.iter (begin fun chr ->
        match chr with
        | 'f' -> Options.analysis := Options.Forward :: !Options.analysis
        | 'b' -> Options.analysis := Options.Backward :: !Options.analysis
        | _ -> raise (Arg.Bad ("Wrong argument `"^text^"'; option `-analysis' expects only 'f' or 'b' characters in its argument string"))
      end) text;
      Options.analysis := List.rev !Options.analysis;
      if !Options.analysis=[] then Options.analysis := [Options.Forward];
    | ("guided",Some "on") -> Options.iteration_guided := true
    | ("widening_start",Some text) -> Options.widening_start := int_of_string text;
    | ("descending",Some text) -> Options.widening_descend := int_of_string text;
    | ("debug",Some text) -> Options.debug := int_of_string text;
    | _ -> ()
  end) args;
  analyze text
  with Exit ->
    print_string "<meta http-equiv=\"refresh\" content=\"0; URL=..\"/>";
    ()

let main () =
  Cgi.set_timeout 15;

  Sscookie.clean_cookies "interprochtml";
  Http.http_header ();

  Html.html_begin
    ~lang:"en"
    ~author:"Antoine Miné, Bertrand Jeannet, Davide Albiero, Damiano Mason"
    ~desc:"\
CGI interface to the Interproc static analyzer, \
illustrating the use of the APRON Abstract Domain Library"
    "Interproc Analyzer"
  ;
  mainpage();
  Html.html_end
    ~author:"Antoine Miné, Bertrand Jeannet, Davide Albiero, Damiano Mason"
    ();
  ()

let _ = main()
