# Rotazione automatica tra gli sfondi scelti con la selezione multipla di scegli-sfondo.
#   rotazione-sfondi avvia | ferma | ripristina (all'avvio di Hyprland, se era attiva) | ciclo (interno)
UNIT=rotazione-sfondi

case "${1:-}" in
  avvia)
    systemctl --user stop "$UNIT" 2>/dev/null || true
    touch "$CONF_DIR/rotazione-attiva"
    systemd-run --user --unit="$UNIT" --collect --quiet \
      -E PATH -E WAYLAND_DISPLAY -E XDG_RUNTIME_DIR -E HYPRLAND_INSTANCE_SIGNATURE \
      rotazione-sfondi ciclo ;;
  ferma)
    rm -f "$CONF_DIR/rotazione-attiva"
    systemctl --user stop "$UNIT" 2>/dev/null || true ;;
  ripristina)
    if [ -f "$CONF_DIR/rotazione-attiva" ]; then exec rotazione-sfondi avvia; fi ;;
  ciclo)
    i=0
    while true; do
      mapfile -t lista < <(grep -v '^$' "$CONF_DIR/rotazione" 2>/dev/null || true)
      [ ${#lista[@]} -eq 0 ] && exit 0
      p=${lista[$((i % ${#lista[@]}))]}
      [ -f "$p" ] && applica_sfondo "$p"
      i=$((i + 1))
      sleep "$(( $(cat "$CONF_DIR/intervallo" 2>/dev/null || echo 10) * 60 ))"
    done ;;
  *)
    echo "uso: rotazione-sfondi avvia|ferma|ripristina" >&2; exit 1 ;;
esac
