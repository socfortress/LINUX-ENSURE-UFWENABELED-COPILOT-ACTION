#!/bin/sh
set -eu

ScriptName="Check-Firewall-Status"
LogPath="/tmp/${ScriptName}-script.log"
ARLog="/var/ossec/logs/active-responses.log"
LogMaxKB=100
LogKeep=5
HostName="$(hostname)"
runStart=$(date +%s)

WriteLog() {
  Message="$1"; Level="${2:-INFO}"
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  line="[$ts][$Level] $Message"
  case "$Level" in
    ERROR) printf '\033[31m%s\033[0m\n' "$line" >&2 ;;
    WARN)  printf '\033[33m%s\033[0m\n' "$line" >&2 ;;
    DEBUG) [ "${VERBOSE:-0}" -eq 1 ] && printf '%s\n' "$line" >&2 ;;
    *)     printf '%s\n' "$line" >&2 ;;
  esac
  printf '%s\n' "$line" >> "$LogPath"
}

RotateLog() {
  [ -f "$LogPath" ] || return 0
  size_kb=$(du -k "$LogPath" | awk '{print $1}')
  [ "$size_kb" -le "$LogMaxKB" ] && return 0
  i=$((LogKeep-1))
  while [ $i -ge 0 ]; do
    [ -f "$LogPath.$i" ] && mv -f "$LogPath.$i" "$LogPath.$((i+1))"
    i=$((i-1))
  done
  mv -f "$LogPath" "$LogPath.1"
}

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
escape_json() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

BeginNDJSON(){ TMP_AR="$(mktemp)"; }
AddRecord(){
  ts="$(iso_now)"; profile="$1"; enabled="$2"; logging="$3"
  printf '{"timestamp":"%s","host":"%s","action":"%s","copilot_action":true,"profile":"%s","enabled":%s,"logging":%s}\n' \
    "$ts" "$HostName" "$ScriptName" "$(escape_json "$profile")" "$enabled" "$logging" >> "$TMP_AR"
}
AddStatus(){
  ts="$(iso_now)"; st="${1:-info}"; msg="$(escape_json "${2:-}")"
  printf '{"timestamp":"%s","host":"%s","action":"%s","copilot_action":true,"status":"%s","message":"%s"}\n' \
    "$ts" "$HostName" "$ScriptName" "$st" "$msg" >> "$TMP_AR"
}

CommitNDJSON(){
  [ -s "$TMP_AR" ] || AddStatus "no_results" "no firewall profiles detected"
  AR_DIR="$(dirname "$ARLog")"
  [ -d "$AR_DIR" ] || WriteLog "Directory missing: $AR_DIR (will attempt write anyway)" WARN
  if mv -f "$TMP_AR" "$ARLog"; then
    WriteLog "Wrote NDJSON to $ARLog" INFO
  else
    WriteLog "Primary write FAILED to $ARLog" WARN
    if mv -f "$TMP_AR" "$ARLog.new"; then
      WriteLog "Wrote NDJSON to $ARLog.new (fallback)" WARN
    else
      keep="/tmp/active-responses.$$.ndjson"
      cp -f "$TMP_AR" "$keep" 2>/dev/null || true
      WriteLog "Failed to write both $ARLog and $ARLog.new; saved $keep" ERROR
      rm -f "$TMP_AR" 2>/dev/null || true
      exit 1
    fi
  fi
  for p in "$ARLog" "$ARLog.new"; do
    if [ -f "$p" ]; then
      sz=$(wc -c < "$p" 2>/dev/null || echo 0)
      ino=$(ls -li "$p" 2>/dev/null | awk '{print $1}')
      head1=$(head -n1 "$p" 2>/dev/null || true)
      WriteLog "VERIFY: path=$p inode=$ino size=${sz}B first_line=${head1:-<empty>}" INFO
    fi
  done
}

RotateLog
WriteLog "=== SCRIPT START : $ScriptName (host=$HostName) ==="
BeginNDJSON

if command -v ufw >/dev/null 2>&1; then
  status="$(ufw status verbose 2>/dev/null || true)"
  case "$status" in
    *inactive*) enabled=false ;;
    *active*)   enabled=true ;;
    *)          enabled=false ;;
  esac
  if printf '%s\n' "$status" | grep -qi "Logging: on"; then
    logging=true
  else
    logging=false
  fi
  AddRecord "ufw" "$enabled" "$logging"
else
  AddStatus "error" "ufw not installed"
fi

CommitNDJSON
dur=$(( $(date +%s) - runStart ))
WriteLog "=== SCRIPT END : ${dur}s ==="
