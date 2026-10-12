# oring: pannello degli agenti AI per serpantinum (progetto separato: ~/Projects/oring).
#
#   SUPER+I → pannello sul lato destro, nello stile e con i colori di serpantinum
#            → l'agente scelto nell'intestazione: Claude Code (abbonamento), Codex, OpenCode,
#              Goose o un modello locale con Ollama
#            → server MCP "desktop": finestre, workspace, screenshot, OCR, mouse, tastiera, appunti...
#              Clic, tasti, chiusura finestre e appunti chiedono sempre conferma nel pannello.
#   Telegram → @oring_bot: stessa conversazione dal telefono, permessi come pulsanti (/new /agent /stop /status)
#
# Ogni agente va autenticato una volta dal terminale: claude, codex login, opencode auth login,
# goose configure.
{ pkgs, inputs, ... }:

{
  # Livello di accesso (sandbox / full): file di root in /var/lib/oring, si cambia solo al PC con
  #   oring admin full      (password di amministratore chiesta da polkit, solo nella sessione locale)
  #   oring admin sandbox   (di nuovo con la sandbox)      oring admin   (mostra il livello)
  # In "sandbox" da Telegram si usano solo agenti in sandbox (Claude); in "full" tutti, e Claude senza sandbox.
  imports = [ inputs.oring.nixosModules.default ];
  programs.oring.admin.enable = true;

  home-manager.users.voodoo = {
    imports = [ inputs.oring.homeManagerModules.default ];

    programs.oring = {
      enable = true;
      extraPackages = with pkgs; [ codex codex-acp opencode goose-cli ];
      settings = {
        language = "it";
        system_prompt = ''
          Sei l'assistente integrato nel desktop di voodoo: NixOS con Hyprland (tiling) e la shell
          serpantinum, monitor ultrawide 3440x1440. Ti parla da un pannello laterale stretto: rispondi in
          italiano, in modo conciso, con markdown semplice.
          Puoi agire sul desktop con gli attrezzi del server MCP "desktop" (finestre, workspace, avvio di
          app, screenshot, lettura del testo sullo schermo, sfondi, musica, notifiche, appunti, mouse e
          tastiera). Quando ti chiede di fare qualcosa, fallo direttamente e conferma in una frase.
          Regole: chiudi finestre solo se te lo chiede esplicitamente. Usa mouse e tastiera solo quando
          l'azione richiesta lo rende necessario, preferendo gli attrezzi dedicati per finestre e
          workspace; prima di cliccare individua il punto con trova_testo o screenshot, e dopo verifica il
          risultato. Non scrivere mai password o dati sensibili, non confermare acquisti, pagamenti, invii
          di messaggi o cancellazioni senza che l'utente lo abbia chiesto in modo esplicito.
        '';
        agents = [
          { id = "claude"; name = "Claude"; type = "claude-cli"; }
          { id = "codex"; name = "Codex"; type = "acp"; command = "codex-acp"; }
          { id = "opencode"; name = "OpenCode"; type = "acp"; command = "opencode acp"; }
          { id = "goose"; name = "Goose"; type = "acp"; command = "goose acp"; }
          { id = "locale"; name = "Qwen (locale)"; type = "openai"; model = "qwen3:4b"; }
        ];
        # Telegram (@oring_bot): il token è in ~/.config/oring/telegram-token (privato, fuori da Nix);
        # risponde solo alla chat di voodoo
        gateways = [
          { type = "telegram"; token_file = "~/.config/oring/telegram-token"; allowed_chats = [ 918280932 ]; progress = false; }
        ];
      };
    };
  };

  # Modelli locali per l'agente "Qwen (locale)": Ollama sulla GTX 1060 tramite Vulkan
  # (la versione CUDA andrebbe compilata da zero: non è nella cache perché non libera).
  # Con 3 GB di memoria video girano bene solo modelli piccoli (fino a ~4 miliardi di parametri).
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    loadModels = [ "qwen3:4b" ];
  };
}
