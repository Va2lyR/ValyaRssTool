<#
    ===========================================================================
    Application Name : ValyaRssTool v2.0
    File Name        : ValyaRsser.ps1
    Description      : Modern GUI Toolkit Launcher for Diagnostics & Forensic Tools
    Language         : English Interface
    Version          : 2.0 (Enhanced & Optimized)
    ===========================================================================
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# --- Error Handling & Strict Mode ---
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Assembly Loading ---
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to load required .NET assemblies. $_" -ForegroundColor Red
    exit 1
}

# --- Tools Database (28 Tools) ---
$script:toolsList = @(
    [PSCustomObject]@{ Name = "TeslaPro // Doomsday Detector"; Category = "Client Detection"; Desc = "Detects Doomsday client traces and runs a specialized detection workflow."; Url = "https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1"; Icon = "🔍" },
    [PSCustomObject]@{ Name = "Xkzutos // Mod Analyzer"; Category = "Minecraft"; Desc = "Analyzes Minecraft mods by checking metadata, file hashes, and known indicators."; Url = "https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1"; Icon = "🎮" },
    [PSCustomObject]@{ Name = "TeslaPro // GhostClientFinder"; Category = "Client Detection"; Desc = "Searches for Ghost Client traces and suspicious modifications inside Minecraft files."; Url = "https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1"; Icon = "👻" },
    [PSCustomObject]@{ Name = "Tonynoh // Meow Mod Analyzer"; Category = "Minecraft"; Desc = "Analyzes Minecraft mods and detects suspicious files and hidden client indicators."; Url = "https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1"; Icon = "🐱" },
    [PSCustomObject]@{ Name = "CheesyDqrkisFucker"; Category = "Client Detection"; Desc = "Searches for Dqrkis-related traces and suspicious modifications linked to the client."; Url = "https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1"; Icon = "🛡️" },
    [PSCustomObject]@{ Name = "TeslaPro // VPN Finder"; Category = "Network"; Desc = "Searches for active VPN connections and related system traces."; Url = "https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1"; Icon = "🌐" },
    [PSCustomObject]@{ Name = "AnyDesk Install Script"; Category = "Remote Access"; Desc = "Downloads and installs AnyDesk using an automated PowerShell script."; Url = "https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1"; Icon = "💻" },
    [PSCustomObject]@{ Name = "Sellgui // Prime Macro Detector"; Category = "Macro Detection"; Desc = "Detects Prime macro traces and suspicious macro-related activity."; Url = "https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1"; Icon = "⌨️" },
    [PSCustomObject]@{ Name = "Nicc // Macro Detector"; Category = "Macro Detection"; Desc = "Searches for macro-related traces and suspicious system activity."; Url = "https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1"; Icon = "🎯" },
    [PSCustomObject]@{ Name = "Jar Parser"; Category = "File Analysis"; Desc = "Analyzes .jar files for suspicious classes, strings, and modifications."; Url = "https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1"; Icon = "📦" },
    [PSCustomObject]@{ Name = "Alt Detector"; Category = "Account Detection"; Desc = "Searches the system for alternative accounts and related traces."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1"; Icon = "👤" },
    [PSCustomObject]@{ Name = "Scheduled Tasks"; Category = "System"; Desc = "Checks scheduled tasks for suspicious or unusual entries."; Url = "https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1"; Icon = "⏰" },
    [PSCustomObject]@{ Name = "BAM Parser"; Category = "Forensic"; Desc = "Parses BAM data to help identify previously executed applications."; Url = "https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1"; Icon = "📊" },
    [PSCustomObject]@{ Name = "Streams"; Category = "Forensic"; Desc = "Searches for NTFS Alternate Data Streams and hidden streams."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1"; Icon = "🌊" },
    [PSCustomObject]@{ Name = "Signatures"; Category = "Security"; Desc = "Checks digital signatures and helps identify unsigned files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1"; Icon = "✍️" },
    [PSCustomObject]@{ Name = "BAM Deleted Keys"; Category = "Forensic"; Desc = "Searches BAM data for deleted, missing, or unusual Registry entries."; Url = "https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1"; Icon = "🗑️" },
    [PSCustomObject]@{ Name = "Hard Disk Converter"; Category = "System"; Desc = "Converts hard-disk volume identifiers into readable drive paths."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusHardDiskVolumeConverter.ps1"; Icon = "💾" },
    [PSCustomObject]@{ Name = "All In One"; Category = "Multi-Tool"; Desc = "Runs multiple screenshare and forensic checks through one script."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1"; Icon = "🔧" },
    [PSCustomObject]@{ Name = "Prefetch Integrity"; Category = "Forensic"; Desc = "Checks Windows Prefetch files for inconsistencies or modifications."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1"; Icon = "📁" },
    [PSCustomObject]@{ Name = "AnyDesk Reset"; Category = "Remote Access"; Desc = "Resets or restores certain AnyDesk settings and configuration files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/anydesk.ps1"; Icon = "🔄" },
    [PSCustomObject]@{ Name = "Spokwn BAM"; Category = "Forensic"; Desc = "Analyzes BAM data using Spokwn's BAM parser."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1"; Icon = "📈" },
    [PSCustomObject]@{ Name = "Mini SS"; Category = "Quick Check"; Desc = "Runs a small and quick screenshare check."; Url = "https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1"; Icon = "⚡" },
    [PSCustomObject]@{ Name = "Spokwn Tool Downloader"; Category = "Utility"; Desc = "Downloads multiple Spokwn screenshare tools through one script."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Spokwn-Collect.ps1"; Icon = "⬇️" },
    [PSCustomObject]@{ Name = "Services"; Category = "System"; Desc = "Checks important Windows services and their current configuration."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1"; Icon = "⚙️" },
    [PSCustomObject]@{ Name = "Signed Scheduled Tasks"; Category = "Security"; Desc = "Checks scheduled tasks and reviews their digital signatures."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks"; Icon = "🔏" },
    [PSCustomObject]@{ Name = "Collector with AV Exclusion"; Category = "Forensic"; Desc = "Collects system information and forensic data while managing exclusions."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Collector.ps1"; Icon = "📋" },
    [PSCustomObject]@{ Name = "DoomsDay Finder"; Category = "Client Detection"; Desc = "Searches for files and indicators associated with the DoomsDay client."; Url = "https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1"; Icon = "☠️" },
    [PSCustomObject]@{ Name = "SSToolsHub"; Category = "Multi-Tool"; Desc = "Gathers CMD and EXE tools into one script to facilitate checks."; Url = "https://raw.githubusercontent.com/3ntrsquad/SSToolsHub/refs/heads/main/SSToolsHub.ps1"; Icon = "🛠️" }
)

# --- Theme Configuration (Dark Modern) ---
$script:theme = @{
    Bg          = [System.Drawing.Color]::FromArgb(15, 15, 25)
    Panel       = [System.Drawing.Color]::FromArgb(30, 30, 45)
    Card        = [System.Drawing.Color]::FromArgb(40, 42, 60)
    CardHover   = [System.Drawing.Color]::FromArgb(50, 52, 75)
    Accent      = [System.Drawing.Color]::FromArgb(98, 160, 234)
    AccentDark  = [System.Drawing.Color]::FromArgb(70, 130, 200)
    Text        = [System.Drawing.Color]::FromArgb(240, 240, 245)
    SubText     = [System.Drawing.Color]::FromArgb(160, 165, 185)
    Success     = [System.Drawing.Color]::FromArgb(76, 175, 80)
    Warning     = [System.Drawing.Color]::FromArgb(255, 152, 0)
    Danger      = [System.Drawing.Color]::FromArgb(244, 67, 54)
    Button      = [System.Drawing.Color]::FromArgb(53, 116, 240)
    ButtonHover = [System.Drawing.Color]::FromArgb(70, 140, 255)
    Border      = [System.Drawing.Color]::FromArgb(60, 65, 85)
}

# --- Category Colors ---
$script:categoryColors = @{
    "Client Detection"  = [System.Drawing.Color]::FromArgb(244, 67, 54)
    "Minecraft"         = [System.Drawing.Color]::FromArgb(76, 175, 80)
    "Network"           = [System.Drawing.Color]::FromArgb(33, 150, 243)
    "Remote Access"     = [System.Drawing.Color]::FromArgb(156, 39, 176)
    "Macro Detection"   = [System.Drawing.Color]::FromArgb(255, 152, 0)
    "File Analysis"     = [System.Drawing.Color]::FromArgb(0, 188, 212)
    "Account Detection" = [System.Drawing.Color]::FromArgb(233, 30, 99)
    "System"            = [System.Drawing.Color]::FromArgb(103, 58, 183)
    "Forensic"          = [System.Drawing.Color]::FromArgb(63, 81, 181)
    "Security"          = [System.Drawing.Color]::FromArgb(0, 150, 136)
    "Multi-Tool"        = [System.Drawing.Color]::FromArgb(121, 85, 72)
    "Quick Check"       = [System.Drawing.Color]::FromArgb(255, 193, 7)
    "Utility"           = [System.Drawing.Color]::FromArgb(96, 125, 139)
}

# --- Main Window Setup ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "ValyaRssTool v2.0 - Forensic & System Analysis Toolkit"
$mainForm.Size = New-Object System.Drawing.Size(1100, 780)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = $script:theme.Bg
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$mainForm.MinimumSize = New-Object System.Drawing.Size(900, 600)
$mainForm.MaximizeBox = $true
$mainForm.Icon = [System.Drawing.SystemIcons]::Shield
$mainForm.KeyPreview = $true

# --- Header Panel ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 100
$headerPanel.BackColor = $script:theme.Panel
$headerPanel.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)
$mainForm.Controls.Add($headerPanel)

# Title Label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "ValyaRssTool"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $script:theme.Accent
$lblTitle.Location = New-Object System.Drawing.Point(25, 12)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

# Subtitle Label
$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Forensic & System Analysis Toolkit Hub  |  28 Tools Available"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblSubTitle.ForeColor = $script:theme.SubText
$lblSubTitle.Location = New-Object System.Drawing.Point(27, 55)
$lblSubTitle.AutoSize = $true
$headerPanel.Controls.Add($lblSubTitle)

# Status Label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$lblStatus.ForeColor = $script:theme.Success
$lblStatus.Location = New-Object System.Drawing.Point(27, 78)
$lblStatus.AutoSize = $true
$headerPanel.Controls.Add($lblStatus)

# --- Search & Filter Panel ---
$filterPanel = New-Object System.Windows.Forms.Panel
$filterPanel.Size = New-Object System.Drawing.Size(420, 80)
$filterPanel.Location = New-Object System.Drawing.Point(650, 10)
$filterPanel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($filterPanel)

# Search Label
$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Search:"
$lblSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblSearch.ForeColor = $script:theme.SubText
$lblSearch.Location = New-Object System.Drawing.Point(0, 8)
$lblSearch.AutoSize = $true
$filterPanel.Controls.Add($lblSearch)

# Search TextBox
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Size = New-Object System.Drawing.Size(250, 28)
$txtSearch.Location = New-Object System.Drawing.Point(65, 5)
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtSearch.BackColor = $script:theme.Bg
$txtSearch.ForeColor = $script:theme.Text
$txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtSearch.Text = "Search tools..."
$txtSearch.ForeColor = $script:theme.SubText
$filterPanel.Controls.Add($txtSearch)

# Category Filter Label
$lblCategory = New-Object System.Windows.Forms.Label
$lblCategory.Text = "Category:"
$lblCategory.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblCategory.ForeColor = $script:theme.SubText
$lblCategory.Location = New-Object System.Drawing.Point(0, 42)
$lblCategory.AutoSize = $true
$filterPanel.Controls.Add($lblCategory)

# Category ComboBox
$cmbCategory = New-Object System.Windows.Forms.ComboBox
$cmbCategory.Size = New-Object System.Drawing.Size(250, 28)
$cmbCategory.Location = New-Object System.Drawing.Point(65, 38)
$cmbCategory.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cmbCategory.BackColor = $script:theme.Bg
$cmbCategory.ForeColor = $script:theme.Text
$cmbCategory.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cmbCategory.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbCategory.Items.Add("All Categories")
$script:toolsList | Select-Object -ExpandProperty Category -Unique | Sort-Object | ForEach-Object { $cmbCategory.Items.Add($_) }
$cmbCategory.SelectedIndex = 0
$filterPanel.Controls.Add($cmbCategory)

# Tool Count Label
$lblCount = New-Object System.Windows.Forms.Label
$lblCount.Text = "28 tools"
$lblCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblCount.ForeColor = $script:theme.Accent
$lblCount.Location = New-Object System.Drawing.Point(330, 8)
$lblCount.AutoSize = $true
$filterPanel.Controls.Add($lblCount)

# --- Main Container ---
$mainContainer = New-Object System.Windows.Forms.Panel
$mainContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainContainer.BackColor = $script:theme.Bg
$mainContainer.Padding = New-Object System.Windows.Forms.Padding(0)
$mainForm.Controls.Add($mainContainer)
$mainContainer.SendToBack()

# --- Content Panel (Cards) ---
$contentPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$contentPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$contentPanel.AutoScroll = $true
$contentPanel.Padding = New-Object System.Windows.Forms.Padding(20)
$contentPanel.BackColor = $script:theme.Bg
$contentPanel.WrapContents = $true
$contentPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$mainContainer.Controls.Add($contentPanel)

# --- Bottom Status Bar ---
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
$statusBar.BackColor = $script:theme.Panel
$statusBar.ForeColor = $script:theme.SubText
$statusBar.Height = 25
$mainForm.Controls.Add($statusBar)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Hover over a tool to see details | Double-click card to run"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusBar.Items.Add($statusLabel)

# --- Progress Bar ---
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(200, 5)
$progressBar.Location = New-Object System.Drawing.Point(450, 50)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$progressBar.Visible = $false
$progressBar.BackColor = $script:theme.Accent
$headerPanel.Controls.Add($progressBar)

# --- Execution Handler ---
function Invoke-ToolExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Url)) {
            throw "URL is missing for this tool."
        }

        $cleanUrl = $Url.Trim()

        if (-not ($cleanUrl -match '^https?://')) {
            throw "Invalid URL format. Only HTTP/HTTPS URLs are supported."
        }

        if (-not ($cleanUrl -match '^https://raw\.githubusercontent\.com/')) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "This tool is not from a trusted source (GitHub).`n`nURL: $cleanUrl`n`nDo you want to continue anyway?",
                "Security Warning",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                return
            }
        }

        $script:lblStatus.Text = "Launching: $Name..."
        $script:lblStatus.ForeColor = $script:theme.Warning
        $script:progressBar.Visible = $true

        $executionCommand = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
`$Host.UI.RawUI.WindowTitle = 'ValyaRssTool - $Name'
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  ValyaRssTool - Executing: $Name' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  Source: $cleanUrl' -ForegroundColor Gray
Write-Host '  Time:   `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')' -ForegroundColor Gray
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
try {
    irm '$cleanUrl' -ErrorAction Stop | iex
} catch {
    Write-Host "ERROR: Failed to execute tool. `$_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    [void]`$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
"@

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = "powershell.exe"
        $startInfo.Arguments = "-NoExit -ExecutionPolicy Bypass -Command `"$executionCommand`""
        $startInfo.Verb = "runas"
        $startInfo.UseShellExecute = $true

        [void][System.Diagnostics.Process]::Start($startInfo)

        $script:lblStatus.Text = "Launched: $Name"
        $script:lblStatus.ForeColor = $script:theme.Success

    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to launch tool:`n`n$($_.Exception.Message)",
            "Execution Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $script:lblStatus.Text = "Error launching tool"
        $script:lblStatus.ForeColor = $script:theme.Danger
    } finally {
        $script:progressBar.Visible = $false
    }
}

# --- Card Creation Engine ---
function New-ToolCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Tool
    )

    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(320, 160)
    $card.BackColor = $script:theme.Card
    $card.Margin = New-Object System.Windows.Forms.Padding(10)
    $card.Padding = New-Object System.Windows.Forms.Padding(12)
    $card.Cursor = [System.Windows.Forms.Cursors]::Hand
    $card.Tag = $Tool

    # Category Badge
    $badge = New-Object System.Windows.Forms.Label
    $badge.Text = $Tool.Category
    $badge.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
    $badge.ForeColor = [System.Drawing.Color]::White
    $badge.BackColor = $script:categoryColors[$Tool.Category]
    if (-not $badge.BackColor) { $badge.BackColor = [System.Drawing.Color]::Gray }
    $badge.Location = New-Object System.Drawing.Point(220, 8)
    $badge.AutoSize = $true
    $badge.Padding = New-Object System.Windows.Forms.Padding(6, 2, 6, 2)
    $badge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $card.Controls.Add($badge)

    # Title
    $tName = New-Object System.Windows.Forms.Label
    $tName.Text = "$($Tool.Icon) $($Tool.Name)"
    $tName.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $tName.ForeColor = $script:theme.Text
    $tName.Location = New-Object System.Drawing.Point(12, 10)
    $tName.Size = New-Object System.Drawing.Size(200, 24)
    $tName.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $card.Controls.Add($tName)

    # Description
    $tDesc = New-Object System.Windows.Forms.Label
    $tDesc.Text = $Tool.Desc
    $tDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $tDesc.ForeColor = $script:theme.SubText
    $tDesc.Location = New-Object System.Drawing.Point(12, 40)
    $tDesc.Size = New-Object System.Drawing.Size(296, 60)
    $tDesc.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $card.Controls.Add($tDesc)

    # URL Preview
    $tUrl = New-Object System.Windows.Forms.Label
    $urlDisplay = if ($Tool.Url.Length -gt 45) { $Tool.Url.Substring(0, 45) + "..." } else { $Tool.Url }
    $tUrl.Text = $urlDisplay
    $tUrl.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Italic)
    $tUrl.ForeColor = [System.Drawing.Color]::FromArgb(100, 105, 125)
    $tUrl.Location = New-Object System.Drawing.Point(12, 105)
    $tUrl.Size = New-Object System.Drawing.Size(296, 18)
    $tUrl.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $card.Controls.Add($tUrl)

    # Run Button
    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Run Tool"
    $btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnRun.ForeColor = [System.Drawing.Color]::White
    $btnRun.BackColor = $script:theme.Button
    $btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnRun.FlatAppearance.BorderSize = 0
    $btnRun.Size = New-Object System.Drawing.Size(120, 32)
    $btnRun.Location = New-Object System.Drawing.Point(188, 125)
    $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnRun.Tag = $Tool

    $btnRun.Add_MouseEnter({ $this.BackColor = $script:theme.ButtonHover })
    $btnRun.Add_MouseLeave({ $this.BackColor = $script:theme.Button })

    $btnRun.Add_Click({
        $selected = $this.Tag
        Invoke-ToolExecution -Url $selected.Url -Name $selected.Name
    })

    $card.Controls.Add($btnRun)

    # Card Events
    $card.Add_MouseEnter({
        $this.BackColor = $script:theme.CardHover
        $script:statusLabel.Text = "Category: $($this.Tag.Category) | Double-click to run"
    })
    $card.Add_MouseLeave({
        $this.BackColor = $script:theme.Card
        $script:statusLabel.Text = "Hover over a tool to see details | Double-click card to run"
    })
    $card.Add_DoubleClick({
        Invoke-ToolExecution -Url $this.Tag.Url -Name $this.Tag.Name
    })

    # Context Menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $contextMenu.BackColor = $script:theme.Panel
    $contextMenu.ForeColor = $script:theme.Text

    $menuRun = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuRun.Text = "Run Tool"
    $menuRun.Add_Click({
        Invoke-ToolExecution -Url $Tool.Url -Name $Tool.Name
    })
    $contextMenu.Items.Add($menuRun)

    $menuCopy = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuCopy.Text = "Copy URL"
    $menuCopy.Add_Click({
        [System.Windows.Forms.Clipboard]::SetText($Tool.Url)
        $script:statusLabel.Text = "URL copied to clipboard!"
    })
    $contextMenu.Items.Add($menuCopy)

    $menuOpen = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuOpen.Text = "Open in Browser"
    $menuOpen.Add_Click({
        Start-Process $Tool.Url
    })
    $contextMenu.Items.Add($menuOpen)

    $card.ContextMenuStrip = $contextMenu

    return $card
}

# --- Render Engine ---
function Render-Tools {
    [CmdletBinding()]
    param(
        [string]$FilterText = "",
        [string]$CategoryFilter = "All Categories"
    )

    $script:contentPanel.SuspendLayout()
    $script:contentPanel.Controls.Clear()

    $filteredTools = $script:toolsList | Where-Object {
        $nameMatch = $_.Name -like "*$FilterText*"
        $descMatch = $_.Desc -like "*$FilterText*"
        $catMatch = ($CategoryFilter -eq "All Categories") -or ($_.Category -eq $CategoryFilter)
        ($nameMatch -or $descMatch) -and $catMatch
    }

    $script:lblCount.Text = "$($filteredTools.Count) tools"

    if ($filteredTools.Count -eq 0) {
        $noResults = New-Object System.Windows.Forms.Label
        $noResults.Text = "No tools found matching your criteria.`n`nTry adjusting your search or category filter."
        $noResults.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Italic)
        $noResults.ForeColor = $script:theme.SubText
        $noResults.Size = New-Object System.Drawing.Size(400, 60)
        $noResults.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $noResults.Location = New-Object System.Drawing.Point(350, 200)
        $script:contentPanel.Controls.Add($noResults)
    } else {
        foreach ($tool in $filteredTools) {
            $card = New-ToolCard -Tool $tool
            $script:contentPanel.Controls.Add($card)
        }
    }

    $script:contentPanel.ResumeLayout()
    $script:contentPanel.PerformLayout()
}

# --- Search Placeholder ---
$txtSearch.Add_GotFocus({
    if ($this.Text -eq "Search tools...") {
        $this.Text = ""
        $this.ForeColor = $script:theme.Text
    }
})

$txtSearch.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($this.Text)) {
        $this.Text = "Search tools..."
        $this.ForeColor = $script:theme.SubText
    }
})

# --- Event Handlers ---
$txtSearch.Add_TextChanged({
    $searchText = if ($this.Text -eq "Search tools...") { "" } else { $this.Text }
    Render-Tools -FilterText $searchText -CategoryFilter $cmbCategory.SelectedItem
})

$cmbCategory.Add_SelectedIndexChanged({
    $searchText = if ($txtSearch.Text -eq "Search tools...") { "" } else { $txtSearch.Text }
    Render-Tools -FilterText $searchText -CategoryFilter $this.SelectedItem
})

# --- Keyboard Shortcuts ---
$mainForm.Add_KeyDown({
    param($sender, $e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::F) {
        $txtSearch.Focus()
        $e.Handled = $true
    }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $txtSearch.Text = "Search tools..."
        $txtSearch.ForeColor = $script:theme.SubText
        $cmbCategory.SelectedIndex = 0
        Render-Tools
        $e.Handled = $true
    }
})

# --- Form Resize ---
$mainForm.Add_Resize({
    if ($script:contentPanel -and $script:contentPanel.Controls.Count -gt 0) {
        $availableWidth = $script:contentPanel.ClientSize.Width - 60
        $cardsPerRow = [math]::Max(1, [math]::Floor($availableWidth / 340))
        $cardWidth = [math]::Floor($availableWidth / $cardsPerRow) - 20

        foreach ($control in $script:contentPanel.Controls) {
            if ($control -is [System.Windows.Forms.Panel]) {
                $control.Width = [math]::Min(320, $cardWidth)
            }
        }
    }
})

# --- Initial Render ---
Render-Tools

# --- Show Form ---
[void]$mainForm.ShowDialog()
