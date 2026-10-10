# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.serpantinum.nixosModules.default
      ./rofi   # selettori rofi (temi adi1090x): finestre, sfondi, stile
      ./file-manager.nix   # Yazi (SUPER+E) + Nautilus (SUPER+SHIFT+E)
      ./terminale.nix      # kitty: trasparenza, font, colori del tema
      #./refind.nix         # schermata di avvio rEFInd (icone NixOS / Windows)
      ./refind-solo.nix
      ./avvio.nix          # animazione di avvio (Plymouth) + login di serpantinum (SDDM)
      ./aspetto.nix        # font Google Sans (e cursore)
      ./assistente         # assistente Claude nel desktop (SUPER+I) + server MCP per Hyprland
    ];

  # Use the systemd-boot EFI boot loader.
  #  boot.loader.systemd-boot.enable = true;
  boot.supportedFilesystems = [ "ntfs" ];
  #
  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.devices = [ "nodev" ];
  #boot.loader.grub.efiSupport = true;
  #boot.loader.grub.useOSProber = true;  

  # Tema dentro il flake (la cartella deve contenere direttamente theme.txt)
  #boot.loader.grub.theme = ./grub-theme;
  # Monitor 21:9: risoluzione nativa (se la scheda video non la offre, GRUB ripiega su "auto")
  #boot.loader.grub.gfxmodeEfi = "3440x1440,auto";

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  #services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "it2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Driver NVIDIA proprietario (GTX 1060, Pascal).
  # Pascal è supportato solo fino al ramo 580: le versioni 590+ (stable/latest) NON funzionano.
  # Se qualcosa va storto: al boot scegli in GRUB la generazione precedente di NixOS.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;               # i moduli "open" non supportano Pascal
    modesetting.enable = true;  # necessario per Wayland/Hyprland
    nvidiaSettings = true;
    # Salva la memoria della scheda video prima della sospensione e la ripristina al risveglio.
    # Senza, dopo la sospensione automatica (serpantinum: 10 min di inattività) la GPU si corrompe
    # (errori NVRM Xid 31/13) e Hyprland va in crash. Attiva anche nvidia-suspend/resume.
    powerManagement.enable = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."voodoo" = {
    isNormalUser = true;
    description = "voodoo";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
     vim 
     wget
     kitty # Aggiunto kitty dato che lo hai inserito come terminale di default nelle scorciatoie di Hyprland
     hyprpolkitagent
     hyprlauncher
     waybar
     hyprpaper
     mako
     hypridle
     hyprlock
     grim
     slurp
     wireplumber
     brightnessctl
     rofi
     wofi
     wl-clipboard
     cliphist
     nvidia-vaapi-driver   # accelerazione video hardware (VA-API) su NVIDIA
     xdg-user-dirs   # serpantinum usa xdg-user-dir per trovare le cartelle (Immagini, ecc.)
     claude-code
     google-chrome 
     obsidian
     spotify 
     vscode.fhs
     git                  # versionamento di /etc/nixos
 ];

  system.stateVersion = "26.05"; 

  # Configurazione Hyprland di Sistema
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  # L'agente polkit (finestra password) lo fornisce serpantinum: niente polkit-gnome, altrimenti va in conflitto
  security.polkit.enable = true;

  # Dipendenze di sistema di serpantinum (power-profiles, bluetooth, i2c per la luminosità, font)
  programs.serpantinum.enable = true;
  services.upower.enable = true;   # batteria/energia nella barra

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  #################
  # Home manager
  #################
  home-manager.users.voodoo = { 
    imports = [
      inputs.serpantinum.homeManagerModules.default
    ];

    home.stateVersion = "24.11"; 

    # Sfondi video: la decodifica hardware NVIDIA (VA-API) fa crashare quickshell (segfault in nvGetImage),
    # quindi serpantinum decodifica i video via software. Alternativa da provare: "cuda".
    systemd.user.services.serpantinum.Service.Environment = [ "QT_FFMPEG_DECODING_HW_DEVICE_TYPES=," ];

    # Configurazione Utente Serpantinum
    programs.serpantinum = {
      enable = true;
      systemd.enable = true;
      settings = {
        wallpaperDir = "/home/voodoo/Pictures/Wallpapers";
        
        general = {
          language = "en";
          weatherUnit = "metric";
          weatherInterval = 30;
        };

        bar = {
          position = "top";
          style = "solid";
          width = 40;
          workspaceCount = 10;
          modules = {
            left = [ "workspaces" ];
            center = [ "time" ];
            right = [ "tray" [ "kb" "wifi" "bt" "vol" "bat" ] ];
          };
        };

        theme = {
          fontFamily = "Google Sans";
          borderRadius = 12;
          matugen = true;
        };

        notifications = {
          dnd = false;
          position = "top right";
          sound = true;
        };
      };
    };

    # Tema del cursore (uguale per Hyprland, app GTK, Qt e XWayland)
    home.pointerCursor = {
      enable = true;
      package = pkgs.google-cursor;
      name = "GoogleDot-Black";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = true;
    };

    # Equalizzatore usato da serpantinum
    services.easyeffects.enable = true;

    # Configurazione Utente Hyprland (0.56+ usa Lua)
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;    # avvia hyprland-session.target -> graphical-session.target (serpantinum ecc.)
      # Hyprland e il portal sono installati da programs.hyprland (nixpkgs): niente doppioni
      package = null;
      portalPackage = null;
      configType = "lua";
      # Config ufficiale di serpantinum dal flake input (si aggiorna con `nix flake update serpantinum`),
      # caricata in ordine alfabetico; z-local (./hyprland-local.lua) viene per ultimo e la personalizza.
      # L'autostart del repo è escluso: avvierebbe serpantinumd una seconda volta.
      extraLuaFiles =
        let serp = f: builtins.readFile "${inputs.serpantinum}/compositors/hyprland/config/${f}.lua";
        in {
          "s1-variables" = serp "variables";
          "s2-env"       = serp "env";
          "s3-monitors"  = serp "monitors";
          "s4-settings"  = serp "settings";
          "s5-keybinds"  = serp "keybinds";
          "z-local"      = ./hyprland-local.lua;
        };
    };
  };
}
