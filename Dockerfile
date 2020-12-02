FROM alpine:3.11.3

WORKDIR /usr

ARG _HOME_DIR_NAME=fp-fba-failed-logins-importer-ping
ENV _HOME_DIR_NAME=${_HOME_DIR_NAME}

COPY container-files container-files/

RUN apk update && apk add --no-cache bash \
    nfs-utils \
    rpcbind \
    bc \
    wget \
    curl \
    logrotate \
    openssl \
    ca-certificates \
    coreutils \
    && mkdir -p /mnt/ping/logs \
    && tar -zxvf container-files/${_HOME_DIR_NAME}-v*.tar.gz \
    && rm -f container-files/${_HOME_DIR_NAME}-v*.tar.gz \
    && chmod 755 ${_HOME_DIR_NAME}/source/run-fba-ping-batch-events.sh \
    ${_HOME_DIR_NAME}/source/run-fba-ping-mfa-batch-events.sh \
    ${_HOME_DIR_NAME}/source/start-fba-ping-streamed-events.sh \
    container-files/start-services.sh \
    container-files/entrypoint.sh 

ENTRYPOINT ["./container-files/entrypoint.sh"]