FROM ocaml/opam:alpine-ocaml-4.13-flambda AS build
LABEL author="Davide Albiero, Damiano Mason"

WORKDIR /home/opam

# PPL
RUN wget https://support.bugseng.com/ppl/download/ftp/releases/1.2/ppl-1.2.tar.xz && \
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

RUN sudo chown -R opam:opam /home/opam/interproc
RUN opam exec -- make all


FROM httpd:2.4.58-alpine AS server
LABEL author="Davide Albiero, Damiano Mason"

WORKDIR /usr/local/apache2
COPY --from=build /home/opam/interproc/_build/default/interprocweb.exe /usr/local/apache2/cgi-bin/interproc
COPY interproc/examples/* /usr/local/apache2/cgi-bin/examples/
COPY show_program.js /usr/local/apache2/htdocs/show_program.js
COPY index.html /usr/local/apache2/htdocs/interproc.html
RUN rm htdocs/index.html

RUN echo 'Alias "/examples/" "cgi-bin/examples/"' >> conf/httpd.conf
RUN echo '<Directory "/usr/local/apache2/cgi-bin/examples">' >> conf/httpd.conf
RUN echo "    SetHandler default-handler" >> conf/httpd.conf
RUN echo "    AllowOverride None" >> conf/httpd.conf
RUN echo "</Directory>" >> conf/httpd.conf
RUN echo "LoadModule cgid_module modules/mod_cgid.so" >> conf/httpd.conf
RUN echo "LoadModule cgid_module modules/mod_rewrite.so" >> conf/httpd.conf
RUN echo "DirectoryIndex interproc.html" >> conf/httpd.conf

CMD ["httpd-foreground"]

EXPOSE 80
