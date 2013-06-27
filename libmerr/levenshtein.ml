(* Minimum of three integers. This function is deliberately
 * not polymorphic because (1) we only need to compare integers 
 * and (2) the OCaml compilers do not perform type specialisation 
 * for user-defined functions. *)
let minimum x y z =
  let min a b : int = if a < b then a else b in
  min (min x y) z
 
(* Matrix initialisation. *)
let init_matrix n m =
  let init_col = Array.init m in
  Array.init n (function
    | 0 -> init_col (function j -> j)
    | i -> init_col (function 0 -> i | _ -> 0)
  )
 
(* Computes the Levenshtein distance between two unicode strings.
 * If you want to run it faster, add the -unsafe option when
 * compiling or use Array.unsafe_* functions (but be careful
 * with these well-named unsafe features). *)
let distance_unicode x y =
  match Array.length x, Array.length y with
  | 0, n -> n
  | m, 0 -> m
  | m, n ->
     let matrix = init_matrix (m + 1) (n + 1) in
     for i = 1 to m do
       let s = matrix.(i) and t = matrix.(i - 1) in
       for j = 1 to n do
         let cost = abs (compare x.(i - 1) y.(j - 1)) in
         s.(j) <- minimum
           (t.(j) + 1)
           (s.(j - 1) + 1)
           (t.(j - 1) + cost)
       done
     done;
     matrix.(m).(n)

let to_unistring s =
  let u = ref [] in
  String.iter (fun c ->
    u := (int_of_char c) :: !u
  ) s;
  Array.of_list (List.rev !u)
 
(* This function takes two strings, convert them to unicode string (int array)
 * and then call distance_unicode, so we can compare utf8 strings. *)
let distance x y =
  distance_unicode (to_unistring x) (to_unistring y)
