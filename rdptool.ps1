# Pfad zur RDP-Datei aus Argumenten
param (
    [string]$RdpFilePath
)

#requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$regsettings = @{}


if (-Not $RdpFilePath) {
    Write-Host "Bitte eine RDP-Datei angeben." -ForegroundColor Red
    return
}

if (-Not (Test-Path $RdpFilePath)) {
    Write-Host "Die angegebene Datei wurde nicht gefunden: $RdpFilePath" -ForegroundColor Red
    return
}

# Funktion zum Laden der .rdp-Datei
function Load-RdpFile {
    param ([string]$FilePath)

    if (-Not (Test-Path $FilePath)) {
        Write-Host "Die Datei wurde nicht gefunden: $FilePath" -ForegroundColor Red
        return $null
    }

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

    $content = Get-Content -Path $FilePath
    $updatedContent = @()
    $updatedKeys = @{}

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


    foreach ($key in $Settings.Keys) {
        if (-Not $updatedKeys.ContainsKey($key)) {
            $updatedContent += "$($key):$($Settings[$key])"
        }
    }

    Set-Content -Path $FilePath1 -Value $updatedContent -Force
}

# Funktion zum Speichern der Konfiguration in der Registry
function Save-ConfigToRegistry {
    param ([hashtable]$Settings)

    $regKeyPath = "HKCU:\Software\ABXRDPConfig"
    if (-Not (Test-Path $regKeyPath)) {
        New-Item -Path $regKeyPath -Force | Out-Null
    }

    foreach ($key in $Settings.Keys) {
        Set-ItemProperty -Path $regKeyPath -Name $key -Value $Settings[$key]
    }

    [System.Windows.Forms.MessageBox]::Show("Konfiguration erfolgreich in der Registry gespeichert!", "Erfolg")
}

# Funktion zum Laden der Konfiguration aus der Registry
function Load-ConfigFromRegistry {
    param ()

    $regKeyPath = "HKCU:\Software\ABXRDPConfig"
    $settings = @{}

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

}

# Übliche Bildschirmgrößen (kann im File konfiguriert werden)
$screenResolutions = @(
    "1024x768",
    "1280x800",
    "1366x768",
    "1440x900",
    "1600x900",
    "1920x1080",
    "2560x1440",
    "3840x2160"
)


$settings = Load-RdpFile -FilePath $RdpFilePath

if (-Not $settings) {
    $settings = $defaultSettings
}

# GUI erstellen
$form = New-Object System.Windows.Forms.Form
$form.Text = "RDP-Einstellungen anpassen"
$form.Size = New-Object System.Drawing.Size(600, 500)

$y = 10

$controls = @{}




foreach ($key in $defaultSettings.Keys) {
   
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "" + @{
        "use multimon:i" = "Verwende mehrere Monitore"
        "audiocapturemode:i" = "Aktiviere Audioaufnahme"
        "redirectclipboard:i" = "Leite Zwischenablage um"
        "redirectdrives:i" = "Leite lokale Laufwerke um"
        "redirectprinters:i" = "Leite Drucker um"
        "dynamic resolution:i" = "Aktiviere dynamische Auflösung"
        "screen mode id:i" = "Setze Bildschirmmodus (1=Fenter)"
    }[$key]
    $label.Location = New-Object System.Drawing.Point(10, $y)
    $label.Size = New-Object System.Drawing.Size(250, 20)
    $form.Controls.Add($label)

    if ($defaultSettings[$key] -match "^[01]$") {
        # Use radio buttons for binary values
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
        $radioNo.Location = New-Object System.Drawing.Point(100, 0)
        $radioNo.Checked = ($settings[$key] -eq "0") -or ($settings[$key] -eq $null -and $defaultSettings[$key] -eq "0")
        $panel.Controls.Add($radioNo)

        $controls[$key] = @{
            "Yes" = $radioYes
            "No" = $radioNo
        }
    } elseif ($key -eq "screenResolutions:i") {
        $resolutionComboBox = New-Object System.Windows.Forms.ComboBox
        $resolutionComboBox.Location = New-Object System.Drawing.Point(270, $y)
        $resolutionComboBox.Size = New-Object System.Drawing.Size(300, 20)
        $resolutionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $resolutionComboBox.Items.AddRange($screenResolutions)
        $resolutionComboBox.SelectedItem = "$($settings["desktopwidth:i:"])x$($settings["desktopheight:i:"])"
        $form.Controls.Add($resolutionComboBox)    
        $controls[$key] = "$($settings["desktopwidth:i:"])x$($settings["desktopheight:i:"])"
    
    }  elseif ($key -eq "desktopwidth:i:" -or $key -eq "desktopheight:i:") {
        # Skip width and height for now, add combo box later
        
    } else {
        # Use a text box for non-binary values
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Text = if ($settings[$key] -ne $null) { $settings[$key] } else { $defaultSettings[$key] }
        $textBox.Location = New-Object System.Drawing.Point(270, $y)
        $textBox.Size = New-Object System.Drawing.Size(300, 20)
        $form.Controls.Add($textBox)

        $controls[$key] = $textBox
    }

    $y += 30

}



$y += 40

$insertText = "user_"

# Datei- und Verzeichnisinformationen extrahieren
$directory = Split-Path $RdpFilePath
$filename = [System.IO.Path]::GetFileNameWithoutExtension($RdpFilePath)
$extension = [System.IO.Path]::GetExtension($RdpFilePath)

# Neuen Dateinamen erstellen
$newFilename = "$insertText$filename$extension"

# Neuer vollständiger Pfad
$RdpFilePath1 = Join-Path -Path $directory -ChildPath $newFilename
$RdpFilePath1

$saveRegistryButton = New-Object System.Windows.Forms.Button
$saveRegistryButton.Text = "In Registry speichern"
$saveRegistryButton.Location = New-Object System.Drawing.Point(10, $y)
$saveRegistryButton.Add_Click({
    
    $selectedResolution = $resolutionComboBox.SelectedItem -split "x"
    $settings["desktopwidth:i"] = $selectedResolution[0]
    $settings["desktopheight:i"] = $selectedResolution[1]
    
    foreach ($key in $defaultSettings.Keys) {
        if ($controls[$key] -is [System.Collections.Hashtable]) {
            $regsettings[$key] = if ($controls[$key].Yes.Checked) { "1" } else { "0" }
        } else {
            if ($key -eq "screenResolutions:i") {
                $regsettings[$key] = $resolutionComboBox.SelectedItem
            }
            if ($key -eq "desktopwidth:i:" ) {
                $regsettings[$key] =  $settings["desktopwidth:i"]
            }
            if ( $key -eq "desktopheight:i:") {
                $regsettings[$key] = $settings["desktopheight:i"]
            }

        }
    }
    Save-ConfigToRegistry -Settings $regsettings
})
$form.Controls.Add($saveRegistryButton)

$applyRegistryButton = New-Object System.Windows.Forms.Button
$applyRegistryButton.Text = "Aus Registry anwenden"
$applyRegistryButton.Location = New-Object System.Drawing.Point(150, $y)
$applyRegistryButton.Add_Click({
    $registrySettings = Load-ConfigFromRegistry
    if ($registrySettings.Count -gt 0) {
        $settings = $registrySettings
    } else {
        $settings = $defaultSettings
        [System.Windows.Forms.MessageBox]::Show("Keine gespeicherte Konfiguration gefunden. Standardwerte werden angewendet.", "Hinweis")
    }

    $resolutionComboBox.SelectedItem = "$($settings["desktopwidth:i:"])x$($settings["desktopheight:i:"])"

    
    foreach ($key in $settings.Keys) {
        if ($controls.ContainsKey($key)) {
            if ($controls[$key] -is [System.Collections.Hashtable]) {
                $controls[$key].Yes.Checked = ($settings[$key] -eq "1")
                $controls[$key].No.Checked = ($settings[$key] -eq "0")
            } else {
                $controls[$key].Text = $settings[$key]
            }
        }
    }
})
$form.Controls.Add($applyRegistryButton)

$y += 40


$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Speichern"
$saveButton.Location = New-Object System.Drawing.Point(10, $y)
$saveButton.Add_Click({
    foreach ($key in $controls.Keys) {
        if ($controls[$key] -is [System.Collections.Hashtable]) {
            # Handle binary values
            if ($controls[$key].Yes.Checked) {
                $settings[$key] = "1"
            } elseif ($controls[$key].No.Checked) {
                $settings[$key] = "0"
            }
        } else {
            # Handle non-binary values
            $settings[$key] = $controls[$key].Text
        }
    } 
    $selectedResolution = $resolutionComboBox.SelectedItem -split "x"
    $settings["desktopwidth:i"] = $selectedResolution[0]
    $settings["desktopheight:i"] = $selectedResolution[1]

    Save-RdpFile -FilePath $RdpFilePath -FilePath1 $RdpFilePath1 -Settings $settings
 #   [System.Windows.Forms.MessageBox]::Show("Einstellungen gespeichert!", "Erfolg")
    $form.Close()
})
$form.Controls.Add($saveButton)

# Add Start Button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Starten"
$startButton.Location = New-Object System.Drawing.Point(100, $y)
$startButton.Add_Click({
    foreach ($key in $controls.Keys) {
        if ($controls[$key] -is [System.Collections.Hashtable]) {
            # Handle binary values
            if ($controls[$key].Yes.Checked) {
                $settings[$key] = "1"
            } elseif ($controls[$key].No.Checked) {
                $settings[$key] = "0"
            }
        } else {
            # Handle non-binary values
            $settings[$key] = $controls[$key].Text
        }
    }

    $selectedResolution = $resolutionComboBox.SelectedItem -split "x"
    $settings["desktopwidth:i"] = $selectedResolution[0]
    $settings["desktopheight:i"] = $selectedResolution[1]

    Save-RdpFile -FilePath $RdpFilePath -FilePath1 $RdpFilePath1 -Settings $settings
    Start-Process -FilePath "mstsc.exe" -ArgumentList $RdpFilePath1
#    [System.Windows.Forms.MessageBox]::Show("Verbindung gestartet!", "Erfolg")
    $form.Close()
})
$form.Controls.Add($startButton)
$form.AcceptButton = $startButton


$form.ShowDialog()
