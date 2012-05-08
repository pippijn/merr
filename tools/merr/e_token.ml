open E_parser

let token_name = function
  | TK_UNDERSCORE -> "TK_UNDERSCORE"
  | TK_TYCON _ -> "TK_TYCON"
  | TK_STRING _ -> "TK_STRING"
  | TK_IDENTIFIER _ -> "TK_IDENTIFIER"
  | TK_EQUALS -> "TK_EQUALS"
  | TK_BAR -> "TK_BAR"
  | TK_ARROW -> "TK_ARROW"
  | KW_OPEN -> "KW_OPEN"
  | KW_LET -> "KW_LET"
  | KW_FUNCTION -> "KW_FUNCTION"
  | KW_DEFAULT -> "KW_DEFAULT"
  | KW_MODULE -> "KW_MODULE"
  | EOF -> "EOF"


let string_of_token = function
  | TK_UNDERSCORE -> "_"
  | TK_TYCON s -> s
  | TK_STRING s -> s
  | TK_IDENTIFIER s -> s
  | TK_EQUALS -> "="
  | TK_BAR -> "|"
  | TK_ARROW -> "->"
  | KW_OPEN -> "open"
  | KW_LET -> "let"
  | KW_FUNCTION -> "function"
  | KW_DEFAULT -> "default"
  | KW_MODULE -> "module"
  | EOF -> "end of input"
