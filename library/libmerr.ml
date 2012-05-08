module type Support = sig
  type token
  type state

  val eof : token
  val expected : state -> string list
  val string_of_token : token -> string
end


let close_match lst tok =
  List.filter (fun candidate ->
    Levenshtein.distance tok candidate <= 2
  ) lst


module Make(T : Support) = struct

  let string_of_expected state token =
    let tok = "\"" ^ (T.string_of_token token) ^ "\"" in

    let expected =
      match T.expected state with
      | []  -> ""
      | lst ->
          match close_match lst tok with
          | [] -> "; expected one of: " ^ (String.concat ", " lst)
          | xs -> "; did you mean one of " ^ (String.concat ", " xs) ^ "?"
    in

    let token_string =
      if token = T.eof then
        "end of file"
      else
        tok ^ " token"
    in

    "unexpected " ^ token_string ^ expected

end
