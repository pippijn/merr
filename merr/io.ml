let open_in = function
  | "-" -> stdin
  | file -> open_in file

let open_out = function
  | "-" -> stdout
  | file -> open_out file
