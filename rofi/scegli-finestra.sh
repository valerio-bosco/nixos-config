# Elenca tutte le finestre aperte (con il loro workspace).
#   Invio      -> porta la finestra scelta nel workspace attuale
#   Alt+Invio  -> vai tu nel workspace della finestra scelta
chiudi_se_aperto
ws=$(hyprctl -j activeworkspace | jq -r '.id')

lista=$(hyprctl -j clients | jq -r '
  sort_by(.workspace.id)[]
  | select(.mapped and .workspace.id > 0)
  | "\(.address)\t[\(.workspace.id)]  \(.class)  —  \(.title)"')

set +e
scelta=$(printf '%s\n' "$lista" | rofi -dmenu -i -p "Finestre" \
  -display-columns 2 -display-column-separator '\t' \
  -mesg "Invio: porta qui (workspace $ws)   ·   Alt+Invio: vai lì" \
  -kb-accept-alt "" -kb-custom-1 "Alt+Return" -theme "$(tema_rofi)")
codice=$?
set -e

[ -z "$scelta" ] && exit 0
addr=$(printf '%s' "$scelta" | cut -f1)

case $codice in
  0)  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$ws\", window = \"address:$addr\" })" >/dev/null
      hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null ;;
  10) hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null ;;
esac
