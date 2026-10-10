# Terminale kitty: crea ~/.config/kitty/kitty.conf (gestito da home-manager, file in sola lettura:
# per cambiare qualcosa modifica QUESTO file e fai il rebuild).
# I colori restano in ~/.config/kitty/colors.conf, che serpantinum riscrive quando cambia il tema.
{ ... }:

{
  home-manager.users.voodoo.programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 13;

      background_opacity = "0.85";    # trasparenza dello sfondo (1.0 = opaco); il testo resta pieno
      background_blur = 0;             # la sfocatura la fa già Hyprland

      window_padding_width = 6;
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      cursor_trail = 1;                # scia del cursore animata
      enable_audio_bell = "no";
      scrollback_lines = 10000;
    };
    # Sfondo, testo, cursore e selezione seguono il tema di serpantinum (aggiornati al cambio tema)...
    # ...ma i 16 colori del terminale restano quelli standard di kitty: alcuni temi (es. Obsidian)
    # li mettono tutti in scala di grigi e prompt, ls, Yazi, Claude Code perderebbero i colori.
    # Vengono dopo l'include, quindi hanno la precedenza.
    extraConfig = ''
      include ~/.config/kitty/colors.conf

      color0  #000000
      color8  #767676
      color1  #cc0403
      color9  #f2201f
      color2  #19cb00
      color10 #23fd00
      color3  #cecb00
      color11 #fffd00
      color4  #0d73cc
      color12 #1a8fff
      color5  #cb1ed1
      color13 #fd28ff
      color6  #0dcdcd
      color14 #14ffff
      color7  #dddddd
      color15 #ffffff
    '';
  };
}
