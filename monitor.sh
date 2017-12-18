#!/bin/bash
source telegram_api.sh

while getopts "v:adn:" opt; do
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
        \?) echo "-v <alarm_value> -a -d -n <instance_name>"
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

sound="media/alarm.wav"
header="###############################"
footer="###################################################################################"
bold="\033[1m"
underline="\033[4m"
tag_end="\033[0m"

DATE=`date '+%d/%m/%y %H:%M:%S'`

echo -e "${bold}[${DATE}] Setting alarm mode to: ${simbol_utf8}${tag_end}"

echo -e "${bold}[${DATE}] Setting alarm value to: R$ ${alarm}${tag_end}"

send_to_telegram "config" "${simbol}" "${alarm}"

while [[ true ]]
do
    DATE=`date '+%d/%m/%y %H:%M:%S'`

    foxbit=`curl -s "https://api.blinktrade.com/api/v1/BRL/ticker"`

    if ! jq -e . >/dev/null 2>&1 <<<"${foxbit}"; then
        echo "[${DATE}] Trying to get data"
        sleep 10
        continue
    fi

    high=`echo "${foxbit}" | jq '.high'`
    last=`echo "${foxbit}" | jq '.last'`
    low=`echo "${foxbit}" | jq '.low'`
    buy=`echo "${foxbit}" | jq '.buy'`
    sell=`echo "${foxbit}" | jq '.sell'`

    mode_last="Last: R$ ${last}"

    if [[ "${last_prev%.*}" -lt "${last%.*}" && ${descending} == false ]]; then
        mode_last="${bold}${mode_last} ${simbol_utf8}${tag_end}"
    elif [[ "${last_prev%.*}" -gt "${last%.*}" && ${descending} == true ]]; then
        mode_last="${bold}${mode_last} ${simbol_utf8}${tag_end}"
    fi

    echo -e "[${DATE}] ${mode_last} | Low: R$ ${low} | High: R$ ${high}"

    if [[ "${high_prev%.*}" -lt "${last%.*}" && "${high_prev%.*}" -gt 0 ]]; then
        send_to_telegram "update" "↗ High" "${last}"
    elif [[ "${low_prev%.*}" -gt "${last%.*}" ]]; then
        send_to_telegram "update" "↘ Low" "${last}"
    fi

    high_prev=`echo "${high%.*}" | bc`
    last_prev=`echo "${last%.*}" | bc`
    low_prev=`echo "${low%.*}" | bc`

    diff=`echo "${last%.*} - ${alarm%.*}" | bc`

    if [[ (${diff} -lt 0 && ${descending} == true) || (${diff} -gt 0 && ${descending} == false) ]]; then
        echo -e "${bold}${header} ${DATE} ${header}${tag_end}
        \n\t\t\t ${bold}[X] Value found: R$ ${last}${tag_end}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${underline}https://foxbit.exchange/#trading${tag_end}
        \n${bold}${footer}${tag_end}"

        play ${sound} 2> /dev/null

        send_to_telegram "alarm" "${simbol}" "${foxbit}"

        alarm=${last}

        echo -e "${bold}[${DATE}] ${action} alarm value to last: R$ ${alarm}${tag_end}"
    fi
done
