%{
  open A_ast
%}

%token EOF

%token TK_NEWLINE
%token TK_COLON
%token TK_SQUOT
%token TK_PERIOD
%token TK_ARROW
%token TK_LSQBRACK
%token TK_RSQBRACK
%token TK_HASH
%token TK_MINMIN
%token TK_LBRACK
%token TK_RBRACK
%token TK_COMMA
%token TK_STARSTAR

%token KW_ACCEPT
%token KW_ON
%token KW_PRODUCTION
%token KW_REDUCE
%token KW_SHIFT
%token KW_STATE
%token KW_CONFLICT
%token KW_TO

%token<string> TK_NTERM
%token<string> TK_TERM
%token<int> TK_INTEGER


%start parse
%type<A_ast.states> parse

%%

parse
	: state+ EOF
		{ $1 }


state
	: KW_STATE TK_INTEGER TK_COLON TK_NEWLINE state_description TK_NEWLINE
		{ State ($2, fst $5, snd $5) }


state_description
	: production+ jump_description+ conflict?
		{ $1, $2 }


production
	: left_hand_side TK_ARROW right_hand_side TK_NEWLINE
		{ Production ($1, $3) }


left_hand_side
	: nonterminal
		{ $1 }
	| nonterminal TK_SQUOT
		{ $1 ^ "'" }


nonterminal
	: nonterminal_word
		{ $1 }
        | nonterminal_word TK_LBRACK arguments TK_RBRACK
		{ $1 ^ "(" ^ $3 ^ ")" }


arguments
	: argument
		{ $1 }
        | arguments TK_COMMA argument
		{ $1 ^ "," ^ $3 }


argument
	: nonterminal	{ $1 }
        | TK_TERM	{ $1 }


right_hand_side
	: rhs_part*
		{ $1 }


rhs_part
	: input
		{ $1 }
        | TK_LSQBRACK right_hand_side TK_RSQBRACK
		{ Bracketed ($2) }


nonterminal_word
	: TK_NTERM	{ $1 }
	| KW_ACCEPT	{ "accept" }
	| KW_ON		{ "On" }
	| KW_PRODUCTION	{ "production" }
	| KW_REDUCE	{ "reduce" }
	| KW_SHIFT	{ "shift" }
	| KW_STATE	{ "state" }
	| KW_TO		{ "to" }


input
	: nonterminal
		{ Nonterminal $1 }
        | TK_TERM
		{ Terminal $1 }
        | TK_PERIOD
		{ CurrentPosition }
        | TK_HASH
		{ EndOfInput }


jump_description
	: TK_MINMIN KW_ON input action
		{ Jump ($3, $4) }


conflict
	: TK_STARSTAR KW_CONFLICT KW_ON TK_TERM+ TK_NEWLINE
        	{ 0 }


action
	: KW_SHIFT KW_TO KW_STATE TK_INTEGER TK_NEWLINE
		{ Shift ($4) }
        | KW_REDUCE KW_PRODUCTION production
		{ Reduce ($3) }
        | KW_ACCEPT nonterminal TK_NEWLINE
		{ Accept ($2) }
