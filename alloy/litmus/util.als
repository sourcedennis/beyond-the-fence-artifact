module util

fun symmetric[r: univ->univ] : univ->univ { r & ~r }
fun optional[f: univ->univ] : univ->univ  { iden + f }
pred irreflexive[rel: univ->univ]         { no iden & rel }
pred acyclic[rel: univ->univ]             { irreflexive[^rel] }
fun inverse_iden[bag: univ] : bag -> bag {
 (bag -> bag) - (bag <: iden)
}
pred total[rel: univ->univ, bag: univ] {
  inverse_iden[bag] in ^rel + ^~rel
  acyclic[rel]
}

fun ident[e: univ] : univ->univ       { iden & e->e }
fun imm[rel: univ->univ] : univ->univ { rel - rel.rel }
pred transitive[rel: univ->univ]      { rel = ^rel }
pred strict_partial[rel: univ->univ] {
  irreflexive[rel]
  transitive[rel]
}

fun dom[rel : univ -> univ ] :  univ { univ.~rel }
fun codom[rel : univ -> univ]:  univ { univ.rel }
