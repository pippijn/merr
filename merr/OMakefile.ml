install Program ".DEFAULT" [
  (* Target *)
  Name		"merr";

  (* Sources *)
  Modules [
    "A_ast";
    "A_errors";
    "A_lexer";
    "A_parser";
    "Automerr";
    "Colour";
    "Diagnostics";
    "E_ast";
    "E_errors";
    "E_lexer";
    "E_parser";
    "E_token";
    "E_tokens";
    "Io";
    "MakeErr";
    "Merr";
    "Settings";
    "T_lexer";
  ];

  (* Library dependencies *)
  OCamlRequires [
    "batteries";
    "merr";
    "sexplib.syntax";
  ];

  (* Camlp4 *)
  Flags [
    "a_ast.ml",		"-syntax camlp4o";
    "e_ast.ml",		"-syntax camlp4o";
    "makeErr.ml",	"-syntax camlp4o";
  ];

  Var ("RUNMERR", "merr.native -merr -e -");
]
