#!/bin/bash
source api_config.txt

send_to_telegram()
{
	if [[ (-z ${telegram_token}) || (-z ${telegram_chat_id}) ]]; then
        return 0
    fi

    if [[ -z ${name} ]]; then
        name=`hostname`
    fi

    data=$1
    custom_data=$2

    case "${data}" in
        "config")
		msg="*New alarm ${simbol} (${interval_min} min)
		R$ ${alarm}*"
		;;
        "update")
		msg="*${custom_data}: R$ ${last}*"
        ;;
    	"alarm")
		msg="*Alarm: R$ ${last} ${simbol}*
		  Low: R$ ${low}
		 High: R$ ${high}
		  Buy: R$ ${buy}
		   Sell: R$ ${sell}
		https://foxbit.exchange/#trading"
		;;
        "summary")
        msg="*Summary of ${custom_data} min (${duration}s)*
		 Low: R$ ${period_low}
		High: R$ ${period_high}
		 Last: R$ ${last}"
        ;;
	esac

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text=$"${msg}
\`${name}\`"
}
