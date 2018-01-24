# Foxbit Monitor script

### Description

This script monitors the bitcoin value from Foxbit exchange using API (Blinktrade as default) and notifies if the **Alarm**, **High** or **Low** value has been catched up.
The notices can also be sent by Foxbit Monitor Bot by Telegram BOT.

### Requirements

`sudo apt-get install jq`

`sudo apt-get install sox`

### Config file

Create/Use `config.txt` file to set some scripts configurations (API; Alarm sound file; BTC, Reference and Variation value; Exchange infos and Telegram):

*api_config.txt*
```
api_ticker="<URL>"
alarm_sound="<FILE_PATH>"
btc="<BTC_VALUE>"
trade_fee="<EXCHANGE_TRADE_FEE>"
ref="<BRL_VALUE>"
var="<VARIATION_VALUE>"
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man monitor.sh

`./monitor.sh -v <alarm_value> -a -d -t <summary_interval_in_seconds> -n <instance_name> -c <identification_color>`

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-t <summary_interval_in_seconds>`: Time interval of summary (in seconds)
- `-n <instance_name>`: Instance name
- `-c <identification_color>`: Color name (`0 black` | `1 blue` | `2 cyan` | `3 green` | `4 purple` | `5 red` | `6 white` | `7 yellow`)
- `-m`: Mute (Alarm sound and Telegram publisher)

### Example

*api_config.txt*
```
btc="0.5"
ref="13500"
var="5000"
```

`./monitor.sh -d -t 60 -n XPTO_SCRIPT -c 1`

- Alarm value: **R$ 18593** (Considering exchange trade fees)
- Mode: **Ascending ↗**
- Summary interval: **60 sec (1min)**
- Alarm name (at telegram): **XPTO_SCRIPT**
- Shell color: **Blue**
- Goal value: **R$ 582.67**

### Foxbit data from BlinkTrade API

https://blinktrade.com/docs
