#!/bin/bash
set -euo pipefail

phase=${1:?before or after}
validation_dir=/home/omarchy/validation-bulk
case $phase in
  before) remover="$validation_dir/bin/omarchy-webapp-remove-all-original" ;;
  after) remover="$validation_dir/bin/omarchy-webapp-remove-all-candidate" ;;
  *) exit 2 ;;
esac

icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
app_dir="$HOME/.local/share/applications"
bulk_dir="$validation_dir/applications"
mkdir -p "$validation_dir/fixtures" "$icon_dir" "$bulk_dir"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==' |
  base64 -d >"$validation_dir/fixtures/icon.png"
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" rx="12" fill="#3288dd"/></svg>' >"$validation_dir/fixtures/icon.svg"
cat >"$validation_dir/fixtures/icon.xpm" <<'XPM'
/* XPM */
static char *icon[] = {"1 1 1 1", "b c blue", "b"};
XPM
printf '%s\n' '[Desktop Entry]' 'Name=Unrelated App' 'Exec=foot' 'Type=Application' >"$validation_dir/ordinary.desktop"
cp "$validation_dir/ordinary.desktop" "$bulk_dir/Unrelated App.desktop"

printf 'Omarchy BULK web app icon cleanup: %s\n' "${phase^^}"
printf 'Kernel: %s\n' "$(uname -r)"
pacman -Q omarchy-dev gtk3 desktop-file-utils
printf '\nReal installer + remove-all, no command stubs\n'

for extension in png svg xpm; do
  name="Omarchy Bulk Icon Check $extension"
  stem="omarchy-bulk-icon-check-$extension"
  cp "$validation_dir/fixtures/icon.$extension" "$icon_dir/$stem-neighbor.$extension"
  cp "$validation_dir/fixtures/icon.$extension" "$icon_dir/$stem.$extension.bak"
  omarchy webapp install "$name" https://example.com "$validation_dir/fixtures/icon.$extension" >/dev/null
  cmp -s "$validation_dir/fixtures/icon.$extension" "$icon_dir/$stem.$extension"
  mv "$app_dir/$name.desktop" "$bulk_dir/"
done
"$remover" "$bulk_dir"

remaining=0
for extension in png svg xpm; do
  name="Omarchy Bulk Icon Check $extension"
  stem="omarchy-bulk-icon-check-$extension"
  [[ ! -e $bulk_dir/$name.desktop ]]
  cmp -s "$validation_dir/fixtures/icon.$extension" "$icon_dir/$stem-neighbor.$extension"
  cmp -s "$validation_dir/fixtures/icon.$extension" "$icon_dir/$stem.$extension.bak"
  if [[ -e $icon_dir/$stem.$extension ]]; then
    printf '%-3s: launcher removed; ICON LEFT BEHIND; controls preserved\n' "${extension^^}"
    remaining=$((remaining + 1))
  else
    printf '%-3s: launcher removed; icon removed; controls preserved\n' "${extension^^}"
  fi
done
cmp -s "$validation_dir/ordinary.desktop" "$bulk_dir/Unrelated App.desktop"
printf 'Ordinary launcher, neighboring icons and backups: preserved\n'
printf 'Orphaned app icons: %s\n' "$remaining"
if [[ $phase == "before" ]]; then
  (( remaining == 2 ))
else
  (( remaining == 0 ))
fi
