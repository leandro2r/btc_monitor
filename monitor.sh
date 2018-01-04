#!/bin/bash
source config.txt
source telegram_api.sh

HEADER="##############################"
FOOTER="###############################################################################"
BOLD="\033[1m"
UNDERLINE="\033[4m"
STYLE_END="\033[0m"

while getopts "v:adn:i:" opt; do
    case $opt in
        a) simbol="↗"
           simbol_utf8="\xE2\x86\x97"
           mode="Ascending ${simbol}"
           descending=false
           action="Increasing"
           mode_color="\033[1;32m"
        ;;
        d) simbol="↘"
           simbol_utf8="\xE2\x86\x98"
           mode="Descending ${simbol}"
           descending=true
           action="Decreasing"
           mode_color="\033[1;31m"
        ;;
        v) alarm="${OPTARG}"
           last_prev="${alarm}"
        ;;
        n) name="${OPTARG}"
        ;;
        i) period_interval="${OPTARG}"
        ;;
        \?) echo "-v <alarm_value> -a -d -n <instance_name> "
                 "-i <summary_interval_in_seconds>"
            exit
        ;;
    esac
done

# Validate optargs
if [[ -z ${alarm} ]]; then
    alarm=0
elif [[ -z ${mode} ]]; then
    echo -e "Choose one mode: -a (Ascending \xE2\x86\x97) -d (Descending \xE2\x86\x98)"
    exit 1
fi

if [[ -z ${api_ticker} ]]; then
    # Default api_ticker: Blinktrade
    api_ticker="https://api.blinktrade.com/api/v1/BRL/ticker"
fi

if [[ -z ${trade_fee} ]]; then
    # Default passive trade fee: 0,25% (Foxbit)
    trade_fee=0.25
fi

if [[ -z ${alarm_sound} ]]; then
    # Default alarm sound: register machine
    alarm_sound="media/alarm.wav"
fi

if [[ -z ${period_interval} ]]; then
    # Default value: 10min
    period_interval=600
fi

DATE=`date '+%d/%m/%y %H:%M:%S'`
interval_min=`echo "${period_interval} / 60" | bc`
percent_total=`echo "scale=2;100 - ${trade_fee} / 1" | bc -l`

echo -e "${BOLD}[${DATE}] Setting alarm mode to: ${simbol_utf8}
                    Setting alarm value to: R$ ${alarm}
                    Setting summary interval to: ${period_interval}s (${interval_min} min)${STYLE_END}"

send_to_telegram "config" ${interval_min} ${btc}

START_TIME=$SECONDS

while [[ true ]]
do
    DATE=`date '+%d/%m/%y %H:%M:%S'`

    json_data=`curl -s "${api_ticker}"`

    if ! jq -e . >/dev/null 2>&1 <<<"${json_data}"; then
        echo "[${DATE}] Trying to get data"
        sleep 5
        continue
    fi

    high=`echo "${json_data}" | jq -r 'select(.high != null) | .high'`
    last=`echo "${json_data}" | jq -r 'select(.last != null) | .last'`
    low=`echo "${json_data}" | jq -r 'select(.low != null) | .low'`
    buy=`echo "${json_data}" | jq -r 'select(.buy != null) | .buy'`
    sell=`echo "${json_data}" | jq -r 'select(.sell != null) | .sell'`

    if [[ -z ${high} || -z ${last} || -z ${low} ]]; then
        echo "[${DATE}] Trying to get data"
        sleep 5
        continue
    fi

    if [[ ! -z ${btc} ]]; then
        btc_brl=`echo "(${btc} * (${percent_total} / 100)) * ${last}" | bc -l`
        btc_brl=`echo "scale=2;${btc_brl} / 1" | bc -l`
        mode_btc_brl="[R$ ${btc_brl}]"
    fi

    mask_last=`echo "scale=2;${last} / 1" | bc -l`

    if [[ ("${last_prev%.*}" -lt "${last%.*}" && ${descending} == false)
        || ("${last_prev%.*}" -gt "${last%.*}" && ${descending} == true) ]]; then
        mode_last="${mode_color}${simbol_utf8} R$ ${mask_last}${STYLE_END}"
        mode_btc_brl="${mode_color}${mode_btc_brl}${STYLE_END}"
    else
        mode_last="\xE2\xA4\xBA R$ ${mask_last}"
    fi

    echo -e "[${DATE}] ${mode_last} | \xE2\xA4\x93 R$ ${low} | \xE2\xA4\x92 R$ ${high} ${mode_btc_brl}"

    if [[ "${high%.*}" -eq "${last%.*}"
        && "${high_prev%.*}" -lt "${high%.*}" ]]; then
        send_to_telegram "update" "↗ High" ${last}
    elif [[ "${low%.*}" -eq "${last%.*}"
        && "${low_prev%.*}" -gt "${low%.*}" ]]; then
        send_to_telegram "update" "↘ Low" ${last}
    fi

    high_prev="${high}"
    last_prev="${last}"
    low_prev="${low}"

    diff=`echo "${last%.*} - ${alarm%.*}" | bc`

    if [[ (${diff} -lt 0 && ${descending} == true)
        || (${diff} -gt 0 && ${descending} == false) ]]; then
        echo -e "${BOLD}${HEADER} ${DATE} ${HEADER}${STYLE_END}
        \n\t\t\t ${BOLD}[\xE2\x9C\x96] Value found: R$ ${last}${STYLE_END}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${UNDERLINE}https://foxbit.exchange/#trading${STYLE_END}
        \n${BOLD}${FOOTER}${STYLE_END}"

        play ${alarm_sound} 2> /dev/null

        send_to_telegram "alarm" ${percent_total} ${btc_brl}

        alarm=${last}

        echo -e "[${DATE}] ${mode_color}${action} alarm value to last: R$ ${alarm}${STYLE_END}"
    fi

    # Metrics for summary
    if [[ -z ${period_low} ]]; then
        period_high="${last}"
        period_low="${last}"
    fi

    if [[ "${last%.*}" -gt "${period_high%.*}" ]]; then
        period_high="${last}"
    elif [[ "${last%.*}" -lt "${period_low%.*}" ]]; then
        period_low="${last}"
    fi

    duration=`echo "${SECONDS} - ${START_TIME}" | bc`

    if [[ ${duration} -ge ${period_interval} ]]; then
        send_to_telegram "summary" ${percent_total} ${btc_brl}
        period_high="${last}"
        period_low="${last}"
        START_TIME=$SECONDS
    fi
done
