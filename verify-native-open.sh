#!/bin/bash
set -euo pipefail
phase=${1:?before or after}
validation_dir=/home/omarchy/validation-clipboard
touch "$validation_dir/open-start-$phase"
wtype -M alt -k Return -m alt

for attempt in {1..100}; do
  if hyprctl -j clients | jq -e '.[] | select(.class == "org.omarchy.nvim")' >/dev/null; then
    break
  fi
  sleep 0.2
done
hyprctl -j clients | jq -e '.[] | select(.class == "org.omarchy.nvim")' >/dev/null
mapfile -d '' -t opened < <(find "$HOME/.local/state/omarchy/clipboard-open" -maxdepth 1 -type f -newer "$validation_dir/open-start-$phase" -print0)
(( ${#opened[@]} == 1 ))
cp "${opened[0]}" "$validation_dir/$phase.txt"
printf 'Native clipboard Alt+Enter: %s\n' "${phase^^}"
printf 'Expected bytes: %s\n' "$(wc -c <"$validation_dir/expected.txt")"
printf 'Editor file bytes: %s\n' "$(wc -c <"$validation_dir/$phase.txt")"
printf 'File bytes (hex):\n'
od -An -tx1 "$validation_dir/$phase.txt"
if [[ $phase == "before" ]]; then
  ! cmp -s "$validation_dir/expected.txt" "$validation_dir/$phase.txt"
else
  cmp "$validation_dir/expected.txt" "$validation_dir/$phase.txt"
fi
hyprctl -j clients | jq -c '[.[] | select(.class == "org.omarchy.nvim") | {class,title,pid,address}]'
touch "$validation_dir/open-ready-$phase"
