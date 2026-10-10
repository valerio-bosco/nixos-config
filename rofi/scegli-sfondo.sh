# Selettore di sfondi/tema: immagini e video (sfondi animati) in ~/Pictures/Wallpapers.
#   Invio            applica lo sfondo (animazione + colori di tutto il sistema)
#   Shift+Invio      seleziona più sfondi; poi Invio = rotazione automatica tra quelli scelti
chiudi_se_aperto
mkdir -p "$DIR_SFONDI" "$CONF_DIR"
mapfile -t sfondi < <(elenco_sfondi)

extra=()
if [ -f "$CONF_DIR/rotazione-attiva" ]; then
  extra+=("  Ferma la rotazione ($(wc -l < "$CONF_DIR/rotazione") sfondi, ogni $(cat "$CONF_DIR/intervallo" 2>/dev/null || echo 10) min)")
fi
extra+=("  Sfondo casuale" "  Apri la cartella degli sfondi")

if [ ${#sfondi[@]} -eq 0 ]; then
  msg="Nessuno sfondo: metti immagini o video (.mp4/.webm) in $DIR_SFONDI"
else
  msg="Invio: applica   ·   Shift+Invio: selezione multipla → rotazione"
fi

# Griglia di miniature (sovrascrive il layout dello stile scelto)
GRIGLIA="window { width: 1100px; } listview { columns: 4; lines: 3; spacing: 10px; flow: horizontal; }
 element { orientation: vertical; padding: 10px; spacing: 8px; }
 element-icon { size: 200px; } element-text { horizontal-align: 0.5; }"

set +e
scelte=$({
  printf '%s\n' "${extra[@]}"
  for f in "${sfondi[@]}"; do
    nome=$(basename "$f"); nome=${nome%.*}
    if e_video "$f"; then nome="  $nome"; fi
    printf '%s\0icon\x1f%s\n' "$nome" "$(miniatura "$f")"
  done
} | rofi -dmenu -i -p "Sfondo" -multi-select -show-icons -format i -async-pre-read 0 -mesg "$msg" \
    -theme "$(tema_rofi)" -theme-str "$GRIGLIA")
set -e
[ -z "$scelte" ] && exit 0

scelti=()
while read -r i; do
  if [ "$i" -lt ${#extra[@]} ]; then
    case "${extra[$i]}" in
      *"Ferma"*)    rotazione-sfondi ferma; exit 0 ;;
      *"casuale"*)  [ ${#sfondi[@]} -gt 0 ] && applica_sfondo "${sfondi[RANDOM % ${#sfondi[@]}]}"; exit 0 ;;
      *"cartella"*) xdg-open "$DIR_SFONDI" >/dev/null 2>&1 & exit 0 ;;
    esac
  else
    scelti+=("${sfondi[$((i - ${#extra[@]}))]}")
  fi
done <<< "$scelte"

if [ ${#scelti[@]} -eq 1 ]; then
  rotazione-sfondi ferma
  applica_sfondo "${scelti[0]}"
elif [ ${#scelti[@]} -gt 1 ]; then
  set +e
  minuti=$(printf '%s\n' 1 5 10 15 30 60 | rofi -dmenu -p "Cambia ogni (minuti)" -selected-row 2 \
    -mesg "${#scelti[@]} sfondi selezionati per la rotazione" -theme "$(tema_rofi)")
  set -e
  [[ "$minuti" =~ ^[0-9]+$ ]] || exit 0
  printf '%s\n' "${scelti[@]}" > "$CONF_DIR/rotazione"
  echo "$minuti" > "$CONF_DIR/intervallo"
  rotazione-sfondi avvia
fi
