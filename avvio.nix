# Avvio grafico: animazione al posto delle righe di testo + schermata di login di serpantinum.
#
#   rEFInd → animazione Plymouth (tema "rings") → login SDDM (tema Material You di serpantinum) → Hyprland
#   (anche allo spegnimento si vede l'animazione al posto dei messaggi)
{ pkgs, lib, inputs, ... }:

let
  # Tema di login "Material You" incluso in serpantinum (il suo installatore per Arch lo configura,
  # il modulo NixOS no: per questo prima si vedeva il login standard GDM)
  # La schermata di login viene disegnata SENZA scheda video (QT_QUICK_BACKEND=software, sotto):
  # dopo un riavvio da Windows la GPU NVIDIA può dare errore al primo uso (NVRM Xid 32,
  # "QRhiGles2: Context is lost") e il login andava in crash lasciando lo schermo nero.
  # Senza GPU l'effetto ColorOverlay del tema non funziona e le icone sparivano: qui il colore viene
  # scritto direttamente nelle icone SVG, che diventano visibili, e gli overlay vengono spenti.
  temaLogin = pkgs.runCommand "sddm-tema-material-you" { nativeBuildInputs = [ pkgs.perl ]; } ''
    mkdir -p $out/share/sddm/themes
    cp -r ${inputs.serpantinum}/config/sddm/themes/material-you $out/share/sddm/themes/
    chmod -R u+w $out
    f=$out/share/sddm/themes/material-you/Main.qml
    # lucchetto: grigio-verde; le altre icone: verde scuro (gli stessi colori degli overlay originali)
    perl -pi -e "s/stroke='black'(?=.*<rect x='3' y='11')/stroke='%238ca090'/g" $f
    perl -pi -e "s/stroke='black'/stroke='%230F3C2C'/g" $f
    perl -0pi -e 's/visible: false/visible: true/g; s/ColorOverlay \{/ColorOverlay {\n                                visible: false/g' $f
    # controlli: nessuna icona nera rimasta, 5 overlay spenti
    ! grep -q "stroke='black'" $f
    test "$(grep -c 'ColorOverlay {' $f)" = 5
  '';

  # Animazione di avvio: https://github.com/adi1090x/plymouth-themes (si scarica solo quella scelta)
  animazione = "rings";
in
{
  # ── Login ───────────────────────────────────────────────────────────────────
  services.displayManager.gdm.enable = lib.mkForce false;   # il login standard di prima
  services.displayManager.sddm = {
    enable = true;
    # X11 e non Wayland: con NVIDIA il compositore Wayland di SDDM (weston) non mostrava il cursore
    wayland.enable = false;
    package = pkgs.kdePackages.sddm;                        # SDDM per Qt6 (il tema lo richiede)
    # stesso cursore di Hyprland
    settings.Theme = { CursorTheme = "GoogleDot-Black"; CursorSize = 24; };
    # su NixOS i cursori non stanno in /usr/share/icons: va detto alla schermata di login dove cercarli
    settings.General.GreeterEnvironment = "XCURSOR_PATH=/run/current-system/sw/share/icons,XCURSOR_THEME=GoogleDot-Black,XCURSOR_SIZE=24,QT_QUICK_BACKEND=software";
    theme = "material-you";
    extraPackages = with pkgs.kdePackages; [ qt5compat qtsvg qtdeclarative ];
  };
  services.xserver.enable = true;                           # serve solo per la schermata di login (X11)
  services.xserver.desktopManager.xterm.enable = false;     # niente sessione "xterm" nel login
  services.displayManager.defaultSession = "hyprland";
  # Cursore "di base" dello schermo di login: lo imposta SDDM con xsetroot, che deve sapere quale tema
  # usare e dove trovarlo (senza, compare la vecchia freccia nera di X11)
  systemd.services.display-manager.path = [ pkgs.xsetroot ];
  systemd.services.display-manager.environment = {
    XCURSOR_PATH = "/run/current-system/sw/share/icons";
    XCURSOR_THEME = "GoogleDot-Black";
    XCURSOR_SIZE = "24";
  };
  # La schermata di login (Qt) legge il tema del cursore SOLO dalla risorsa X "Xcursor.theme"
  # (libxcb-cursor ignora XCURSOR_THEME): la si imposta all'avvio del server X di SDDM
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xrdb}/bin/xrdb -merge <<EOF
    Xcursor.theme: GoogleDot-Black
    Xcursor.size: 24
    EOF
  '';
  environment.systemPackages = [ temaLogin pkgs.google-cursor ];

  # ── Animazione di avvio e spegnimento ──────────────────────────────────────
  boot.plymouth = {
    enable = true;
    theme = animazione;
    themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ animazione ]; }) ];
  };

  # Niente messaggi a schermo durante l'avvio
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "splash" "udev.log_level=3" "rd.udev.log_level=3" "systemd.show_status=auto"
    # I messaggi "di emergenza" del kernel (es. "No irq handler for N.55", innocui, presenti da sempre)
    # non si possono zittire con quiet/loglevel. La console di testo viene legata solo ai terminali 2-6:
    # sul primo schermo il testo non compare, Plymouth (che disegna direttamente) sì.
    # Testo dell'avvio: Ctrl+Alt+F2. (NON usare console=ttyN: Plymouth si sposta su quella console)
    "fbcon=vc:2-6"
    "vt.global_cursor_default=0"   # niente cursore lampeggiante prima dell'animazione
  ];
  boot.initrd.systemd.enable = true;     # avvio iniziale gestito da systemd: Plymouth parte prima e più fluido

  # Driver NVIDIA caricato subito: l'animazione è alla risoluzione nativa 3440x1440
  # (senza, partirebbe a 1024x768 e sfarfallerebbe quando arriva il driver)
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
