{
  open E_parser

  let string_token str =
    let add_char (chars, escape) = function
      | '\\' ->
          if escape then
            chars ^ "\\", false
          else
            chars, true

      | 'n' when escape -> chars ^ "\n", false
      | 't' when escape -> chars ^ "\t", false
      | '"' when escape -> chars ^ "\"", false

      | c -> chars ^ (BatString.of_char c), false
    in

    let chars, _ =
      BatString.fold_left add_char ("", false) (String.sub str 1 (String.length str - 2))
    in

    TK_STRING chars
}

let alnum	= ['A'-'Z' 'a'-'z' '0'-'9' '_']

let id		= ['a'-'z'] alnum *
let tycon	= ['A'-'Z'] alnum *

let dstring	= '"'  ('\\' _ | [^ '\\' '"' ])* '"'

rule token = parse
  | "let"		{ KW_LET }
  | "open"		{ KW_OPEN }
  | "function"		{ KW_FUNCTION }
  | "default"		{ KW_DEFAULT }
  | "module"		{ KW_MODULE }

  | "="			{ TK_EQUALS }
  | "|"			{ TK_BAR }
  | "->"		{ TK_ARROW }
  | "_"			{ TK_UNDERSCORE }

  | id as s		{ TK_IDENTIFIER s }
  | tycon as s		{ TK_TYCON s }

  | dstring as s	{ string_token s }

  | [' ' '\t']		{ token lexbuf }
  | '\n'		{ Lexing.new_line lexbuf; token lexbuf }

  | "(*"		{ comment lexbuf }

  | eof			{ EOF }


and comment = parse
  | "*)"		{ token lexbuf }
  | _			{ comment lexbuf }
