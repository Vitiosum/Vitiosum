#!/usr/bin/env bash
# Rebuilds README.md from demos.tsv, three demos per row.
# A demo without a thumbnail gets one from its social preview:
#   social-preview.sh <local clone> <out.jpg>, then 640×320.
set -euo pipefail
cd "$(dirname "$0")/.."
DEMOS_DIR=${DEMOS_DIR:-$HOME/ClaudeByVitio}
KIT=${KIT:-$DEMOS_DIR/docs/superpowers/brand-kit}
GH=https://github.com/Vitiosum

thumb() {
  local out="assets/$1.jpg" tmp
  [[ -f $out ]] && return
  tmp=$(mktemp -d)
  bash "$KIT/social-preview.sh" "$DEMOS_DIR/$1" "$tmp/full.jpg"
  magick "$tmp/full.jpg" -resize 640x320 -strip -quality 80 "$out"
  rm -rf "$tmp"
}

gallery() {
  local section="" n=0 sec repo line
  while IFS=$'\t' read -r sec repo line; do
    thumb "$repo"
    if [[ $sec != "$section" ]]; then
      [[ -n $section ]] && printf '</tr>\n</table>\n\n'
      printf '### %s\n\n<table>\n<tr>\n' "$sec"
      section=$sec; n=0
    elif (( n % 3 == 0 )); then
      printf '</tr>\n<tr>\n'
    fi
    printf '<td width="33%%" valign="top"><a href="%s/%s"><img src="assets/%s.jpg" alt="%s"></a><br><a href="%s/%s"><b>%s</b></a><br><sub>%s</sub></td>\n' \
      "$GH" "$repo" "$repo" "$repo" "$GH" "$repo" "$repo" "$line"
    n=$((n + 1))
  done < <(tail -n +2 demos.tsv)
  printf '</tr>\n</table>\n'
}

{
  cat <<'EOF'
<a href="https://www.clever.cloud"><img src="assets/banner.jpg" alt="Clever Cloud demos: runnable apps, one world each" width="100%"></a>

Runnable apps that show what [Clever Cloud](https://www.clever.cloud) does, one world per demo: an aquarium for the Go runtime, a control tower for Rust and PostgreSQL, a border post for Keycloak.

Every repo follows the same form:

- desktop and phone screenshots of the app running;
- **Run it yourself**: deploy it on your own Clever Cloud organization with [clever-tools](https://github.com/CleverCloud/clever-tools) in a few commands;
- the variables, the routes and a short code tour;
- the page itself shows what the platform is doing: instance, add-on, network.

EOF
  gallery
  cat <<'EOF'

### Agent skills

- [**land-on-clever-cloud**](https://github.com/Vitiosum/land-on-clever-cloud): migrate an app from Heroku, Vercel, Supabase, docker-compose or a VM to Clever Cloud, with Claude Code or Codex.
- [**clever-tools-skill**](https://github.com/Vitiosum/clever-tools-skill): deploy, configure and diagnose an app on Clever Cloud with clever-tools.

### Also running on Clever Cloud

- [**clash-royale-advisor**](https://github.com/Vitiosum/clash-royale-advisor): a Clash Royale deck advisor on Next.js, PostgreSQL and Redis.
EOF
} > README.md
echo "README.md: $(tail -n +2 demos.tsv | wc -l | tr -d ' ') demos"
