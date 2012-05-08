open Sexplib.Conv
open Sexplib.Sexp

type message =
  | Message of string
  | DefaultMessage
  with sexp

type case =
  FollowCase of string * message
  with sexp

type fragment =
  CodeFragment of string * case list
  with sexp

type import =
  | ModuleOpen of string
  | ModuleAlias of string * string
  with sexp

type handler =
  | Handler of (*imports*)import list * (*func*)string * (*fragments*)fragment list
  with sexp
