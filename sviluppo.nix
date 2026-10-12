# Strumenti di sviluppo: Docker (motore + compose) e Python 3.12.
# Docker Desktop non esiste per NixOS: il motore Docker offre gli stessi comandi (docker, docker compose).
{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    # Pulizia settimanale di immagini/container inutilizzati
    autoPrune.enable = true;
  };

  # Il gruppo docker permette di usare docker senza sudo (equivale a dare accesso root: scelta voluta)
  users.users."voodoo".extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose   # anche come plugin: `docker compose`
    python312
  ];
}
