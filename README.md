# BTC Monitor

### Description

This script monitors the bitcoin value from btc exchange using API (Bitstamp as default) and notifies if the **Alarm**, **High** or **Low** value has been catched up.
The notices can also be sent by a Telegram BOT.

There are two code versioned of the solution in this repository. The `./shell/` version was the first one made in Shell and the newest is in Python 3.7 found in `./python/`.

### Docker repository

The BTC Monitor has a docker hub repository with both images.
([btc_monitor docker hub](https://hub.docker.com/r/leandro2r/btc_monitor))

### REST API ticker supported

```
# Bitstamp
https://www.bitstamp.net/api/v2/ticker/btcusd/

# Foxbit watcher
http://watcher.foxbit.com.br/api/Ticker?exchange=Foxbit

```

### REST API Docs

- https://www.bitstamp.net/api
- https://watcher-docs.foxbit.com.br/
