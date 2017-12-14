#!/bin/bash

send_to_telegram()
{
    text=$1

    curl -s --output /dev/null -X POST \
    https://api.telegram.org/bot${telegram_token}/sendMessage \
    -d chat_id=${telegram_chat_id} -d parse_mode="Markdown" \
    -d text="${text}"
}
