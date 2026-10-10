# Se il workspace attuale ha finestre, vai al primo workspace vuoto (desktop libero);
# se è già vuoto, torna al workspace di prima.
finestre=$(hyprctl -j activeworkspace | jq -r '.windows')
if [ "$finestre" -gt 0 ]; then
  hyprctl dispatch 'hl.dsp.focus({ workspace = "empty" })' >/dev/null
else
  hyprctl dispatch 'hl.dsp.focus({ workspace = "previous" })' >/dev/null
fi
