if __package__ is None or __package__ == '':
    from config import Config
else:
    from btc_monitor.config import Config

from datetime import datetime

import os


class Log(Config):
    metadata = {
        'symbol': {
            'asc': b'\xE2\x86\x97'.decode('utf-8'),
            'desc': b'\xE2\x86\x98'.decode('utf-8'),
            'high': b'\xE2\xA4\x92'.decode('utf-8'),
            'last': b'\xE2\xA4\xBA'.decode('utf-8'),
            'low': b'\xE2\xA4\x93'.decode('utf-8'),
            'target': b'\xE2\xAE\xBD'.decode('utf-8'),
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

    def __init__(self):
        super().__init__()
