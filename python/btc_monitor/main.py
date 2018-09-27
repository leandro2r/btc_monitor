#!/usr/bin/env python

from datetime import datetime
from argparse import ArgumentParser
import time
import logging
import requests
import websocket
import sys
import yaml
import json


class BTC():
    config_file = 'btc_monitor.yml'
    log_path = '/var/log/btc_monitor/run.log'

    config = {
        # Default API from Bitstamp
        'api': 'https://www.bitstamp.net/api/v2/ticker/btcusd/',
        'currency': '$',
        'value': 0,
    }

    ticker = {
        'high': 0,
        'last': 0,
        'low': 0,
    }

    metadata = {
        'color': {
            'green': '\033[1;32m',
            'red': '\033[1;31m',
            'white': '\033[0m',
        },
        'symbol': {
            'last': b'\xE2\xA4\xBA'.decode('utf-8'),
            'high': b'\xE2\xA4\x93'.decode('utf-8'),
            'low': b'\xE2\xA4\x92'.decode('utf-8'),
            'asc': b'\xE2\x86\x97'.decode('utf-8'),
            'desc': b'\xE2\x86\x98'.decode('utf-8'),
        }
    }

    def __init__(self):
        # self.log_config()
        self.config_load()
        self.arg_parser()

        self.ticker.update({'api': self.config['api']})

        for key, value in self.config.items():
            if value != 0:
                print('\t\t    {}: {}'.format(key, value))

    def log(self, msg):
        now = datetime.now().strftime('%d-%m-%y %H:%M:%S')
        print('[{}] {}'.format(now, msg))

    def config_load(self):
        with open(self.config_file, 'r') as file:
            try:
                self.config.update(yaml.safe_load(file))
            except Exception as error:
                print(error)

        self.log('Setting config from {}...'.format(self.config_file))

    def arg_parser(self):
        parser = ArgumentParser(description='BTC monitor parameters.')

        parser.add_argument('-a', '--ascending', action='store_true',
                            help='Ascending')
        parser.add_argument('-d', '--descending', action='store_true',
                            help='Descending')
        parser.add_argument('-v', '--value', type=float, help='Value')

        args = parser.parse_args()

        if args.value:
            self.config['value'] = args.value

        if args.ascending:
            self.config['mode'] = 'ascending'
        elif args.descending:
            self.config['mode'] = 'descending'

    def log_config(self):
        FORMAT = '[%(asctime)s] %(message)s'
        logging.basicConfig(filename=self.log_path,
                            level=logging.INFO,
                            format=FORMAT)

    def http_call(self, url, payload=''):
        try:
            payload = requests.get(url, stream=True).json()
        except requests.exceptions.RequestException as error:
            print('Failed to connect: {}'.format(error))

        return payload

    def ws_call(self, url, payload=''):
        try:
            # Foxbit
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
        except websocket.WebSocketConnectionClosedException as error:
            print('Failed to connect: {}'.format(error))

        return payload

    def connect(self):
        if 'ws://' in self.config['api'] or 'wss://' in self.config['api']:
            payload = self.ws_call(self.config['api'])
        else:
            payload = self.http_call(self.config['api'])

        return payload

    def monitor(self):
        config = self.config
        ticker = self.ticker
        color = self.metadata['color']
        symbol = self.metadata['symbol']

        last = self.metadata['symbol']['last']

        res = self.connect()
        while not res:
            print('Trying to reconnect...')
            time.sleep(3)
            res = self.connect()

        if config.get('mode') and ticker['last'] != 0:
            if (config['mode'] == 'ascending' and
               res['last'] > ticker['last']):
                last = '{}{}'.format(color['green'], symbol['asc'])
            elif (config['mode'] == 'descending' and
                  res['last'] < ticker['last']):
                last = '{}{}'.format(color['red'], symbol['desc'])

        ticker.update(res)

        self.log(
            '{} {} {} {}| {} {} {} | {} {} {} '.format(
                last, config['currency'], ticker['last'], color['white'],
                symbol['low'], config['currency'], ticker['low'],
                symbol['high'], config['currency'], ticker['high'],
            )
        )


if __name__ == '__main__':
    Monitor = BTC()

    try:
        while True:
            Monitor.monitor()
    except KeyboardInterrupt:
        print('\nExiting...')
        sys.exit(1)
