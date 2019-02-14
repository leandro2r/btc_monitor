FROM alpine:latest

ENV TZ=America/Sao_Paulo

RUN apk update && apk --no-cache add \
    tzdata \
    bash \
    curl \
    bc \
    shadow \
    jq \
    sox

WORKDIR /home/btc_monitor

RUN groupmod -g 92 audio

COPY . .

RUN cp -f config.txt config.txt.example

ENTRYPOINT ["./monitor.sh"]
# CMD [""]
