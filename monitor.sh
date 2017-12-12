#!/bin/bash

while getopts "v:" opt; do
    case $opt in
        v) alarm="${OPTARG}"
        ;;
        \?) echo "-v <alarm_value>"
            exit
        ;;
    esac
done

# Requirements
if [ `dpkg-query -l jq | echo $?` -ne 0 ]; then
    sudo apt-get install jq
fi

if [ `dpkg-query -l sox | echo $?` -ne 0 ]; then
    sudo apt-get install sox
fi

bold="\033[1m"
underline="\033[4m"
tag_end="\033[0m"

# Validate optargs
if [[ "${alarm}" -gt 0 ]]; then
    DATE=`date '+%d/%m/%Y %H:%M:%S'`
    echo -e "${bold}[${DATE}] Setting alarm value to: R$ ${alarm}${tag_end}" 
fi

file="media/alarm.wav"

header="#############################"
footer="###############################################################################"

while [[ true ]]
do
    DATE=`date '+%d/%m/%Y %H:%M:%S'`

    foxbit=`curl -s -X GET "https://api.blinktrade.com/api/v1/BRL/ticker"`

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

    echo "[${DATE}] Last: R$ ${last} | Low: R$ ${low} | High: R$ ${high}"

    diff=$(echo "${last%.*} - ${alarm%.*}" | bc)

    if [[ ${diff} -lt 0 ]]; then
        echo -e "${bold}${header} ${DATE} ${header}${tag_end}
        \n\t\t\t ${bold}[X] Value found: R$ ${last}${tag_end}
        \t\t [i] Buy: R$ ${buy} | Sell: R$ ${sell}
        \t\t ${underline}https://foxbit.exchange/#trading${tag_end}
        \n${bold}${footer}${tag_end}"

        play ${file} 2> /dev/null

        alarm=${last}

        echo -e "${bold}[${DATE}] Decreasing alarm value to last: R$ ${alarm}${tag_end}"       
    fi
done
