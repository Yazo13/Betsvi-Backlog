#!/usr/bin/env bash
# ამოწმებს ბეწვის საიტსა და API-ს, უმატებს ხაზს status/uptime.csv-ს და
# ამზადებს ორ ფრაგმენტს, რომლებსაც workflow status/README.md-ში ჩასვამს.
set -uo pipefail

CSV="status/uptime.csv"
OUT="${RUNNER_TEMP:-/tmp}"
mkdir -p status
[ -f "$CSV" ] || echo "timestamp_utc,target,status,expected,ok,seconds" > "$CSV"

# სახელი|მისამართი|მოსალოდნელი სტატუსი
TARGETS=(
  "site|https://www.betsvi.ge/|200"
  "api|https://api.betsvi.ge/api/Announcements/active|401"
)

now=$(date -u +"%Y-%m-%d %H:%M")

for entry in "${TARGETS[@]}"; do
  IFS='|' read -r name url expected <<< "$entry"

  read -r code secs <<< "$(curl -s -o /dev/null -w '%{http_code} %{time_total}' \
    --max-time 40 "$url" 2>/dev/null || echo '000 0')"

  if [ "$code" = "$expected" ]; then ok="yes"; else ok="no"; fi
  echo "$now,$name,$code,$expected,$ok,$secs" >> "$CSV"
  echo "$name -> $code (expected $expected) in ${secs}s"
done

# ── ბოლო 14 შემოწმება ──────────────────────────────────────────────────────
{
  echo "| დრო (UTC) | რა | სტატუსი | წამი | OK |"
  echo "|---|---|---|---|---|"
  tail -n +2 "$CSV" | tail -28 | tac | while IFS=, read -r ts name code exp ok secs; do
    mark="yes"; [ "$ok" = "no" ] && mark="**NO**"
    printf "| %s | %s | %s | %s | %s |\n" "$ts" "$name" "$code" "$secs" "$mark"
  done
} > "$OUT/recent.md"

total=$(tail -n +2 "$CSV" | wc -l | tr -d ' ')
good=$(tail -n +2 "$CSV" | awk -F, '$5=="yes"' | wc -l | tr -d ' ')
slow=$(tail -n +2 "$CSV" | awk -F, '$6+0 > 3' | wc -l | tr -d ' ')

{
  echo "- შემოწმება სულ: **$total**"
  echo "- წარმატებული: **$good**"
  echo "- 3 წამზე ნელი პასუხი: **$slow**"
} > "$OUT/summary.md"
