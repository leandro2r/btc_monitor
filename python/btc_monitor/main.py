#!/usr/bin/env python

from argparse import ArgumentParser
from datetime import datetime
from playsound import playsound
import json
import logging
import requests
import time
import re
import sys
import websocket
import yaml


class BTC():
    CONFIG_FILE = os.environ.get('CONFIG_FILE', '/etc/btc_monitor/btc_monitor.yml')
    LOG_PATH = os.environ.get('LOG_PATH', '/var/log/btc_monitor/run.log')

    config = {
        # Default API from Bitstamp
        'api': 'https://www.bitstamp.net/api/v2/ticker/btcusd/',
        'currency': '$',
        'mute': False,
        'sound': 'media/alarm.mp3',
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
            'none': '\033[0m',
            'red': '\033[1;31m',
            'white': '\033[1m',
            'yellow': '\033[1;33m',
        },
        'symbol': {
            'asc': b'\xE2\x86\x97'.decode('utf-8'),
            'desc': b'\xE2\x86\x98'.decode('utf-8'),
            'high': b'\xE2\xA4\x93'.decode('utf-8'),
            'last': b'\xE2\xA4\xBA'.decode('utf-8'),
            'low': b'\xE2\xA4\x92'.decode('utf-8'),
            'target': b'\xE2\x9C\x96'.decode('utf-8'),
        }
    }

    def log(self, msg):
        now = datetime.now().strftime('%d-%m-%y %H:%M:%S')
        print('[{}] {}'.format(now, msg))

    def dict_update(cur, new):
        for key, value in new.items():
            if isinstance(value, collections.Mapping):
                cur[key] = dict_update(cur.get(key, {}), value)
            else:
                cur[key] = value
        return cur

    def config_load(self):
        try:
            with open(self.CONFIG_FILE, 'r') as file:
                yml = yaml.load(file)
                if yml:
                    self.dict_update(self.config, yml)
                src = self.CONFIG_FILE
        except Exception as error:
            src = 'default'

        self.log('Setting config from {}...'.format(src))

    def arg_parser(self):
        parser = ArgumentParser(description='BTC monitor parameters.')

        parser.add_argument('-a', '--ascending', action='store_true',
                            help='Ascending')
        parser.add_argument('-d', '--descending', action='store_true',
                            help='Descending')
        parser.add_argument('-m', '--mute', action='store_true',
                            help='Mute')
        parser.add_argument('-v', '--value', type=float, help='Value')

        args = parser.parse_args()

        if args.value:
            self.config['value'] = args.value

        if args.mute:
            self.config['mute'] = True

        if args.ascending:
            self.config['mode'] = 'ascending'
        elif args.descending:
            self.config['mode'] = 'descending'

    def log_config(self):
        FORMAT = '[%(asctime)s] %(message)s'
        logging.basicConfig(filename=self.LOG_PATH,
                            level=logging.INFO,
                            format=FORMAT)

    def http_call(self, url, payload=''):
        try:
            payload = requests.get(url, stream=True)
        except requests.exceptions.RequestException as error:
            print('Failed to connect: {}'.format(error))

        try:
            payload = payload.json()
        except:
            print('Failed to parse json')
            payload = ''

        return payload

    def ws_call(self, url, payload={}):
        try:
            # Foxbit
            req = {
                'm': 0,
                'i': 0,
                'n': 'SubscribeTicker',
                # 'n': 'GetTickerHistory',
                'o': '',
            }

            posix_dt = int(round((
                datetime.now().timestamp() - 10800
            ) * 1000))

            req['o'] = json.dumps({
                'InstrumentId': 1,
                # 'FromDate': posix_dt,
                'OMSId': 1,
                'Interval': 60,
                'IncludeLastCount': 1,
            })

            api = websocket.create_connection(url)
            api.send(json.dumps(req))
            output = json.loads(api.recv())['o']
            api.close()

            output = eval(output)
            output = str(output[0]).split(',')

            payload = {
                'high': output[1].strip(),
                'last': output[7].strip(),
                'low': output[2].strip(),
            }
        except websocket.WebSocketConnectionClosedException as error:
            print('Failed to connect: {}'.format(error))

        return payload

    def connect(self):
        if 'ws://' in self.config['api'] or 'wss://' in self.config['api']:
            payload = self.ws_call(self.config['api'])
        else:
            payload = self.http_call(self.config['api'])

        return payload

    def alarm(self, target, value, mode, color, symbol):
        gotcha = False

        if mode == 'ascending':
            if value > target:
                gotcha = True
        else:
            if value < target:
                gotcha = True

        if gotcha:
            if not self.config['mute']:
                with open(self.config['sound'], 'rb') as file:
                    playsound(self.config['sound'])
            self.log(
                '{}########################################\n\n'
                '\t\t\t   [{}] Value found: {} {}\n\n\t\t    ###'
                '#####################################{}'.format(
                    color['white'],
                    symbol['target'],
                    self.config['currency'],
                    value,
                    color['none'],
                )
            )
            target = value

        return target

    def monitor(self):
        config = self.config
        ticker = self.ticker
        color = self.metadata['color']
        symbol = self.metadata['symbol']

        last = self.metadata['symbol']['last']

        res = self.connect()
        while not res:
            print('Trying to reconnect...')
            time.sleep(1)
            res = self.connect()

        if config.get('mode'):
            if (config['mode'] == 'ascending' and
                 float(res['last']) > float(ticker['last'])):
                last = '{}{}'.format(color['green'], symbol['asc'])
            elif (config['mode'] == 'descending' and
                  float(res['last']) < float(ticker['last'])):
                last = '{}{}'.format(color['red'], symbol['desc'])

        ticker.update(res)

        self.log(
            '{} {} {} {}| {} {} {} | {} {} {} '.format(
                last, config['currency'], ticker['last'], color['none'],
                symbol['low'], config['currency'], ticker['low'],
                symbol['high'], config['currency'], ticker['high'],
            )
        )

        if config.get('mode') and ticker['last'] != 0:
            if config['value'] > 0:
                value = self.alarm(
                    config['value'],
                    float(res['last']),
                    config['mode'],
                    color,
                    symbol,
                )

                if value != config['value']:
                    self.log(
                        '{}Updating alarm value to last: {} {} {}'.format(
                            color['green'],
                            config['currency'],
                            value,
                            color['none'],
                        )
                    )
                    config.update({'value': value})
    
    def __init__(self):
        # self.log_config()
        self.config_load()
        self.arg_parser()
        self.ticker.update({'api': self.config['api']})

        for key, value in self.config.items():
            if value != 0:
                print('\t\t    {}: {}'.format(key, value))


def main():
    Monitor = BTC()

    try:
        while True:
            Monitor.monitor()
    except KeyboardInterrupt:
        print(' Exiting...')
        sys.exit(1)


if __name__ == '__main__':
    main()
