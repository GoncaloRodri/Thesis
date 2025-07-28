FROM gugarodri/dptor_base

WORKDIR /app

COPY tor /app/tor

RUN cd /app/tor && ./autogen.sh && \ 
./configure --disable-manpage --disable-asciidoc \
    --disable-html-manual --disable-unittests && make && make install

COPY testing/configuration /app/conf
COPY testing/scripts/swarm_entry.sh /swarm_entry.sh

ENTRYPOINT [ "/swarm_entry.sh" ]