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

    data=$1
    custom_data=$2
    value=$3

    case "${data}" in
        "config")
		msg="New alarm ${simbol} (${custom_data} min)
		   R$ ${alarm}"
        if [[ ! -z ${value} ]]; then
            msg="${msg}
  BTC ${value}"
        fi
        if [[ ! -z ${goal} ]]; then
            msg="${msg}
◉ R$ ${goal}"
        fi
        msg="*${msg}*"
		;;
        "update")
		msg="*${custom_data}: R$ ${value}*"
        ;;
    	"alarm")
		msg="*Alarm: R$ ${last} ${simbol}*
		  Buy: R$ ${buy}
		  Sell: R$ ${sell}"
        if [[ ! -z ${value} ]]; then
            msg="${msg}
	*Value: R$ ${value}* (${custom_data}%)"
        fi
        msg="${msg} https://foxbit.exchange/#trading"
		;;
        "summary")
        msg="*Summary of ${interval_min} min (${duration}s)*
		 Low: R$ ${summary_low}
		High: R$ ${summary_high}
		 Last: R$ ${last}"
        if [[ ! -z ${value} ]]; then
            msg="${msg}
	Value: R$ ${value} (${custom_data}%)"
        fi
        msg="${msg}
◉ R$ ${alarm}"
        if [[ ! -z ${goal} ]]; then
            msg="${msg} (R$ ${goal})"
        fi
        ;;
	esac

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text=$"${msg}
\`${name}\`"
}
