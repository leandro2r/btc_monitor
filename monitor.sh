#!/bin/bash
source config.txt
source telegram_api.sh

HEADER="##############################"
FOOTER="###############################################################################"
BOLD="\033[1m"
UNDERLINE="\033[4m"
STYLE_END="\033[0m"

while getopts "v:n:t:c:admh" opt; do
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
           prev_last="${alarm}"
        ;;
        n) name="${OPTARG}"
        ;;
        t) time_interval="${OPTARG}"
        ;;
        c)  case "${OPTARG}" in
                "black"|0) COLOR="\033[0;30m"
                ;;
                "blue"|1) COLOR="\033[0;34m"
                ;;
                "cyan"|2) COLOR="\033[0;36m"
                ;;
                "green"|3) COLOR="\033[0;32m"
                ;;
                "purple"|4) COLOR="\033[0;35m"
                ;;
                "red"|5) COLOR="\033[0;31m"
                ;;
                "white"|6) COLOR="\033[0;37m"
                ;;
                "yellow"|7) COLOR="\033[0;33m"
                ;;
            esac
        ;;
        m) mute=true
        ;;
        h|\?) echo "-v <alarm_value> -a (Ascending) -d (Descending)"\
                   "-n <instance_name> -t <summary_interval_in_seconds>"\
                   "-c <identification_color> -m (Mute)"
            exit
        ;;
    esac
done

# Validate optargs
if [[ ! -z ${alarm} && -z ${mode} ]]; then
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

if [[ -z ${time_interval} ]]; then
    # Default time interval: 10min
    time_interval=600
fi

DATE=`date '+%d/%m/%y %H:%M:%S'`
interval_min=`echo "${time_interval} / 60" | bc`
total_percent=`echo "scale=2;100 - ${trade_fee} / 1" | bc -l`

if [[ -z ${alarm} && ! -z ${ref} && ! -z ${var} && -z ${mute} ]]; then
    brl_var=`echo "${ref} + ${var}" | bc`

    if [[ ${descending} == false ]]; then
        # SELL
        alarm=`echo "(${brl_var} * (100 + (${trade_fee} * 2)) / 100) + 1" | bc`
    else
        # BUY
        alarm=`echo "(${brl_var} * (100 - (${trade_fee} * 2)) / 100) - 1" | bc`
    fi
fi

if [[ ! -z ${btc} ]]; then
    goal=`echo "scale=2;${btc} * ${alarm} / 1" | bc -l`
fi

echo -e "${COLOR}[${DATE}] ${BOLD}Setting alarm mode to: ${simbol_utf8}
                    Setting alarm value to: R$ ${alarm}
                    Setting summary interval to: ${time_interval}s (${interval_min} min)
                    Setting goal value to: R$ ${goal}${STYLE_END}"

send_to_telegram "config" ${interval_min} ${btc}

START_TIME=$SECONDS

while [[ true ]]
do
    DATE=`date '+%d/%m/%y %H:%M:%S'`

    json_data=`curl -s "${api_ticker}"`

    if ! jq -e . >/dev/null 2>&1 <<<"${json_data}"; then
        echo -e "${COLOR}[${DATE}]${STYLE_END} Trying to get data"
        sleep 5
        continue
    fi

    high=`echo "${json_data}" | jq -r 'select(.high != null) | .high'`
    last=`echo "${json_data}" | jq -r 'select(.last != null) | .last'`
    low=`echo "${json_data}" | jq -r 'select(.low != null) | .low'`
    buy=`echo "${json_data}" | jq -r 'select(.buy != null) | .buy'`
    sell=`echo "${json_data}" | jq -r 'select(.sell != null) | .sell'`

    if [[ -z ${high} || -z ${last} || -z ${low} ]]; then
        echo -e "${COLOR}[${DATE}]${STYLE_END} Trying to get data"
        sleep 5
        continue
    fi

    if [[ ! -z ${btc} ]]; then
        btc_brl=`echo "(${btc} * (${total_percent} / 100)) * ${last}" | bc -l`
        btc_brl=`echo "scale=2;${btc_brl} / 1" | bc -l`
        mode_btc_brl="[R$ ${btc_brl}]"
    fi

    mask_last=`echo "scale=2;${last} / 1" | bc -l`

    if [[ ("${prev_last%.*}" -lt "${last%.*}" && ${descending} == false)
        || ("${prev_last%.*}" -gt "${last%.*}" && ${descending} == true) ]]; then
        mode_last="${mode_color}${simbol_utf8} R$ ${mask_last}${STYLE_END}"
        mode_btc_brl="${mode_color}${mode_btc_brl}${STYLE_END}"
    else
        mode_last="\xE2\xA4\xBA R$ ${mask_last}"
    fi

    echo -e "${COLOR}[${DATE}]${STYLE_END} ${mode_last} | \xE2\xA4\x93 R$ ${low} | \xE2\xA4\x92 R$ ${high} ${mode_btc_brl}"

    if [[ "${high%.*}" -eq "${last%.*}"
        && "${prev_high%.*}" -lt "${high%.*}" ]]; then
        send_to_telegram "update" "↗ High" ${last}
    elif [[ "${low%.*}" -eq "${last%.*}"
        && "${prev_low%.*}" -gt "${low%.*}" ]]; then
        send_to_telegram "update" "↘ Low" ${last}
    fi

    prev_high="${high}"
    prev_last="${last}"
    prev_low="${low}"

    if [[ ${alarm} -ne 0 ]]; then
        diff=`echo "${last%.*} - ${alarm%.*}" | bc`

        if [[ (${diff} -lt 0 && ${descending} == true)
            || (${diff} -gt 0 && ${descending} == false) ]]; then
            echo -e "${COLOR}${HEADER} ${DATE} ${HEADER}${STYLE_END}
            \n\t\t\t ${BOLD}[\xE2\x9C\x96] Value found: R$ ${last}${STYLE_END}
            \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
            \t\t ${UNDERLINE}https://foxbit.exchange/#trading${STYLE_END}
            \n${COLOR}${FOOTER}${STYLE_END}"

            if [[ -z ${mute} ]]; then
                play ${alarm_sound} 2> /dev/null
            fi

            send_to_telegram "alarm" ${total_percent} ${btc_brl}

            alarm=${last}

            echo -e "${COLOR}[${DATE}]${STYLE_END} ${mode_color}${action} alarm value to last: R$ ${alarm}${STYLE_END}"
        fi
    fi

    # Metrics for summary
    if [[ -z ${summary_low} ]]; then
        summary_high="${last}"
        summary_low="${last}"
    fi

    if [[ "${last%.*}" -gt "${summary_high%.*}" ]]; then
        summary_high="${last}"
    elif [[ "${last%.*}" -lt "${summary_low%.*}" ]]; then
        summary_low="${last}"
    fi

    duration=`echo "${SECONDS} - ${START_TIME}" | bc`

    if [[ ${duration} -ge ${time_interval} ]]; then
        send_to_telegram "summary" ${total_percent} ${btc_brl}
        summary_high="${last}"
        summary_low="${last}"
        START_TIME=$SECONDS
    fi
done
