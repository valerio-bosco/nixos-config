# Ponte tra il pannello (Quickshell) e Claude Code in modalità headless.
#   assistente-claude <id-sessione|""> <messaggio>
# Stampa su stdout gli eventi JSON di Claude Code (uno per riga, formato stream-json).
# MCP_CONFIG e PROMPT_SISTEMA vengono definiti da NixOS (default.nix) prima di questo script.
sessione=$1
messaggio=$2

argomenti=(
  -p "$messaggio"
  --output-format stream-json --verbose
  --mcp-config "$MCP_CONFIG" --strict-mcp-config
  # Attrezzi permessi senza conferma: quelli del server MCP di Hyprland e la lettura dei file.
  # Tutto il resto (comandi shell, modifica di file, ...) in questa modalità viene rifiutato.
  --allowedTools "mcp__hyprland" "Read"
  --append-system-prompt "$PROMPT_SISTEMA"
)
if [ -n "$sessione" ]; then
  argomenti+=(--resume "$sessione")
fi

cd "$HOME"
# stdin chiuso: altrimenti Claude Code aspetta 3 secondi un input che non arriva
exec claude "${argomenti[@]}" < /dev/null
