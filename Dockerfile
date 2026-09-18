ARG DEBIAN_VERSION=13-slim
ARG BCFTOOLS_VERSION=1.23.1
ARG BCFTOOLS_SHA256=01899a46f9420cdc1385d52fcfc84cce2806f9c996b787081a90d7dfc85eafa3
ARG HTSLIB_VERSION=1.24
ARG HTSLIB_SHA256=28a8de191381c7a97a35675ceac76fa1ea95e7b678d6a2e9d600a7874e4077de

# builder #####################################################################

FROM debian:${DEBIAN_VERSION} AS builder

ARG BCFTOOLS_VERSION
ARG BCFTOOLS_SHA256
ARG BCFTOOLS_URL="https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2"
ARG HTSLIB_VERSION
ARG HTSLIB_SHA256
ARG HTSLIB_URL="https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libbz2-dev \
        libcurl4-openssl-dev \
        libdeflate-dev \
        libgsl-dev \
        liblzma-dev \
        libncurses-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

RUN curl -fsSL --retry 3 -o "htslib.tar.bz2" "${HTSLIB_URL}" \
    && echo "${HTSLIB_SHA256}  htslib.tar.bz2" | sha256sum -c - \
    && tar -xjf htslib.tar.bz2 \
    && cd "htslib-${HTSLIB_VERSION}" \
    && ./configure \
        --prefix=/opt/bcftools \
        --enable-libcurl \
        --enable-s3 \
        --enable-gcs \
    && make -j"$(nproc)" \
    && make install

# --enable-libgsl turns on the polysomy and cnv plugins; --enable-perl-filters
# is deliberately left off, since it would pull a perl runtime into the image.
RUN curl -fsSL --retry 3 -o "bcftools.tar.bz2" "${BCFTOOLS_URL}" \
    && echo "${BCFTOOLS_SHA256}  bcftools.tar.bz2" | sha256sum -c - \
    && tar -xjf bcftools.tar.bz2 \
    && cd "bcftools-${BCFTOOLS_VERSION}" \
    && ./configure \
        --prefix=/opt/bcftools \
        --with-htslib=/opt/bcftools \
        --enable-libgsl \
        LDFLAGS="-Wl,-rpath,/opt/bcftools/lib" \
    && make -j"$(nproc)" all \
    && make install \
    && strip /opt/bcftools/bin/* /opt/bcftools/lib/libhts.so.* || true

# runtime #####################################################################

FROM debian:${DEBIAN_VERSION} AS runtime

ARG DEBIAN_VERSION
ARG BCFTOOLS_VERSION

LABEL org.opencontainers.image.title="bcftools" \
    org.opencontainers.image.description="bcftools on debian:${DEBIAN_VERSION}" \
    org.opencontainers.image.version="${BCFTOOLS_VERSION}" \
    org.opencontainers.image.source="https://github.com/samtools/bcftools" \
    org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/bcftools/bin:${PATH} \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libbz2-1.0 \
        libcurl4 \
        libdeflate0 \
        libgsl28 \
        liblzma5 \
        libncursesw6 \
        procps \
        libssl3 \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=builder /opt/bcftools /opt/bcftools

# No ENTRYPOINT: Nextflow invokes the container as `/bin/bash -c ...`, and an
# ENTRYPOINT of ["bcftools"] turns that into `bcftools /bin/bash`, which fails
# with: [main] unrecognized command '/bin/bash'
CMD ["bcftools", "--version"]
