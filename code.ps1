Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Your GIF URL
$url = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/3b14503d-34f3-4d4a-97c5-55df02571188/dgq6axy-46697be1-04da-4650-a7c4-33a6466edb32.gif?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiIvZi8zYjE0NTAzZC0zNGYzLTRkNGEtOTdjNS01NWRmMDI1NzExODgvZGdxNmF4eS00NjY5N2JlMS0wNGRhLTQ2NTAtYTdjNC0zM2E2NDY2ZWRiMzIuZ2lmIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.3z67Wys6W3OM37SHea9frI_lrCggRdkC3GPexKlQlK8"

$temp = "$env:TEMP\toothless.gif"

# Download GIF
if (!(Test-Path $temp)) {
    Invoke-WebRequest -Uri $url -OutFile $temp
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Toothless"
$form.Size = New-Object System.Drawing.Size(300,300)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.StartPosition = "Manual"

# Prevent closing (reopen immediately)
$form.Add_FormClosing({
    $_.Cancel = $true
    $form.Hide()
    Start-Sleep -Milliseconds 200
    $form.Show()
})

# Picture box
$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = "Fill"
$picture.SizeMode = "StretchImage"
$picture.Image = [System.Drawing.Image]::FromFile($temp)
$form.Controls.Add($picture)

# Screen bounds
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Random start position
$form.Left = Get-Random -Minimum 0 -Maximum ($screen.Width - 300)
$form.Top  = Get-Random -Minimum 0 -Maximum ($screen.Height - 300)

# Movement speed
$dx = 5
$dy = 5

# Timer for bouncing movement
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 20

$timer.Add_Tick({
    $form.Left += $script:dx
    $form.Top  += $script:dy

    if ($form.Left -le 0 -or $form.Left + $form.Width -ge $screen.Width) {
        $script:dx = -$script:dx
    }

    if ($form.Top -le 0 -or $form.Top + $form.Height -ge $screen.Height) {
        $script:dy = -$script:dy
    }
})

$timer.Start()

[void]$form.ShowDialog()
