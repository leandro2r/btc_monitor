#!/usr/bin/env python

from datetime import datetime
from argparse import ArgumentParser
import logging
import requests
import websocket
import sys
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


def config_load():
    with open(config_file, 'r') as file:
        try:
            config.update(yaml.safe_load(file))
        except Exception as error:
            print(error)

    log('Setting config from {}...'.format(config_file))

    for key, value in config.items():
        if value != 0:
            print('\t\t    {}: {}'.format(key, value))


def arg_parser():
    parser = ArgumentParser(description='BTC monitor parameters.')
    parser.add_argument('-a', '--ascending', action='store_true',
                        help='Ascending')
    parser.add_argument('-d', '--descending', action='store_true',
                        help='Descending')
    parser.add_argument('-v', '--value', type=float, help='Value')

    args = parser.parse_args()

    if args.value:
        config['value'] = args.value

    if args.ascending:
        config['mode'] = 'ascending'
    elif args.descending:
        config['mode'] = 'descending'


def log_config():
    FORMAT = '[%(asctime)s] %(message)s'
    logging.basicConfig(filename=log_path,
                        level=logging.INFO,
                        format=FORMAT)


def log(msg):
    now = datetime.now().strftime('%d-%m-%y %H:%M:%S')
    print('[{}] {}'.format(now, msg))


def http_call(url):
    try:
        payload = requests.get(url, stream=True).json()

        return payload
    except requests.exceptions.RequestException as error:
        print('Failed to connect: {}'.format(error))

        sys.exit(1)


def ws_call(url):
    try:
        req = {
            'm': 0,
            'i': 0,
            'n': 'GetTickerHistory',
            'o': '',
        }

        posix_dt = int(round((
            datetime.now().timestamp() - 10800
        ) * 1000))

        req['o'] = json.dumps({
            'InstrumentId': 1,
            'FromDate': posix_dt,
        })

        api = websocket.create_connection(url)
        api.send(json.dumps(req))
        payload = json.loads(api.recv())
        api.close()

        print(json.dumps(req))
        print(json.dumps(payload))

        return payload
    except websocket.WebSocketConnectionClosedException as error:
        print('Failed to connect: {}'.format(error))

        sys.exit(1)


def monitor():
    green = '\033[1;32m'
    red = '\033[1;31m'
    white = '\033[0m'

    symbol_last = b'\xE2\xA4\xBA'.decode('utf-8')
    symbol_high = b'\xE2\xA4\x93'.decode('utf-8')
    symbol_low = b'\xE2\xA4\x92'.decode('utf-8')

    symbol_asc = b'\xE2\x86\x97'.decode('utf-8')
    symbol_desc = b'\xE2\x86\x98'.decode('utf-8')

    if 'ws://' in config['api'] or 'wss://' in config['api']:
        res = ws_call(config['api'])
    else:
        res = http_call(config['api'])

    if config.get('value') and ticker['last'] != 0:
        if config.get('mode'):
            if (config['mode'] == 'ascending' and
                res['last'] > ticker['last']):
                symbol_last = '{}{}'.format(green, symbol_asc)
            elif (config['mode'] == 'descending' and
                  res['last'] < ticker['last']):
                symbol_last = '{}{}'.format(red, symbol_desc)

    ticker.update(res)

    log(
        '{} {} {} {}| {} {} {} | {} {} {} '.format(
            symbol_last, config['currency'], ticker['last'], white,
            symbol_low, config['currency'], ticker['low'],
            symbol_high, config['currency'], ticker['high'],
        )
    )


if __name__ == '__main__':
    # log_config()
    config_load()
    arg_parser()
    try:
        while True:
            monitor()
    except KeyboardInterrupt:
        print('\nExiting...')
        sys.exit(1)
