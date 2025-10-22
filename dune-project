(lang dune 3.7)
(name interpreters_translators)
(using menhir 2.1)

(generate_opam_files true)

(source (github yourusername/interpreters-translators_bachelorThesis))
(license MIT)
(authors "Your Name <your.email@example.com>")
(maintainers "Your Name <your.email@example.com>")

(package
 (name interpreters_translators)
 (synopsis "Interpreters and Translators for LOOP, WHILE, and GOTO languages")
 (description "Bachelor thesis project implementing interpreters and translators for LOOP, WHILE, and GOTO languages as defined in the FSK lecture at LMU Munich.")
 (depends
  (ocaml (>= 4.14.0))
  dune
  (menhir (>= 20220210))
  (alcotest :with-test)
  (qcheck :with-test)))

