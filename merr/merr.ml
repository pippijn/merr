let output_name_function output strings =
  output_string output "let name_of_token = function\n";
  Hashtbl.iter (fun name _ ->
    output_string output "  | ";
    output_string output name;
    output_string output " _ -> \"";
    output_string output (String.escaped name);
    output_string output "\"\n";
  ) strings


let output_desc_function output strings =
  output_string output "let desc_of_token = function\n";
  Hashtbl.iter (fun name desc ->
    output_string output "  | ";
    output_string output name;
    output_string output " _ -> ";
    output_string output desc;
    output_string output "\n";
  ) strings


let output strings imports handler expected =
  let output = Io.open_out Settings.output in
  output_string output (Buffer.contents imports);
  if Buffer.length expected <> 0 then
    output_string output (Buffer.contents expected)
  else
    output_string output "\nlet expected state = []\n";

  begin match strings with
  | None -> ()
  | Some strings ->
      output_string output "\n";
      output_name_function output strings;
      output_string output "\n";
      output_desc_function output strings;
  end;

  output_string output "
let string_of_expected state token =
  let close_match lst tok =
    List.filter (fun candidate ->
      Levenshtein.distance tok candidate <= 2
    ) lst
  in
  let tok_name = name_of_token token in
  let expected =
    match expected state with
    | []  -> \"\"
    | lst ->
        match close_match lst tok_name with
        | [] -> \"; expected one of: \" ^ (String.concat \", \" lst)
        | xs -> \"; did you mean one of \" ^ (String.concat \", \" xs) ^ \"?\"
  in

  \"unexpected \" ^ (desc_of_token token) ^ expected

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

    let strings =
      match automerr with
      | None -> None
      | Some (strings, states) ->
          Buffer.add_char expected '\n';
          Automerr.codegen expected strings states;
          Some strings
    in

    output strings imports handler expected

  with
  | Failure msg ->
      print_string ("Failure: " ^ msg);
      print_newline ();
      exit 1
