<#
    .NOTES
    ===========================================================================
    Tool Name   : ValyaRssTool
    Description : Modern GUI Launcher for Screenshare & System Diagnostic Tools
    ===========================================================================
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- قائمة الأدوات والروابط ---
$toolsList = @(
    @{ Name = "TeslaPro // Doomsday Detector"; Desc = "Detects Doomsday client traces and runs a specialized detection workflow."; Url = "https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1" },
    @{ Name = "Xkzutos // Mod Analyzer"; Desc = "Analyzes Minecraft mods by checking metadata, file hashes, and known indicators."; Url = "https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1" },
    @{ Name = "TeslaPro // GhostClientFinder"; Desc = "Searches for Ghost Client traces and suspicious modifications inside Minecraft files."; Url = "https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1" },
    @{ Name = "Tonynoh // Meow Mod Analyzer"; Desc = "Analyzes Minecraft mods and detects suspicious files and hidden client indicators."; Url = "https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1" },
    @{ Name = "CheesyDqrkisFucker"; Desc = "Searches for Dqrkis-related traces and suspicious modifications linked to the client."; Url = "https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1" },
    @{ Name = "TeslaPro // VPN Finder"; Desc = "Searches for active VPN connections and related traces."; Url = "https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1" },
    @{ Name = "AnyDesk Install Script"; Desc = "Downloads and installs AnyDesk using an automated PowerShell script."; Url = "https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1" },
    @{ Name = "Sellgui // Prime Macro Detector"; Desc = "Detects Prime macro traces and suspicious macro-related activity."; Url = "https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1" },
    @{ Name = "Nicc // Macro Detector"; Desc = "Searches for macro-related traces and suspicious activity."; Url = "https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1" },
    @{ Name = "Jar Parser"; Desc = "Analyzes .jar files for suspicious classes, strings, and cheat modifications."; Url = "https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1" },
    @{ Name = "Alt Detector"; Desc = "Searches the system for alternative accounts and related traces."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1" },
    @{ Name = "Scheduled Tasks"; Desc = "Checks scheduled tasks for suspicious or unusual entries."; Url = "https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1" },
    @{ Name = "BAM Parser"; Desc = "Parses BAM data to help identify previously executed applications."; Url = "https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1" },
    @{ Name = "Streams"; Desc = "Searches for NTFS Alternate Data Streams and hidden streams."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1" },
    @{ Name = "Signatures"; Desc = "Checks digital signatures and helps identify unsigned files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1" },
    @{ Name = "BAM Deleted Keys"; Desc = "Searches BAM data for deleted, missing, or unusual Registry entries."; Url = "https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1" },
    @{ Name = "Hard Disk Converter"; Desc = "Converts hard-disk volume identifiers into readable drive paths."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusHardDiskVolumeConverter.ps1" },
    @{ Name = "All In One"; Desc = "Runs multiple screenshare and forensic checks through one script."; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1" },
    @{ Name = "Prefetch Integrity"; Desc = "Checks Windows Prefetch files for inconsistencies or modifications."; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1" },
    @{ Name = "AnyDesk Reset"; Desc = "Resets or restores certain AnyDesk settings and files."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/anydesk.ps1" },
    @{ Name = "Spokwn BAM"; Desc = "Analyzes BAM data using Spokwn's BAM parser."; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1" },
    @{ Name = "Mini SS"; Desc = "Runs a small and quick screenshare check."; Url = "https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1" },
    @{ Name = "Spokwn Tool Downloader"; Desc = "Downloads multiple Spokwn screenshare tools through one script."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Spokwn-Collect.ps1" },
    @{ Name = "Services"; Desc = "Checks important Windows services and their current configuration."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1" },
    @{ Name = "Signed Scheduled Tasks"; Desc = "Checks scheduled tasks and reviews their digital signatures."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks" },
    @{ Name = "Collector with AV Exclusion"; Desc = "Collects system information and forensic data while managing exclusions."; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Collector.ps1" },
    @{ Name = "DoomsDay Finder"; Desc = "Searches for files and indicators associated with the DoomsDay client."; Url = "https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1" },
    @{ Name = "SSToolsHub"; Desc = "Gathers CMD and EXE tools into one script to facilitate checks."; Url = "https://raw.githubusercontent.com/3ntrsquad/SSToolsHub/refs/heads/main/SSToolsHub.ps1" }
)

# --- الألوان والإنشاء ---
$colorBg      = [System.Drawing.Color]::FromArgb(24, 24, 37)     # Dark Background
$colorPanel   = [System.Drawing.Color]::FromArgb(30, 30, 46)     # Card Background
$colorAccent  = [System.Drawing.Color]::FromArgb(137, 180, 250)  # Blue Accent
$colorText    = [System.Drawing.Color]::FromArgb(205, 214, 244)  # Main Text
$colorSubText = [System.Drawing.Color]::FromArgb(166, 173, 200)  # Subtitle Text
$colorButton  = [System.Drawing.Color]::FromArgb(114, 135, 253)  # Button Primary

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "ValyaRssTool v1.0"
$mainForm.Size = New-Object System.Drawing.Size(950, 700)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = $colorBg
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$mainForm.MaximizeBox = $false

# --- الهيدر الرئيسي (Header) ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 100
$headerPanel.BackColor = $colorPanel
$mainForm.Controls.Add($headerPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "ValyaRssTool"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $colorAccent
$lblTitle.Location = New-Object System.Drawing.Point(25, 15)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Centralized CMD & PowerShell Forensic Tools Hub"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$lblSubTitle.ForeColor = $colorSubText
$lblSubTitle.Location = New-Object System.Drawing.Point(27, 55)
$lblSubTitle.AutoSize = $true
$headerPanel.Controls.Add($lblSubTitle)

# --- صندوق البحث (Search Box) ---
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Size = New-Object System.Drawing.Size(250, 30)
$txtSearch.Location = New-Object System.Drawing.Point(650, 35)
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$txtSearch.BackColor = $colorBg
$txtSearch.ForeColor = $colorText
$txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$headerPanel.Controls.Add($txtSearch)

# --- لوحة العرض الرئيسية (Scrollable FlowLayoutPanel) ---
$containerPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$containerPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$containerPanel.AutoScroll = $true
$containerPanel.Padding = New-Object System.Windows.Forms.Padding(20)
$containerPanel.BackColor = $colorBg
$mainForm.Controls.Add($containerPanel)

# --- دالة تشغيل السكربتات في نافذة جديدة ---
function Launch-ToolScript ($url, $name) {
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Write-Host 'Running $name...'; irm '$url' | iex`""
    } catch {
        [System.Windows.Forms.MessageBox]::Show("تعذر تشغيل الأداة: $_", "خطأ", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# --- دالة رسم أدوات الشاشة (Render Tools) ---
function Render-Tools ($filterText = "") {
    $containerPanel.Controls.Clear()
    $containerPanel.SuspendLayout()

    foreach ($tool in $toolsList) {
        if ($filterText -ne "" -and ($tool.Name -notlike "*$filterText*" -and $tool.Desc -notlike "*$filterText*")) {
            continue
        }

        # إنشاء بطاقة الأداة (Card)
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(425, 120)
        $card.BackColor = $colorPanel
        $card.Margin = New-Object System.Windows.Forms.Padding(10)

        # عنوان الأداة
        $tName = New-Object System.Windows.Forms.Label
        $tName.Text = $tool.Name
        $tName.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $tName.ForeColor = $colorAccent
        $tName.Location = New-Object System.Drawing.Point(12, 10)
        $tName.Size = New-Object System.Drawing.Size(400, 25)
        $card.Controls.Add($tName)

        # وصف الأداة
        $tDesc = New-Object System.Windows.Forms.Label
        $tDesc.Text = $tool.Desc
        $tDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $tDesc.ForeColor = $colorSubText
        $tDesc.Location = New-Object System.Drawing.Point(12, 35)
        $tDesc.Size = New-Object System.Drawing.Size(400, 40)
        $card.Controls.Add($tDesc)

        # زر التشغيل
        $btnRun = New-Object System.Windows.Forms.Button
        $btnRun.Text = "تشغيل الأداة"
        $btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnRun.ForeColor = [System.Drawing.Color]::White
        $btnRun.BackColor = $colorButton
        $btnRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnRun.FlatAppearance.BorderSize = 0
        $btnRun.Size = New-Object System.Drawing.Size(110, 30)
        $btnRun.Location = New-Object System.Drawing.Point(300, 80)
        $btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        $scriptUrl = $tool.Url
        $toolTitle = $tool.Name
        $btnRun.Add_Click({ Launch-ToolScript -url $scriptUrl -name $toolTitle })
        
        $card.Controls.Add($btnRun)
        $containerPanel.Controls.Add($card)
    }

    $containerPanel.ResumeLayout()
}

# ربط حدث البحث
$txtSearch.Add_TextChanged({
    Render-Tools -filterText $txtSearch.Text
})

# التشغيل الأولي
Render-Tools
[void]$mainForm.ShowDialog()
