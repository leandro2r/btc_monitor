FROM alpine:latest

ARG CI_COMMIT_TAG=dev

ENV TZ=America/Sao_Paulo
ENV VERSION=$CI_COMMIT_TAG

RUN apk update && apk --no-cache add \
    tzdata \
    bash \
    make \
    curl \
    bc \
    jq \
    sox

COPY . /home/btc_monitor

RUN cd /home/btc_monitor &&\
    make install

RUN apk del make &&\
    rm -rf /home/btc_monitor

WORKDIR /etc/btc_monitor

ENTRYPOINT ["monitor"]
# CMD [""]
