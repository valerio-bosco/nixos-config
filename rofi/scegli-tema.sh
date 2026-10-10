# Selettore dei temi colore di serpantinum (gli stessi del pannello SUPER+H → Tema).
# "Matugen" = i colori seguono lo sfondo: ogni cambio sfondo (SUPER+T) li ricalcola con l'animazione.
chiudi_se_aperto
IMPOSTAZIONI="$HOME/.config/serpantinum/settings.json"
attuale=$(jq -r '.theme.activePreset // "Matugen"' "$IMPOSTAZIONI" 2>/dev/null || echo Matugen)

mapfile -t temi < <(cd "$TEMI_SERP" && for f in *.json; do printf '%s\n' "${f%.json}"; done | sort -f)

riga=0
for i in "${!temi[@]}"; do [ "${temi[$i]}" = "$attuale" ] && riga=$((i + 1)); done

set +e
scelta=$({
  segno=" "; [ "$attuale" = "Matugen" ] && segno="✓"
  printf '%s  <span color="#89b4fa">■</span><span color="#a6e3a1">■</span><span color="#f38ba8">■</span>  Matugen <i>(colori dallo sfondo)</i>\n' "$segno"
  for t in "${temi[@]}"; do
    segno=" "; [ "$t" = "$attuale" ] && segno="✓"
    read -r cb cs ct < <(jq -r '[.colors.base, .colors.blue, .colors.text] | join(" ")' "$TEMI_SERP/$t.json")
    printf '%s  <span color="%s">■</span><span color="%s">■</span><span color="%s">■</span>  %s\n' "$segno" "$cb" "$cs" "$ct" "$t"
  done
} | rofi -dmenu -i -markup-rows -p "Tema" -format i -selected-row "$riga" \
    -mesg "Attuale: $attuale   ·   Invio: applica" -theme "$(tema_rofi)")
set -e
[ -z "$scelta" ] && exit 0

modo=$(jq -r '.theme.mode // "dark"' "$IMPOSTAZIONI" 2>/dev/null || echo dark)
tmp=$(mktemp "$IMPOSTAZIONI.XXXX")

if [ "$scelta" -eq 0 ]; then
  jq '.theme.activePreset = "Matugen" | .theme.matugen = true' "$IMPOSTAZIONI" > "$tmp" && mv "$tmp" "$IMPOSTAZIONI"
  sfondo=$(serpantinum ipc call wallpaper getWallpaperPath "" 2>/dev/null || true)
  if [ -n "$sfondo" ] && [ -f "$sfondo" ]; then
    if e_video "$sfondo"; then sfondo=$(miniatura "$sfondo"); fi
    sleep 0.5
    serpantinum ipc call matugen generateImage "$sfondo" >/dev/null 2>&1 || true
  fi
else
  t=${temi[$((scelta - 1))]}
  colori=$(jq -c '.colors' "$TEMI_SERP/$t.json")
  jq --arg n "$t" --argjson c "$colori" '.theme.activePreset = $n | .theme.matugen = false | .theme.colors = $c' \
    "$IMPOSTAZIONI" > "$tmp" && mv "$tmp" "$IMPOSTAZIONI"
  sleep 0.5
  serpantinum ipc call matugen generateFromStatic "$colori" "$modo" >/dev/null 2>&1 || true
fi
