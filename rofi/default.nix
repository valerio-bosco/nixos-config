# Selettori rofi (temi adi1090x/rofi) per Hyprland + serpantinum.
# Scorciatoie in ../hyprland-local.lua:
#   SUPER+Tab        scegli-finestra   elenco finestre (porta qui / vai lì)
#   SUPER+X          mostra-desktop    workspace vuoto e ritorno
#   SUPER+T          scegli-sfondo     sfondi (anche video) con animazione e cambio colori; multiselezione = rotazione
#   SUPER+SHIFT+T    scegli-stile      stile dei selettori (anteprima dal vivo)
#   SUPER+ALT+T      scegli-tema       temi colore di serpantinum (o Matugen = colori dallo sfondo)
{ pkgs, inputs, ... }:

let
  # Raccolta temi https://github.com/adi1090x/rofi (versione fissata)
  adi = pkgs.fetchFromGitHub {
    owner = "adi1090x";
    repo = "rofi";
    rev = "512a585fff6da5b2a90e5948059b062516ddb2e7";
    hash = "sha256-iUX0Quae06tGd7gDgXZo1B3KYgPHU+ADPBrowHlv02A=";
  };

  # Font usati dai temi adi1090x (icone Feather, GrapeNuts, ...)
  adiFonts = pkgs.runCommand "adi1090x-rofi-fonts" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${adi}/fonts/*.ttf $out/share/fonts/truetype/
  '';

  # Ogni script riceve il percorso dei temi e la libreria comune
  script = name: deps: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = deps;
    text = ''
      export ADI=${adi}/files
      export TEMI_SERP=${inputs.serpantinum}/src/assets/themes
      # shellcheck source=/dev/null
      source ${./lib-tema.sh}
    '' + builtins.readFile (./. + "/${name}.sh");
  };

  base = with pkgs; [ rofi jq hyprland coreutils procps ];
in
{
  fonts.packages = [ adiFonts pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = [
    (script "scegli-finestra" base)
    (script "mostra-desktop" base)
    (script "scegli-sfondo" (base ++ [ pkgs.ffmpeg pkgs.xdg-utils ]))
    (script "rotazione-sfondi" (base ++ [ pkgs.ffmpeg pkgs.systemd ]))
    (script "scegli-stile" base)
    (script "scegli-tema" (base ++ [ pkgs.ffmpeg ]))
  ];
}
