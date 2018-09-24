#!/usr/bin/env python

from datetime import datetime, timedelta
import logging
import requests
import websocket
import sys
import os
import yaml
import json


config_file = 'btc_monitor.yml'
log_path = '/var/log/btc_monitor/run.log'

config = {
    # Default API from Bitstamp
    'api': 'https://www.bitstamp.net/api/v2/ticker/btcusd/',
    'currency': '$',
}

ticker = {
    'high': 0,
    'last': 0,
    'low': 0,
}


def log_config():
    FORMAT = '[%(asctime)s] %(message)s'
    logging.basicConfig(filename=log_path,
                        level=logging.INFO,
                        format=FORMAT)


def config_load():
    try:
        config.update(yaml.load(open(config_file, 'r')))
	print('Setting config from {}'.format(config_file))
    except yaml.YAMLError as error:
        print('Setting default config...')


def http_call(url):
    try:
        ticker.update(requests.get(url, stream=True).json())

        return 0
    except requests.exceptions.RequestException as error:
        print('Failed to connect...')

        sys.exit(1)


def ws_call(url):
    try:
        req = {
            'm': 0,
            'i': 0,
            'n': 'GetTickerHistory',
            'o': '',
        }

        req['o'] = json.dumps({
            'InstrumentId': 1,
            'FromDate': 1537839036,
        })

        api = websocket.create_connection(url)
        api.send(json.dumps(req))
        payload = json.loads(api.recv())
        api.close()

        ticker.update(payload['o'])

        return 0
    except websocket.WebSocketConnectionClosedException as error:
        print('Failed to connect...')

        sys.exit(1)


def monitor():
    symbol_high = b'\xE2\xA4\x93'.decode()
    symbol_last = b'\xE2\xA4\xBA'.decode()
    symbol_low =  b'\xE2\xA4\x92'.decode()

    now = datetime.now().strftime('%d-%m-%y %H:%M:%S')

    try:
        if 'ws' in config['api']:
            ws_call(config['api'])
        else:
            http_call(config['api'])

        print(
            '[{}] {} {} {} | {} {} {} | {} {} {} '.format(
                now,
                symbol_last, config['currency'], ticker['last'],
                symbol_low,  config['currency'], ticker['low'],
                symbol_high, config['currency'], ticker['high'],
            )
        )

    except KeyboardInterrupt:
        print('\nExiting...')
        sys.exit(1)


if __name__ == '__main__':
    # log_config()
    config_load()
    while True:
        monitor()
