
all: build

build:
	@dune build
	chmod +x _build/default/interproc.exe
	chmod +x _build/default/interprocweb.exe
	@ln -sf _build/default/interproc.exe interproc
	@ln -sf _build/default/interprocweb.exe interprocweb

install: build
	@opam install .

test: build
	@./test.sh

clean:
	@dune clean
	@rm -f interproc
	@rm -f ./examples/*.log ./examples/*/*.log *~