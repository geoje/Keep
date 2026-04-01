#!/usr/bin/env zsh

ACCESS_TOKEN=$(sqlite3 "$HOME/Library/Application Support/kr.ygh.keep/default.sqlite" \
  "SELECT ZACCESSTOKEN FROM ZACCOUNT WHERE ZACCESSTOKEN != '' ORDER BY Z_PK DESC LIMIT 1;")

COLORS=(RED ORANGE YELLOW GREEN TEAL CERULEAN BLUE PURPLE PINK BROWN GRAY)
COLOR=${COLORS[$((RANDOM % ${#COLORS[@]} + 1))]}

NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
TS_MS=$(( $(date +%s) * 1000 ))
NOTE_ID="${TS_MS}.$(( RANDOM * RANDOM % 9000000000 + 1000000000 ))"
LIST_ITEM_ID="sct.$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 12)"

TITLE=$(cat /usr/share/dict/words | sort -R | head -n 1)
TEXT=$(curl -s "https://lorem-api.com/api/lorem")

BODY=$(cat <<EOF
{
  "nodes": [
    {
      "id": "${NOTE_ID}",
      "kind": "notes#node",
      "type": "NOTE",
      "parentId": "root",
      "sortValue": $(( RANDOM * RANDOM % 9000000000 + 1000000000 )),
      "text": "",
      "title": "${TITLE}",
      "color": "${COLOR}",
      "isArchived": false,
      "isPinned": false,
      "timestamps": {
        "kind": "notes#timestamps",
        "created": "${NOW}",
        "updated": "${NOW}",
        "userEdited": "${NOW}"
      },
      "nodeSettings": {
        "newListItemPlacement": "BOTTOM",
        "graveyardState": "COLLAPSED",
        "checkedListItemsPolicy": "GRAVEYARD"
      },
      "annotationsGroup": {"kind": "notes#annotationsGroup"},
      "collaborators": []
    },
    {
      "id": "${LIST_ITEM_ID}",
      "kind": "notes#node",
      "type": "LIST_ITEM",
      "parentId": "${NOTE_ID}",
      "sortValue": $(( RANDOM * RANDOM % 9000000000 + 1000000000 )),
      "text": "${TEXT}",
      "checked": false,
      "timestamps": {
        "kind": "notes#timestamps",
        "created": "${NOW}",
        "updated": "${NOW}",
        "userEdited": "${NOW}"
      },
      "nodeSettings": {
        "newListItemPlacement": "BOTTOM",
        "graveyardState": "COLLAPSED",
        "checkedListItemsPolicy": "GRAVEYARD"
      },
      "annotationsGroup": {"kind": "notes#annotationsGroup"}
    }
  ],
  "clientTimestamp": "${NOW}",
  "requestHeader": {
    "clientSessionId": "s--${TS_MS}--$(( RANDOM * RANDOM % 4294967295 ))",
    "clientPlatform": "ANDROID",
    "clientVersion": {"major": "9", "minor": "9", "build": "9", "revision": "9"},
    "capabilities": [
      {"type": "NC"}, {"type": "PI"}, {"type": "LB"}, {"type": "AN"}, {"type": "SH"},
      {"type": "DR"}, {"type": "TR"}, {"type": "IN"}, {"type": "SNB"}, {"type": "MI"},
      {"type": "CO"}
    ]
  }
}
EOF
)

curl -s \
  -X POST "https://www.googleapis.com/notes/v1/changes" \
  -H "Authorization: OAuth ${ACCESS_TOKEN}" \
  -H "Accept-Encoding: gzip, deflate" \
  -H "Content-Type: application/json" \
  -H "User-Agent: github.com/geoje/keep" \
  --compressed \
  -d "${BODY}" | jq .
