# This script provides a graphical user interface (GUI) to modify and save RDP (Remote Desktop Protocol) file settings.
# It allows users to load an RDP file, adjust settings, save the updated file, and store/load configurations from the Windows registry.
# To convert this script to an executable, use a tool like `ps2exe`:
# Example: ps2exe.ps1 -inputFile rdptool.ps1 -outputFile C:\Data\Tools\rdpFileChanger\rdptool.exe -noConsole

# Pfad zur RDP-Datei aus Argumenten
param (
    [string]$RdpFilePath
)



# Benötigte PowerShell-Version
#requires -Version 5.1

# Einbinden von .NET Assemblies für GUI-Komponenten
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


# Initialisieren des HashTables für Registry-Einstellungen
$regsettings = @{}

# Überprüfen, ob der Pfad zur RDP-Datei angegeben wurde
if (-Not $RdpFilePath) {
    Write-Verbose "Bitte eine RDP-Datei angeben." -ForegroundColor Red
    return
}

# Überprüfen, ob die angegebene RDP-Datei existiert
if (-Not (Test-Path $RdpFilePath)) {
    Write-Verbose "Die angegebene Datei wurde nicht gefunden: $RdpFilePath" -ForegroundColor Red
    return
}

# Funktion zum Laden der .rdp-Datei
function Load-RdpFile {
    param ([string]$FilePath)

    # Überprüfen, ob die Datei existiert
    if (-Not (Test-Path $FilePath)) {
        Write-Verbose "Die Datei wurde nicht gefunden: $FilePath" -ForegroundColor Red
        return $null
    }

    # Laden des Datei-Inhalts und Parsen der Einstellungen
    $content = Get-Content -Path $FilePath
    $settings = @{}

    foreach ($line in $content) {
        if ($line -match "^(?<key>.+?):(?<value1>.+):(?<value>.+)") {
            $settings[$matches.key + ":" + $matches.value1 ] = $matches.value
        }
    }

    return $settings
}

# Funktion zum Speichern der .rdp-Datei
function Save-RdpFile {
    param (
        [string]$FilePath,
        [string]$FilePath1,
        [hashtable]$Settings
    )

    # Laden des Datei-Inhalts
    $content = Get-Content -Path $FilePath
    $updatedContent = @()
    $updatedKeys = @{}

    # Aktualisieren der Einstellungen im Datei-Inhalt
    foreach ($line in $content) {
        if ($line -match "^(?<key>.+?):(?<value1>.+):(?<value>.+)") {
            $key = $matches.key
            $value = $matches.value
            $value1 = $matches.value1
            if ($defaultSettings.ContainsKey($key+":"+$value1)) {
                if ($Settings.ContainsKey($key+":"+$value1)) {
                    $updatedContent += "$($key):$($value1):$($Settings[$key+":"+$value1])"
                    $updatedKeys[$key+":"+$value1] = $true
                } else {
                    $updatedContent += $line
                    $updatedKeys[$key+":"+$value1] = $true
                }
            } else {
                $updatedContent += $line
                $updatedKeys[$key+":"+$value1] = $true
            }
        } else {
            $updatedContent += $line
        }
    }

    # Hinzufügen neuer Einstellungen, die noch nicht im Datei-Inhalt sind
    foreach ($key in $Settings.Keys) {
        if (-Not $updatedKeys.ContainsKey($key)) {
            $updatedContent += "$($key):$($Settings[$key])"
        }
    }

    # Speichern des aktualisierten Datei-Inhalts
    Set-Content -Path $FilePath1 -Value $updatedContent -Force
}

# Funktion zum Speichern der Konfiguration in der Registry
function Save-ConfigToRegistry {
    param ([hashtable]$Settings)

    # Pfad zum Registry-Schlüssel
    $regKeyPath = "HKCU:\Software\ABXRDPConfig"
    if (-Not (Test-Path $regKeyPath)) {
        New-Item -Path $regKeyPath -Force | Out-Null
    }

    # Speichern der Einstellungen in der Registry
    foreach ($key in $Settings.Keys) {
        Set-ItemProperty -Path $regKeyPath -Name $key -Value $Settings[$key]
    }

    # Anzeigen einer Erfolgsmeldung
    [System.Windows.Forms.MessageBox]::Show("Konfiguration erfolgreich in der Registry gespeichert!", "Erfolg")
}

# Funktion zum Laden der Konfiguration aus der Registry
function Load-ConfigFromRegistry {
    param ()

    # Pfad zum Registry-Schlüssel
    $regKeyPath = "HKCU:\Software\ABXRDPConfig"
    $settings = @{}

    # Laden der Einstellungen aus der Registry
    if (Test-Path $regKeyPath) {
        $properties = Get-ItemProperty -Path $regKeyPath
        foreach ($property in $properties.PSObject.Properties) {
            if ($property.Name -ne "PSPath" -and $property.Name -ne "PSParentPath" -and $property.Name -ne "PSChildName" -and $property.Name -ne "PSDrive" -and $property.Name -ne "PSProvider") {
                $settings[$property.Name] = $property.Value
            }
        }
    }

    return $settings
}

function get-settings-from-gui {
    param ([hashtable]$controls1) 

$settings = @{}


    foreach ($key in $controls1.Keys) {
        if ($controls1[$key] -is [System.Collections.Hashtable]) {
            # Handle binary values
            if ($controls1[$key].Yes.Checked) {
                $settings[$key] = "1"
            } elseif ($controls1[$key].No.Checked) {
                $settings[$key] = "0"
            }
        } elseif ($key -eq "screenResolutions:i") {
            foreach ($radioButton in $controls1["screenResolutions:i"].Controls) {
                if ($radioButton.Checked) {
#                    $settings[$key] = $radioButton.Text
                    $selectedResolution = $radioButton.Text -split "x"
                    $settings["desktopwidth:i"] = $selectedResolution[0]
                    $settings["desktopheight:i"] = $selectedResolution[1]
                    break
                }
            }
        } elseif ($key -eq "desktopwidth:i") {
        } elseif ($key -eq "desktopheight:i") {
        } else {
        # Handle non-binary values
        $settings[$key] = $controls1[$key].Text
        }   
    }
  
    return $Settings

}


function set-gui-from-settings {
    foreach ($radioButton in $controls["screenResolutions:i"].Controls) {
        if ($radioButton.Text -eq "$($settings["desktopwidth:i"])x$($settings["desktopheight:i"])") {
            $radioButton.Checked = $true
            break
        }
    }

    foreach ($key in $defaultSettings.Keys) {
        if ($controls.ContainsKey($key)) {
            if ($controls.ContainsKey($key)) {
                if ($controls[$key] -is [System.Collections.Hashtable]) {
                    $controls[$key].Yes.Checked = ($settings[$key] -eq "1")
                    $controls[$key].No.Checked = ($settings[$key] -eq "0")
                } else {
                    $controls[$key].Text = $settings[$key]
                }
            }
        }
    }

 
}

[System.Windows.Forms.Application]::EnableVisualStyles()



# Initiale Einstellungen (Defaults)
$defaultSettings = @{
    "use multimon:i" = "0"  # Ermöglicht die Verwendung mehrerer Monitore
    "screenResolutions:i" = "1600x768"
    "audiocapturemode:i" = "1"  # Aktiviert die Audiowiedergabe auf dem Client
    "redirectclipboard:i" = "1"  # Ermöglicht das Umleiten der Zwischenablage
    "redirectprinters:i" = "1"  # Aktiviert die Druckerumleitung
    "dynamic resolution:i" = "1"  # Passt die Auflösung dynamisch an
    "desktopwidth:i:" ="1600"  # Setzt die Desktopbreite in Pixeln
    "desktopheight:i:" = "960"  # Setzt die Desktophöhe in Pixeln
    "screen mode id:i" = "1"  # Setzt den Bildschirmmodus (2 = Vollbild)
}

# Übliche Bildschirmgrößen (kann im File konfiguriert werden)
$screenResolutions = @(
    "1024x768",
    "1280x800",
    "1366x768",
    "1440x900",
    "1600x900",
    "1920x1080",
    "1920x950",
    "2560x1400",
    "2500x1350",
    "3200x1350",
    "3840x2160"
)

# Laden der Einstellungen aus der RDP-Datei oder Verwendung der Standardwerte
$settings = Load-RdpFile -FilePath $RdpFilePath

if (-Not $settings) {
    $settings = $defaultSettings
}

# Erstellen der GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "RDP-Einstellungen anpassen"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.Font = New-Object System.Drawing.Font("Arial Unicode MS", 8.25)

$y = 10

# Initialisieren der Steuerelemente
$controls = @{}

# Hinzufügen der Steuerelemente für die Einstellungen
foreach ($key in $defaultSettings.Keys) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = @{
        "use multimon:i" = "Verwende mehrere Monitore"
        "screenResolutions:i" = "Bildschirmgrösse"
        "audiocapturemode:i" = "Aktiviere Audioaufnahme"
        "redirectclipboard:i" = "Leite Zwischenablage um"
        "redirectprinters:i" = "Leite Drucker um"
        "dynamic resolution:i" = "Aktiviere dynamische Auflösung"
        "screen mode id:i" = "Setze Bildschirmmodus (1=Fenter)"
    }[$key]
    $label.Location = New-Object System.Drawing.Point(10, $y)
    $label.Font = [System.Drawing.SystemFonts]::DefaultFont
    # Measure the size of the text in the label
    $labelSize = [System.Windows.Forms.TextRenderer]::MeasureText($label.Text, $label.Font)
    # Set the size of the label based on the measured size
    $label.Size = New-Object System.Drawing.Size(($labelSize.Width + 20), ($labelSize.Height +5))
    $form.Controls.Add($label)

    if ($key -eq "screen mode id:i") {
        # Verwenden eines TextBox für nicht-binäre Werte
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Text = if ($settings[$key] -ne $null) { $settings[$key] } else { $defaultSettings[$key] }
        $textBox.Location = New-Object System.Drawing.Point(270, $y)
        $textBox.Size = New-Object System.Drawing.Size(300, 20)
        $form.Controls.Add($textBox)

        $controls[$key] = $textBox

    } elseif ($defaultSettings[$key] -match "^[01]$") {
        # Verwenden von Radiobuttons für binäre Werte
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Location = New-Object System.Drawing.Point(270, $y)
        $panel.Size = New-Object System.Drawing.Size(300, 30)
        $form.Controls.Add($panel)

        $radioYes = New-Object System.Windows.Forms.RadioButton
        $radioYes.Text = "Ja"
        $radioYes.Location = New-Object System.Drawing.Point(0, 0)
        $radioYes.Checked = ($settings[$key] -eq "1") -or ($settings[$key] -eq $null -and $defaultSettings[$key] -eq "1")
        $panel.Controls.Add($radioYes)

        $radioNo = New-Object System.Windows.Forms.RadioButton
        $radioNo.Text = "Nein"
        $radioNo.Location = New-Object System.Drawing.Point(110, 0)
        $radioNo.Checked = ($settings[$key] -eq "0") -or ($settings[$key] -eq $null -and $defaultSettings[$key] -eq "0")
        $panel.Controls.Add($radioNo)

        $controls[$key] = @{
            "Yes" = $radioYes
            "No" = $radioNo
        }
        } elseif ($key -eq "screenResolutions:i") {
        # Verwenden eines Panels für Bildschirmauflösungen
        $resolutionPanel = New-Object System.Windows.Forms.Panel
        $resolutionPanel.Location = New-Object System.Drawing.Point(270, $y)
        $resolutionPanel.Size = New-Object System.Drawing.Size(300, 100)
        $form.Controls.Add($resolutionPanel)

        $columnCount = 3
        $columnWidth = 110
        $rowHeight = 20
        $index = 0
        $y += 50


        foreach ($resolution in $screenResolutions) {
            $radioResolution = New-Object System.Windows.Forms.RadioButton
            $radioResolution.Text = $resolution
            $radioResolution.Location = New-Object System.Drawing.Point((($index % $columnCount) * $columnWidth), ([math]::Floor($index / $columnCount) * $rowHeight))
            $radioResolution.Checked = ($resolution -eq "$($settings["desktopwidth:i"])x$($settings["desktopheight:i"])")
            $resolutionPanel.Controls.Add($radioResolution)
            $index++
        }

        $controls[$key] = $resolutionPanel
        
        }  elseif ($key -eq "desktopwidth:i:" -or $key -eq "desktopheight:i:" ) {
        # Skip width and height for now, add combo box later
        
    } else {
        # Verwenden eines TextBox für nicht-binäre Werte
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Text = if ($settings[$key] -ne $null) { $settings[$key] } else { $defaultSettings[$key] }
        $textBox.Location = New-Object System.Drawing.Point(270, $y)
        $textBox.Font = [System.Drawing.SystemFonts]::DefaultFont
        # Measure the size of the text in the label
        $labelSize = [System.Windows.Forms.TextRenderer]::MeasureText($textBox.Text, $textBox.Font)
        # Set the size of the label based on the measured size
        $textBox.Size = New-Object System.Drawing.Size(($labelSize.Width + 20), ($labelSize.Height +5))
        $form.Controls.Add($textBox)

        $controls[$key] = $textBox
    }

    $y += 30
}

$y += 40

$insertText = "user_"

# System-Temp-Verzeichnis und Dateiname festlegen
$tempDirectory = [System.IO.Path]::GetTempPath()
$tempFileName = [System.IO.Path]::GetFileName($RdpFilePath)
$RdpFilePath1 = Join-Path -Path $tempDirectory -ChildPath $tempFileName

# Hinzufügen des Buttons zum Speichern in die Registry
$saveRegistryButton = New-Object System.Windows.Forms.Button
$saveRegistryButton.Text = "In Registry speichern"
$saveRegistryButton.Location = New-Object System.Drawing.Point(10, $y)
$saveRegistryButton.Font = [System.Drawing.SystemFonts]::DefaultFont
# Measure the size of the text in the label
$labelSize = [System.Windows.Forms.TextRenderer]::MeasureText($saveRegistryButton.Text, $saveRegistryButton.Font)
# Set the size of the label based on the measured size
$saveRegistryButton.Size = New-Object System.Drawing.Size(($labelSize.Width + 20), ($labelSize.Height +5))

$saveRegistryButton.Add_Click({

    $regsettings = get-settings-from-gui($controls)

    Save-ConfigToRegistry -Settings $regsettings
})

$form.Controls.Add($saveRegistryButton)

# Hinzufügen des Buttons zum Anwenden der Einstellungen aus der Registry
$applyRegistryButton = New-Object System.Windows.Forms.Button
$applyRegistryButton.Text = "Aus Registry anwenden"
$applyRegistryButton.Location = New-Object System.Drawing.Point(150, $y)
$applyRegistryButton.Font = [System.Drawing.SystemFonts]::DefaultFont
# Measure the size of the text in the label
$labelSize = [System.Windows.Forms.TextRenderer]::MeasureText($applyRegistryButton.Text, $applyRegistryButton.Font)
# Set the size of the label based on the measured size
$applyRegistryButton.Size = New-Object System.Drawing.Size(($labelSize.Width + 20), ($labelSize.Height +5))

$applyRegistryButton.Add_Click({
    $registrySettings = Load-ConfigFromRegistry
    if ($registrySettings.Count -gt 0) {
        $settings = $registrySettings
    } else {
        $settings = $defaultSettings
        [System.Windows.Forms.MessageBox]::Show("Keine gespeicherte Konfiguration gefunden. Standardwerte werden angewendet.", "Hinweis")
    }

    set-gui-from-settings($settings)

})

$form.Controls.Add($applyRegistryButton)

$y += 40

# Hinzufügen des Buttons zum Speichern der Einstellungen
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Speichern"
$saveButton.Location = New-Object System.Drawing.Point(10, $y)
$saveButton.Add_Click({

    $settings = get-settings-from-gui($controls)

    Save-RdpFile -FilePath $RdpFilePath -FilePath1 $RdpFilePath1 -Settings $settings
    # [System.Windows.Forms.MessageBox]::Show("Einstellungen gespeichert!", "Erfolg")
    $form.Close()
})

$form.Controls.Add($saveButton)

# Hinzufügen des Buttons zum Starten der RDP-Verbindung
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Starten"
$startButton.Location = New-Object System.Drawing.Point(100, $y)
$startButton.Add_Click({

    $settings = @{}
    $settings = get-settings-from-gui($controls)

    Save-RdpFile -FilePath $RdpFilePath -FilePath1 $RdpFilePath1 -Settings $settings
    Start-Process -FilePath "mstsc.exe" -ArgumentList $RdpFilePath1
    # [System.Windows.Forms.MessageBox]::Show("Verbindung gestartet!", "Erfolg")
    $form.Close()
})
$form.Controls.Add($startButton)
$form.AcceptButton = $startButton

# Anzeigen des Formulars
$form.ShowDialog()
