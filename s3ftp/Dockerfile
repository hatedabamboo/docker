ARG ALPINE_VERSION=3.16

FROM alpine:$ALPINE_VERSION AS build

ARG S3FS_VERSION=v1.91

RUN apk --no-cache add \
    alpine-sdk \
    autoconf \
    automake \
    build-base \
    ca-certificates \
    curl-dev \
    fuse-dev \
    git \
    libcurl \
    libressl-dev \
    libxml2-dev \
    mailcap && \
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
    cd s3fs-fuse && \
    git checkout tags/${S3FS_VERSION} && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j && \
    make install

FROM alpine:$ALPINE_VERSION

COPY --from=build /usr/bin/s3fs /usr/bin/s3fs

ENV AWS_S3_URL=https://s3.amazonaws.com \
    AWS_S3_ACCESS_KEY_ID= \
    AWS_S3_SECRET_ACCESS_KEY= \
    AWS_S3_BUCKET= \
    AWS_S3_MOUNT=/mnt/s3fs/ \
    AWS_S3_ACL= \
    S3FS_DEBUG=0 \
    S3FS_ARGS= \
    MIN_PORT= \
    MAX_PORT= \
    ADDRESS= \
    SSL_ENABLE=YES \
    DEBUG_SSL=NO \
    TLS_CERT= \
    TLS_KEY=

RUN mkdir ${AWS_S3_MOUNT} && \
    apk --no-cache add \
    ca-certificates \                                                                                                                                                                                                                                                                                                          fuse \
    libcurl \
    libgcc \
    libstdc++ \
    libxml2 \
    mailcap \
    supervisor \
    tini \
    vsftpd

COPY entrypoint.sh /

CMD [ "/sbin/tini", "--", "/entrypoint.sh" ]
