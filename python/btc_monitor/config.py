from argparse import ArgumentParser

import collections.abc as collections
import os
import yaml


class Config():
    config = {}

    def __init__(self):
        CONFIG_FILE = os.environ.get(
            'CONFIG_FILE',
            '/etc/btc_monitor/btc_monitor.yml'
        )
        LOG_FILE = os.environ.get(
            'LOG_FILE',
            '/var/log/btc_monitor/run.log'
        )

        # Default API from Bitstamp
        self.config.update({
            'api': os.environ.get(
                'API',
                'https://www.bitstamp.net/api/v2/ticker/btcusd/'
            ),
            'currency': os.environ.get('CURRENCY', '$'),
            'color': os.environ.get('COLOR_ID', 'white'),
            'mute': False,
            'sound': os.environ.get(
                'SOUND_FILE',
                '/opt/btc_monitor/media/alarm.mp3'
            ),
            'value': 0,
            'btc': os.environ.get('BTC', 0),
            'trade_fee': os.environ.get('TRADE_FEE', 0),
        })

        self.arg_parser()
        self.config_load()

        for key, value in self.config.items():
            if value != 0:
                print('\t\t    {}: {}'.format(key, value))

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
                yml = yaml.load(file, Loader=yaml.BaseLoader)
                if yml:
                    self.dict_update(self.config, yml)
                src = self.CONFIG_FILE
        except Exception as error:
            src = 'default'
            self.log('Error on {}'.format(error))

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
