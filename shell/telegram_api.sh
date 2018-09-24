#!/bin/bash

send_to_telegram()
{
    if [[ (-z ${telegram_token}) || (-z ${telegram_chat_id}) 
           || (! -z ${mute}) ]]; then
        return 0
    fi

    if [[ -z ${name} ]]; then
        name=`hostname`
    fi

    case $1 in
        "config")
            msg="New alarm ${simbol} (${interval_min} min)\
                 %0A${currency} ${alarm}"

            if [[ ! -z ${btc} ]]; then
                msg+="%0ABTC ${btc}"
            fi

            msg="*${msg}*"
        ;;
        "update")
            msg="*$2: ${currency} ${last}*"
        ;;
        "alarm")
            msg="*Alarm: ${currency} ${last} ${simbol}*\
                 %0A   Buy: ${currency} ${buy}\
                 %0A   Sell: ${currency} ${sell}"

            if [[ ! -z ${btc_brl} ]]; then
                msg+="%0A*Price: ${currency} ${btc_brl}* (${percent_total}%)"
            fi
        ;;
        "summary")
            msg="*Summary of ${interval_min} min (${duration}s)*\
                %0A Low: ${currency} ${summary_low}\
                %0AHigh: ${currency} ${summary_high}\
                %0A Last: ${currency} ${last}"

            if [[ ! -z ${btc_brl} ]]; then
                msg+="%0APrice: ${currency} ${btc_brl} (${percent_total}%)"
            fi
        ;;
    esac

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text=$"${msg}%0A\`${name}\`"
}
