# ValyaRssTools - GUI Dashboard
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# النافذة الرئيسية
$form = New-Object System.Windows.Forms.Form
$form.Text = "ValyaRssTools"
$form.Size = New-Object System.Drawing.Size(850, 720)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

# العنوان
$label = New-Object System.Windows.Forms.Label
$label.Text = "ValyaRssTools - لوحة أدوات التفتيش والفحص"
$label.Location = New-Object System.Drawing.Point(20, 15)
$label.Size = New-Object System.Drawing.Size(800, 30)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# لوحة قابلة للتمرير (Scrollable Panel) لاستيعاب جميع الأزرار
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 50)
$panel.Size = New-Object System.Drawing.Size(795, 600)
$panel.AutoScroll = $true
$form.Controls.Add($panel)

# قائمة السكربتات والروابط
$tools = @(
    @{ Name = "TeslaPro // Doomsday Detector"; Url = "https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1" },
    @{ Name = "Xkzutos // Mod Analyzer"; Url = "https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1" },
    @{ Name = "TeslaPro // GhostClientFinder"; Url = "https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1" },
    @{ Name = "Tonynoh // Meow Mod Analyzer"; Url = "https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1" },
    @{ Name = "CheesyDqrkisFucker"; Url = "https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1" },
    @{ Name = "TeslaPro // VPN Finder"; Url = "https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1" },
    @{ Name = "AnyDesk Install Script"; Url = "https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1" },
    @{ Name = "Sellgui // Prime Macro Detector"; Url = "https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1" },
    @{ Name = "Nicc // Macro Detector"; Url = "https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1" },
    @{ Name = "Jar Parser"; Url = "https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1" },
    @{ Name = "Alt Detector"; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1" },
    @{ Name = "Scheduled Tasks"; Url = "https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1" },
    @{ Name = "BAM Parser"; Url = "https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1" },
    @{ Name = "Streams"; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1" },
    @{ Name = "Signatures"; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1" },
    @{ Name = "BAM Deleted Keys"; Url = "https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1" },
    @{ Name = "Hard Disk Converter"; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusHardDiskVolumeConverter.ps1" },
    @{ Name = "All In One"; Url = "https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1" },
    @{ Name = "Prefetch Integrity"; Url = "https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1" },
    @{ Name = "AnyDesk Reset"; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/anydesk.ps1" },
    @{ Name = "Spokwn BAM"; Url = "https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1" },
    @{ Name = "Mini SS"; Url = "https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1" },
    @{ Name = "Spokwn Tool Downloader"; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Spokwn-Collect.ps1" },
    @{ Name = "Services"; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1" },
    @{ Name = "Signed Scheduled Tasks"; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks" },
    @{ Name = "Collector with AV Exclusion"; Url = "https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Collector.ps1" },
    @{ Name = "DoomsDay Finder"; Url = "https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1" },
    @{ Name = "SSToolsHub"; Url = "https://raw.githubusercontent.com/3ntrsquad/SSToolsHub/refs/heads/main/SSToolsHub.ps1" }
)

# إنشاء الأزرار تلقائياً في عمودين
$xLeft = 20
$xRight = 390
$y = 10
$isLeft = $true

foreach ($tool in $tools) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $tool.Name
    $btn.Size = New-Object System.Drawing.Size(350, 40)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    
    if ($isLeft) {
        $btn.Location = New-Object System.Drawing.Point($xLeft, $y)
        $isLeft = $false
    } else {
        $btn.Location = New-Object System.Drawing.Point($xRight, $y)
        $y += 50
        $isLeft = $true
    }

    # تحديد الحدث عند الضغط على الزر
    $scriptUrl = $tool.Url
    $btn.Add_Click({
        param($sender, $e)
        $targetUrl = $sender.Tag
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm '$targetUrl' | iex"
    }.GetNewClosure())
    
    $btn.Tag = $scriptUrl
    $panel.Controls.Add($btn)
}

# عرض النافذة
$form.ShowDialog()
