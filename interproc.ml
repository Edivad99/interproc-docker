(** Master module *)

(* This file is part of the Interproc analyzer, released under GPL license.
   Please read the COPYING file packaged in the distribution.

   Copyright (C) Mathias Argoud, Ga�l Lalire, Bertrand Jeannet 2007.
*)

open Format
open Options

let main () =
  (* Parsing the command line *)
  Arg.parse
    speclist
      (begin fun name -> Options.inputfilename := name end)
      "interproc <options> <inputfile>"
  ;
  (* Parsing the program *)
  let input = open_in !Options.inputfilename in
  let lexbuf = Lexing.from_channel input in
  lexbuf.Lexing.lex_curr_p <- { lexbuf.Lexing.lex_curr_p with
    Lexing.pos_fname = "file "^(!Options.inputfilename);
  };
  let prog = Frontend.parse_lexbuf Format.err_formatter lexbuf in
  close_in input;

  if !debug>0 then
    printf "%sProgram with its control points:%s@.%a@."
      (!Options.displaytags).precolorB (!Options.displaytags).postcolor
      (PSpl_syn.print_program
        (begin fun fmt point ->
          fprintf fmt "%s%a%s"
          (!Options.displaytags).precolorR
          PSpl_syn.print_point point
          (!Options.displaytags).postcolor
        end))
      prog
  ;

  (* Computing solution *)
  Frontend.analyze_and_display Format.std_formatter prog;
  ()

let _ = main()
