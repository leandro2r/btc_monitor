#!/usr/bin/env python

if __package__ is None or __package__ == '':
    from btc_monitor import BTC
else:
    from btc_monitor.btc_monitor import BTC

import sys


def main():
    Monitor = BTC()

    try:
        while True:
            Monitor.monitor()
    except KeyboardInterrupt:
        print('^C Exiting...{}'.format(Monitor.log_format(False, 'white')))
        sys.exit(1)


if __name__ == '__main__':
    main()
