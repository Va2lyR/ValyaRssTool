Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------
# 1. شاشة الأنيميشن والمقدمة العصريّة (ASCII Intro)
# ---------------------------------------------------------
Clear-Host
$host.UI.RawUI.ForegroundColor = "Magenta"

$banner = @"
__     __bdL  _        R  ____       
\ \   / /_ _| |  _   _|  _ \ 
 \ \ / / _` | | | | | | |_) |
  \ V / (_| | | |_| | |  _ < 
   \_/ \__,_|_|\__, |_|_| \_\
               |___/         
"@

foreach ($line in $banner -split "`n") {
    Write-Host $line -ForegroundColor Blue
    Start-Sleep -Milliseconds 40
}

Write-Host "`n[+] INITIALIZING VALYAR COMMAND SUITE V2.0..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 250
Write-Host "[+] LOADING MODULES & SECURITY TOOLS..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 250
Write-Host "[+] LAUNCHING GUI INTERFACE..." -ForegroundColor Green
Start-Sleep -Milliseconds 300

# ---------------------------------------------------------
# 2. قائمة البيانات والأدوات (Data Structure)
# ---------------------------------------------------------
$global:ToolsList = @(
    # Category: Mod Analyzers
    @{ Name = "TeslaPro // Doomsday Detector"; Category = "Mod Analyzers"; Desc = "Launches Doomsday client detection workflow."; Cmd = "powershell -NoProfile -ExecutionPolicy Bypass -Command `"iex (irm 'https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1')`"" },
    @{ Name = "Xkzutos // Mod Analyzer"; Category = "Mod Analyzers"; Desc = "Analyzes Minecraft mods using metadata and hashes."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1')`"" },
    @{ Name = "TeslaPro // GhostClientFinder"; Category = "Mod Analyzers"; Desc = "Detects Ghost Client traces and modifications."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1')`"" },
    @{ Name = "Tonynoh // Meow Mod Analyzer"; Category = "Mod Analyzers"; Desc = "Analyzes Minecraft mods for suspicious indicators."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')`"" },
    @{ Name = "CheesyDqrkisFucker"; Category = "Mod Analyzers"; Desc = "Searches for Dqrkis-related traces."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')`"" },
    
    # Category: Macro Detectors
    @{ Name = "Sellgui // Prime Macro Detector"; Category = "Macro Detectors"; Desc = "Detects Prime macro traces and activity."; Cmd = "powershell -ExecutionPolicy Bypass -NoProfile -Command `"iwr 'https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1' -UseBasicParsing | iex`"" },
    @{ Name = "Nicc // Macro Detector"; Category = "Macro Detectors"; Desc = "Searches for macro-related traces."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1')`"" },

    # Category: Forensics
    @{ Name = "Jar Parser"; Category = "Forensics"; Desc = "Analyzes .jar files for suspicious classes."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1')`"" },
    @{ Name = "Alt Detector"; Category = "Forensics"; Desc = "Searches for alternative accounts on system."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1')`"" },
    @{ Name = "Scheduled Tasks"; Category = "Forensics"; Desc = "Checks scheduled tasks for suspicious entries."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1')`"" },
    @{ Name = "BAM Parser"; Category = "Forensics"; Desc = "Parses BAM data for executed applications."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1')`"" },
    @{ Name = "Streams Finder"; Category = "Forensics"; Desc = "Searches for NTFS Alternate Data Streams."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1')`"" },
    @{ Name = "Signatures Checker"; Category = "Forensics"; Desc = "Checks digital signatures of system files."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1')`"" },
    @{ Name = "Prefetch Integrity"; Category = "Forensics"; Desc = "Analyzes Windows Prefetch files for anomalies."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1')`"" },
    
    # Category: Utilities
    @{ Name = "TeslaPro // VPN Finder"; Category = "Utilities"; Desc = "Searches for active VPN connections."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"iex (irm 'https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1')`"" },
    @{ Name = "AnyDesk Installer"; Category = "Utilities"; Desc = "Downloads and installs AnyDesk automatically."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1')`"" },
    @{ Name = "All In One Checker"; Category = "Utilities"; Desc = "Runs comprehensive screenshare checks."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1')`"" }
)

# ---------------------------------------------------------
# 3. بناء الواجهة الرسومية (Modern Dark WinForms GUI)
# ---------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "ValyaR Command Suite"
$form.Size = New-Object System.Drawing.Size(950, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Sidebar Panel
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Size = New-Object System.Drawing.Size(200, 600)
$sidebar.Dock = "Left"
$sidebar.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 29)
$form.Controls.Add($sidebar)

# Logo Text
$lblLogo = New-Object System.Windows.Forms.Label
$lblLogo.Text = "ValyaR"
$lblLogo.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$lblLogo.ForeColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
$lblLogo.Location = New-Object System.Drawing.Point(10, 20)
$lblLogo.AutoSize = $true
$sidebar.Controls.Add($lblLogo)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "COMMAND SUITE"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(108, 108, 128)
$lblSub.Location = New-Object System.Drawing.Point(15, 55)
$lblSub.AutoSize = $true
$sidebar.Controls.Add($lblSub)

# Sidebar Buttons
$btnCmd = New-Object System.Windows.Forms.Button
$btnCmd.Text = "ValyaR Cmd"
$btnCmd.Location = New-Object System.Drawing.Point(10, 100)
$btnCmd.Size = New-Object System.Drawing.Size(180, 40)
$btnCmd.FlatStyle = "Flat"
$btnCmd.FlatAppearance.BorderSize = 0
$btnCmd.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
$btnCmd.ForeColor = [System.Drawing.Color]::White
$btnCmd.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCmd.Cursor = [System.Windows.Forms.Cursors]::Hand
$sidebar.Controls.Add($btnCmd)

$btnOverview = New-Object System.Windows.Forms.Button
$btnOverview.Text = "OverView"
$btnOverview.Location = New-Object System.Drawing.Point(10, 150)
$btnOverview.Size = New-Object System.Drawing.Size(180, 40)
$btnOverview.FlatStyle = "Flat"
$btnOverview.FlatAppearance.BorderSize = 0
$btnOverview.BackColor = [System.Drawing.Color]::FromArgb(34, 34, 46)
$btnOverview.ForeColor = [System.Drawing.Color]::White
$btnOverview.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnOverview.Cursor = [System.Windows.Forms.Cursors]::Hand
$sidebar.Controls.Add($btnOverview)

# Main Container
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(210, 10)
$mainPanel.Size = New-Object System.Drawing.Size(710, 540)
$form.Controls.Add($mainPanel)

# Overview View Panel
$pnlOverview = New-Object System.Windows.Forms.Panel
$pnlOverview.Size = New-Object System.Drawing.Size(710, 540)
$pnlOverview.Visible = $false
$mainPanel.Controls.Add($pnlOverview)

$lblDevTitle = New-Object System.Windows.Forms.Label
$lblDevTitle.Text = "ValyaR Control Center"
$lblDevTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblDevTitle.ForeColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
$lblDevTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblDevTitle.AutoSize = $true
$pnlOverview.Controls.Add($lblDevTitle)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Developer: Valyar`nDiscord Dev: _iaec`nVersion: v2.0 GUI Edition"
$lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$lblInfo.Location = New-Object System.Drawing.Point(20, 80)
$lblInfo.AutoSize = $true
$pnlOverview.Controls.Add($lblInfo)

# Cmd View Panel
$pnlCmd = New-Object System.Windows.Forms.Panel
$pnlCmd.Size = New-Object System.Drawing.Size(710, 540)
$mainPanel.Controls.Add($pnlCmd)

# Search Box
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(10, 10)
$txtSearch.Size = New-Object System.Drawing.Size(690, 30)
$txtSearch.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 29)
$txtSearch.ForeColor = [System.Drawing.Color]::White
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$pnlCmd.Controls.Add($txtSearch)

# Scrollable Tools Panel
$flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowPanel.Location = New-Object System.Drawing.Point(10, 50)
$flowPanel.Size = New-Object System.Drawing.Size(690, 480)
$flowPanel.AutoScroll = $true
$pnlCmd.Controls.Add($flowPanel)

# Function to render tools
function Populate-Tools ($list) {
    $flowPanel.Controls.Clear()
    foreach ($tool in $list) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(660, 65)
        $card.BackColor = [System.Drawing.Color]::FromArgb(22, 22, 29)
        $card.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)

        $tName = New-Object System.Windows.Forms.Label
        $tName.Text = $tool.Name
        $tName.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $tName.Location = New-Object System.Drawing.Point(10, 8)
        $tName.AutoSize = $true
        $card.Controls.Add($tName)

        $tDesc = New-Object System.Windows.Forms.Label
        $tDesc.Text = $tool.Desc
        $tDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $tDesc.ForeColor = [System.Drawing.Color]::Gray
        $tDesc.Location = New-Object System.Drawing.Point(10, 32)
        $tDesc.AutoSize = $true
        $card.Controls.Add($tDesc)

        $btnRun = New-Object System.Windows.Forms.Button
        $btnRun.Text = "Run"
        $btnRun.Size = New-Object System.Drawing.Size(85, 35)
        $btnRun.Location = New-Object System.Drawing.Point(560, 15)
        $btnRun.FlatStyle = "Flat"
        $btnRun.FlatAppearance.BorderSize = 0
        $btnRun.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
        $btnRun.ForeColor = [System.Drawing.Color]::White
        $btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnRun.Tag = $tool.Cmd
        
        $btnRun.Add_Click({
            $cmd = $this.Tag
            Start-Process powershell -ArgumentList "-NoExit -Command $cmd"
        })

        $card.Controls.Add($btnRun)
        $flowPanel.Controls.Add($card)
    }
}

Populate-Tools $global:ToolsList

# Navigation Events
$btnOverview.Add_Click({
    $pnlOverview.Visible = $true
    $pnlCmd.Visible = $false
    $btnOverview.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
    $btnCmd.BackColor = [System.Drawing.Color]::FromArgb(34, 34, 46)
})

$btnCmd.Add_Click({
    $pnlOverview.Visible = $false
    $pnlCmd.Visible = $true
    $btnCmd.BackColor = [System.Drawing.Color]::FromArgb(138, 43, 226)
    $btnOverview.BackColor = [System.Drawing.Color]::FromArgb(34, 34, 46)
})

# Real-time Filter Event
$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.ToLower()
    if ([string]::IsNullOrWhiteSpace($q)) {
        Populate-Tools $global:ToolsList
    } else {
        $filtered = $global:ToolsList | Where-Object { 
            $_.Name.ToLower().Contains($q) -or $_.Category.ToLower().Contains($q) -or $_.Desc.ToLower().Contains($q)
        }
        Populate-Tools $filtered
    }
})

# Show Window
[void]$form.ShowDialog()
