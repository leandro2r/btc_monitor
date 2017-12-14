#!/bin/bash
source api_config.txt

send_to_telegram()
{
	if [[ (-z ${telegram_token}) || (-z ${telegram_chat_id}) ]]; then
        return 0
    fi

    info_type=$1
	mode=$2
    data=$3

    name=`hostname`

    title="\`${name}\`
Alarm mode: *${mode}*"

    case "${info_type}" in
		"config")
			msg="${title}
 Alarm value: *R$ ${data}*"
		;;
    	"alarm")
			msg="${title}
 Value found: *R$ ${last}*
		             Buy: *R$ ${buy}*
		             Sell: *R$ ${sell}*
			     https://foxbit.exchange/#trading"
		;;
	esac

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text="${msg}"
}
