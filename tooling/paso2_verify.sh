#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-http://localhost:3000}"

echo "== Admin login =="
ADMIN_TOKEN=$(curl -s -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d '{"email":"admin@zylo.fm","password":"admin123456"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')

echo "== Register DJ =="
DJ_EMAIL="dj_test_$(date +%s)@zylo.fm"
DJ_PASSWORD='djpassword123'
DJ_REGISTER_RESP=$(curl -s -X POST "$BASE/auth/register" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$DJ_EMAIL\",\"password\":\"$DJ_PASSWORD\",\"displayName\":\"DJ Test\"}")

DJ_TOKEN=$(echo "$DJ_REGISTER_RESP" | python3 -c 'import sys,json
try:
  print(json.load(sys.stdin).get("access_token", ""))
except Exception:
  print("")')

if [[ -z "$DJ_TOKEN" ]]; then
  echo "REGISTER_FAILED"
  echo "$DJ_REGISTER_RESP" | head -c 600
  echo
  exit 1
fi

DJ_ID=$(curl -s "$BASE/dj/me" -H "Authorization: Bearer $DJ_TOKEN" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

echo "== Approve DJ =="
curl -s -X POST "$BASE/admin/djs/$DJ_ID/approve" -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null

echo "== Create tiny WAV =="
python3 -c 'import wave,struct; p="/tmp/zylo_test.wav"; w=wave.open(p,"w"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(44100); w.writeframes(b"".join(struct.pack("<hh",0,0) for _ in range(44100))); w.close(); print(p)'

COVER="/Users/jbmusic/Desktop/Zylo APP/zylo_fm_app/web/favicon.png"

echo "== Upload mix (expects Cloudinary URLs) =="
HTTP=$(curl -s -o /tmp/zylo_upload_body.json -w "%{http_code}" -X POST "$BASE/mixes/upload" \
  -H "Authorization: Bearer $DJ_TOKEN" \
  -F "audio=@/tmp/zylo_test.wav" \
  -F "cover=@$COVER" \
  -F "title=Cloudinary E2E Test" \
  -F "description=auto" \
  -F "genre=Test" \
  -F "isClean=true")

echo "HTTP=$HTTP"
cat /tmp/zylo_upload_body.json

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  echo
  echo "UPLOAD_FAILED"
  exit 1
fi

AUDIO_URL=$(cat /tmp/zylo_upload_body.json | python3 -c 'import sys,json; print(json.load(sys.stdin).get("audioUrl",""))')
COVER_URL=$(cat /tmp/zylo_upload_body.json | python3 -c 'import sys,json; print(json.load(sys.stdin).get("coverUrl",""))')

if [[ "$AUDIO_URL" != https://res.cloudinary.com/* || "$COVER_URL" != https://res.cloudinary.com/* ]]; then
  echo
  echo "NOT_CLOUDINARY_URLS"
  echo "audioUrl=$AUDIO_URL"
  echo "coverUrl=$COVER_URL"
  exit 1
fi

STATUS=$(cat /tmp/zylo_upload_body.json | python3 -c 'import sys,json; print(json.load(sys.stdin).get("status",""))')
if [[ "$STATUS" != "pending" ]]; then
  echo
  echo "EXPECTED_PENDING_STATUS"
  echo "status=$STATUS"
  exit 1
fi

echo "== List pending (admin) =="
PENDING=$(curl -s "$BASE/mixes/pending" -H "Authorization: Bearer $ADMIN_TOKEN")
echo "$PENDING" | python3 -c 'import sys,json; data=json.load(sys.stdin); print("pending_count", len(data))'

MIX_ID=$(echo "$PENDING" | python3 -c 'import sys,json; data=json.load(sys.stdin); print(data[0]["id"] if data else "")')
if [[ -z "$MIX_ID" ]]; then
  echo "NO_PENDING_MIX"
  exit 2
fi

echo "== Approve mix =="
curl -s -X POST "$BASE/admin/mixes/$MIX_ID/approve" -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null

echo "== Public mixes =="
PUBLIC=$(curl -s "$BASE/mixes/public")
echo "$PUBLIC" | python3 -c 'import sys,json; data=json.load(sys.stdin); print("public_count", len(data))'
FOUND=$(echo "$PUBLIC" | python3 -c 'import sys,json; data=json.load(sys.stdin); import os; mid=os.environ.get("MID"); print("found", any(m.get("id")==mid for m in data))' MID="$MIX_ID")
echo "$FOUND"

echo
echo "PASO_4_OK"
