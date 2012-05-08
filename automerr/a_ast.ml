open Sexplib.Conv

type statenum = int with sexp
type nonterminal = string with sexp
type terminal = string with sexp

type right_side =
  | Nonterminal of nonterminal
  | Terminal of terminal
  | CurrentPosition
  | EndOfInput
  | Bracketed of right_side list
  with sexp

type production =
  | Production of nonterminal * right_side list
  with sexp

type action =
  | Shift of statenum
  | Reduce of production
  | Accept of nonterminal
  with sexp

type jump =
  | Jump of right_side * action
  with sexp

type state =
  | State of statenum * production list * jump list
  with sexp

type states = state list with sexp
