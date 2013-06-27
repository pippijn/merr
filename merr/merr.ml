
let output imports handler expected =
  let output = Io.open_out Settings.output in
  output_string output (Buffer.contents imports);
  begin if Buffer.length expected <> 0 then
    output_string output (Buffer.contents expected)
  else
    output_string output "\nlet expected state = []\n"
  end;

  output_string output "
module Merr = Libmerr.Make (struct
  type token = Tokens.token
  type state = int

  let eof = EOF
  let expected = expected
  let string_of_token = string_of_token
end)

let string_of_expected = Merr.string_of_expected
";

  output_string output (Buffer.contents handler);
  close_out output


let () =
  try
    let imports = Buffer.create 512 in
    let handler = Buffer.create 512 in
    let expected = Buffer.create 512 in

    let automerr =
      match Settings.automaton, Settings.tokens with
      | "", "" -> None
      | "", _ -> raise (Invalid_argument ("-t does not make sense without -a"))

      | automaton, "" ->
          let states = Automerr.parse_states automaton in
          Some (Hashtbl.create 0, states)

      | automaton, tokens ->
          let strings = Automerr.parse_strings tokens in
          let states = Automerr.parse_states automaton in
          Some (strings, states)
    in

    if Settings.errors <> "" then begin
      MakeErr.process imports handler
    end;

    begin match automerr with
    | None -> ()
    | Some (strings, states) ->
        Buffer.add_char expected '\n';
        Automerr.codegen expected strings states
    end;

    output imports handler expected

  with
  | Failure msg ->
      print_string ("Failure: " ^ msg);
      print_newline ();
      exit 1
