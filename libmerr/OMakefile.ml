install Library ".DEFAULT" [
  (* Target *)
  Name		"merr";
  Description	"Merr support library";
  Version	"0.1";

  (* Sources *)
  Modules [
    "Levenshtein";
    "Libmerr";
  ];
]