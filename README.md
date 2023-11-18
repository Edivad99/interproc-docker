Interproc
=========

About
-----
Interprocedural static analyzer for an academic imperative language with
numerical variables and procedure calls.

Required
--------
OCaml libraries
  
+ [camllib](http://gforge.inria.fr/projects/bjeannet/)
+ [fixpoint](http://gforge.inria.fr/projects/bjeannet/)


```bash
opam pin add -n git+https://github.com/jogiet/camllib.git#master
opam pin add -n git+https://github.com/jogiet/fixpoint.git#master
```

C/OCaml library

+ [apron](http://svn.cri.ensmp.fr/apron)

Installation
------------

```bash
opam pin add -n git+https://github.com/jogiet/interproc.git#master
opam depext -i interproc
```

TODOs
-----

- [x] build via dune
- [x] install via opam
- [ ] clean the remaining of the old build system
- [ ] integrate documentation via github pages
- [ ] revive old cgi scripts
- [ ] Better frontend using HTML visualizer


