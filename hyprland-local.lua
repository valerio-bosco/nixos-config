-- Personalizzazioni locali di Hyprland.
-- Viene caricato DOPO la config ufficiale di serpantinum (compositors/hyprland/config/*.lua
-- del flake input), quindi qui si sovrascrivono/aggiungono solo le differenze.
-- Installato da home-manager come ~/.config/hypr/z-local.lua: modifica QUESTO file in /etc/nixos.

-- Tastiera: italiano + inglese, Alt+Shift per cambiare layout
hl.config({
    input = {
        kb_layout  = "it,us",
        kb_options = "grp:alt_shift_toggle",
    },
})

-- GPU NVIDIA (driver proprietario 580): variabili consigliate dalla wiki di Hyprland
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Cursore software: su NVIDIA quello hardware può sfarfallare
hl.config({
    cursor = {
        no_hardware_cursors = 1,
    },
})

-- Tema del cursore (installato da home.pointerCursor in configuration.nix)
hl.env("XCURSOR_THEME", "GoogleDot-Black")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "GoogleDot-Black")
hl.env("HYPRCURSOR_SIZE", "24")

-- Autostart: serpantinumd parte già come servizio systemd e easyeffects via home-manager,
-- quindi qui restano solo i watcher degli appunti (servono al pannello clipboard, SUPER+C).
hl.on("hyprland.start", function ()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- SUPER+R: launcher (in serpantinum era "serpantinum reload", spostato su SUPER+SHIFT+R)
hl.unbind("SUPER + R")
hl.bind("SUPER + R", hl.dsp.exec_cmd("serpantinum msg toggle launcher"))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("serpantinum reload"))

-- Scorciatoie che la config di serpantinum non definisce
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exit())   -- esci da Hyprland (emergenza)

-- Ignora le richieste di "massimizza" delle app (es. kitty): altrimenti le nuove finestre
-- coprono tutto lo schermo invece di dividere lo spazio con le altre (tiling)
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Alt+Tab: passa alla finestra successiva del workspace e la porta in primo piano
hl.bind("ALT + Tab", function ()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Schermo intero (premi di nuovo per tornare com'era)
hl.bind("SUPER + Z", hl.dsp.window.fullscreen({ mode = "maximized" }))   -- massimizza, la barra resta visibile
hl.bind("SUPER + SHIFT + Z", hl.dsp.window.fullscreen())                 -- schermo intero vero, senza barra

-- SUPER+Tab: elenco di tutte le finestre; Invio = portala qui, Alt+Invio = vai lì
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("scegli-finestra"))
-- SUPER+X: mostra il desktop (va al primo workspace vuoto; premi di nuovo per tornare)
hl.bind("SUPER + X", hl.dsp.exec_cmd("mostra-desktop"))

-- SUPER+T: sfondi e tema (immagini e video, con animazione; Shift+Invio per selezionarne più = rotazione)
hl.bind("SUPER + T", hl.dsp.exec_cmd("scegli-sfondo"))
-- SUPER+SHIFT+T: stile dei selettori (temi adi1090x/rofi, anteprima dal vivo)
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("scegli-stile"))
-- All'avvio riprende la rotazione degli sfondi, se era attiva
hl.on("hyprland.start", function ()
    hl.exec_cmd("rotazione-sfondi ripristina")
end)
-- SUPER+ALT+T: tema colori di serpantinum (Matugen = i colori seguono lo sfondo)
hl.bind("SUPER + ALT + T", hl.dsp.exec_cmd("scegli-tema"))

-- File manager: Yazi nel terminale (SUPER+E, prima puntava a Nautilus non installato) e Nautilus grafico
hl.unbind("SUPER + E")
hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty --class yazi -e yazi"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("nautilus --new-window"))

-- Trasparenza delle finestre: attiva piena, non attive leggermente trasparenti (con la sfocatura di serpantinum)
hl.config({
    decoration = {
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
    },
})

-- SUPER+I: pannello dell'assistente Claude (chat + azioni sul desktop tramite MCP)
hl.bind("SUPER + I", hl.dsp.exec_cmd("assistente-toggle"))

-- Scala dello schermo: 1.0666667 (= 128/120). Con 3440x1440 è l'unico valore tra 1 e 1.25 che
-- Hyprland accetta (la scala deve essere un multiplo di 1/120 e dividere la risoluzione in interi).
-- Per ingrandire ancora un po' senza saltare a 1.25 si alzano i testi (vedi aspetto.nix, terminale.nix).
hl.monitor({ output = "HDMI-A-1", mode = "3440x1440@84.96", position = "0x0", scale = 1.0666667 })
