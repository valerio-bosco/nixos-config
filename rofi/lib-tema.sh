# Libreria comune dei selettori: costruisce il tema rofi attuale.
# Stile (layout adi1090x) in ~/.config/rofi-temi/stile, colori presi dal tema di serpantinum
# (~/.local/state/serpantinum/qs_colors.json, aggiornato da matugen quando cambia lo sfondo).
CONF_DIR="$HOME/.config/rofi-temi"
CACHE_DIR="$HOME/.cache/rofi-temi"
STILE_DEFAULT="type-2/style-2"

stile_attuale() {
  local s
  s=$(cat "$CONF_DIR/stile" 2>/dev/null || true)
  if [ -z "$s" ] || [ ! -f "$ADI/launchers/$s.rasi" ]; then s=$STILE_DEFAULT; fi
  printf '%s' "$s"
}

# Stampa il percorso del file tema da passare a rofi -theme
tema_rofi() {
  local stile=${1:-$(stile_attuale)}
  mkdir -p "$CONF_DIR" "$CACHE_DIR" "$HOME/.config/rofi"
  # alcuni stili importano ~/.config/rofi/colors/... e ~/.config/rofi/images/...
  ln -sfn "$ADI/colors" "$HOME/.config/rofi/colors"
  ln -sfn "$ADI/images" "$HOME/.config/rofi/images"

  local colori="$HOME/.local/state/serpantinum/qs_colors.json"
  local b ba f s a u
  if [ -f "$colori" ]; then
    b=$(jq -r '.base // "#1e1e2e"' "$colori");      ba=$(jq -r '.surface0 // "#313244"' "$colori")
    f=$(jq -r '.text // "#cdd6f4"' "$colori");      s=$(jq -r '.blue // "#89b4fa"' "$colori")
    a=$(jq -r '.green // "#a6e3a1"' "$colori");     u=$(jq -r '.red // "#f38ba8"' "$colori")
  else
    b="#1e1e2e"; ba="#313244"; f="#cdd6f4"; s="#89b4fa"; a="#a6e3a1"; u="#f38ba8"
  fi

  local out="$CACHE_DIR/tema.rasi"
  if [ "$(cat "$CONF_DIR/colori" 2>/dev/null || true)" = "originali" ]; then
    printf '@import "%s"\n' "$ADI/launchers/$stile.rasi" > "$out"
    printf '%s' "$out"
    return
  fi
  cat > "$out" <<RASI
@import "$ADI/launchers/$stile.rasi"
* {
    background:     ${b}FF;
    background-alt: ${ba}FF;
    foreground:     ${f}FF;
    selected:       ${s}FF;
    active:         ${a}FF;
    urgent:         ${u}FF;
}
RASI
  printf '%s' "$out"
}

# ---- Sfondi (usati da scegli-sfondo e rotazione-sfondi) ----
DIR_SFONDI="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

e_video() {
  case "${1,,}" in *.mp4|*.mkv|*.mov|*.webm) return 0 ;; *) return 1 ;; esac
}

elenco_sfondi() {
  find "$DIR_SFONDI" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
    -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' \
    -o -iname '*.webm' \) 2>/dev/null | sort -V
}

# Miniatura in cache (per i video: un fotogramma), stampa il percorso
miniatura() {
  local f=$1 m
  mkdir -p "$CACHE_DIR/miniature"
  m="$CACHE_DIR/miniature/$(printf '%s' "$f" | md5sum | cut -c1-16).jpg"
  if [ ! -s "$m" ] || [ "$f" -nt "$m" ]; then
    if e_video "$f"; then
      ffmpeg -y -loglevel error -ss 1 -i "$f" -frames:v 1 -vf scale=640:-2 "$m" 2>/dev/null ||
        ffmpeg -y -loglevel error -i "$f" -frames:v 1 -vf scale=640:-2 "$m" 2>/dev/null || true
    else
      ffmpeg -y -loglevel error -i "$f" -frames:v 1 -vf scale=640:-2 "$m" 2>/dev/null || true
    fi
  fi
  printf '%s' "$m"
}

# Applica lo sfondo tramite serpantinum: transizione animata casuale + nuovi colori (matugen)
applica_sfondo() {
  local p=$1 colori=$1
  serpantinum ipc call wallpaper setWallpaper all "$p" random >/dev/null 2>&1 || true
  if e_video "$p"; then colori=$(miniatura "$p"); fi
  serpantinum ipc call matugen generateImage "$colori" >/dev/null 2>&1 || true
}

# Se un selettore è già aperto, lo chiude ed esce (premere di nuovo la scorciatoia = chiudi)
chiudi_se_aperto() {
  if pgrep -u "$(id -u)" -x rofi >/dev/null; then
    pkill -u "$(id -u)" -x rofi
    exit 0
  fi
}
