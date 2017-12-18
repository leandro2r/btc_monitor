#!/bin/bash
source telegram_api.sh

while getopts "v:adn:i:" opt; do
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

if [[ -z ${period_interval} ]]; then
    # Default value: 30min
    period_interval=1800
fi

sound="media/alarm.wav"
header="###############################"
footer="###################################################################################"
bold="\033[1m"
underline="\033[4m"
tag_end="\033[0m"

DATE=`date '+%d/%m/%y %H:%M:%S'`
interval_min=`echo "${period_interval} / 60" | bc`

echo -e "${bold}[${DATE}] Setting alarm mode to: ${simbol_utf8}
                    Setting alarm value to: R$ ${alarm}
                    Setting summary interval to: ${period_interval}s (${interval_min} min)${tag_end}"

send_to_telegram "config"

START_TIME=$SECONDS

while [[ true ]]
do
    DATE=`date '+%d/%m/%y %H:%M:%S'`

    json_data=`curl -s "https://api.blinktrade.com/api/v1/BRL/ticker"`

    if ! jq -e . >/dev/null 2>&1 <<<"${json_data}"; then
        echo "[${DATE}] Trying to get data"
        sleep 10
        continue
    fi

    high=`echo "${json_data}" | jq '.high'`
    last=`echo "${json_data}" | jq '.last'`
    low=`echo "${json_data}" | jq '.low'`
    buy=`echo "${json_data}" | jq '.buy'`
    sell=`echo "${json_data}" | jq '.sell'`

    mode_last="Last: R$ ${last}"

    if [[ "${last_prev%.*}" -lt "${last%.*}" && ${descending} == false ]]; then
        mode_last="${bold}${mode_last} ${simbol_utf8}${tag_end}"
    elif [[ "${last_prev%.*}" -gt "${last%.*}" && ${descending} == true ]]; then
        mode_last="${bold}${mode_last} ${simbol_utf8}${tag_end}"
    fi

    echo -e "[${DATE}] ${mode_last} | Low: R$ ${low} | High: R$ ${high}"

    if [[ "${high_prev%.*}" -lt "${last%.*}" && "${high_prev%.*}" -gt 0 ]]; then
        send_to_telegram "update" "↗ High"
    elif [[ "${low_prev%.*}" -gt "${last%.*}" ]]; then
        send_to_telegram "update" "↘ Low"
    fi

    high_prev="${high%.*}"
    last_prev="${last%.*}"
    low_prev="${low%.*}"

    diff=`echo "${last%.*} - ${alarm%.*}" | bc`

    if [[ (${diff} -lt 0 && ${descending} == true) 
        || (${diff} -gt 0 && ${descending} == false) ]]; then
        echo -e "${bold}${header} ${DATE} ${header}${tag_end}
        \n\t\t\t ${bold}[X] Value found: R$ ${last}${tag_end}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${underline}https://foxbit.exchange/#trading${tag_end}
        \n${bold}${footer}${tag_end}"

        play ${sound} 2> /dev/null

        send_to_telegram "alarm"

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
        send_to_telegram "summary" `echo "${duration} / 60" | bc`
        period_high="${last}"
        period_low="${last}"
        START_TIME=$SECONDS
    fi
done
