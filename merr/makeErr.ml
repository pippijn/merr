open E_ast
open Sexplib.Conv
open Sexplib.Sexp

exception Fatal of string

let state_token_pair code =
  let input, output = Unix.open_process (Settings.program ^ " 2>&1") in
  output_string output code;
  close_out output;

  let error = input_line input in
  ignore (Unix.close_process (input, output));
  error


let error pair =
  let open Genlex in

  let parse_error = parser
    [< 'Kwd "("; 'Int state; 'Kwd ","; 'Ident token; 'Kwd ")" >] -> (state, token)
  in

  let lexer = make_lexer ["("; ","; ")"] in
  let tokens = lexer (Stream.of_string pair) in

  try
    parse_error tokens
  with Stream.Failure ->
    failwith pair



let get_states fragments =
  let rec get states a b = function
    | CodeFragment (code, _) :: tl ->
        let b = b + 1 in
        Printf.fprintf stderr "\rretrieving error states... %d%%" (b * 100 / a);
        flush stderr;
        begin try
          get (error (state_token_pair code) :: states) a b tl
        with Failure msg ->
          raise (Fatal (msg ^ " while parsing " ^ code))
        end
    | [] -> states
  in

  let states = get [] (List.length fragments) 0 fragments in
  prerr_newline ();
  List.rev states


let string_of_message = function
  | Message s -> s
  | DefaultMessage -> "default"


let message_table states fragments =
  let table = Hashtbl.create (List.length fragments) in

  List.iter2 (fun (state, _) (CodeFragment (code, cases)) ->
    List.iter (fun (FollowCase (token, message)) ->
      try
        let conflict = Hashtbl.find table (state, token) in
        Diagnostics.error [
          "in code sample \"" ^ code ^ "\"";
          "    message \"" ^ (string_of_message message) ^ "\"";
          "  conflicts with";
          "    message \"" ^ (string_of_message conflict) ^ "\"";
        ]
      with Not_found ->
        Hashtbl.add table (state, token) message
    ) cases
  ) states fragments;

  let cases =
    Hashtbl.fold (fun (state, token) message cases ->
      (state, token, message) :: cases
    ) table []
  in

  List.sort (fun (s1, t1, _) (s2, t2, _) ->
    let c1 = compare s1 s2 in
    if c1 = 0 then
      compare t1 t2
    else
      c1
  ) cases


let codegen out imports func table =
  Printf.bprintf out "\nlet %s state token =\n  match state, token with\n" func;
  List.iter (fun (state, token, msg) ->
    match msg with
    | Message msg ->
        let has_arg = BatString.exists msg "%s" in

        let token =
          if token = "_" && has_arg then
            "arg"
          else if has_arg then
            "(" ^ token ^ " as arg)"
          else
            token
        in

        let msg =
          let msg = String.escaped msg in
          if has_arg then
            snd (BatString.replace msg "%s" "\" ^ (string_of_token arg) ^ \"")
          else
            msg
        in

        Printf.bprintf out "  | %d, %s -> \"%s\"\n" state token msg
    | DefaultMessage -> ()
  ) table;
  Buffer.add_string out "  | state, token -> Printf.sprintf \"(%d) %s\" state (string_of_expected state token)\n"


let process import_out handler_out =
  let errors = Settings.errors in
  let input = Io.open_in errors in
  let lexbuf = 
    let open Lexing in
    let lexbuf = from_channel input in
    lexbuf.lex_curr_p <- {
      lexbuf.lex_curr_p with
      pos_fname = (if errors = "-" then "<stdin>" else errors);
    };
    lexbuf
  in

  try

    match E_parser.parse E_lexer.token lexbuf with
    | Handler (imports, func, fragments) ->
        let states = get_states fragments in
        let table = message_table states fragments in

        List.iter (function
          | ModuleOpen name ->
              Printf.bprintf import_out "open %s\n" name
          | ModuleAlias (alias, name) ->
              Printf.bprintf import_out "module %s = %s\n" alias name
        ) imports;

        codegen handler_out imports func table

  with E_parser.StateError (token, state) as e ->

    begin if Settings.merr then
      Printf.fprintf stderr "(%d, %s)\n" state "token"
    else
      let string_of_position pos =
        let open Lexing in
        Printf.sprintf "%s:%d:%d"
          (Colour.white pos.pos_fname)
          pos.pos_lnum
          (pos.pos_cnum - pos.pos_bol + 1)
      in

      let pos = Lexing.lexeme_start_p lexbuf in

      match BatString.nsplit (E_errors.message state token) "\n" with
      | msg :: notes ->
          let strpos = string_of_position pos in
          Printf.fprintf stderr "%s: %s %s\n" strpos (Colour.red "error:") (Colour.white msg);
          List.iter (
            Printf.fprintf stderr "%s: %s %s\n" strpos (Colour.grey "note:")
          ) notes;

          let open Lexing in

          let bol = pos.pos_bol - lexbuf.lex_abs_pos in
          let eol = String.index_from lexbuf.lex_buffer bol '\n' in

          let column = pos.pos_cnum - pos.pos_bol in
          Printf.fprintf stderr "%s\n%*s%s\n"
            (String.sub lexbuf.lex_buffer bol (eol - bol))
            column "" (Colour.green "^")
      | [] -> failwith "no error message"
    end;

    raise e
