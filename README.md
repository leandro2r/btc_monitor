# Foxbit Monitor script

### Description

This script monitors the bitcoin value from Foxbit exchange using API (Blinktrade as default) and notifies if the **Alarm**, **High** or **Low** value has been catched up.
The notices can also be sent by Foxbit Monitor Bot by Telegram BOT.

### Requirements

`sudo apt-get install jq`

`sudo apt-get install sox`

### Config file

Create/Use `config.txt` file to set some scripts configurations (API, sound file, BTC value, Exchange infos and Telegram):

*api_config.txt*
```
api_ticker="<URL>"
alarm_sound="<FILE_PATH>"
btc="<BTC_VALUE>"
trade_fee="<EXCHANGE_TRADE_FEE>"
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man monitor.sh

`./monitor.sh -v <alarm_value> -a -d -i <summary_interval_in_seconds> -n <instance_name> -c <identification_color>`

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-i <summary_interval_in_seconds>`: Interval duration (in seconds)
- `-n <instance_name>`: Instance name
- `-c <identification_color>`: Color name (blue|cyan|gray|purple|orange)

### Foxbit data from BlinkTrade API

https://blinktrade.com/docs
