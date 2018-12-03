#
# Dockerfile
#
# @author hanjiang.yu@bitmain.com
# @copyright btc.com
# @since 2018-12-01
#
#

FROM ubuntu:18.04
LABEL maintainer="Hanjiang Yu <hanjiang.yu@bitmain.com>"

# Install build dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bsdmainutils \
    build-essential \
    cmake \
    curl \
    git \
    libboost-all-dev \
    libconfig++-dev \
    libcurl4-openssl-dev \
    libgmp-dev \
    libgoogle-glog-dev \
    libhiredis-dev \
    libmysqlclient-dev \
    libprotobuf-dev \
    libssl-dev \
    libtool \
    libzmq3-dev \
    libzookeeper-mt-dev \
    openssl \
    pkg-config \
    protobuf-compiler \
    wget \
    yasm \
    zlib1g-dev \
    && apt-get autoremove && apt-get clean q&& rm -rf /var/lib/apt/lists/*

# Build libevent static library
#
# Notice: the release of libevent has a dead lock bug,
#         so use the code for the master branch here.
# Issue:  sserver accidental deadlock when release StratumSession
#         from consume thread
#         <https://github.com/btccom/btcpool/issues/75>
RUN cd /tmp && \
    git clone https://github.com/btccom/libevent.git --branch master-pkg-config --depth 1 && \
    cd libevent && \
    ./autogen.sh && \
    ./configure --disable-shared && \
    make && \
    make install && \
    rm -rf /tmp/*

# Build librdkafka static library
RUN cd /tmp && wget https://github.com/edenhill/librdkafka/archive/0.9.1.tar.gz && \
    [ $(sha256sum 0.9.1.tar.gz | cut -d " " -f 1) = "5ad57e0c9a4ec8121e19f13f05bacc41556489dfe8f46ff509af567fdee98d82" ] && \
    tar zxvf 0.9.1.tar.gz && cd librdkafka-0.9.1 && \
    ./configure && make && make install && rm -rf /tmp/*

# Remove dynamic libraries of librdkafka
# In this way, the constructed deb package will
# not have dependencies that not from software sources.
RUN cd /usr/local/lib && \
    find . | grep 'rdkafka' | grep '.so' | xargs rm

# Build blockchain
RUN mkdir /work && git clone https://github.com/Bitcoin-ABC/bitcoin-abc.git --branch v0.17.2 --depth 1 /work/bitcoin && \
    cd /work/bitcoin && ./autogen.sh && ./configure --with-gui=no --disable-wallet --disable-tests --disable-bench && make && \
    cd /work/bitcoin/src/secp256k1 && ./autogen.sh && ./configure --enable-module-recovery && make

# Used later by btcpool build
ENV CHAIN_TYPE=BCH
