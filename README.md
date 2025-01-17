# RDP Configuration Tool Documentation

## Übersicht
Dieses Tool ermöglicht die einfache Bearbeitung von RDP-Dateien über eine grafische Benutzeroberfläche (GUI). Es unterstützt Funktionen wie:

- Anpassung der RDP-Einstellungen.
- Speicherung der Konfiguration in der Windows-Registry.
- Anwenden gespeicherter Konfigurationen.
- Starten einer RDP-Verbindung mit den angepassten Einstellungen.

## Wie benutzen
### Voraussetzungen
1. PowerShell 5.1 oder höher.
2. Windows mit aktiviertem Zugriff auf die Registry.
3. rdptool.ps1 in ein exe umwandeln, ev. signieren
4. .rdp Filetype autostart für das rdptool.exe konfigurieren

### Nutzung
1. Speichern Sie das Skript als `rdp_config_tool.ps1`.
2. Führen Sie das Skript mit einer RDP-Datei als Parameter aus:
   ```powershell
   .\rdp_config_tool.ps1 -RdpFilePath "C:\Path\to\your.rdp"
   ```
3. Nutzen Sie die GUI, um Änderungen vorzunehmen:
   - **Einstellungen anpassen:** Bearbeiten Sie die Werte in der GUI.
   - **In Registry speichern:** Speichert die aktuelle Konfiguration in der Windows-Registry.
   - **Aus Registry anwenden:** Lädt die gespeicherte Konfiguration aus der Registry und wendet sie an.
   - **Starten:** Speichert die Einstellungen und startet die RDP-Verbindung.

### Nutzung automatisch
1. Speichern Sie das Skript als `rdp_config_tool.ps1`.
2. Exe Datei erstellen
3. RDP Datei mit öffnen mit öffnen und rdptool.exe auswählen.
4. Nutzen Sie die GUI, um Änderungen vorzunehmen:
   - **Einstellungen anpassen:** Bearbeiten Sie die Werte in der GUI.
   - **In Registry speichern:** Speichert die aktuelle Konfiguration in der Windows-Registry.
   - **Aus Registry anwenden:** Lädt die gespeicherte Konfiguration aus der Registry und wendet sie an.
   - **Starten:** Speichert die Einstellungen und startet die RDP-Verbindung.
  
## Exe erstellen
### 1. Script signieren
1. Erstellen Sie ein selbstsigniertes Zertifikat:
   ```powershell
   New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=RDP Tool Signing" -CertStoreLocation Cert:\CurrentUser\My
   ```
2. Signieren Sie das Skript:
   ```powershell
   $cert = Get-Item Cert:\CurrentUser\My\<Thumbprint>
   Set-AuthenticodeSignature -FilePath "rdp_config_tool.ps1" -Certificate $cert
   ```

### 2. Skript in eine ausführbare Datei konvertieren
Nutzen Sie das Modul `ps2exe`:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser
ps2exe -inputFile "rdp_config_tool.ps1" -outputFile "rdp_config_tool.exe"
```

### 3. Optional: EXE signieren
Nutzen Sie `signtool.exe` aus dem Windows SDK:
```cmd
signtool sign /fd SHA256 /a /tr http://timestamp.digicert.com /td SHA256 /f "C:\path\to\cert.pfx" /p YourPassword "rdp_config_tool.exe"
```

## Mögliche Erweiterungen
1. Fehlerkontrollen
