(* OcamlHTML - A library for generating HTML page and build CGI scripts
 *
 * html.mli - 10/9/2000
 * HTML easy generation interface
 *
 * Warning: this library uses optional arguments to make life easier
 *
 * Copyright (C) 2000 Antoine Mine' (mine@di.ens.fr)
 *)

(* escape a string so it can safely appear in an URL *)
val escape_URL: string -> string

(* escape a string so it can safely appear in HTML code *)
val escape_html: string -> string

(* Emit a HTML header with meta-informations

   all attributes (style, align, ...) are automaticly HTML escaped
   URL attributes are HTML escaped but not URL escaped
   custom HTML code is not escaped
*)
val html_begin: 
    ?out:out_channel            (* destination *)
 -> ?lang:string                (* two-letter lang code string *)
 -> ?author:string              (* author meta tag *)
 -> ?desc:string                (* description meta tag *)
 -> ?keywords:string list       (* keywords list for keyword meta tag *)
 -> ?style:(string*string) list (* stylesheet (title,URL) list *)
 -> ?alternate:(string*string*string) list
                                (* alternate documents (title,lang,URL) list *)
 -> ?refresh:int                (* refresh time for refresh meta tag *)
 -> ?refresh_url:string         (* refresh URL for refresh meta tag *)
 -> ?custom:string            (* string to include unescaped in HTML header *)
 -> string                      (* title string (not escaped) *)
 -> unit

(* Emit a HTML footer with optional author name and email *)
val html_end:
    ?out:out_channel   
 -> ?author:string     
 -> ?email:string      
 -> ?custom:string     (* string to include unescaped just before the end *)
 -> unit -> unit

(* Print common HTML tags on stdout
   
   all attributes (style, align, ...) are automaticly HTML escaped
   URL are HTML escaped but not URL escaped
   HTML text within delimiters is NOT escaped unless specified
*)
    
(* useful, even if depreciated by stylesheet *)    
type align = Left | Right | Center | Middle | Top



val h1: 
    ?out:out_channel   
 -> ?align:align
 -> ?style:string      
 -> ?ref:string         (* anchor definition *)
 -> string -> unit

val h2: 
    ?out:out_channel   
 -> ?align:align
 -> ?style:string      
 -> ?ref:string         (* anchor definition *)
 -> string -> unit

val h3: 
    ?out:out_channel   
 -> ?align:align
 -> ?style:string      
 -> ?ref:string         (* anchor definition *)
 -> string -> unit

val h4: 
    ?out:out_channel   
 -> ?align:align
 -> ?style:string      
 -> ?ref:string         (* anchor definition *)
 -> string -> unit


(* Emit a linefeed *)
val br: ?out:out_channel -> unit -> unit
    
(* Emit an horizontal rule *)   
val hr: ?out:out_channel -> unit -> unit
    
(* Print 's' in the code style
   s IS escaped so you MUST NOT use the &...; codes (yeah, & is escaped too!)
*)
val pre: ?out:out_channel -> ?style:string -> string -> unit
    
(* Print 's' in the paragraph style *)
val p: ?out:out_channel -> ?style:string -> string -> unit
    
(* Emit a list *)
val ul: ?out:out_channel -> ?numbered:bool -> ?style:string 
        -> string list -> unit
    
(* build a <a href="...">...</a> string
   the url HTML escaped but not URL escaped
*)
val link: 
    ?style:string
 -> string         (* url *) 
 -> string         (* label *) 
 -> string
    

(* emit a client-side image map *)

type area = 
    Rectangle of (int*int)*(int*int)  (* top-left and bottom-right corners *)
  | Polygon   of (int*int) list       (* list of points *)
  | Circle    of (int*int)*int        (* center and radius *)

val client_image_map: 
    ?out:out_channel
 -> ?size:int*int        (* size in pixels *)
 -> string               (* name of the map, should be unique *)
 -> string               (* URL of the image *)
 -> string               (* alternative text for image-less display *)
 -> ?default_area:string*string 
        (* default (URL,alt) for non-covered area (alt is a text desciption) *)
 -> (area*string*string) list   
        (* list of areas in the image (area,URL,alt) *)
 -> unit

(* emit a server-side image map 
   uppon click, the brower will go to the URL base?x,y
*)
val server_image_map: 
    ?out:out_channel
 -> ?size:int*int        (* size in pixels *)
 -> string               (* base query URL *)
 -> string               (* URL of the image *)
 -> string               (* alternative text for image-less display *)
 -> unit

(* Emit HTML forms  

   argument name and value are HTML escaped
*)

    
(* use Get for small argument set and easy repost by bookmarking of the URL
   use Post for bigger argument set
   use Multipart if you use the file download
*)
type form_method = 
    Get            (* agruments passed URL-encoded in the URL *)
  | Post           (* arguments passed URL-encoded in stdin *)
  | Multipart      (* arguments passed in stdin as multipart MIME document *)
  | Mailto         (* send as a email *)


(* Enclose forms within form_begin / form_end *)

val form_begin: 
     ?out:out_channel 
  -> ?meth:form_method  (* method to use to pass arguments, 
                           must be Multipart for file upload *) 
  -> string             (* URL of the CGI script *)
  -> unit
    
val form_end: ?out:out_channel -> unit -> unit
    
(* one radio button 
   several radios in a radio group share the same name argument and
   have different value,
   at most one in the group can be checked,
   you get name=value telling you which one is checked
*)
val form_radio: 
    ?out:out_channel 
 -> ?checked:bool 
 -> ?label:string 
 -> string            (* name of the argument *)
 -> string            (* value of the argument *)
 -> unit

(* a radio group sharing the same name argument *)    
val form_radios:
     ?out:out_channel
  -> ?vertical:bool        (* alignment, horizontal by default *)
  -> ?checked:int          (* element checked by default *)
  -> string                (* name argument *)
  -> (string*string) list  (* (value,label) list of radio buttons *)
  -> unit

(* a text field *)
val form_text:
    ?out:out_channel 
 -> ?size:int        (* width in characters of the field displayed *)
 -> ?maxlength:int   (* max num of characters in the value *)
 -> ?default:string  (* default value of the argument *)
 -> string           (* name of the argument *)
 -> unit
    
(* same as form_text, but the characters appears as * on the screen *)
val form_password:
    ?out:out_channel 
 -> ?size:int        (* width in characters of the field displayed *)
 -> ?maxlength:int   (* max num of characters in the value *)
 -> ?default:string  (* default value of the argument *)
 -> string           (* name of the argument *)
 -> unit
    
(* local file dialog for file upload,
   you must choose the Multipart method when including this control in a form 
*)
val form_file:
    ?out:out_channel 
 -> ?size:int*int     (* width in characters of the field displayed 
                         and height (>1 => multiple file selection possible) *)
 -> ?maxlength:int    (* max num of characters in the namefile *)
 -> ?default:string   (* default namefile *)
 -> string            (* name of the argument *)
 -> unit

(* sumbit button
   you can have several sumbit buttons with different labels/names
   you get name=label as argument if both are specified
*)
val form_submit: 
    ?out:out_channel
 -> ?label:string      (* label to appear in the button *)
 -> ?name:string       (* if set, you'll get name=label as argument *)
 -> unit -> unit

(* reset button *)
val form_reset: 
    ?out:out_channel 
 -> ?label:string       (* label to appear in the button *)
 -> unit -> unit

(* you get name=data as argument when the checkbox is checked 
   (or name=on if no data is specified) 
*)    
val form_checkbox:
    ?out:out_channel 
 -> ?checked:bool     (* default state *)
 -> ?data:string      (* value of the argument, if checked; "on" by default *)
 -> ?label:string 
 -> string            (* name of the argument *)
 -> unit

(* large text zone *)
val form_textarea: 
    ?out:out_channel 
 -> ?readonly:bool    (* false by default *)
 -> ?default:string   (* default text in the control *)
 -> string            (* name of the argument *)
 -> int               (* number of rows *)
 -> int               (* number of columns *)
 -> unit

(* nothing is displayed but you get an name=value as argument *)    
val form_hidden: 
    ?out:out_channel
 -> string             (* name of the argument *)
 -> string             (* value of the argument *)
 -> unit

(* server-side image map as a graphical submit button in a form
   sumbit position as name.x=...;name.y=... on click 
*)
val form_image_map:
    ?out:out_channel 
 -> ?align:align         (* alignment for image *)
 -> ?size:int*int        (* size in pixels *)
 -> string               (* argument name *)
 -> string               (* URL of the image *)
 -> string               (* alternate text *)
 -> unit


(* hireachical popup menu
*)

type menu = 
    Option of (string option)*string*string*bool
      (* (short label, value, long label, selected by default) *)

  | Menu of string*(menu list)
      (* (label, option list) *)

val form_menu:
    ?out:out_channel  
 -> ?multiple:bool    (* multiple selection, false by default *)
 -> ?size:int         (* number of visible rows *)
 -> string            (* argument name *)
 -> menu list         (* menu content *)
 -> unit
