FROM python:3.7-alpine

ARG CI_COMMIT_TAG=dev

ENV TZ=America/Sao_Paulo
ENV VERSION=$CI_COMMIT_TAG
ENV PYTHONUNBUFFERED=1

COPY . /home/btc_monitor

RUN apk update && apk --no-cache add \
    tzdata \
    sox \
    py-pip && \
    pip install -U pip setuptools &&\
    cd /home/btc_monitor &&\
    ./setup.py install

COPY extras/media /opt/btc_monitor/media
COPY extras/btc_monitor /etc/btc_monitor

RUN find /etc/btc_monitor/* -type f -exec sh -c 'cp -f {} {}.example' \; \
    mkdir -p /var/log/btc_monitor &&\
    apk del py-pip &&\
    rm -rf /home/btc_monitor

WORKDIR /etc/btc_monitor

ENTRYPOINT ["btc_monitor"]
# CMD [""]
