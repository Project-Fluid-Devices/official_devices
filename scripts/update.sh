#!/bin/bash

set +e

send_message() {
	curl -s -X POST https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage -d chat_id="$1" -d text="$(printf "$2")"
}

syntax_check() {
	for json in $CHANGED_JSONS; do
		jq . $json
		if [ "$?" = 0 ]; then
			send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "$json has passed the syntax test"
		else
			send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "$json has failed the syntax test"; SYNTAX_CHECK_RESULT="failed"
		fi
	done
	if [ "$SYNTAX_CHECK_RESULT" = "" ]; then
		SYNTAX_CHECK_RESULT="success"
	fi
}

sudo apt-get update
sudo apt-get install -y jq

send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "Fluid CI\nFound a new commit\n\nFirst step: Checking changed JSONs"

CHANGED_JSONS="$(git diff --name-only HEAD~1 . | grep *.json)"

if [ "$CHANGED_JSONS" = "" ]; then
	send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "No JSON has been added or changed!"
else
	syntax_check
	if [ "$SYNTAX_CHECK_RESULT" != "failed" ]; then
		send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "All modified JSONs are correct!"
	else
		send_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "There's a bad JSONs!\nIt needs to be fixed ASAP\n@SebaUbuntu kill whoever did this commit and fix it"
	fi
fi
