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

    info=$1
	mode=$2
    data=$3

    case "${info}" in
        "config")
		msg="*New alarm ${mode}: R$ ${data}*"
		;;
        "update")
		msg="*${mode}: R$ ${data}*"
        ;;
    	"alarm")
		msg="*Alarm: R$ ${last} ${mode}*
		  Low: R$ ${low}
		 High: R$ ${high}
		  Buy: R$ ${buy}
		   Sell: R$ ${sell}
		https://foxbit.exchange/#trading"
		;;
	esac

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text=$"${msg}
\`${name}\`"
}
