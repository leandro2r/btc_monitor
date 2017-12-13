# Foxbit Monitor script

### Requirements

`sudo apt-get install jq`

`sudo apt-get install sox`

### Config file

Create/Use `api_config.txt` file to set some APIs configs

*api_config.txt*
```
telegram_token="<TOKEN>"
telegram_chat_id="<CHAT_ID>"
```

### Man monitor.sh

`./monitor.sh -v <alarm_value> -a -d`

- `-v`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode

### Foxbit data from BlinkTrade API

https://blinktrade.com/docs
