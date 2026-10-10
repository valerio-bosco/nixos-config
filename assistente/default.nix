# Assistente Claude integrato nel desktop.
#
#   SUPER+I → pannello di chat (Quickshell) sul lato destro
#            → Claude Code in modalità headless (account dell'utente, nessuna chiave API)
#            → server MCP "hyprland": finestre, workspace, app, screenshot, OCR, mouse, tastiera,
#              appunti, sfondi, musica, notifiche
#
# Il server MCP è disponibile anche per Claude Code nel terminale (registrato con `claude mcp add`).
{ pkgs, lib, ... }:

let
  # ── Server MCP per Hyprland ──
  pythonMcp = pkgs.python3.withPackages (ps: [ ps.mcp ]);
  ocr = pkgs.tesseract.override { enableLanguages = [ "eng" "ita" ]; };
  hyprlandMcp = pkgs.writeShellScriptBin "hyprland-mcp" ''
    export PATH=${lib.makeBinPath (with pkgs; [
      hyprland grim playerctl libnotify
      ocr          # leggi_testo / trova_testo
      wtype        # tastiera virtuale (scrivi_testo, premi_tasti)
      wlrctl       # puntatore virtuale (clicca, scorri)
      wl-clipboard # appunti
    ])}:$PATH
    # Avviato fuori dalla sessione grafica (es. Claude Code da `sudo su`): trova da solo
    # l'istanza di Hyprland attiva dell'utente e il suo display Wayland
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u voodoo)}
      [ -d "$XDG_RUNTIME_DIR/hypr" ] || export XDG_RUNTIME_DIR=/run/user/$(id -u voodoo)
      istanza=$(hyprctl instances -j 2>/dev/null | ${pkgs.jq}/bin/jq -c 'sort_by(.time) | last // empty')
      if [ -n "$istanza" ]; then
        export HYPRLAND_INSTANCE_SIGNATURE=$(${pkgs.jq}/bin/jq -r .instance <<< "$istanza")
        export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-$(${pkgs.jq}/bin/jq -r .wl_socket <<< "$istanza")}
      fi
    fi
    exec ${pythonMcp}/bin/python3 ${./hyprland-mcp.py} "$@"
  '';

  configMcp = pkgs.writeText "assistente-mcp.json" (builtins.toJSON {
    mcpServers.hyprland.command = "${hyprlandMcp}/bin/hyprland-mcp";
  });

  promptSistema = ''
    Sei Claude, l'assistente integrato nel desktop di voodoo: NixOS con Hyprland (tiling) e la shell
    serpantinum, monitor ultrawide 3440x1440. Ti parla da un pannello laterale stretto: rispondi in
    italiano, in modo conciso, con markdown semplice.
    Puoi agire sul desktop con gli attrezzi del server MCP "hyprland" (finestre, workspace, avvio di
    app, screenshot, lettura del testo sullo schermo, sfondi, musica, notifiche, appunti, mouse e
    tastiera). Quando ti chiede di fare qualcosa, fallo direttamente e conferma in una frase.
    Regole: chiudi finestre solo se te lo chiede esplicitamente. Usa mouse e tastiera (clicca,
    scorri, scrivi_testo, premi_tasti) solo quando l'azione richiesta lo rende necessario, preferendo
    gli attrezzi dedicati per finestre e workspace; prima di cliccare individua il punto con
    trova_testo o screenshot, e dopo verifica il risultato. Non scrivere mai password o dati
    sensibili, non confermare acquisti, pagamenti, invii di messaggi o cancellazioni senza che
    l'utente lo abbia chiesto in modo esplicito.
    Da qui non puoi eseguire comandi shell né modificare file: se serve, dillo e suggerisci di usare
    Claude Code nel terminale.
  '';

  # ── Ponte pannello → Claude Code ──
  ponte = pkgs.writeShellApplication {
    name = "assistente-claude";
    text = ''
      export MCP_CONFIG=${configMcp}
      export PROMPT_SISTEMA=${lib.escapeShellArg promptSistema}
    '' + builtins.readFile ./assistente-claude.sh;
  };

  # ── Pannello (Quickshell) ──
  configPannello = pkgs.runCommand "assistente-pannello" { } ''
    mkdir -p $out
    cp ${./shell.qml} $out/shell.qml
  '';
  apriChiudi = pkgs.writeShellScriptBin "assistente-toggle" ''
    exec ${pkgs.quickshell}/bin/quickshell -p ${configPannello}/shell.qml ipc call assistente toggle
  '';
  chiedi = pkgs.writeShellScriptBin "assistente-chiedi" ''
    exec ${pkgs.quickshell}/bin/quickshell -p ${configPannello}/shell.qml ipc call assistente chiedi "$*"
  '';
in
{
  environment.systemPackages = [ hyprlandMcp ponte apriChiudi chiedi ];

  home-manager.users.voodoo.systemd.user.services.assistente = {
    Unit = {
      Description = "Pannello assistente Claude";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${configPannello}/shell.qml";
      Restart = "on-failure";
      Environment = [
        "ASSISTENTE_PONTE=${ponte}/bin/assistente-claude"
        # claude, serpantinum, hyprctl, notify-send... come nella sessione dell'utente
        "PATH=/run/wrappers/bin:/etc/profiles/per-user/voodoo/bin:/run/current-system/sw/bin"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
