# Sceglie lo stile dei selettori tra i layout di adi1090x/rofi.
# Invio applica lo stile e riapre subito il selettore con il nuovo aspetto (anteprima dal vivo);
# Esc per chiudere.
chiudi_se_aperto
mapfile -t stili < <(cd "$ADI/launchers" && find . -name 'style-*.rasi' | sed 's|^\./||; s|\.rasi$||' | sort -V)
riga=0
for i in "${!stili[@]}"; do [ "${stili[$i]}" = "$(stile_attuale)" ] && riga=$((i + 2)); done

while true; do
  colori=$(cat "$CONF_DIR/colori" 2>/dev/null || echo tema)
  if [ "$colori" = "originali" ]; then voce_colori="  Colori: originali dello stile (passa a: colori del tema)"
  else voce_colori="  Colori: del tema / sfondo (passa a: originali dello stile)"; fi

  set +e
  scelta=$({ printf '%s\n' "$voce_colori" "  Ripristina stile predefinito"
             printf '%s\n' "${stili[@]}" | sed 's|type-\([0-9]*\)/style-\([0-9]*\)|Tipo \1  ·  Stile \2|'; } |
    rofi -dmenu -i -p "Stile" -selected-row "$riga" \
      -mesg "Attuale: $(stile_attuale)   ·   Invio: prova   ·   Esc: chiudi" \
      -theme "$(tema_rofi)")
  set -e
  [ -z "$scelta" ] && exit 0

  case "$scelta" in
    *"Colori:"*)
      if [ "$colori" = "originali" ]; then echo tema > "$CONF_DIR/colori"; else echo originali > "$CONF_DIR/colori"; fi
      riga=0 ;;
    *"Ripristina"*)
      rm -f "$CONF_DIR/stile"; riga=1 ;;
    *)
      nuovo=$(printf '%s' "$scelta" | sed 's|Tipo \([0-9]*\)  ·  Stile \([0-9]*\)|type-\1/style-\2|')
      echo "$nuovo" > "$CONF_DIR/stile"
      for i in "${!stili[@]}"; do [ "${stili[$i]}" = "$nuovo" ] && riga=$((i + 2)); done ;;
  esac
done
