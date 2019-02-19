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

### Docker image

If you have docker installed in your environment, just pull the image from ([btc_monitor docker hub](https://hub.docker.com/r/leandro2r/btc_monitor))

```shell
$ docker pull leandro2r/btc_monitor:latest-shell
```
