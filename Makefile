
all: build

build:
	@dune build
	@ln -sf _build/default/interproc.exe interproc

install: build
	@opam install .

test: build
	@./test.sh

clean:
	@dune clean
	@rm -f interproc
	@rm -f ./examples/*.log ./examples/*/*.log *~