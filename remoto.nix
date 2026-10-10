# Accesso da remoto: rete privata Tailscale (PC + telefono + altri dispositivi).
#
# Dopo il rebuild, una volta sola:   sudo tailscale up      (apre il login nel browser)
# Sul telefono: app Tailscale, stesso account.
#
# Il firewall resta attivo: le connessioni dalla rete Tailscale sono consentite solo sull'interfaccia
# tailscale0, quindi i servizi aperti per il remoto (es. Wayland, prossimo passo) NON sono raggiungibili
# da internet né dalla rete di casa, ma solo dai tuoi dispositivi collegati a Tailscale.
{ ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ];     # porta di Tailscale: connessioni dirette tra i dispositivi
  };
}
