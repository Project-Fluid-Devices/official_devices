#!/bin/bash

set +e
sudo apt-get update > /dev/null
sudo apt-get install -y jq > /dev/null

edit_ci_message() {
	MESSAGE_TEXT="$MESSAGE_TEXT
$1"
	curl -s -X POST https://api.telegram.org/bot$TG_BOT_TOKEN/editMessageText \
		-d chat_id="$TG_FLUID_MAINTAINERS_CHAT_ID" -d message_id="$MESSAGE_ID" -d text="FluidCI
New commit has been pushed ($LAST_COMMIT)
$MESSAGE_TEXT"
}

LAST_COMMIT=$(git rev-parse --short HEAD)

MESSAGE_ID=$(curl -s -X POST https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage -d chat_id="$TG_FLUID_MAINTAINERS_CHAT_ID" -d text="FluidCI started" | jq .result.message_id)

edit_ci_message "First step: Checking changed JSONs"

CHANGED_JSONS="$(git diff --name-only HEAD~1 . | grep *.json)"
if [ "$CHANGED_JSONS" = "" ]; then
	edit_ci_message "No JSON has been added or changed!"
	exit
else
	for json in $CHANGED_JSONS; do
		jq . $json
		if [ "$?" = 0 ]; then
			edit_ci_message "$json has passed the syntax test"
		else
			edit_ci_message "$json has failed the syntax test"
			SYNTAX_CHECK_RESULT="failed"
		fi
	done
	if [ "$SYNTAX_CHECK_RESULT" != "failed" ]; then
		edit_ci_message "All modified JSONs are correct!"
	else
		edit_ci_message "$TG_FLUID_MAINTAINERS_CHAT_ID" "There's a bad JSONs! @SebaUbuntu kill whoever did this commit and fix it"
		exit
	fi
fi
