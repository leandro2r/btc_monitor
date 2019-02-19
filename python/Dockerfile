FROM python:3.7-alpine

ARG CI_COMMIT_TAG=dev

ENV TZ=America/Sao_Paulo
ENV VERSION=$CI_COMMIT_TAG

RUN apk update && apk --no-cache add \
    tzdata \
    sox \
    py-pip && \
    pip install -U pip setuptools

COPY . /home/btc_monitor

RUN cd /home/btc_monitor &&\
    ./setup.py install

COPY extras/media /opt/btc_monitor/media

COPY extras/btc_monitor /etc/btc_monitor
RUN find /etc/btc_monitor/* -type f -exec sh -c 'cp -f {} {}.example' \;

RUN mkdir -p /var/log/btc_monitor

RUN apk del py-pip &&\
    rm -rf /home/btc_monitor

WORKDIR /etc/btc_monitor

ENTRYPOINT ["btc_monitor"]
# CMD [""]
