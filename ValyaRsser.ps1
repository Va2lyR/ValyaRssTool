<#
    ===========================================================================
    Application Name : ValyaRssTool
    File Name        : ValyaRsser.ps1
    Description      : Modern GUI Toolkit Launcher for Diagnostics & Forensic Tools
    Language         : English Interface
    ===========================================================================
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Tools Database ---
$toolsList = @(
    @{ Name = "TeslaPro // Doomsday Detector"; Desc = "Detects Doomsday client traces and runs a specialized detection workflow."; Url = "https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1" },
    @{ Name = "Xkzutos // Mod Analyzer"; Desc = "Analyzes Minecraft mods by checking metadata, file hashes, and known indicators."; Url = "https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1" },
    @{ Name = "TeslaPro // GhostClientFinder"; Desc = "Searches for Ghost Client traces and suspicious modifications inside Minecraft files."; Url = "https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1" },
    @{ Name = "Tonynoh // Meow Mod Analyzer"; Desc = "Analyzes Minecraft mods and detects suspicious files and hidden client indicators."; Url = "https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1" },
    @{ Name = "CheesyDqrkisFucker"; Desc = "Searches for Dqrkis-related traces and suspicious modifications linked to the client."; Url = "https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1" },
    @{ Name = "TeslaPro // VPN Finder"; Desc = "Searches for active VPN connections and related system traces."; Url = "https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1" },
    @{ Name = "AnyDesk Install Script"; Desc = "Downloads and installs AnyDesk using an automated PowerShell script."; Url = "https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1" },
    @{ Name = "Sellgui // Prime Macro Detector"; Desc = "Detects Prime macro traces and suspicious macro-related activity."; Url = "https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1" },
    @{ Name = "Nicc // Macro Detector"; Desc = "Searches for macro-related traces and suspicious system activity."; Url = "https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1" },
    @{ Name = "Jar Parser"; Desc = "Analyzes .jar files for suspicious classes, strings, and modifications."; Url = "https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1" },
    @{ Name = "Alt Detector"; Desc = "Searches the system for alternative accounts and related traces."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1" },
    @{ Name = "Scheduled Tasks"; Desc = "Checks scheduled tasks for suspicious or unusual entries."; Url = "https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1" },
    @{ Name = "BAM Parser"; Desc = "Parses BAM data to help identify previously executed applications."; Url = "https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1" },
    @{ Name = "Streams"; Desc = "Searches for NTFS Alternate Data Streams and hidden streams."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1" },
    @{ Name = "Signatures"; Desc = "Checks digital signatures and helps identify unsigned files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1" },
    @{ Name = "BAM Deleted Keys"; Desc = "Searches BAM data for deleted, missing, or unusual Registry entries."; Url = "https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1" },
    @{ Name = "Hard Disk Converter"; Desc = "Converts hard-disk volume identifiers into readable drive paths."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusHardDiskVolumeConverter.ps1" },
    @{ Name = "All In One"; Desc = "Runs multiple screenshare and forensic checks through one script."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1" },
    @{ Name = "Prefetch Integrity"; Desc = "Checks Windows Prefetch files for inconsistencies or modifications."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1" },
    @{ Name = "AnyDesk Reset"; Desc = "Resets or restores certain AnyDesk settings and configuration files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/anydesk.ps1" },
    @{ Name = "Spokwn BAM"; Desc = "Analyzes BAM data using Spokwn's BAM parser."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1" },
    @{ Name = "Mini SS"; Desc = "Runs a small and quick screenshare check."; Url = "https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1" },
    @{ Name = "Spokwn Tool Downloader"; Desc = "Downloads multiple Spokwn screenshare tools through one script."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Spokwn-Collect.ps1" },
    @{ Name = "Services"; Desc = "Checks important Windows services and their current configuration."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1" },
    @{ Name = "Signed Scheduled Tasks"; Desc = "Checks scheduled tasks and reviews their digital signatures."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks" },
    @{ Name = "Collector with AV Exclusion"; Desc = "Collects system information and forensic data while managing exclusions."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Collector.ps1" },
    @{ Name = "DoomsDay Finder"; Desc = "Searches for files and indicators associated with the DoomsDay client."; Url = "https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1" },
    @{ Name = "SSToolsHub"; Desc = "Gathers CMD and EXE tools into one script to facilitate checks."; Url = "https://raw.githubusercontent.com/3ntrsquad/SSToolsHub/refs/heads/main/SSToolsHub.ps1" }
)

# --- Theme Configuration ---
$colorBg      = [System.Drawing.Color]::FromArgb(20, 22, 30)
$colorPanel   = [System.Drawing.Color]::FromArgb(28, 31, 43)
$colorAccent  = [System.Drawing.Color]::FromArgb(98, 160, 234)
$colorText    = [System.Drawing.Color]::FromArgb(240, 240, 245)
$colorSubText = [System.Drawing.Color]::FromArgb(160, 165, 185)
$colorButton  = [System.Drawing.Color]::FromArgb(53, 116, 240)

# --- Main Window Setup ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "ValyaRssTool"
$mainForm.Size = New-Object System.Drawing.Size(960, 720)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = $colorBg
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$mainForm.MaximizeBox = $false

# --- Header Panel ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 90
$headerPanel.BackColor = $colorPanel
$mainForm.Controls.Add($headerPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "ValyaRssTool"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $colorAccent
$lblTitle.Location = New-Object System.Drawing.Point(25, 18)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Forensic & System Analysis Toolkit Hub"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSubTitle.ForeColor = $colorSubText
$lblSubTitle.Location = New-Object System.Drawing.Point(27, 52)
$lblSubTitle.AutoSize = $true
$headerPanel.Controls.Add($lblSubTitle)

# --- Search Box ---
$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Search:"
$lblSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblSearch.ForeColor = $colorSubText
$lblSearch.Location = New-Object System.Drawing.Point(620, 33)
$lblSearch.AutoSize = $true
$headerPanel.Controls.Add($lblSearch)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Size = New-Object System.Drawing.Size(220, 28)
$txtSearch.Location = New-Object System.Drawing.Point(680, 30)
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtSearch.BackColor = $colorBg
$txtSearch.ForeColor = $colorText
$txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$headerPanel.Controls.Add($txtSearch)

# --- Container Layout ---
$containerPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$containerPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$containerPanel.AutoScroll = $true
$containerPanel.Padding = New-Object System.Windows.Forms.Padding(15)
$containerPanel.BackColor = $colorBg
$mainForm.Controls.Add($containerPanel)

# --- Fixed Execution Handler ---
function Launch-ToolScript ($url, $name) {
    try {
        if ([string]::IsNullOrWhiteSpace($url)) {
            [System.Windows.Forms.MessageBox]::Show("URL is missing for this tool.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        # Trim whitespace cleanly
        $cleanUrl = $url.ToString().Trim()

        # Construct execution command with TLS 1.2 enforcement
        $cmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Clear-Host; Write-Host 'Executing $name...' -ForegroundColor Cyan; Write-Host 'Source: $cleanUrl' -ForegroundColor Gray; Write-Host ''; irm '$cleanUrl' | iex"

        # Launch in a persistent PowerShell window
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmd
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to launch tool: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# --- GUI Render Engine ---
function Render-Tools ($filterText = "") {
    $containerPanel.Controls.Clear()
    $containerPanel.SuspendLayout()

    foreach ($tool in $toolsList) {
        if ($filterText -ne "" -and ($tool.Name -notlike "*$filterText*" -and $tool.Desc -notlike "*$filterText*")) {
            continue
        }

        # Card Container
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(430, 125)
        $card.BackColor = $colorPanel
        $card.Margin = New-Object System.Windows.Forms.Padding(8)

        # Tool Title
        $tName = New-Object System.Windows.Forms.Label
        $tName.Text = $tool.Name
        $tName.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
        $tName.ForeColor = $colorAccent
        $tName.Location = New-Object System.Drawing.Point(12, 10)
        $tName.Size = New-Object System.Drawing.Size(405, 22)
        $card.Controls.Add($tName)

        # Tool Description
        $tDesc = New-Object System.Windows.Forms.Label
        $tDesc.Text = $tool.Desc
        $tDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $tDesc.ForeColor = $colorSubText
        $tDesc.Location = New-Object System.Drawing.Point(12, 34)
        $tDesc.Size = New-Object System.Drawing.Size(405, 42)
        $card.Controls.Add($tDesc)

        # Action Button
        $btnRun = New-Object System.Windows.Forms.Button
        $btnRun.Text = "Run Tool"
        $btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnRun.ForeColor = [System.Drawing.Color]::White
        $btnRun.BackColor = $colorButton
        $btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnRun.FlatAppearance.BorderSize = 0
        $btnRun.Size = New-Object System.Drawing.Size(110, 30)
        $btnRun.Location = New-Object System.Drawing.Point(305, 82)
        $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        # Store tool hash table directly in Tag property to avoid scope issues
        $btnRun.Tag = $tool

        # Attach Click Event using $this.Tag
        $btnRun.Add_Click({
            $selectedTool = $this.Tag
            Launch-ToolScript -url $selectedTool.Url -name $selectedTool.Name
        })
        
        $card.Controls.Add($btnRun)
        $containerPanel.Controls.Add($card)
    }

    $containerPanel.ResumeLayout()
}

# --- Event Handlers ---
$txtSearch.Add_TextChanged({
    Render-Tools -filterText $txtSearch.Text
})

# --- Initial Execution ---
Render-Tools
[void]$mainForm.ShowDialog()
