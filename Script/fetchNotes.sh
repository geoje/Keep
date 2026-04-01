#!/usr/bin/env zsh

ACCESS_TOKEN=$(sqlite3 "$HOME/Library/Application Support/kr.ygh.keep/default.sqlite" \
  "SELECT ZACCESSTOKEN FROM ZACCOUNT WHERE ZACCESSTOKEN != '' ORDER BY Z_PK DESC LIMIT 1;")

BODY=$(cat <<EOF
{
  "nodes": [],
  "clientTimestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
  "requestHeader": {
    "clientSessionId": "s--$(( $(date +%s) * 1000 ))--$(( RANDOM * RANDOM % 4294967295 ))",
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
