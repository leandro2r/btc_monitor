#!/bin/bash
source config.txt
source telegram_api.sh

while getopts "v:adn:i:b:" opt; do
    case $opt in
        a) simbol="↗"
           simbol_utf8="\xE2\x86\x97"
           mode="Ascending ${simbol}"
           descending=false
           action="Increasing"
        ;;
        d) simbol="↘"
           simbol_utf8="\xE2\x86\x98"
           mode="Descending ${simbol}"
           descending=true
           action="Decreasing"
        ;;
        v) alarm="${OPTARG}"
           last_prev="${alarm}"
        ;;
        n) name="${OPTARG}"
        ;;
        i) period_interval="${OPTARG}"
        ;;
        b) btc="${OPTARG}"
        ;;
        \?) echo "-v <alarm_value> -a -d -n <instance_name> "
                 "-i <summary_interval_in_seconds>"
            exit
        ;;
    esac
done

# Validate optargs
if [[ -z ${alarm} ]]; then
    echo -e "Choose an alarm value for monitoring: -v <alarm_value>"
    exit 1
fi

if [[ -z ${action} ]]; then
    echo -e "Choose one option: -a (Ascending \xE2\x86\x97) -d (Descending \xE2\x86\x98)"
    exit 1
fi

if [[ -z ${api_ticker} ]]; then
    # Default api_ticker: Blinktrade
    api_ticker="https://api.blinktrade.com/api/v1/BRL/ticker"
fi

if [[ -z ${alarm_sound} ]]; then
    # Default alarm sound: register machine
    alarm_sound="media/alarm.wav"
fi

if [[ -z ${period_interval} ]]; then
    # Default value: 30min
    period_interval=1800
fi

header="##############################"
footer="###############################################################################"
bold="\033[1m"
underline="\033[4m"
tag_end="\033[0m"

DATE=`date '+%d/%m/%y %H:%M:%S'`
interval_min=`echo "${period_interval} / 60" | bc`

echo -e "${bold}[${DATE}] Setting alarm mode to: ${simbol_utf8}
                    Setting alarm value to: R$ ${alarm}
                    Setting summary interval to: ${period_interval}s (${interval_min} min)${tag_end}"

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
        btc_brl=`echo "scale=2;(${btc} * ${last}) / 1" | bc -l`
        mode_btc_brl="[R$ ${btc_brl}]"
    fi

    mask_last=`echo "scale=2;${last} / 1" | bc -l`

    if [[ "${last_prev%.*}" -lt "${last%.*}" && ${descending} == false ]]; then
        mode_last="${bold}${simbol_utf8} R$ ${mask_last}${tag_end}"
        mode_btc_brl="${bold}${mode_btc_brl}${tag_end}"
    elif [[ "${last_prev%.*}" -gt "${last%.*}" && ${descending} == true ]]; then
        mode_last="${bold}${simbol_utf8} R$ ${mask_last}${tag_end}"
        mode_btc_brl="${bold}${mode_btc_brl}${tag_end}"
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
        echo -e "${bold}${header} ${DATE} ${header}${tag_end}
        \n\t\t\t ${bold}[\xE2\x9C\x96] Value found: R$ ${last}${tag_end}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${underline}https://foxbit.exchange/#trading${tag_end}
        \n${bold}${footer}${tag_end}"

        play ${alarm_sound} 2> /dev/null

        send_to_telegram "alarm" "" ${btc_brl}

        alarm=${last}

        echo -e "${bold}[${DATE}] ${action} alarm value to last: R$ ${alarm}${tag_end}"
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
        send_to_telegram "summary" `echo "${duration} / 60" | bc` ${btc_brl}
        period_high="${last}"
        period_low="${last}"
        START_TIME=$SECONDS
    fi
done
