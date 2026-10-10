# rEFInd come UNICO bootloader (niente GRUB).
#
#   firmware UEFI → rEFInd → Windows (predefinito, Windows Boot Manager nella partizione EFI di Windows)
#                          → NixOS (avvia direttamente il kernel dell'ultima generazione)
#
# NixOS copia kernel e initrd in /boot/EFI/refind/kernels e riscrive /boot/EFI/refind/refind.conf
# a ogni rebuild.
#
# Tema "nero": sfondo nero, icone bianche. Costruito qui sotto partendo da
#   - icone dei sistemi operativi di rEFInd-minimal (nere) → rese bianche
#   - icone dei pulsanti (spegni, riavvia, firmware) dal set ufficiale di rEFInd → rese bianche
#
# Nota: all'avvio la scheda video (UEFI GOP) offre al massimo 1024x768, quindi la schermata
# di rEFInd è a quella risoluzione.
{ pkgs, lib, ... }:

let
  # Tema https://github.com/evanpurkhiser/rEFInd-minimal (versione fissata), solo per le icone
  minimal = pkgs.fetchFromGitHub {
    owner = "evanpurkhiser";
    repo = "rEFInd-minimal";
    rev = "56a06a4bd9ed76c05523a22017056dbecca4145d";
    hash = "sha256-ALDa8bhgiHyIRmyGh8/1P56TvEG/gqC0qOqAWbtURyg=";
  };
  iconeRefind = "${pkgs.refind}/share/refind/icons";

  # Il tema nero, generato con ImageMagick
  temaNero = pkgs.runCommand "refind-tema-nero" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    mkdir -p $out/icons
    bianco() { magick "$1" -alpha on -fill white -colorize 100% "$2"; }

    # icone dei sistemi operativi (tutte quelle di rEFInd-minimal)
    for f in ${minimal}/icons/os_*.png; do bianco "$f" "$out/icons/$(basename "$f")"; done
    # icone dei pulsanti: prima quelle ufficiali di rEFInd, poi quelle di minimal dove ci sono
    for f in ${iconeRefind}/func_*.png; do bianco "$f" "$out/icons/$(basename "$f")"; done
    for f in ${minimal}/icons/func_*.png; do bianco "$f" "$out/icons/$(basename "$f")"; done

    magick -size 1920x1080 xc:black $out/background.png
    # riquadro di selezione: bianco al 14%, angoli arrotondati
    magick -size 144x144 xc:none -fill 'rgba(255,255,255,0.14)' -draw 'roundrectangle 0,0 143,143 20,20' $out/selection_big.png
    magick -size 64x64   xc:none -fill 'rgba(255,255,255,0.14)' -draw 'roundrectangle 0,0 63,63 12,12'   $out/selection_small.png
  '';

  # Partizione EFI di Windows (nvme0n1p2), dove sta il Windows Boot Manager
  partWindows = "4A14D602-1A9E-4688-8CE2-AD9D4548A51C";

  # Tutti i file del tema, uno per uno (additionalFiles copia singoli file dentro /boot/EFI/refind)
  fileTema = dir: prefisso:
    lib.concatMapAttrs (nome: tipo:
      if tipo == "directory" then fileTema "${dir}/${nome}" "${prefisso}/${nome}"
      else { "${prefisso}/${nome}" = "${dir}/${nome}"; }
    ) (builtins.readDir dir);
in
{
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;

  boot.loader.refind = {
    enable = true;
    maxGenerations = 1;          # una sola voce NixOS (l'ultima generazione)

    additionalFiles = (fileTema "${temaNero}" "themes/nero") // {
      # Icona della voce NixOS: rEFInd usa l'icona del volume (.VolumeIcon.png nella radice di /boot)
      # quando la voce non ne indica una (la voce NixOS la genera il modulo, senza icona)
      "/boot/.VolumeIcon.png" = "${temaNero}/icons/os_nixos.png";
    };

    # Messo in cima a refind.conf, prima della voce NixOS generata in automatico
    extraConfig = ''
      resolution max
      use_graphics_for windows,linux

      # Solo le voci scritte (Windows qui sotto + NixOS): niente scansione automatica
      scanfor manual

      # Tema nero: niente scritte, niente frecce, solo icone
      hideui singleuser,hints,arrows,label,badges
      icons_dir themes/nero/icons
      banner themes/nero/background.png
      banner_scale fillscreen
      selection_big   themes/nero/selection_big.png
      selection_small themes/nero/selection_small.png
      showtools shutdown,reboot,firmware

      menuentry "Windows" {
        icon /EFI/refind/themes/nero/icons/os_win.png
        volume ${partWindows}
        loader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };

  # Avvio predefinito: Windows.
  # Il modulo NixOS scrive sempre "default_selection 2" in fondo a refind.conf (l'ultima riga vince),
  # quindi dopo l'installazione del bootloader la si sostituisce. Lo script di attivazione gira
  # subito dopo l'installazione del bootloader durante nixos-rebuild.
  system.activationScripts.refindAvvioWindows = ''
    if [ -f /boot/EFI/refind/refind.conf ]; then
      ${pkgs.gnused}/bin/sed -i 's/^default_selection .*/default_selection "Windows"/' /boot/EFI/refind/refind.conf
    fi
  '';

  environment.systemPackages = [ pkgs.efibootmgr ];
}
