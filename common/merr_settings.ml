type settings = {
  mutable program : string;
  mutable errors : string;
  mutable automaton : string;
  mutable tokens : string;
  mutable output : string;
  mutable merr : bool;
}

let opts = {
  program = "";
  errors = "";
  automaton = "";
  tokens = "";
  output = "-";
  merr = false;
}

let cmd =
  let open Arg in
  align [
    ("-p",		String (fun s -> opts.program <- s),	"<file> Parser program");
    ("-e",		String (fun s -> opts.errors <- s),	"<file> Error sample file");
    ("-a",		String (fun s -> opts.automaton <- s),	"<file> Menhir-generated .automaton file");
    ("-t",		String (fun s -> opts.tokens <- s),	"<file> Token-to-string file");
    ("-o",		String (fun s -> opts.output <- s),	"<file> Output file");
    ("-merr",		Unit (fun () -> opts.merr <- true),	" Output (state, token) pairs on parse error");
  ]

let () =
  let invalid_argument arg = failwith ("invalid argument: " ^ arg) in
  Arg.parse cmd invalid_argument "Usage: merr <options>\nOptions are:"

let require arg = function
  | "" -> raise (Invalid_argument (arg))
  | s -> s

let program = opts.program
let errors = opts.errors
let automaton = opts.automaton
let tokens = opts.tokens
let output = opts.output
let merr = opts.merr
