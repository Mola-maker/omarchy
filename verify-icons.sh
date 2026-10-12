#!/bin/bash
set -euo pipefail

phase=${1:?before or after}
validation_dir=/home/omarchy/validation
case $phase in
  before) remover="$validation_dir/bin/omarchy-webapp-remove-original" ;;
  after) remover="$validation_dir/bin/omarchy-webapp-remove-candidate" ;;
  *) exit 2 ;;
esac

icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
app_dir="$HOME/.local/share/applications"
mkdir -p "$validation_dir/fixtures" "$icon_dir"

printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' |
  base64 -d >"$validation_dir/fixtures/icon.png"
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" rx="12" fill="#3288dd"/></svg>' >"$validation_dir/fixtures/icon.svg"
cat >"$validation_dir/fixtures/icon.xpm" <<'XPM'
/* XPM */
static char *icon[] = {"1 1 1 1", "b c blue", "b"};
XPM

printf 'Omarchy web app icon cleanup: %s\n' "${phase^^}"
printf 'Kernel: %s\n' "$(uname -r)"
pacman -Q omarchy-dev git gtk3 desktop-file-utils 2>/dev/null
printf '\nReal install and remove commands, no command stubs\n'

remaining=0
for extension in png svg xpm; do
  name="Omarchy Icon Check $extension"
  icon_file="$icon_dir/omarchy-icon-check-$extension.$extension"
  neighbor="$icon_dir/omarchy-icon-check-$extension-neighbor.$extension"
  cp "$validation_dir/fixtures/icon.$extension" "$neighbor"

  omarchy webapp install "$name" https://example.com "$validation_dir/fixtures/icon.$extension"
  cmp -s "$validation_dir/fixtures/icon.$extension" "$icon_file"
  OMARCHY_REMOVE_NOTIFY=false "$remover" "$name"

  [[ ! -e $app_dir/$name.desktop ]]
  cmp -s "$validation_dir/fixtures/icon.$extension" "$neighbor"
  if [[ -e $icon_file ]]; then
    printf '%-3s: launcher removed; icon LEFT BEHIND; neighbor preserved\n' "${extension^^}"
    remaining=$((remaining + 1))
  else
    printf '%-3s: launcher removed; icon removed; neighbor preserved\n' "${extension^^}"
  fi
  rm "$neighbor"
done
printf '\nResidual app icons: %s\n' "$remaining"
if [[ $phase == "before" ]]; then
  (( remaining == 2 ))
  printf 'Original bug reproduced: SVG and XPM icons remain.\n'
else
  (( remaining == 0 ))
  printf 'PASS: PNG, SVG and XPM install/remove round trips.\n'
fi
