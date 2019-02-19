# BTC Monitor (Shell Script)

### Requirements

```shell
$ [sudo] apt-get install jq
$ [sudo] apt-get install sox
$ [sudo] make install
```

### Config file

Create/Use `btc_monitor.txt` file to set some scripts configurations (API, Alarm sound file, BTC value, Exchange infos and Telegram):

*extras/btc_monitor/btc_monitor.txt*
```
api_ticker="<URL>"
alarm_sound="<FILE_PATH>"
btc="<BTC_VALUE>"
currency="<CURRENCY_SYMBOL>"
trade_fee="<EXCHANGE_TRADE_FEE>"
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man btc_monitor

```shell
$ btc_monitor -v <alarm_value> -a -d -t <summary_interval_in_seconds> -n <instance_name> -c <identification_color>
```

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-t <summary_interval_in_seconds>`: Time interval of summary (in seconds)
- `-n <instance_name>`: Instance name
- `-c <identification_color>`: Color name (`0 black` | `1 blue` | `2 cyan` | `3 green` | `4 purple` | `5 red` | `6 white` | `7 yellow`)
- `-m`: Mute (Alarm sound and Telegram publisher)

### REST API ticker supported

```
# Bitstamp
api_ticker="https://www.bitstamp.net/api/v2/ticker/btcusd/"

# Foxbit watcher
api_ticker="http://watcher.foxbit.com.br/api/Ticker?exchange=Foxbit"

```

### REST API Docs

- https://www.bitstamp.net/api
- https://watcher-docs.foxbit.com.br/
