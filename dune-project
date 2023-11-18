(lang dune 3.7)

(name interproc)
(version dev)

(using menhir 2.1)

(generate_opam_files true)

(source
 (github jogiet/interproc))

(authors "Bertrand Jeannet")

(maintainers "Josselin Giet")

(license LGPL)

(documentation https://pop-art.inrialpes.fr/people/bjeannet/bjeannet-forge/interproc/index.html)

(package
 (name interproc)
 (synopsis "Interprocedural analyzer")
 (description "Interproc is an interprocedural analyzer for a small imperative language with (recursive) procedure calls. It infers invariants on the numerical variables of analyzed program.")
 (depends ocaml dune menhirLib menhir apron fixpoint camllib)
 (tags
  ("Abstract interpretation" "interprocedural analysis")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
