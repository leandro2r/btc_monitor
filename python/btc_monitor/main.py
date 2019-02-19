#!/usr/bin/env python

from argparse import ArgumentParser
from datetime import datetime
import collections.abc as collections
import json
import logging
import os
import re
import requests
import subprocess
import sys
import time
import websocket
import yaml


class BTC():
    API = os.environ.get('API', 'https://www.bitstamp.net/api/v2/ticker/btcusd/')
    COLOR_ID = os.environ.get('COLOR_ID', 'white')
    CONFIG_FILE = os.environ.get('CONFIG_FILE', '/etc/btc_monitor/btc_monitor.yml')
    LOG_PATH = os.environ.get('LOG_PATH', '/var/log/btc_monitor/run.log')
    SOUND_FILE = os.environ.get('SOUND_FILE', '/opt/btc_monitor/media/alarm.mp3')

    config = {
        # Default API from Bitstamp
        'api': API,
        'currency': '$',
        'color': COLOR_ID,
        'mute': False,
        'sound': SOUND_FILE,
        'value': 0,
    }

    ticker = {
        'high': 0,
        'last': 0,
        'low': 0,
    }

    metadata = {
        'symbol': {
            'asc': b'\xE2\x86\x97'.decode('utf-8'),
            'desc': b'\xE2\x86\x98'.decode('utf-8'),
            'high': b'\xE2\xA4\x92'.decode('utf-8'),
            'last': b'\xE2\xA4\xBA'.decode('utf-8'),
            'low': b'\xE2\xA4\x93'.decode('utf-8'),
            'target': b'\xE2\x9C\x96'.decode('utf-8'),
        }
    }

    def log_format(self, bold = False, color = ''):
        d = {
            'black': '\033[{};30m'.format(int(bold)),
            'blue': '\033[{};33m'.format(int(bold)),
            'cyan': '\033[{};36m'.format(int(bold)),
            'green': '\033[{};32m'.format(int(bold)),
            'purple': '\033[{};35m'.format(int(bold)),
            'red': '\033[{};31m'.format(int(bold)),
            'white': '\033[{}m'.format(int(bold)),
            'yellow': '\033[{};33m'.format(int(bold)),
        }

        if not color:
            color = self.config['color']

        return d.get(color, d['white'])

    def log_config(self):
        FORMAT = '{}[%(asctime)s]{} %(message)s'.format(
            self.log_format(),
            self.log_format(),
        )
        logging.basicConfig(filename=self.LOG_PATH,
                            level=logging.INFO,
                            format=FORMAT)

    def log(self, msg):
        now = datetime.now().strftime('%d-%m-%y %H:%M:%S')
        print(
            '{}[{}]{} {}'.format(
                self.log_format(),
                now,
                self.log_format(),
                msg,                
            )
        )

    def dict_update(self, cur, new):
        for key, value in new.items():
            key = key.lower()
            if isinstance(value, collections.Mapping):
                cur[key] = self.dict_update(cur.get(key, {}), value)
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
        parser.add_argument('-c', '--color', type=str, 
                            help='Identification color')
        parser.add_argument('-m', '--mute', action='store_true',
                            help='Mute')
        parser.add_argument('-v', '--value', type=float, help='Value')

        args = parser.parse_args()

        if args.value:
            self.config['value'] = args.value

        if args.color:
            self.config['color'] = args.color

        if args.mute:
            self.config['mute'] = True

        if args.ascending:
            self.config['mode'] = 'ascending'
        elif args.descending:
            self.config['mode'] = 'descending'

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
                # 'n': 'SubscribeTicker',
                'n': 'GetTickerHistory',
                'o': '',
            }

            posix_dt = int(round((
                datetime.now().timestamp() - 10800
            ) * 1000))

            req['o'] = json.dumps({
                'InstrumentId': 1,
                'FromDate': posix_dt,
                # 'OMSId': 1,
                # 'Interval': 60,
                # 'IncludeLastCount': 1,
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

    def alarm(self, target, value, mode, symbol):
        gotcha = False

        if mode == 'ascending':
            if value > target:
                gotcha = True
        else:
            if value < target:
                gotcha = True

        if gotcha:
            self.log(
                '{}{}\n\n'
                '\t\t\t   [{}] Value found: {} {}\n\n'
                '{}{}'.format(
                    self.log_format(True), '#'*55,
                    symbol['target'],
                    self.config['currency'],
                    value,
                    '#'*75, self.log_format(),
                )
            )

            target = value

            if not self.config['mute']:
                try:
                    with open(self.config['sound'], 'rb') as file:
                        subprocess.check_call(
                            'play {}'.format(self.config['sound']), 
                            stderr=subprocess.PIPE, 
                            shell=True,
                        )
                except OSError as msg:
                    self.log(
                        'Error on playing alarm sound: {}'.format(msg)
                    )

        return target

    def monitor(self):
        config = self.config
        ticker = self.ticker
        symbol = self.metadata['symbol']
        last = self.metadata['symbol']['last']

        res = {}

        d = self.connect()
        while not d:
            print('Trying to connect...')
            time.sleep(1)
            d = self.connect()

        self.dict_update(res, d)

        if config.get('mode'):
            if (config['mode'] == 'ascending' and
                 float(res['last']) > float(ticker['last'])):
                last = '{}{}'.format(self.log_format(True, 'green'), symbol['asc'])
            elif (config['mode'] == 'descending' and
                  float(res['last']) < float(ticker['last'])):
                last = '{}{}'.format(self.log_format(True, 'red'), symbol['desc'])

        ticker.update(res)

        self.log(
            '{} {} {} {} | {} {} {} | {} {} {} '.format(
                last, config['currency'], ticker['last'], self.log_format(),
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
                    symbol,
                )

                if value != config['value']:
                    self.log(
                        '{}Updating alarm value to last: {} {} {}'.format(
                            self.log_format(True),
                            config['currency'],
                            value,
                            self.log_format(False),
                        )
                    )
                    config.update({'value': value})
    
    def __init__(self):
        self.arg_parser()
        # self.log_config()
        self.config_load()        
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
        print('Exiting...{}'.format(Monitor.log_format(False, 'white')))
        sys.exit(1)


if __name__ == '__main__':
    main()
