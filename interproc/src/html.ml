(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * html.ml - 10/9/2000
 * HTML easy generation
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)


(* Number between 0 and 15 -> char corresponding to the hexa digit
*)    
let to_hex i = 
  if i>=0  && i<=9  then Char.chr (i+Char.code '0') else
  if i>=10 && i<=15 then Char.chr (i-10+Char.code 'a') else
  raise 
    (Invalid_argument 
       "Argument must be an hexa digit between 0 and 15 in Html.to_hex")



(* To be espcape when in a URL component (RFC 2396) 
*)
let is_URL_escape = function
    '\000'..'\031' | '\127'         (* controls *)
  | '\128'..'\255'                  (* non US-ASCII *)
  | ';' | '/'| '?' | ':' | '@'| '&' (* reserved *)
  | '=' | '+' | '$' | ','
  | '<' | '>' | '#' | '%' | '"'     (* delimiters *)
  | '{' | '}' | '|' | '\\' | '^'    (* unwise *)
  | '[' | ']' | '`'
  | ' '                             (* space *)
  | '~'                             (* not sure whether this is 
				       allowed/necessary/disallowed... *)
    -> true
  | _ -> false
	
	
	
let escape_URL s =
  let buf = Buffer.create 16 in
  for i=0 to (String.length s)-1 do
    if is_URL_escape s.[i]
    then Buffer.add_string buf (Printf.sprintf "%%%c%c"
      				  (to_hex ((Char.code s.[i]) / 16))
				  (to_hex ((Char.code s.[i]) mod 16)))
    else if s.[i]=' ' then Buffer.add_char buf '+'
    else Buffer.add_char buf s.[i]
  done;
  Buffer.contents buf



let escape_html s =
  let buf = Buffer.create 16 in
  for i=0 to (String.length s)-1 do
    if s.[i]='<' then Buffer.add_string buf "&lt;" else
    if s.[i]='>' then Buffer.add_string buf "&gt;" else
    if s.[i]='&' then Buffer.add_string buf "&amp;" else
    if s.[i]='"' then Buffer.add_string buf "&quot;" else
    Buffer.add_char buf s.[i]
  done;
  Buffer.contents buf
    
    
    

(* Emit a HTML header with meta-informations

   all attributes (style, align, ...) are automaticly HTML escaped
   URL attributes are HTML escaped but not URL escaped
   custom HTML code is not escaped
*)
let html_begin 
    ?(out=stdout)     (* destination *)
    ?lang             (* two-letter lang code string *)
    ?author           (* author meta tag *)
    ?desc             (* description meta tag *)
    ?keywords         (* keywords list for keyword meta tag *)
    ?style            (* stylesheet (title,URL) list *)
    ?(alternate=[])   (* alternate documents (title,lang,URL) list *)
    ?refresh          (* refresh time for refresh meta tag *)
    ?refresh_url      (* refresh URL for refresh meta tag *)
    ?custom           (* string to include unescaped in HTML header *)
    title             (* title string (not escaped) *)
    =

  Printf.fprintf out "<!DOCTYPE html>\r\n";
  
  (match lang with  
    None   -> Printf.fprintf out "<html>\r\n"
  | Some s -> Printf.fprintf out "<html lang=\"%s\">\r\n" (escape_html s));

  Printf.fprintf out "<head><title>%s</title>\r\n" (escape_html title);
  Printf.fprintf out "<meta charset=\"UTF-8\">\r\n";
  Printf.fprintf out "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\r\n";
  
  (match refresh with  
    None   -> ()
  | Some s -> Printf.fprintf out "<meta http-equiv=\"Refresh\" content=\"%s\">\r\n"
	((string_of_int s)^(match refresh_url with None -> ""|
	  Some s -> "; URL="^s)));

  (match author with  
    None   -> ()
  | Some s -> Printf.fprintf out "<meta name=\"author\" content=\"%s\">\r\n"
	(escape_html s));
  
  (match desc with  
    None   -> ()
  | Some s -> Printf.fprintf out "<meta name=\"description\" content=\"%s\">\r\n"
	(escape_html s));
  
  (match keywords with
    None   -> ()
  | Some s -> 
      Printf.fprintf out "<meta name=\"keywords\" content=\"";
      Printf.fprintf out "\">\r\n";
      let rec toto:(string list->unit) = function 
	  []    -> () 
	| a::[] -> Printf.fprintf out "%s" (escape_html a)
	| a::b  -> Printf.fprintf out "%s," (escape_html a); toto b
      in toto s;
      Printf.fprintf out "\">\r\n");
  
  (match style with
    None   -> ()
  | Some s ->
      ignore (List.map (function (b,c) -> 
	Printf.fprintf out 
   "<link rel=\"Stylesheet\" title=\"%s\" type=\"text/css\" href=\"%s\">\r\n"
	  (escape_html b) (escape_html c)) s));
  
  ignore (List.map (function (a,b,c) -> 
    Printf.fprintf out 
      "<link rel=\"Alternate\" title=\"%s\" lang=\"%s\" hreflang=\"%s\" href=\"%s\">\r\n" 
      (escape_html a) (escape_html b) (escape_html b) (escape_html c))
	    alternate);

  (match custom with None -> () | Some s -> Printf.fprintf out "%s" s);
  
  Printf.fprintf out "</head>\r\n<body>\r\n"
    
    
(* Emit a HTML footer with optional author name and email
*)
let html_end ?(out=stdout) ?author ?email ?custom () =
  Printf.fprintf out "<br><br><hr><address>\r\n";
  (match author with None -> () | Some s -> Printf.fprintf out "%s<br>\r\n" s);
  (match email with None -> () | Some s -> Printf.fprintf out
      "<a href=\"mailto:%s\">%s</a><br>\r\n" s s);
  (match custom with None -> () | Some s -> Printf.fprintf out "%s\r\n" s);
  Printf.fprintf out "</address></body>\r\n</html>\r\n"
    
    
    
    
(* Print common HTML tags on stdout
   
   all attributes (style, align, ...) are automaticly HTML escaped
   URL are HTML escaped but not URL escaped
   HTML text within delimiters is NOT escaped unless specified
*)
type align = Left | Right | Center | Middle | Top
    
let string_of_align = function
    None        -> "" 
  | Some Left   -> " align=\"left\""
  | Some Right  -> " align=\"right\"" 
  | Some Center -> " align=\"center\""
  | Some Middle -> " align=\"middle\"" 
  | Some Top    -> " align=\"top\""
 	
let h ?(out=stdout) ?align ?style ?ref h name =
  (match ref with Some s-> Printf.fprintf out "<a name=\"%s\">" (escape_html s)|None->());
  Printf.fprintf out "<%s%s%s>%s</%s>\r\n"
    h (string_of_align align)
    (match style with None->"" | Some s->(" class=\""^(escape_html s)^"\""))
    name h;
  (match ref with Some s-> Printf.fprintf out "</a>"|None->())
    
(* Print 'name' within header <hi></hi> delimiters
*)
let h1 ?out ?align ?style ?ref name = h ?out ?align ?style ?ref "h1" name
let h2 ?out ?align ?style ?ref name = h ?out ?align ?style ?ref "h2" name
let h3 ?out ?align ?style ?ref name = h ?out ?align ?style ?ref "h3" name
let h4 ?out ?align ?style ?ref name = h ?out ?align ?style ?ref "h4" name
    
(* Emit a linefeed
*)
let br ?(out=stdout) () = Printf.fprintf out "<br>\r\n"
    
(* Emit an horizontal rule
*)   
let hr ?(out=stdout) () = Printf.fprintf out "<hr>\r\n"
    
(* Print 's' in the code style
   s IS escaped so you MUST NOT use the &...; codes (yeah, & is escaped too!)
*)
let pre ?(out=stdout) ?style s = 
  Printf.fprintf out "<pre%s>%s</pre>"
    (match style with None->"" | Some s->(" class=\""^(escape_html s)^"\""))
    (escape_html s)
    
(* Print 's' in the paragraph style
*)
let p ?(out=stdout) ?style data =
  Printf.fprintf out "<p%s>%s</p>\r\n"
    (match style with None->"" | Some s->(" class=\""^(escape_html s)^"\""))
    data
    
(* Emit a list
*)
let ul ?(out=stdout) ?(numbered=false) ?style s =
  let l = (match numbered with true->"ol" | false->"ul") in
  Printf.fprintf out "<%s%s>\r\n"
    l
    (match style with None->"" | Some s->(" class=\""^(escape_html s)^"\""));
  ignore (List.map (function a -> Printf.fprintf out "<li>%s\r\n" a) s);
  Printf.fprintf out "</%s>\r\n" l

(* build a <a href="...">...</a> string
   the URL is HTML escaped but not URL escaped
*)
let link ?(out=stdout) ?style url label =
  Printf.fprintf out
    "<a href=\"%s\"%s>%s</a>"
    (escape_html url)
    (match style with None->"" | Some s->(" class=\""^(escape_html s)^"\""))
    label;

(* emit a client-side image map 
*)

type area = 
    Rectangle of (int*int)*(int*int)  (* top-left and bottom-right corners *)
  | Polygon   of (int*int) list       (* list of points *)
  | Circle    of (int*int)*int        (* center and radius *)

let client_image_map ?(out=stdout) ?size name img alt ?default_area areas = 
  Printf.fprintf out "<map name=\"%s\">\r\n" (escape_html name);
  ignore (List.map (function
      (Rectangle ((x1,y1),(x2,y2)),url,alt) ->
	Printf.fprintf out 
     "<area shape=\"rect\" coords=\"%i,%i,%i,%i\" href=\"%s\" alt=\"%s\">\r\n"
	  x1 y1 x2 y2 (escape_html url) (escape_html alt)
    | (Circle ((x,y),r),url,alt) ->
	Printf.fprintf out 
     "<area shape=\"circle\" coords=\"%i,%i,%i\" href=\"%s\" alt=\"%s\">\r\n"
	  x y r (escape_html url) (escape_html alt)
    | (Polygon l,url,alt) ->
	Printf.fprintf out 
	  "<area shape=\"polygon\" coords=\"";
	let rec toto = function
	    [] -> ()
	  | (x,y)::[] -> Printf.fprintf out "%i,%i" x y
	  | (x,y)::l -> Printf.fprintf out "%i,%i," x y; toto l
	in toto l;
	Printf.fprintf out "\" href=\"%s\" alt=\"%s\">\r\n" 
	  (escape_html url) (escape_html alt)
	  ) areas);
  (match default_area with None->() | Some (url,alt) ->
    Printf.fprintf out "<area shape=\"default\" href=\"%s\" alt=\"%s\">\r\n"
      (escape_html url) (escape_html alt));
  Printf.fprintf out "</map>\r\n";
  Printf.fprintf out "<img src=\"%s\" alt=\"%s\" usemap=\"#%s\"%s>"
    (escape_html img) (escape_html alt) (escape_html name)
    (match size with None -> "" | Some (x,y) ->
      " width=\""^(string_of_int x)^"\" height=\""^(string_of_int y)^"\"")
  

(* emit a server-side image map
*)
let server_image_map ?(out=stdout) ?size address img alt = 
  Printf.fprintf out 
    "<a href=\"%s\"><img ismap src=\"%s\" alt=\"%s\"%s></a>\r\n" 
    (escape_html address)
    (escape_html img)
    (escape_html alt)
    (match size with None -> "" | Some (x,y) ->
      " width=\""^(string_of_int x)^"\" height=\""^(string_of_int y)^"\"")


(* Emit HTML forms
*)

type form_method = Get | Post | Multipart | Mailto


(* Enclose forms within form_begin / form_end *)

let form_begin ?(out=stdout) ?(meth=Get) address =
  Printf.fprintf out "<form action=\"%s\" method=\"%s\">\r\n"
    (match meth with
      Mailto ->(escape_html ("mailto:"^address))
    | _ -> (escape_html address) )
    (match meth with 
      Post->"post" 
    | Get ->"get"
    | Multipart -> "post\" enctype=\"multipart/form-data"
    | Mailto -> "post\" enctype=\"text/plain"
      )
    
let form_end ?(out=stdout) () =
  Printf.fprintf out "</form>\r\n"
    
(* one radio button 
*)
let form_radio ?(out=stdout) ?(checked=false) ?(label="") name data =
  Printf.fprintf out "<input type=\"radio\" name=\"%s\" value=\"%s\"%s>%s\r\n"
    (escape_html name) (escape_html data)
    (if checked then " checked" else "")
    (escape_html label)

(* group of several radio buttons
*)
let form_radios ?(out=stdout) ?(vertical=false) ?(checked=0) name options =
  let i = ref 0 in
  ignore (List.map (function (data,label) -> 
    Printf.fprintf out 
      "<input type=\"radio\" name=\"%s\" value=\"%s\"%s>%s%s\r\n"
      (escape_html name) (escape_html data)
      (if !i=checked then " checked" else "")
      (escape_html label)
      (if vertical then "" else "<br>");
    incr i) 
	    options)

    
(* text field 
*)
let form_text ?(out=stdout) ?size ?maxlength ?default name =
  Printf.fprintf out "<input type=\"text\" name=\"%s\"%s%s%s>\r\n" 
    (escape_html name)
    (match default with None -> "" | Some s ->
      " value=\""^(escape_html s)^"\"")
    (match size with None -> "" | Some s ->
      " size=\""^(string_of_int s)^"\"")
    (match maxlength with None -> "" | Some s ->
      " maxlength=\""^(string_of_int s)^"\"")

(* text field with content hidden on screen (but transmited in clear)
*)
let form_password ?(out=stdout) ?size ?maxlength ?default name =
  Printf.fprintf out "<input type=\"password\" name=\"%s\"%s%s%s>\r\n" 
    (escape_html name)
    (match default with None -> "" | Some s ->
      " value=\""^(escape_html s)^"\"")
    (match size with None -> "" | Some s ->
      " size=\""^(string_of_int s)^"\"")
    (match maxlength with None -> "" | Some s ->
      " maxlength=\""^(string_of_int s)^"\"")

(* local file open box for upload
*)
let form_file ?(out=stdout) ?size ?maxlength ?default name =
  Printf.fprintf out "<input type=\"file\" name=\"%s\"%s%s%s>\r\n" 
    (escape_html name)
    (match default with None -> "" | Some s ->
      " value=\""^(escape_html s)^"\"")
    (match size with None -> "" | Some (w,h) ->
      " size="^(string_of_int w)^","^(string_of_int h)^"")
    (match maxlength with None -> "" | Some s ->
      " maxlength=\""^(string_of_int s)^"\"")
    
(* sumbit button (you can have several with different names/labels)
*)
let form_submit ?(out=stdout) ?label ?name () =
  Printf.fprintf out "<input type=\"submit\"%s%s>\r\n" 
    (match name with None -> "" | Some s ->
      " name=\""^(escape_html s)^"\"")
    (match label with None -> "" | Some s ->
      " value=\""^(escape_html s)^"\"")

(* reset button
*)
let form_reset ?(out=stdout) ?label () =
  Printf.fprintf out "<input type=\"reset\"%s>\r\n"
    (match label with None -> "" | Some s ->
      " value=\""^(escape_html s)^"\"")

(* checkbox
*)
let form_checkbox 
    ?(out=stdout) ?(checked=false) ?(data="on") ?(label="") name =
  Printf.fprintf out 
    "<input type=\"checkbox\" name=\"%s\" value=\"%s\"%s>%s\r\n"
    (escape_html name) (escape_html data)
    (if checked then " checked" else "")
    (escape_html label)
    
(* multiline text field
*)
let form_textarea ?(out=stdout) ?(readonly=false) ?(default="") 
    name rows cols =
  Printf.fprintf out 
    "<textarea name=\"%s\" rows=\"%i\" cols=\"%i\"%s>%s</textarea>\r\n"
    (escape_html name) rows cols
    (if readonly then " readonly" else "")
    (escape_html default)
    
(* hidden and non editable
*)
let form_hidden ?(out=stdout) name data =
  Printf.fprintf out "<input type=\"hidden\" name=\"%s\" value=\"%s\">\r\n"
    (escape_html name) (escape_html data)

(* server-side image map as a graphical submit button in a form
*)
let form_image_map ?(out=stdout) ?align ?size name img alt =
  Printf.fprintf out "<input type=\"image\" name=\"%s\" src=\"%s\" alt=\"%s\"%s%s>\r\n"
    (escape_html name)
    (escape_html img)
    (escape_html alt)
    (string_of_align align)
    (match size with None -> "" | Some (x,y) ->
      " width=\""^(string_of_int x)^"\" height=\""^(string_of_int y)^"\"")

    
(* hireachical popup menu
*)

type menu = 
    Option of (string option)*string*string*bool
  | Menu of string*(menu list)

let form_menu ?(out=stdout) ?(multiple=false) ?size name m =
  Printf.fprintf out "<select name=\"%s\"%s%s>\r\n" (escape_html name)
    (if multiple then " multiple" else "")
    (match size with None->"" | Some i->
      "size=\""^(string_of_int i)^"\"");
  let rec toto = function
      Option (label,data,text,selected) ->
	Printf.fprintf out "<option value=\"%s\"%s%s>%s</option>\r\n"
	  (escape_html data) 
	  (match label with None->"" | Some s->
	    " label=\""^(escape_html s)^"\"")
	  (if selected then " selected" else "")
	  text
    | Menu (label,m) ->
	Printf.fprintf out "<optgroup label=\"%s\">\r\n" (escape_html label);
	ignore (List.map toto m);
	Printf.fprintf out "</optgroup>\r\n"
  in 
  ignore (List.map toto m);
  Printf.fprintf out "</select>\r\n"
