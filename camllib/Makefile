
all: build

build:
	@dune build

doc: build
	@dune build @doc

install:
	@opam install . --working-dir

clean:
	@ rm -rf *~
	@dune clean