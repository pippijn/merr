{
  exception Eof
}

let digit   = ['0'-'9']
let lcase   = ['a'-'z']
let ucase   = ['A'-'Z']
let ident   = lcase | ucase | digit | '_'

let term    = ucase ident*

let toktype = '<' [^'>']+ '>'

let dstring = '"'  ('\\' _ | [^ '\\' '"' ])* '"'

let ws      = [' ' '\t']

rule token = parse
  | "%token" ws* (toktype as ty)? ws+ (term as term) ws+ (dstring as str)
      { (ty, term, str) }

  | "%%"
      { raise Eof }

  | '\n'
      { Lexing.new_line lexbuf; token lexbuf }

  | _ as c
      { let {Lexing.pos_lnum; pos_cnum; pos_bol} = Lexing.lexeme_start_p lexbuf in
          failwith ("unexpected character in token list: " ^ Char.escaped c ^
                    " at " ^ (string_of_int pos_lnum) ^ ":" ^ (string_of_int (pos_cnum - pos_bol)))
      }
