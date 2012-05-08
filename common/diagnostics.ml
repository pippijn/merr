let error msg =
  prerr_string "\n\027[1;31merror:\027[0m ";
  List.iter (Printf.fprintf stderr "%s\n") msg;
  prerr_newline ();
  raise Exit
