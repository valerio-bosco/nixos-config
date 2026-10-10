# File manager: Yazi (terminale, SUPER+E) + Nautilus (grafico, SUPER+SHIFT+E).
# Le scorciatoie sono in hyprland-local.lua.
{ pkgs, ... }:

{
  # Nautilus + servizi che gli servono fuori da GNOME
  environment.systemPackages = with pkgs; [
    nautilus
    sushi                # anteprima rapida in Nautilus (barra spaziatrice)
  ];
  services.gvfs.enable = true;        # cestino, dischi esterni, reti, telefoni (MTP)
  services.udisks2.enable = true;     # montaggio dei dischi USB
  services.gnome.sushi.enable = true;
  programs.dconf.enable = true;       # dove Nautilus salva le sue preferenze

  home-manager.users.voodoo = {
    # Necessario per il comando "y" (vedi sotto): crea ~/.bashrc gestito da home-manager
    programs.bash.enable = true;

    programs.yazi = {
      enable = true;
      # Comando "y": apre yazi e quando esci il terminale resta nella cartella dove eri arrivato
      enableBashIntegration = true;
      shellWrapperName = "y";

      # Programmi usati da yazi per anteprime e ricerca
      extraPackages = with pkgs; [
        ffmpeg            # miniature dei video
        poppler-utils     # anteprima PDF
        imagemagick       # formati immagine particolari (HEIC, ecc.)
        resvg             # anteprima SVG
        p7zip             # contenuto degli archivi
        jq                # anteprima JSON
        fd                # ricerca file  (tasto s)
        ripgrep           # ricerca nel contenuto  (tasto S)
        fzf               # salto rapido  (tasto z)
        zoxide            # cartelle frequenti  (tasto Z)
        wl-clipboard      # copia negli appunti
      ];

      # I colori seguono quelli del terminale, che serpantinum aggiorna insieme al tema
      settings = {
        mgr = {
          ratio = [ 1 3 4 ];          # colonne: cartella padre / attuale / anteprima
          sort_by = "natural";
          sort_dir_first = true;
          show_hidden = false;         # "." per mostrare/nascondere i file nascosti
          linemode = "size";
          show_symlink = true;
        };
        preview = {
          max_width = 1200;
          max_height = 1600;
        };
      };

      keymap = {
        mgr.prepend_keymap = [
          { on = [ "g" "n" ]; run = "shell --orphan 'nautilus .'"; desc = "Apri la cartella in Nautilus"; }
          { on = [ "g" "w" ]; run = "cd ~/Pictures/Wallpapers"; desc = "Vai agli sfondi"; }
          { on = [ "g" "p" ]; run = "cd ~/Projects"; desc = "Vai a Projects"; }
          { on = [ "g" "s" ]; run = "cd ~/Projects/_knowledge/_second_brain/voodoo"; desc = "Vai al second brain"; }
          { on = [ "g" "e" ]; run = "cd /etc/nixos"; desc = "Vai alla config di NixOS"; }
        ];
      };
    };

    # Le cartelle si aprono con Nautilus (prima si aprivano con VS Code)
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        # già impostati prima (Chrome come browser predefinito)
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/about" = [ "google-chrome.desktop" ];
        "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
      };
    };
  };
}
