#!/bin/bash
source api_config.txt

while getopts "v:ad" opt; do
    case $opt in
        a) mode="Ascending"
           descending=false
           action="Increasing"
        ;;
        d) mode="Descending"
           descending=true
           action="Decreasing"
        ;;
        v) alarm="${OPTARG}"
           previous="${alarm}"
        ;;
        \?) echo "-v <alarm_value> -a -d"
            exit
        ;;
    esac
done

bold="\033[1m"
underline="\033[4m"
tag_end="\033[0m"

# Validate optargs
if [[ -z "${action}" ]]; then
    echo "Choose one option: -a (Ascending) -d (Descending)"
    exit 1
fi

DATE=`date '+%d/%m/%Y %H:%M:%S'`

echo -e "${bold}[${DATE}] Setting alarm mode to: ${mode}${tag_end}"

if [[ "${alarm}" -gt 0 ]]; then
    echo -e "${bold}[${DATE}] Setting alarm value to: R$ ${alarm}${tag_end}"
fi

file="media/alarm.wav"

header="###############################"
footer="###################################################################################"

while [[ true ]]
do
    DATE=`date '+%d/%m/%Y %H:%M:%S'`

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

    # Calculate inital alarm value
    if [[ "${alarm%.*}" -eq 0 ]]; then
        d1=$(echo "${high%.*} - ${last%.*}" | bc)
        d2=$(echo "${last%.*} - ${low%.*}" | bc)

        alarm=$([ ${d1} -le ${d2} ] \
        && echo "${last%.*} - ${d1%.*}" \
        || echo "${last%.*} - ${d2%.*}")

        alarm=$(echo "${alarm%.*}" | bc)

        echo -e "${bold}[${DATE}] Setting alarm value to: R$ ${alarm}${tag_end}"  
    fi

    if [[ "${previous%.*}" -lt "${last%.*}" ]]; then
        direction="${bold}[+]${tag_end}"
    elif [[ "${previous%.*}" -gt "${last%.*}" ]]; then
        direction="${bold}[-]${tag_end}"
    else
        direction="${bold}[=]${tag_end}"
    fi

    echo -e "[${DATE}] ${direction} Last: R$ ${last} | Low: R$ ${low} | High: R$ ${high}"

    previous=$(echo "${last%.*}" | bc)

    diff=$(echo "${last%.*} - ${alarm%.*}" | bc)

    if [[ (${diff} -lt 0 && ${descending} == true) || (${diff} -gt 0 && ${descending} == false) ]]; then
        echo -e "${bold}${header} ${DATE} ${header}${tag_end}
        \n\t\t\t ${bold}[X] Value found: R$ ${last}${tag_end}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${underline}https://foxbit.exchange/#trading${tag_end}
        \n${bold}${footer}${tag_end}"

        play ${file} 2> /dev/null

        if [[ (! -z ${telegram_token}) && (! -z ${telegram_chat_id}) ]]; then
            telegram_text="Alarm mode: \`${mode}\`  Value found: *R$ ${last}*
	             Buy: *R$ ${buy}*
	             Sell: *R$ ${sell}*
		     https://foxbit.exchange/#trading"

            curl -s --output /dev/null -X POST \
            https://api.telegram.org/bot${telegram_token}/sendMessage \
            -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
            -d text="${telegram_text}"
        fi

        alarm=${last}

        echo -e "${bold}[${DATE}] ${action} alarm value to last: R$ ${alarm}${tag_end}"
    fi
done
