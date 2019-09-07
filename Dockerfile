#FROM debian:jessie
FROM ubuntu:18.04

LABEL maintainer="Linagora Folks <lgs-openpaas-dev@linagora.com>"
LABEL description="Provides an image with Janus Gateway"

RUN apt-get update -y \
    && apt-get upgrade -y

RUN apt-get install -y \
    build-essential \
    libmicrohttpd-dev \
    libjansson-dev \
    libssl-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libini-config-dev \
    libcollection-dev \
    pkg-config \
    gengetopt \
    libtool \
    autotools-dev \
    automake \
    gtk-doc-tools

RUN apt-get install -y \
    sudo \
    make \
    git \
    doxygen \
    graphviz \
    libconfig-dev \
    cmake

RUN cd ~ \
    && git clone https://github.com/cisco/libsrtp.git \
    && cd libsrtp \
    && git checkout v2.2.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/sctplab/usrsctp \
    && cd usrsctp \
    && ./bootstrap \
    && ./configure --prefix=/usr \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/warmcat/libwebsockets.git \
    && cd libwebsockets \
    && git checkout v3.2.0 \
    && mkdir build \
    && cd build \
    && cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr .. \
    && make \
    && sudo make install

RUN apt-get remove -y libnice-dev \
    && cd /tmp && rm -rf libnice && git clone https://github.com/libnice/libnice.git && cd libnice \
    && git checkout 0.1.16 \
    && ./autogen.sh --disable-gtk-doc \
    && ./configure \
    && make \
    && make install

# --enable-docs
RUN cd ~ \
    && git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && git checkout v0.7.4 \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --disable-rabbitmq --disable-mqtt \
    && make CFLAGS='-std=c99' \
    && make install \
    && make configs

#RUN cp -rp ~/janus-gateway/certs /opt/janus/share/janus

COPY conf/*.cfg /opt/janus/etc/janus/

RUN apt-get install nginx -y
COPY nginx/nginx.conf /etc/nginx/nginx.conf

CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=${DOCKER_IP}