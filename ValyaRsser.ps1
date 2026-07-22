<#
.SYNOPSIS
    ValyaRsser - Launcher GUI لأدوات ValyaRssTool
.DESCRIPTION
    يفتح واجهة رسومية (WinForms) فيها زر لكل سكربت PowerShell موجود
    داخل مجلد tools، وعند الضغط على الزر يشغّل السكربت المطابق
    في نافذة PowerShell جديدة.
.NOTES
    شغّل هذا الملف بصلاحيات مناسبة حسب الأداة (بعض الأدوات، متل قراءة
    BAM من الـ Registry، تحتاج صلاحيات Administrator).
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- إعدادات عامة ----------
$RootDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolsDir = Join-Path $RootDir "tools"

if (-not (Test-Path $ToolsDir)) {
    [System.Windows.Forms.MessageBox]::Show(
        "مجلد tools غير موجود بجانب ValyaRsser.ps1`n($ToolsDir)",
        "ValyaRssTool - خطأ",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# خريطة أسماء الزر المعروضة -> اسم الملف (اختياري، لو حبيت تسمية أجمل من اسم الملف)
$DisplayNameMap = @{
    "DoomsdayClientDetectorV3.ps1" = "Doomsday Client Detector"
    "VPNFinder.ps1"                = "VPN Finder"
    "BAMParser.ps1"                = "BAM Parser"
}

# ---------- دالة تشغيل سكربت في نافذة PowerShell جديدة ----------
function Start-Tool {
    param([string]$ScriptPath)

    if (-not (Test-Path $ScriptPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            "الملف غير موجود:`n$ScriptPath",
            "ValyaRssTool - خطأ",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    # -NoExit يخلي نافذة الـ PowerShell مفتوحة بعد ما تخلص الأداة عشان تشوف النتيجة
    Start-Process powershell.exe -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-NoExit",
        "-File", "`"$ScriptPath`""
    )
}

# ---------- بناء الواجهة ----------
$Form                 = New-Object System.Windows.Forms.Form
$Form.Text            = "ValyaRssTool"
$Form.Size            = New-Object System.Drawing.Size(420, 520)
$Form.StartPosition   = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox     = $false
$Form.BackColor       = [System.Drawing.Color]::FromArgb(24, 24, 28)

$TitleLabel           = New-Object System.Windows.Forms.Label
$TitleLabel.Text      = "ValyaRssTool"
$TitleLabel.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$TitleLabel.AutoSize  = $false
$TitleLabel.TextAlign = "MiddleCenter"
$TitleLabel.Size      = New-Object System.Drawing.Size(400, 50)
$TitleLabel.Location  = New-Object System.Drawing.Point(10, 10)
$Form.Controls.Add($TitleLabel)

$SubLabel             = New-Object System.Windows.Forms.Label
$SubLabel.Text        = "اختر الأداة اللي بدك تشغّلها"
$SubLabel.Font        = New-Object System.Drawing.Font("Segoe UI", 10)
$SubLabel.ForeColor   = [System.Drawing.Color]::LightGray
$SubLabel.AutoSize    = $false
$SubLabel.TextAlign   = "MiddleCenter"
$SubLabel.Size        = New-Object System.Drawing.Size(400, 25)
$SubLabel.Location    = New-Object System.Drawing.Point(10, 60)
$Form.Controls.Add($SubLabel)

# Panel قابل للتمرير يحتوي أزرار الأدوات
$Panel            = New-Object System.Windows.Forms.Panel
$Panel.Location   = New-Object System.Drawing.Point(10, 95)
$Panel.Size       = New-Object System.Drawing.Size(384, 350)
$Panel.AutoScroll = $true
$Form.Controls.Add($Panel)

# اجلب كل سكربتات .ps1 داخل tools
$ScriptFiles = Get-ChildItem -Path $ToolsDir -Filter "*.ps1" | Sort-Object Name

$y = 0
foreach ($file in $ScriptFiles) {

    $displayName = if ($DisplayNameMap.ContainsKey($file.Name)) {
        $DisplayNameMap[$file.Name]
    } else {
        [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    }

    $btn              = New-Object System.Windows.Forms.Button
    $btn.Text         = $displayName
    $btn.Size         = New-Object System.Drawing.Size(360, 45)
    $btn.Location     = New-Object System.Drawing.Point(5, $y)
    $btn.Font         = New-Object System.Drawing.Font("Segoe UI", 11)
    $btn.BackColor    = [System.Drawing.Color]::FromArgb(40, 40, 48)
    $btn.ForeColor    = [System.Drawing.Color]::White
    $btn.FlatStyle    = "Flat"
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
    $btn.Tag          = $file.FullName

    $btn.Add_Click({
        param($sender, $e)
        Start-Tool -ScriptPath $sender.Tag
    })

    $Panel.Controls.Add($btn)
    $y += 55
}

if ($ScriptFiles.Count -eq 0) {
    $emptyLabel           = New-Object System.Windows.Forms.Label
    $emptyLabel.Text      = "ما في أي أداة داخل مجلد tools حالياً."
    $emptyLabel.ForeColor = [System.Drawing.Color]::Gray
    $emptyLabel.AutoSize  = $true
    $emptyLabel.Location  = New-Object System.Drawing.Point(5, 10)
    $Panel.Controls.Add($emptyLabel)
}

# زر تحديث القائمة (لو ضفت أداة جديدة بدون ما تعيد فتح البرنامج)
$RefreshBtn           = New-Object System.Windows.Forms.Button
$RefreshBtn.Text      = "تحديث القائمة"
$RefreshBtn.Size      = New-Object System.Drawing.Size(384, 35)
$RefreshBtn.Location  = New-Object System.Drawing.Point(10, 455)
$RefreshBtn.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
$RefreshBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 160)
$RefreshBtn.ForeColor = [System.Drawing.Color]::White
$RefreshBtn.FlatStyle = "Flat"
$RefreshBtn.Add_Click({
    $Form.Close()
    & $MyInvocation.MyCommand.Path
})
$Form.Controls.Add($RefreshBtn)

[void]$Form.ShowDialog()
