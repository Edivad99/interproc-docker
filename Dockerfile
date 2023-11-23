FROM ocaml/opam:alpine-ocaml-4.13-flambda AS build
LABEL author="Davide Albiero"
LABEL author="Damiano Mason"

WORKDIR /home/opam

# PPL
RUN wget https://www.bugseng.com/external/ppl/download/ftp/releases/1.2/ppl-1.2.tar.xz && \
  tar xfv ppl-1.2.tar.xz

RUN sudo apk add m4 gmp-dev perl mpfr-dev --no-cache

RUN cd ppl-1.2 && \
  ./configure

RUN cd ppl-1.2 && \
  sudo make -j$(nproc)

RUN cd ppl-1.2 && \
  sudo make install && \
  make -j$(nproc) installcheck

RUN opam install conf-ppl
RUN opam install apron

COPY camllib /home/opam/camllib
COPY fixpoint /home/opam/fixpoint
COPY interproc /home/opam/interproc

RUN opam pin add camllib ./camllib
RUN opam pin add fixpoint ./fixpoint
RUN opam pin add interproc ./interproc

WORKDIR /home/opam/interproc

RUN opam depext -i interproc

RUN eval $(opam env) && \
  sudo make all


FROM httpd:2.4.58-alpine AS server
LABEL author="Davide Albiero"
LABEL author="Damiano Mason"

WORKDIR /usr/local/apache2
COPY --from=build /home/opam/interproc/_build/default/interprocweb.exe /usr/local/apache2/cgi-bin/interprocweb.exe
COPY interproc/examples/* /usr/local/apache2/cgi-bin/examples/
COPY index.html /usr/local/apache2/htdocs/index.html

CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"

EXPOSE 80
