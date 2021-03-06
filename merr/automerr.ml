open A_ast
open Sexplib.Sexp

let bprintf = Printf.bprintf

let codegen out strings states =
  bprintf out "let expected = function\n";
  List.iter (fun (State (state, productions, jumps)) ->
    let terms =
      List.fold_left (fun terms jump ->
        match jump with
        | Jump ((Terminal term), (Shift _)) ->
            term :: terms
        | _ -> terms
      ) [] jumps
    in

    let lookup table key =
      try
        Hashtbl.find table key
      with Not_found ->
        key
    in

    match terms with
    | _::_ ->
        bprintf out "  | %d -> [" state;
        List.iter (bprintf out "\"%s\";") (List.map String.escaped (List.map (lookup strings) terms));
        bprintf out "]\n"
    | _ -> ()
  ) states;
  bprintf out "  | _ -> []\n"


let open_file file = if file = "-" then stdin else open_in file


let parse_strings strings =
  let lexbuf = Lexing.from_channel (open_file strings) in
  let table = Hashtbl.create 10 in
  begin try
    while true do
      match T_lexer.token lexbuf with
      | (_, term, str) -> Hashtbl.add table term str
    done
  with T_lexer.Eof ->
    ()
  end;
  table

let debug token lexbuf =
  let tok = token lexbuf in
  let open A_parser in
  let str =
    match tok with
    | EOF -> "EOF"

    | TK_NEWLINE -> "TK_NEWLINE"
    | TK_COLON -> "TK_COLON"
    | TK_SQUOT -> "TK_SQUOT"
    | TK_PERIOD -> "TK_PERIOD"
    | TK_ARROW -> "TK_ARROW"
    | TK_LSQBRACK -> "TK_LSQBRACK"
    | TK_RSQBRACK -> "TK_RSQBRACK"
    | TK_HASH -> "TK_HASH"
    | TK_MINMIN -> "TK_MINMIN"
    | TK_LBRACK -> "TK_LBRACK"
    | TK_RBRACK -> "TK_RBRACK"
    | TK_COMMA -> "TK_COMMA"
    | TK_STARSTAR -> "TK_STARSTAR"

    | KW_ACCEPT -> "KW_ACCEPT"
    | KW_ON -> "KW_ON"
    | KW_PRODUCTION -> "KW_PRODUCTION"
    | KW_REDUCE -> "KW_REDUCE"
    | KW_SHIFT -> "KW_SHIFT"
    | KW_STATE -> "KW_STATE"
    | KW_CONFLICT -> "KW_CONFLICT"
    | KW_TO -> "KW_TO"

    | TK_NTERM s -> "TK_NTERM " ^ s
    | TK_TERM s -> "TK_TERM " ^ s
    | TK_INTEGER d -> "TK_INTEGER " ^ string_of_int d
  in
  Printf.printf "%s\n" str;
  tok


let loc_error lexbuf msg =
  let open Lexing in
  let { pos_lnum; pos_cnum; pos_bol } = Lexing.lexeme_start_p lexbuf in
  failwith (
    string_of_int pos_lnum
    ^ ":"
    ^ (string_of_int (pos_cnum - pos_bol))
    ^ ": "
    ^ msg
  )

let parse_states states =
  let lexbuf = Lexing.from_channel (open_file states) in
  try
    A_parser.parse A_lexer.token lexbuf
  with A_parser.StateError (token, state) ->
    let expected = A_errors.expected state in
    loc_error lexbuf ("expected one of: " ^ String.concat ", " expected)
