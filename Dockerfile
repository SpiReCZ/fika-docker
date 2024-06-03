#FROM ubuntu:latest AS builder
# https://github.com/git-lfs/git-lfs/issues/5749
FROM bitnami/git:latest AS builder

RUN apt update && \
    apt install -yq curl git git-lfs dos2unix unzip

# Install Node Version Manager and NodeJS
ARG NODE=20.11.1
RUN git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm
RUN \. $HOME/.nvm/nvm.sh && \
    nvm install $NODE

WORKDIR /src

ARG SPT="changeme"
ARG SPT_URL=https://dev.sp-tarkov.com/SPT/Server.git/
## Clone the SPT AKI repo
RUN git clone $SPT_URL .

WORKDIR /src/project

## Check out and git-lfs
RUN git checkout tags/$SPT && \
    git-lfs fetch --all && \
    git-lfs pull

## Install npm dependencies and run build
RUN \. $HOME/.nvm/nvm.sh && \
    npm install && \
    npm run build:release -- --arch=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo x64) --platform=linux && \
    mv build/ /opt/srv/

ARG FIKA="changeme"
WORKDIR /fika
RUN curl -L https://github.com/project-fika/Fika-Server/releases/download/${FIKA}/fika-server.zip -o fika-server.zip && \
    unzip fika-server.zip "user/*" -d /opt/srv && \
    sed -i 's/127.0.0.1/0.0.0.0/g' /opt/srv/Aki_Data/Server/configs/http.json

COPY bullet.sh config.sh /opt/

# Fix for Windows
RUN dos2unix /opt/bullet.sh

FROM ubuntu:latest

WORKDIR /opt
# Exposing ports
EXPOSE 6969 6970

ARG SPT
ARG FIKA
LABEL SPT=$SPT FIKA=$FIKA

# Specify the default command to run when the container starts
CMD bash ./bullet.sh

COPY --from=builder /opt /opt

# Install tools and Set permissions
RUN apt update && \
    apt install -yq curl unzip yq unrar p7zip && \
    apt clean && rm -rf /var/lib/apt/lists && \
    chmod o+rwx /opt /opt/srv /opt/srv/* -R
