
# ══════════════════════════════════════════════════════════════════════════════
# TOOTHLESS
# ══════════════════════════════════════════════════════════════════════════════
#
#  • Downloads GIF + MP3 to:
#       C:\Users\<USERNAME>\TOOTHLESS\
#
#  • Plays the GIF locally
#  • Plays the MP3 on loop
#  • Volume = 30% normally
#  • Lid closed = 50%
#  • Keeps laptop awake with lid closed
#  • Triple-press I within 2 seconds = EMERGENCY STOP
#  • Restores original Windows settings when stopped
#
# ══════════════════════════════════════════════════════════════════════════════


# ──────────────────────────────────────────────────────────────────────────────
# HIDE CONSOLE
# ──────────────────────────────────────────────────────────────────────────────

Add-Type -Name WinAPI -Namespace "" -MemberDefinition @'
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
'@

[WinAPI]::ShowWindow(
    [WinAPI]::GetConsoleWindow(),
    0
) | Out-Null


# ──────────────────────────────────────────────────────────────────────────────
# AUDIO CONTROL
# ──────────────────────────────────────────────────────────────────────────────

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorCls {}

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
    int R1();

    [PreserveSig]
    int GetDefaultAudioEndpoint(
        int dataFlow,
        int role,
        out IMMDevice ppDevice
    );
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
    [PreserveSig]
    int Activate(
        ref Guid iid,
        int dwClsCtx,
        IntPtr pActivationParams,
        [MarshalAs(UnmanagedType.IUnknown)]
        out object ppInterface
    );
}

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
    int R1();
    int R2();
    int R3();
    int R4();

    [PreserveSig]
    int SetMasterVolumeLevelScalar(
        float fLevel,
        Guid pguidEventContext
    );

    int R5();

    [PreserveSig]
    int GetMasterVolumeLevelScalar(
        out float pfLevel
    );

    int R6();
    int R7();
    int R8();
    int R9();

    [PreserveSig]
    int SetMute(
        bool bMute,
        Guid pguidEventContext
    );

    [PreserveSig]
    int GetMute(
        out bool pbMute
    );
}

public class AudioCtrl
{
    static IAudioEndpointVolume EP()
    {
        var e =
            (IMMDeviceEnumerator)new MMDeviceEnumeratorCls();

        IMMDevice d;

        e.GetDefaultAudioEndpoint(
            0,
            1,
            out d
        );

        var g =
            new Guid(
                "5CDF2C82-841E-4546-9722-0CF74078229A"
            );

        object o;

        d.Activate(
            ref g,
            23,
            IntPtr.Zero,
            out o
        );

        return (IAudioEndpointVolume)o;
    }

    public static void Set(float v)
    {
        EP().SetMasterVolumeLevelScalar(
            v,
            Guid.Empty
        );
    }

    public static float Get()
    {
        float v;

        EP().GetMasterVolumeLevelScalar(
            out v
        );

        return v;
    }

    public static void SetMute(bool m)
    {
        EP().SetMute(
            m,
            Guid.Empty
        );
    }

    public static bool GetMute()
    {
        bool m;

        EP().GetMute(
            out m
        );

        return m;
    }
}
'@


# ──────────────────────────────────────────────────────────────────────────────
# KEEP WINDOWS AWAKE
# ──────────────────────────────────────────────────────────────────────────────

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class PowerKeepAwake
{
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(
        uint esFlags
    );

    public const uint ES_CONTINUOUS       = 0x80000000;
    public const uint ES_SYSTEM_REQUIRED  = 0x00000001;
    public const uint ES_DISPLAY_REQUIRED = 0x00000002;

    public static void KeepAwake()
    {
        SetThreadExecutionState(
            ES_CONTINUOUS |
            ES_SYSTEM_REQUIRED
        );
    }

    public static void Release()
    {
        SetThreadExecutionState(
            ES_CONTINUOUS
        );
    }
}
'@


# ──────────────────────────────────────────────────────────────────────────────
# FOLDER
# ──────────────────────────────────────────────────────────────────────────────

$script:toothlessDir =
    "$env:USERPROFILE\TOOTHLESS"

if (!(Test-Path $script:toothlessDir))
{
    New-Item `
        -ItemType Directory `
        -Path $script:toothlessDir `
        -Force |
        Out-Null
}


# ──────────────────────────────────────────────────────────────────────────────
# FILE PATHS
# ──────────────────────────────────────────────────────────────────────────────

$script:gifPath =
    "$script:toothlessDir\toothless.gif"

$script:mp3Path =
    "$script:toothlessDir\toothless.mp3"


# ──────────────────────────────────────────────────────────────────────────────
# DOWNLOAD GIF
# ──────────────────────────────────────────────────────────────────────────────

$gifUrl = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/3b14503d-34f3-4d4a-97c5-55df02571188/dgq6axy-46697be1-04da-4650-a7c4-33a6466edb32.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi8zYjE0NTAzZC0zNGYzLTRkNGEtOTdjNS01NWRmMDI1NzExODgvZGdxNmF4eS00NjY5N2JlMS0wNGRhLTQ2NTAtYTdjNC0zM2E2NDY2ZWRiMzIuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.3z67Wys6W3OM37SHea9frI_lrCggRdkC3GPexKlQlK8"


if (!(Test-Path $script:gifPath))
{
    try
    {
        Invoke-WebRequest `
            -Uri $gifUrl `
            -OutFile $script:gifPath `
            -UseBasicParsing `
            -ErrorAction Stop
    }
    catch
    {
        exit
    }
}


# ──────────────────────────────────────────────────────────────────────────────
# DOWNLOAD MP3
# ──────────────────────────────────────────────────────────────────────────────

if (!(Test-Path $script:mp3Path))
{
    Start-Job -ScriptBlock {

        $dest =
            "$env:USERPROFILE\TOOTHLESS"

        $out =
            "$dest\toothless.mp3"

        if (!(Test-Path $dest))
        {
            New-Item `
                -ItemType Directory `
                -Path $dest `
                -Force |
                Out-Null
        }

        curl.exe `
            -L `
            --ssl-no-revoke `
            -o $out `
            "https://drive.usercontent.google.com/u/0/uc?id=1Ph-0mHRmxhbeavBaDUHUna0k7jVQaaJu&export=download"

    } | Out-Null
}


# ──────────────────────────────────────────────────────────────────────────────
# SAVE ORIGINAL AUDIO
# ──────────────────────────────────────────────────────────────────────────────

$script:origVol =
    [AudioCtrl]::Get()

$script:origMute =
    [AudioCtrl]::GetMute()

[AudioCtrl]::SetMute($false)
[AudioCtrl]::Set(0.3)


# ──────────────────────────────────────────────────────────────────────────────
# SAVE ORIGINAL LID SETTINGS
# ──────────────────────────────────────────────────────────────────────────────

$script:originalACAction = $null
$script:originalDCAction = $null
$script:powerScheme = $null

try
{
    $activeScheme =
        powercfg /getactivescheme

    $script:powerScheme =
        (
            $activeScheme -replace `
                '.*:\s*([a-fA-F0-9-]+).*',
                '$1'
        ).Trim()

    if (
        $script:powerScheme -match
        '^[a-fA-F0-9-]{36}$'
    )
    {
        $ac =
            powercfg /query `
                $script:powerScheme `
                SUB_BUTTONS `
                LIDACTION |
                Select-String `
                    "Current AC Power Setting Index"

        $dc =
            powercfg /query `
                $script:powerScheme `
                SUB_BUTTONS `
                LIDACTION |
                Select-String `
                    "Current DC Power Setting Index"

        if ($ac)
        {
            $script:originalACAction =
                [Convert]::ToInt32(
                    (
                        $ac.ToString() `
                        -replace '.*:\s*',''
                    ).Trim(),
                    16
                )
        }

        if ($dc)
        {
            $script:originalDCAction =
                [Convert]::ToInt32(
                    (
                        $dc.ToString() `
                        -replace '.*:\s*',''
                    ).Trim(),
                    16
                )
        }

        # Lid close = Do nothing
        powercfg `
            /setacvalueindex `
            $script:powerScheme `
            SUB_BUTTONS `
            LIDACTION `
            0 |
            Out-Null

        powercfg `
            /setdcvalueindex `
            $script:powerScheme `
            SUB_BUTTONS `
            LIDACTION `
            0 |
            Out-Null

        powercfg `
            /setactive `
            $script:powerScheme |
            Out-Null
    }
}
catch {}


# ──────────────────────────────────────────────────────────────────────────────
# WINFORMS
# ──────────────────────────────────────────────────────────────────────────────

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:allowClose = $false

$script:activeWindows =
    [System.Collections.Generic.List[psobject]]::new()

$screen =
    [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea


# ──────────────────────────────────────────────────────────────────────────────
# CREATE TOOTHLESS WINDOW
# ──────────────────────────────────────────────────────────────────────────────

function New-BouncyWindow
{
    $form =
        New-Object System.Windows.Forms.Form

    $form.Text =
        "Toothless"

    $form.Size =
        New-Object System.Drawing.Size(
            300,
            300
        )

    $form.FormBorderStyle =
        "FixedSingle"

    $form.MaximizeBox =
        $false

    $form.StartPosition =
        "Manual"

    $form.TopMost =
        $true

    $form.Add_FormClosing({

        if (-not $script:allowClose)
        {
            $_.Cancel = $true
        }

    })


    # ── Local GIF ─────────────────────────────────────────────────────────────

    $pic =
        New-Object System.Windows.Forms.PictureBox

    $pic.Dock =
        "Fill"

    $pic.SizeMode =
        "StretchImage"

    $pic.Image =
        [System.Drawing.Image]::FromFile(
            $script:gifPath
        )

    $form.Controls.Add($pic)


    # ── Random Position ──────────────────────────────────────────────────────

    $form.Left =
        Get-Random `
            -Minimum 0 `
            -Maximum (
                [math]::Max(
                    1,
                    $screen.Width - 300
                )
            )

    $form.Top =
        Get-Random `
            -Minimum 0 `
            -Maximum (
                [math]::Max(
                    1,
                    $screen.Height - 300
                )
            )


    # ── Movement ─────────────────────────────────────────────────────────────

    $winObj =
        [pscustomobject]@{
            Form = $form
            DX   = Get-Random -InputObject @(-5,5)
            DY   = Get-Random -InputObject @(-5,5)
        }

    $script:activeWindows.Add(
        $winObj
    )

    $form.Show()
}


# ──────────────────────────────────────────────────────────────────────────────
# BOUNCE TIMER
# ──────────────────────────────────────────────────────────────────────────────

$bounceTimer =
    New-Object System.Windows.Forms.Timer

$bounceTimer.Interval =
    20

$bounceTimer.Add_Tick({

    foreach (
        $win in $script:activeWindows
    )
    {
        $f =
            $win.Form

        $f.Left +=
            $win.DX

        $f.Top +=
            $win.DY


        if (
            $f.Left -le 0 -or
            (
                $f.Left + $f.Width
            ) -ge $screen.Width
        )
        {
            $win.DX =
                -$win.DX
        }


        if (
            $f.Top -le 0 -or
            (
                $f.Top + $f.Height
            ) -ge $screen.Height
        )
        {
            $win.DY =
                -$win.DY
        }
    }
})

$bounceTimer.Start()


# ──────────────────────────────────────────────────────────────────────────────
# SPAWN TIMER
# ──────────────────────────────────────────────────────────────────────────────

$spawnTimer =
    New-Object System.Windows.Forms.Timer

$spawnTimer.Interval =
    5000

$spawnTimer.Add_Tick({

    New-BouncyWindow

})

$spawnTimer.Start()


# ──────────────────────────────────────────────────────────────────────────────
# MUSIC
# ──────────────────────────────────────────────────────────────────────────────

$script:wmp =
    $null

$musicTimer =
    New-Object System.Windows.Forms.Timer

$musicTimer.Interval =
    2000

$musicTimer.Add_Tick({

    if (
        $script:wmp -eq $null -and
        (Test-Path $script:mp3Path)
    )
    {
        $script:wmp =
            New-Object -ComObject WMPlayer.OCX

        $script:wmp.URL =
            $script:mp3Path

        $script:wmp.settings.setMode(
            "loop",
            $true
        )

        $script:wmp.controls.play()

        $musicTimer.Stop()
    }

})

$musicTimer.Start()


# ──────────────────────────────────────────────────────────────────────────────
# LID STATE
# ──────────────────────────────────────────────────────────────────────────────

$script:lidClosed =
    $false


# ──────────────────────────────────────────────────────────────────────────────
# VOLUME ENFORCER
# ──────────────────────────────────────────────────────────────────────────────

$volTimer =
    New-Object System.Windows.Forms.Timer

$volTimer.Interval =
    250

$volTimer.Add_Tick({

    try
    {
        if ($script:lidClosed)
        {
            # Lid closed = 50%

            if ([AudioCtrl]::GetMute())
            {
                [AudioCtrl]::SetMute($false)
            }

            if (
                [math]::Abs(
                    [AudioCtrl]::Get() - 0.5
                ) -gt 0.01
            )
            {
                [AudioCtrl]::Set(0.5)
            }
        }
        else
        {
            # Lid open = 30%

            if ([AudioCtrl]::GetMute())
            {
                [AudioCtrl]::SetMute($false)
            }

            if (
                [math]::Abs(
                    [AudioCtrl]::Get() - 0.3
                ) -gt 0.01
            )
            {
                [AudioCtrl]::Set(0.3)
            }
        }
    }
    catch {}

})

$volTimer.Start()


# ──────────────────────────────────────────────────────────────────────────────
# LID DETECTION
# ──────────────────────────────────────────────────────────────────────────────

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class LidMonitor : NativeWindow
{
    public event EventHandler LidChanged;

    private static readonly Guid GUID_LIDSWITCH_STATE_CHANGE =
        new Guid(
            "BA3E0F4D-B817-4094-A2D1-D56379E6A0E3"
        );

    [DllImport("user32.dll")]
    static extern IntPtr RegisterPowerSettingNotification(
        IntPtr hRecipient,
        ref Guid PowerSettingGuid,
        int Flags
    );

    const int WM_POWERBROADCAST = 0x0218;
    const int PBT_POWERSETTINGCHANGE = 0x8013;

    public LidMonitor()
    {
        CreateHandle(new CreateParams());

        RegisterPowerSettingNotification(
            this.Handle,
            ref GUID_LIDSWITCH_STATE_CHANGE,
            0
        );
    }

    protected override void WndProc(
        ref Message m
    )
    {
        if (
            m.Msg == WM_POWERBROADCAST &&
            m.WParam.ToInt32() ==
            PBT_POWERSETTINGCHANGE
        )
        {
            if (LidChanged != null)
            {
                LidChanged(
                    this,
                    EventArgs.Empty
                );
            }
        }

        base.WndProc(ref m);
    }

    public void DisposeMonitor()
    {
        DestroyHandle();
    }
}
'@


$lidMonitor =
    New-Object LidMonitor


$lidMonitor.LidChanged += {

    try
    {
        $script:lidClosed =
            -not $script:lidClosed

        if ($script:lidClosed)
        {
            # Laptop lid closed

            [PowerKeepAwake]::KeepAwake()

            [AudioCtrl]::SetMute($false)

            [AudioCtrl]::Set(0.5)
        }
        else
        {
            # Laptop lid opened

            [PowerKeepAwake]::KeepAwake()

            [AudioCtrl]::SetMute($false)

            [AudioCtrl]::Set(0.3)
        }
    }
    catch {}
}


# ──────────────────────────────────────────────────────────────────────────────
# TRIPLE-I EMERGENCY KILL SWITCH
# ──────────────────────────────────────────────────────────────────────────────

$script:iCount =
    0

$script:lastI =
    [DateTime]::MinValue

$script:prevIDown =
    $false


$killTimer =
    New-Object System.Windows.Forms.Timer

$killTimer.Interval =
    20


$killTimer.Add_Tick({

    # VK_I = 0x49

    $isDown =
        (
            (
                [WinAPI]::GetAsyncKeyState(0x49) `
                -band 0x8000
            ) -ne 0
        )


    # Only count the initial key press
    if (
        $isDown -and
        -not $script:prevIDown
    )
    {
        $now =
            [DateTime]::Now


        # More than 2 seconds since previous press
        # means start counting again

        if (
            (
                $now - $script:lastI
            ).TotalSeconds -gt 2
        )
        {
            $script:iCount =
                0
        }


        $script:iCount++

        $script:lastI =
            $now


        # ──────────────────────────────────────────────────────────────────────
        # THREE I PRESSES = STOP EVERYTHING
        # ──────────────────────────────────────────────────────────────────────

        if (
            $script:iCount -ge 3
        )
        {
            # Stop timers

            $bounceTimer.Stop()
            $spawnTimer.Stop()
            $musicTimer.Stop()
            $volTimer.Stop()
            $killTimer.Stop()


            # Stop music

            if ($script:wmp)
            {
                try
                {
                    $script:wmp.controls.stop()
                }
                catch {}
            }


            # Release keep-awake

            try
            {
                [PowerKeepAwake]::Release()
            }
            catch {}


            # Restore original audio

            try
            {
                [AudioCtrl]::Set(
                    $script:origVol
                )

                [AudioCtrl]::SetMute(
                    $script:origMute
                )
            }
            catch {}


            # Restore original lid settings

            try
            {
                if (
                    $script:powerScheme -and
                    $script:originalACAction -ne $null
                )
                {
                    powercfg `
                        /setacvalueindex `
                        $script:powerScheme `
                        SUB_BUTTONS `
                        LIDACTION `
                        $script:originalACAction |
                        Out-Null
                }


                if (
                    $script:powerScheme -and
                    $script:originalDCAction -ne $null
                )
                {
                    powercfg `
                        /setdcvalueindex `
                        $script:powerScheme `
                        SUB_BUTTONS `
                        LIDACTION `
                        $script:originalDCAction |
                        Out-Null
                }


                if ($script:powerScheme)
                {
                    powercfg `
                        /setactive `
                        $script:powerScheme |
                        Out-Null
                }
            }
            catch {}


            # Allow windows to close

            $script:allowClose =
                $true


            foreach (
                $win in $script:activeWindows
            )
            {
                try
                {
                    $win.Form.Close()
                }
                catch {}
            }


            # Dispose lid monitor

            try
            {
                $lidMonitor.DisposeMonitor()
            }
            catch {}


            # Exit application

            [System.Windows.Forms.Application]::Exit()
        }
    }


    $script:prevIDown =
        $isDown
})

$killTimer.Start()


# ──────────────────────────────────────────────────────────────────────────────
# START
# ──────────────────────────────────────────────────────────────────────────────

New-BouncyWindow

[System.Windows.Forms.Application]::Run()
