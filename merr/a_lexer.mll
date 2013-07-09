{
  open A_parser
}


let digit   = ['0'-'9']
let lcase   = ['a'-'z']
let ucase   = ['A'-'Z']
let ident   = lcase | ucase | digit | '_'

let nterm   = lcase ident*
let term    = ucase ident*

rule token = parse
  | "accept"			{ KW_ACCEPT }
  | "on"
  | "On"			{ KW_ON }
  | "production"		{ KW_PRODUCTION }
  | "reduce"			{ KW_REDUCE }
  | "shift"			{ KW_SHIFT }
  | "state"
  | "State"			{ KW_STATE }
  | "Conflict"			{ KW_CONFLICT }
  | "to"			{ KW_TO }

  | "**"			{ TK_STARSTAR }
  | ","				{ TK_COMMA }
  | "("				{ TK_LBRACK }
  | ")"				{ TK_RBRACK }
  | ":"				{ TK_COLON }
  | "'"				{ TK_SQUOT }
  | "."				{ TK_PERIOD }
  | "["				{ TK_LSQBRACK }
  | "]"				{ TK_RSQBRACK }
  | "#"				{ TK_HASH }
  | "--"			{ TK_MINMIN }
  | "->"			{ TK_ARROW }

  | nterm as id			{ TK_NTERM id }
  | term as id			{ TK_TERM id }
  | digit+ as num		{ TK_INTEGER (int_of_string num) }

  | '\n'			{ TK_NEWLINE }
  | ' '				{ token lexbuf }

  | _ as c			{ failwith ("invalid character: " ^ Char.escaped c) }

  | eof				{ EOF }
