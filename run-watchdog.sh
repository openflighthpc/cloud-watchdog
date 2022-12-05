#!/bin/bash

# Get directory of script for locating templates and config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $DIR/settings.sh

OUT=$(bash $DIR/watchdog.sh)

if [[ "$(echo "$OUT" |wc -l)" -eq "3" ]] ; then
    echo "No running systems to shut down"
    exit
fi

cat << EOF | curl --data @- -X POST -H "Authorization: Bearer $SLACK_TOKEN" -H 'Content-Type: application/json' https://slack.com/api/chat.postMessage >>/dev/null 2>&1
{
  		"text": "$OUT",
  		"channel": "$SLACK_CHANNEL",
  		"as_user": true
	}
EOF
