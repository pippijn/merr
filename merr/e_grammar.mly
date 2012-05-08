%{
  open E_ast

  let message_of_case = function FollowCase (_, msg) -> msg
  let cases_of_fragment = function CodeFragment (_, cases) -> cases
%}

%start parse
%type<E_ast.handler> parse

%%

parse
	: module_import+ KW_LET TK_IDENTIFIER TK_EQUALS KW_FUNCTION code_fragments EOF
		{ Handler ($1, $3, List.rev $6) }


module_import
	: KW_OPEN TK_TYCON
        	{ ModuleOpen ($2) }
	| KW_MODULE TK_TYCON TK_EQUALS TK_TYCON
        	{ ModuleAlias ($2, $4) }


code_fragments
	: code_fragment
		{ List.rev $1 }
        | code_fragments code_fragment
		{ List.rev $2 @ $1 }


code_fragment
	: TK_BAR TK_STRING TK_ARROW KW_FUNCTION follow_cases default_case
		{ [CodeFragment ($2, List.rev ($6 :: $5))] }
        | TK_BAR TK_STRING TK_ARROW message
		{ [CodeFragment ($2, [FollowCase ("_", $4)])] }
        | TK_BAR TK_STRING code_fragment
		{ CodeFragment ($2, cases_of_fragment (List.hd $3)) :: $3 }


follow_cases
	:
		{ [] }
        | follow_cases follow_case
		{ List.rev $2 @ $1 }


follow_case
	: TK_BAR TK_TYCON TK_ARROW message
		{ [FollowCase ($2 ^ " _", $4)] }
        | TK_BAR TK_TYCON follow_case
		{ FollowCase ($2 ^ " _", message_of_case (List.hd $3)) :: $3 }

default_case
	: TK_BAR TK_UNDERSCORE TK_ARROW message
		{ FollowCase ("_", $4) }


message
	: string_list
        	{ Message (String.concat "\n" (List.rev $1)) }
	| KW_DEFAULT
        	{ DefaultMessage }


string_list
	: TK_STRING
        	{ [$1] }
        | string_list TK_STRING
        	{ $2 :: $1 }
