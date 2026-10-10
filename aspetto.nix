# Aspetto generale: font e cursore condivisi da desktop, app e schermata di login.
{ pkgs, inputs, ... }:

let
  # Google Sans: il font della schermata di login Material You di serpantinum
  googleSans = pkgs.runCommand "font-google-sans" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${inputs.serpantinum}/config/sddm/themes/material-you/font/*.ttf $out/share/fonts/truetype/
  '';

  # Cursore predefinito di sistema: il tema "default" (quello usato da chi non ne indica uno)
  # rimanda a GoogleDot-Black
  cursore = "GoogleDot-Black";
  cursorePredefinito = pkgs.runCommand "cursore-predefinito" { } ''
    mkdir -p $out/share/icons/default
    printf '[Icon Theme]\nName=Default\nInherits=${cursore}\n' > $out/share/icons/default/index.theme
  '';
in
{
  fonts.packages = [ googleSans ];

  environment.systemPackages = [ pkgs.google-cursor cursorePredefinito ];
  environment.variables = {
    XCURSOR_THEME = cursore;
    XCURSOR_SIZE = "24";
  };
}
