let error msg =
  prerr_string (Colour.red "\nerror: ");
  List.iter (Printf.fprintf stderr "%s\n") msg;
  prerr_newline ();
  raise Exit
