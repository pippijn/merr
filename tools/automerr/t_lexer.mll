{
  exception Eof
}


let d = ['0'-'9']
let ucase = ['A'-'Z']

let term = ucase (ucase | d | '_')*

let toktype = '<' [^'>']+ '>'

let dstring	= '"'  ('\\' _ | [^ '\\' '"' ])* '"'

let ws = [' ' '\t']

rule token = parse
  | "%token" (toktype as ty)? ws+ (term as term) ws+ (dstring as str)
  		{ (ty, term, str) }

  | "%%"	{ raise Eof }

  | '\n'	{ token lexbuf }

  | _ as c	{ failwith (Char.escaped c) }
