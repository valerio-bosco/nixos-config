// Pannello assistente: chat con Claude (Claude Code) sul lato destro dello schermo.
// Si apre/chiude con SUPER+I  →  quickshell -p <questa cartella> ipc call assistente toggle
// Claude può agire sul desktop tramite il server MCP "hyprland" (finestre, workspace, sfondi, ...).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool aperto: false
    property bool occupato: false
    property string sessione: ""
    property string ponte: Quickshell.env("ASSISTENTE_PONTE") || "assistente-claude"

    // ── Colori dal tema di serpantinum (si aggiornano quando cambia il tema) ──
    property var tema: ({})
    readonly property color cSfondo:   tema.base     || "#101010"
    readonly property color cSuperf:   tema.surface0 || "#1e1e1e"
    readonly property color cSuperf2:  tema.surface1 || "#2a2a2a"
    readonly property color cTesto:    tema.text     || "#f0f0f0"
    readonly property color cTenue:    tema.subtext0 || "#a0a0a0"
    readonly property color cAccento:  tema.blue     || "#ffffff"
    readonly property color cErrore:   tema.red      || "#e06c75"
    readonly property string font:     "Google Sans"

    FileView {
        id: fileColori
        path: Quickshell.env("HOME") + "/.local/state/serpantinum/qs_colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.tema = JSON.parse(text()); } catch (e) { }
        }
    }

    // ruolo: "utente" | "claude" | "azione" | "errore"
    ListModel { id: messaggi }

    function aggiungi(ruolo, testo) {
        messaggi.append({ ruolo: ruolo, testo: testo });
        vista.positionViewAtEnd();
    }

    // Nomi leggibili per gli attrezzi del server MCP
    readonly property var nomiAttrezzi: ({
        "elenca_finestre": "Guardo le finestre aperte",
        "elenca_workspace": "Guardo i workspace",
        "metti_a_fuoco": "Metto a fuoco",
        "sposta_in_workspace": "Sposto la finestra",
        "vai_al_workspace": "Cambio workspace",
        "chiudi_finestra": "Chiudo la finestra",
        "schermo_intero": "Schermo intero",
        "flottante": "Finestra flottante",
        "avvia_applicazione": "Avvio",
        "screenshot": "Guardo lo schermo",
        "elenca_sfondi": "Guardo gli sfondi",
        "cambia_sfondo": "Cambio sfondo",
        "notifica": "Notifica",
        "controlla_musica": "Musica",
        "leggi_testo": "Leggo il testo sullo schermo",
        "trova_testo": "Cerco sullo schermo",
        "muovi_mouse": "Sposto il mouse",
        "clicca": "Clic",
        "scorri": "Scorro",
        "scrivi_testo": "Scrivo",
        "premi_tasti": "Premo",
        "leggi_appunti": "Leggo gli appunti",
        "scrivi_appunti": "Copio negli appunti",
        "Read": "Leggo un file"
    })

    function descriviAttrezzo(nome, input) {
        const breve = nome.replace(/^mcp__hyprland__/, "");
        let etichetta = nomiAttrezzi[breve] || breve;
        const dettagli = [];
        for (const k in input) {
            const v = input[k];
            if (typeof v === "string" || typeof v === "number" || typeof v === "boolean")
                dettagli.push(String(v));
        }
        return dettagli.length ? etichetta + ": " + dettagli.join(", ") : etichetta;
    }

    // Una riga di stream-json da Claude Code
    function gestisci(riga) {
        if (!riga.trim()) return;
        let ev;
        try { ev = JSON.parse(riga); } catch (e) { return; }
        if (ev.session_id) root.sessione = ev.session_id;

        if (ev.type === "assistant" && ev.message && ev.message.content) {
            for (const blocco of ev.message.content) {
                if (blocco.type === "text" && blocco.text.trim())
                    aggiungi("claude", blocco.text.trim());
                else if (blocco.type === "tool_use" && blocco.name !== "ToolSearch")   // ricerca interna degli attrezzi: non interessa
                    aggiungi("azione", descriviAttrezzo(blocco.name, blocco.input || {}));
            }
        } else if (ev.type === "result") {
            if (ev.is_error)
                aggiungi("errore", ev.result || "Errore di Claude Code");
            if (ev.permission_denials && ev.permission_denials.length)
                aggiungi("errore", "Azione non permessa da qui: " +
                         ev.permission_denials.map(d => d.tool_name).join(", "));
        }
    }

    function invia(testo) {
        testo = testo.trim();
        if (!testo || occupato) return;
        aggiungi("utente", testo);
        occupato = true;
        processo.command = [root.ponte, root.sessione, testo];
        processo.running = true;
    }

    function nuovaChat() {
        if (occupato) processo.signal(15);
        sessione = "";
        messaggi.clear();
    }

    Process {
        id: processo
        stdout: SplitParser { onRead: dati => root.gestisci(dati) }
        stderr: SplitParser { onRead: dati => console.warn("claude:", dati) }
        onExited: (codice, stato) => {
            root.occupato = false;
            if (codice !== 0 && codice !== 143)
                root.aggiungi("errore", "Claude Code è terminato con codice " + codice);
        }
    }

    IpcHandler {
        target: "assistente"
        function toggle(): void { root.aperto = !root.aperto; }
        function apri(): void { root.aperto = true; }
        function chiudi(): void { root.aperto = false; }
        function chiedi(testo: string): void { root.aperto = true; root.invia(testo); }
    }

    PanelWindow {
        id: finestra
        visible: root.aperto
        color: "transparent"

        WlrLayershell.namespace: "assistente-claude"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.aperto ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.right: true
        anchors.bottom: true
        margins.top: 64       // sotto la barra di serpantinum
        margins.right: 12
        margins.bottom: 12
        implicitWidth: 520

        Rectangle {
            id: pannello
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(root.cSfondo.r, root.cSfondo.g, root.cSfondo.b, 0.94)
            border.width: 1
            border.color: Qt.rgba(root.cTesto.r, root.cTesto.g, root.cTesto.b, 0.08)

            // Esc chiude il pannello
            Keys.onEscapePressed: root.aperto = false

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // ── Intestazione ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: root.occupato ? root.cAccento : root.cTenue
                        SequentialAnimation on opacity {
                            running: root.occupato
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 600 }
                            NumberAnimation { to: 1.0; duration: 600 }
                        }
                    }
                    Text {
                        text: "Claude"
                        color: root.cTesto
                        font.family: root.font
                        font.pixelSize: 20
                        font.weight: Font.Medium
                    }
                    Text {
                        text: root.occupato ? "sta lavorando…" : "assistente del desktop"
                        color: root.cTenue
                        font.family: root.font
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 92; height: 30; radius: 15
                        color: areaNuova.containsMouse ? root.cSuperf2 : root.cSuperf
                        Text {
                            anchors.centerIn: parent
                            text: "Nuova chat"
                            color: root.cTesto
                            font.family: root.font
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: areaNuova
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nuovaChat()
                        }
                    }
                }

                // ── Messaggi ──
                ListView {
                    id: vista
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: messaggi
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Text {
                        visible: messaggi.count === 0
                        anchors.centerIn: parent
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        color: root.cTenue
                        font.family: root.font
                        font.pixelSize: 14
                        lineHeight: 1.3
                        text: "Chiedimi qualcosa, oppure di fare qualcosa sul desktop.\n\n" +
                              "«Metti Spotify nel workspace 3»\n«Cosa c'è aperto?»\n" +
                              "«Cambia sfondo con le colline»\n«Cosa vedi sullo schermo?»"
                    }

                    delegate: Item {
                        id: riga
                        required property string ruolo
                        required property string testo
                        width: vista.width
                        height: bolla.height

                        Rectangle {
                            id: bolla
                            readonly property bool utente: riga.ruolo === "utente"
                            readonly property bool piccola: riga.ruolo === "azione"
                            anchors.right: utente ? parent.right : undefined
                            anchors.left: utente ? undefined : parent.left
                            width: piccola ? Math.min(contenuto.implicitWidth + 24, vista.width)
                                           : Math.min(contenuto.implicitWidth + 28, vista.width * (utente ? 0.85 : 1.0))
                            height: contenuto.implicitHeight + (piccola ? 12 : 20)
                            radius: piccola ? 10 : 14
                            color: utente ? root.cSuperf2
                                 : riga.ruolo === "errore" ? Qt.rgba(root.cErrore.r, root.cErrore.g, root.cErrore.b, 0.15)
                                 : piccola ? "transparent"
                                 : root.cSuperf
                            border.width: piccola ? 1 : 0
                            border.color: Qt.rgba(root.cTesto.r, root.cTesto.g, root.cTesto.b, 0.12)

                            TextEdit {
                                id: contenuto
                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, vista.width * (bolla.utente ? 0.85 : 1.0) - 28)
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                textFormat: riga.ruolo === "claude" ? TextEdit.MarkdownText : TextEdit.PlainText
                                text: riga.ruolo === "azione" ? "⚙ " + riga.testo : riga.testo
                                color: riga.ruolo === "azione" ? root.cTenue
                                     : riga.ruolo === "errore" ? root.cErrore
                                     : root.cTesto
                                selectionColor: root.cAccento
                                font.family: root.font
                                font.pixelSize: riga.ruolo === "azione" ? 12 : 14
                            }
                        }
                    }
                }

                // ── Casella di testo ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Math.max(campo.implicitHeight + 20, 48), 160)
                    radius: 14
                    color: root.cSuperf
                    border.width: 1
                    border.color: campo.activeFocus ? Qt.rgba(root.cAccento.r, root.cAccento.g, root.cAccento.b, 0.5)
                                                    : "transparent"

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 10
                        TextArea {
                            id: campo
                            focus: root.aperto
                            wrapMode: TextArea.Wrap
                            placeholderText: root.occupato ? "Claude sta lavorando…" : "Scrivi a Claude…  (Invio per inviare, Maiusc+Invio per andare a capo)"
                            placeholderTextColor: root.cTenue
                            color: root.cTesto
                            font.family: root.font
                            font.pixelSize: 14
                            background: null
                            Keys.onPressed: evento => {
                                if ((evento.key === Qt.Key_Return || evento.key === Qt.Key_Enter)
                                        && !(evento.modifiers & Qt.ShiftModifier)) {
                                    root.invia(campo.text);
                                    campo.text = "";
                                    evento.accepted = true;
                                } else if (evento.key === Qt.Key_Escape) {
                                    root.aperto = false;
                                    evento.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
