FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apt update
RUN apt install -y \
    tzdata \
    git \
    curl \
    wget \
    bash \
    zip \
    unzip \
    jq \
    gawk \
    software-properties-common \
    python3 \
    python3-pip \
    certbot \
    python3-certbot-dns-rfc2136

RUN wget "https://releases.hashicorp.com/vault/1.18.3/vault_1.18.3_linux_amd64.zip" -O vault.zip && \
    unzip -j vault.zip "vault" -d /usr/local/bin && rm vault.zip

RUN chmod -R a+x /usr/local/bin

RUN mkdir /app
WORKDIR /app
COPY ./renew.sh /app/renew.sh
RUN chmod a+x /app/renew.sh

ENTRYPOINT /app/renew.sh
