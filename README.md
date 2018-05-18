# BTC Monitor Script

### Description

This script monitors the bitcoin value from btc exchange using API (Bitstamp as default) and notifies if the **Alarm**, **High** or **Low** value has been catched up.
The notices can also be sent by a Telegram BOT.

### Requirements

```shell
$ [sudo] apt-get install jq
$ [sudo] apt-get install sox
```

### Config file

Create/Use `config.txt` file to set some scripts configurations (API, Alarm sound file, BTC value, Exchange infos and Telegram):

*config.txt*
```
api_ticker="<URL>"
alarm_sound="<FILE_PATH>"
btc="<BTC_VALUE>"
currency="<CURRENCY_SYMBOL>"
trade_fee="<EXCHANGE_TRADE_FEE>"
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man monitor.sh

```shell
$ ./monitor.sh -v <alarm_value> -a -d -t <summary_interval_in_seconds> -n <instance_name> -c <identification_color>
```

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-t <summary_interval_in_seconds>`: Time interval of summary (in seconds)
- `-n <instance_name>`: Instance name
- `-c <identification_color>`: Color name (`0 black` | `1 blue` | `2 cyan` | `3 green` | `4 purple` | `5 red` | `6 white` | `7 yellow`)
- `-m`: Mute (Alarm sound and Telegram publisher)

### API ticker supported

```
# Bitstamp
api_ticker="https://www.bitstamp.net/api/v2/ticker/btcusd/"

# Blinktrade
api_ticker="https://api.blinktrade.com/api/v1/BRL/ticker"

```

### API Docs

- https://www.bitstamp.net/api
- https://blinktrade.com/docs
