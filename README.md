# Foxbit Monitor script

### Description

This script monitors the bitcoin value from Foxbit exchange using API (Blinktrade as default) and notifies if the **Alarm**, **High** or **Low** value has been catched up.
The notices can also be sent by Foxbit Monitor Bot by Telegram BOT.

### Requirements

`sudo apt-get install jq`

`sudo apt-get install sox`

### Config file

Create/Use `config.txt` file to set some scripts configurations (API, sound file and Telegram)

*api_config.txt*
```
api_ticker="<URL>"
alarm_sound="<FILE_PATH>"
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man monitor.sh

`./monitor.sh -v <alarm_value> -a -d -n <instance_name> -i <summary_interval_in_seconds>`

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-n <instance_name>`: Instance name
- `-i <summary_interval_in_seconds>`: Interval duration (in seconds)

### Foxbit data from BlinkTrade API

https://blinktrade.com/docs
