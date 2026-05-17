# ── Hide Console Window ───────────────────────────────────────────────────────
Add-Type -Name WinAPI -Namespace "" -MemberDefinition @'
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]   public static extern short GetAsyncKeyState(int vKey);
'@
[WinAPI]::ShowWindow([WinAPI]::GetConsoleWindow(), 0) | Out-Null

# ── CoreAudio Volume + Mute Control ──────────────────────────────────────────
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorCls {}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int R1();
    [PreserveSig] int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    [PreserveSig] int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams,
        [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
}
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int R1(); int R2(); int R3(); int R4();
    [PreserveSig] int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int R5();
    [PreserveSig] int GetMasterVolumeLevelScalar(out float pfLevel);
    int R6(); int R7(); int R8(); int R9();
    [PreserveSig] int SetMute(bool bMute, Guid pguidEventContext);
    [PreserveSig] int GetMute(out bool pbMute);
}
public class AudioCtrl {
    static IAudioEndpointVolume EP() {
        var e = (IMMDeviceEnumerator)new MMDeviceEnumeratorCls();
        IMMDevice d; e.GetDefaultAudioEndpoint(0, 1, out d);
        var g = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
        object o; d.Activate(ref g, 23, IntPtr.Zero, out o);
        return (IAudioEndpointVolume)o;
    }
    public static void Set(float v)    { EP().SetMasterVolumeLevelScalar(v, Guid.Empty); }
    public static float Get()          { float v; EP().GetMasterVolumeLevelScalar(out v); return v; }
    public static void SetMute(bool m) { EP().SetMute(m, Guid.Empty); }
    public static bool GetMute()       { bool m; EP().GetMute(out m); return m; }
}
'@

# Save original state, unmute and force 50%
$script:origVol  = [AudioCtrl]::Get()
$script:origMute = [AudioCtrl]::GetMute()
[AudioCtrl]::SetMute($false)
[AudioCtrl]::Set(0.50)

# ── Download MP3 silently in background ───────────────────────────────────────
Start-Job -ScriptBlock {
    $dest = "$env:USERPROFILE\TOOTHLESS"
    if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
    $out = "$dest\toothless.mp3"
    if (!(Test-Path $out)) {
        curl.exe -L --ssl-no-revoke -o $out "https://drive.usercontent.google.com/u/0/uc?id=1Ph-0mHRmxhbeavBaDUHUna0k7jVQaaJu&export=download"
    }
} | Out-Null

# ── WinForms Setup ────────────────────────────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$gifUrl  = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/3b14503d-34f3-4d4a-97c5-55df02571188/dgq6axy-46697be1-04da-4650-a7c4-33a6466edb32.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi8zYjE0NTAzZC0zNGYzLTRkNGEtOTdjNS01NWRmMDI1NzExODgvZGdxNmF4eS00NjY5N2JlMS0wNGRhLTQ2NTAtYTdjNC0zM2E2NDY2ZWRiMzIuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.3z67Wys6W3OM37SHea9frI_lrCggRdkC3GPexKlQlK8"
$gifTemp = "$env:TEMP\toothless.gif"
if (!(Test-Path $gifTemp)) { Invoke-WebRequest -Uri $gifUrl -OutFile $gifTemp }

$script:allowClose = $false

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Toothless"
$form.Size            = New-Object System.Drawing.Size(300, 300)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false
$form.StartPosition   = "Manual"
$form.TopMost         = $true
$form.Add_FormClosing({ if (-not $script:allowClose) { $_.Cancel = $true } })

$pic          = New-Object System.Windows.Forms.PictureBox
$pic.Dock     = "Fill"
$pic.SizeMode = "StretchImage"
$pic.Image    = [System.Drawing.Image]::FromFile($gifTemp)
$form.Controls.Add($pic)

$screen    = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Left = Get-Random -Minimum 0 -Maximum ($screen.Width  - 300)
$form.Top  = Get-Random -Minimum 0 -Maximum ($screen.Height - 300)
$script:dx = 5
$script:dy = 5

# ── Bounce Timer ──────────────────────────────────────────────────────────────
$bounceTimer          = New-Object System.Windows.Forms.Timer
$bounceTimer.Interval = 20
$bounceTimer.Add_Tick({
    $form.Left += $script:dx
    $form.Top  += $script:dy
    if ($form.Left -le 0 -or ($form.Left + $form.Width)  -ge $screen.Width)  { $script:dx = -$script:dx }
    if ($form.Top  -le 0 -or ($form.Top  + $form.Height) -ge $screen.Height) { $script:dy = -$script:dy }
})
$bounceTimer.Start()

# ── Music: poll until MP3 downloaded then play ────────────────────────────────
$script:wmp     = $null
$script:mp3Path = "$env:USERPROFILE\TOOTHLESS\toothless.mp3"

$musicTimer          = New-Object System.Windows.Forms.Timer
$musicTimer.Interval = 2000
$musicTimer.Add_Tick({
    if ($script:wmp -eq $null -and (Test-Path $script:mp3Path)) {
        $script:wmp     = New-Object -ComObject WMPlayer.OCX
        $script:wmp.URL = $script:mp3Path
        $script:wmp.controls.play()
        $musicTimer.Stop()
    }
})
$musicTimer.Start()

# ── Volume Enforcer: unmute + lock at 30% every 500ms ────────────────────────
$volTimer          = New-Object System.Windows.Forms.Timer
$volTimer.Interval = 500
$volTimer.Add_Tick({
    try {
        if ([AudioCtrl]::GetMute())                                  { [AudioCtrl]::SetMute($false) }
        if ([math]::Abs([AudioCtrl]::Get() - 0.30) -gt 0.01)        { [AudioCtrl]::Set(0.30) }
    } catch {}
})
$volTimer.Start()

# ── Kill Switch: press 8 three times within 3 seconds ────────────────────────
$script:eightCount = 0
$script:lastEight  = [DateTime]::MinValue
$script:prevDown   = $false

$killTimer          = New-Object System.Windows.Forms.Timer
$killTimer.Interval = 30
$killTimer.Add_Tick({
    $isDown = (([WinAPI]::GetAsyncKeyState(0x38) -band 0x8000) -ne 0) -or
              (([WinAPI]::GetAsyncKeyState(0x68) -band 0x8000) -ne 0)

    if ($isDown -and -not $script:prevDown) {
        $now = [DateTime]::Now
        if (($now - $script:lastEight).TotalSeconds -gt 3) { $script:eightCount = 0 }
        $script:eightCount++
        $script:lastEight = $now

        if ($script:eightCount -ge 3) {
            $bounceTimer.Stop()
            $musicTimer.Stop()
            $volTimer.Stop()
            $killTimer.Stop()
            if ($script:wmp) { try { $script:wmp.controls.stop() } catch {} }
            [AudioCtrl]::Set($script:origVol)
            [AudioCtrl]::SetMute($script:origMute)
            $script:allowClose = $true
            $form.Close()
        }
    }
    $script:prevDown = $isDown
})
$killTimer.Start()

[void]$form.ShowDialog()
