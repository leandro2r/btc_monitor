# BTC Monitor (Python)

### Requirements

```shell
$ [sudo] apt install python3.7 python-pip
$ ./setup.py install
```

### Man btc_monitor

```shell
$ btc_monitor -v <alarm_value> -a -d -m -c <identification_color>
```

- `-v <alarm_value>`: Monitored value
- `-a`: Ascending mode
- `-d`: Descending mode
- `-m`: Mute (Alarm sound)
- `-c <identification_color>`: Color name (`black` | `blue` | `cyan` | `green` | `purple` | `red` | `white` | `yellow`)

### Docker image

If you have docker installed in your environment, just pull the image from [btc_monitor docker hub](https://hub.docker.com/r/leandro2r/btc_monitor)

```shell
$ docker pull leandro2r/btc_monitor:latest-python
```
