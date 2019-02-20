if __package__ is None or __package__ == '':
    from log import Log
else:
    from btc_monitor.log import Log

from datetime import datetime

import json
import re
import requests
import subprocess
import time
import websocket


class BTC(Log):
    ticker = {
        'high': 0,
        'last': 0,
        'low': 0,
    }

    def rest_call(self, url, payload=''):
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

    def connect(self, api):
        if 'ws://' in api or 'wss://' in api:
            payload = self.ws_call(api)
        else:
            payload = self.rest_call(api)

        return payload

    def value_calc(self, btc, percent, last):
        return round(float(btc)*float(last)*float(1-float(percent)/100), 2)

    def alarm(self, target, currency, value, mode, symbol, color):
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
                '\t\t\t   {} Value found: {} {}\n\n'
                '{}{}'.format(
                    self.log_format(True, color), '#'*50,
                    symbol['target'],
                    currency,
                    value,
                    '#'*70, self.log_format(),
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
                except (OSError, ValueError) as msg:
                    self.log(
                        'Error on playing alarm sound: {}'.format(msg)
                    )

        return target

    def monitor(self):
        config = self.config
        ticker = self.ticker
        symbol = self.metadata['symbol']
        last = self.metadata['symbol']['last']

        color = ''
        res = {}

        d = self.connect(self.config['api'])
        while not d:
            print('Trying to connect...')
            time.sleep(1)
            d = self.connect(self.config['api'])

        self.dict_update(res, d)

        if config.get('mode'):
            if (config['mode'] == 'ascending' and
                 float(res['last']) > float(ticker['last'])):
                color = 'green'
                last = '{}{}'.format(self.log_format(True, color), symbol['asc'])
            elif (config['mode'] == 'descending' and
                  float(res['last']) < float(ticker['last'])):
                color = 'red'
                last = '{}{}'.format(self.log_format(True, color), symbol['desc'])

        ticker.update(res)

        self.log(
            '{} {} {} {}| {} {} {} | {} {} {} ({} {})'.format(
                last, config['currency'], ticker['last'], self.log_format(),
                symbol['low'], config['currency'], ticker['low'],
                symbol['high'], config['currency'], ticker['high'],
                config['currency'],
                self.value_calc(
                    self.config['btc'], 
                    self.config['trade_fee'],
                    float(ticker['last']),
                ),
            )
        )

        if config.get('mode') and ticker['last'] != 0:
            if config['value'] > 0:
                value = self.alarm(
                    config['value'],
                    self.config['currency'],
                    float(res['last']),
                    config['mode'],
                    symbol,
                    color,
                )

                if value != config['value']:
                    self.log(
                        '{}Updating alarm value to last: {} {} {}'.format(
                            self.log_format(True, color),
                            config['currency'],
                            value,
                            self.log_format(),
                        )
                    )
                    config.update({'value': value})
    
    def __init__(self):
        super().__init__()
        self.ticker.update(
            {
                'api': self.config['api'], 
                'last': self.config['value']
            }
        )
