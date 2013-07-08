open Ocamlbuild_plugin;;

try
  let menhir = Unix.getenv "MENHIR" in
    Command.setup_virtual_command_solver "MENHIR"
      (fun () -> P(menhir))
with Not_found ->
  ();;

let host_merr =
  let try_exec_merr merr =
    match Unix.system (merr ^ " -help >/dev/null 2>&1") with
    | Unix.WEXITED 0 -> true
    | _ -> false
  in
  try
    Some (List.find try_exec_merr [Sys.getcwd () ^ "/merr.native"; "merr"])
  with Not_found ->
    None;;

dispatch begin function
  | After_rules ->

      (* These two rules allow to separate the parser into two parts: terminals
         and nonterminals. This way, the lexer does not depend on entire parser,
         but only on the module with token definitions. *)

      rule "menhir: terminals.mly -> tokens.ml, tokens.mli"
        ~deps:["%_terminals.mly"]
        ~prods:["%_tokens.ml"; "%_tokens.mli"]
        begin fun env build ->
          Seq [Cmd (S[ V"MENHIR"; A"--only-tokens"; A"-b"; Px(env "%_tokens");
                       Px(env "%_terminals.mly") ])]
        end;

      (* Pass module name as an argument:
         "merr/e_parser.mlypack":external_tokens(E_tokens) *)

      pflag ["ocaml"; "menhir"] "external_tokens" (fun ml -> S[A"--external-tokens"; A ml]);

      (* Generate the automaton description file, which merr uses as the source. *)

      flag ["ocaml"; "menhir"; "dump"] (A"--dump");

      begin
        match host_merr with
        | Some merr ->
            (* This rule generates the error parser itself. Merr has additional
               logic here to make it meta-circular. *)

            rule "merr: errors.ml.in -> errors.ml"
              ~prod:"%_errors.ml"
              ~deps:[
                "%_errors.ml.in";
                "%_terminals.mly";
                "%_parser.ml";
              ]
              begin fun env build ->
                Cmd(S[
                  P merr;
                  A"-p"; A(merr ^ " -merr -e -");
                  A"-t"; P(env "%_terminals.mly");
                  A"-a"; P(env "%_parser.automaton");
                  A"-e"; P(env "%_errors.ml.in");
                  A"-o"; Px(env "%_errors.ml");
                ]);
              end

        | None ->
            (* This rule is used for bootstrapping merr itself. *)

            rule "merr: errors.ml.empty -> errors.ml"
              ~prod:"%_errors.ml"
              ~dep:"%_errors.ml.empty"
              begin fun env build ->
                Cmd(S[
                  A"cp"; P(env "%_errors.ml.empty"); P(env "%_errors.ml")
                ])
              end
      end

  | _ -> ()
end;;
