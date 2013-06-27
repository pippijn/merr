merr
====

Merr is a syntax error message generator for LR parsers. It passes samples of
erroneous input to the parser and produces an error message function that
produces the error message written in the sample file when the same syntax
error occurs again.  with a modified version of the menhir parser generator.
Adapting other parser generators such as ocamlyacc is probably not difficult.
The modified menhir can be found at https://github.com/pippijn/menhir.

This tool is based on ideas from Clinton Jeffery's "merr" tool at
http://unicon.sourceforge.net/merr/. It is recommended to read the technical
paper introducing the concepts.

Usage
-----

The merr program takes several inputs to produce its error message function
from.

``
  -t <terminals>
  -e <errors.ml.in>
  -a <automaton>
  -p <parser command>
  -o <output.ml>
``

### Terminal names

The terminals file contains an ocamlyacc grammar or tokens file amended with
token names. An extract of this file could look like this:

``ocaml
  %token<string>	TkIDENTIFIER	"identifier"
  %token		TkIF		"if"
  %token		TkTHEN		"then"
  %token		TkELSE		"else"
``

Merr uses these strings when producing default error messages, so that the
user doesn't see the internal names like "TkIDENTIFIER". Since menhir doesn't
understand these extra string literals after the token name, the grammar file
needs to be preprocessed before passing it to the parser generator. A simple
`sed -e 's/^\(%token[^"]*\w\+\)\s*".*"$/\1/'` will safely remove the string
literals as well as leading whitespace. This can be done in a `make` target
like `%.mly: %.mly.in`.


### Sample file

The second input expected by merr is the sample file. Merr works by passing
each sample input to the parser, which should be instrumented to print a pair
of `(state, token)` to its standard output. The `state` should be a number,
and `token` is the token type constructor name, e.g. `TkIF`. The sample file
has a similar syntax as OCaml itself. The following is an excerpt from merr's
own error description.

``ocaml
  module Tokens = Etokens
  open Etoken (* provides string_of_token *)
  open Etokens (* provides the 'token' type *)

  let message = function
    | "open" -> function
        | EOF			-> "expected module name after 'open'"
        | TkIDENTIFIER		-> "unexpected identifier `%s' after 'open'"
        			   "expected module name (capitalised)"
	| _			-> "unexpected token '%s' in handler definition"
    | "open Foo let message = function" -> function
        | EOF			-> "expected '|'-separated code fragments"
	| _			-> "unexpected token '%s' where code fragments expected"
``

One or more `open` directives are always required, and the opened modules
should provide the function `val string_of_token : token -> string` and bring
the token type constructors into scope. Merr can generate a default function
that return the strings in the terminals file, but usually you will want a
better description, using the token data. There can be any number of `open`
and `module` directives

In error messages, the `%s` part of the message is replaced by the application
of `string_of_token` with the erroneous token. So, for instance if that
function returns the `string` argument of the `TkIDENTIFIER` constructor, the
identifier can be printed in the error message.

Error messages can consist of multiple consecutive format strings. In the
error message returned from the generated error function, these are joined
with the new-line character `'\n'`.

The top-level patterns contain erroneous sample input to be passed to the
parser. The inner match dispatches over the current parser token, and a
default catch-all case can be assigned that only regards the state, not the
token. Instead of a nested match, one can also write the message directly
after the code sample. Multi-matches are also possible, if you want the same
error handling for multiple distinct code samples (and therefore states).

Merr will check that all code samples are unique in that they arrive at
different states in the parser, so that there can be no ambiguities about
which error message to display for a given error.


### Automaton file

As a secondary source of error messages, the merr program will try to find out
what tokens would allow a shift action in the parser. It will present the user
with a list of token names (from the terminals file) that the parser might
expect at the state where the error occurred. Menhir can produce an automaton
description parseable by merr, using the option `-dump`.
