
# CONFIG: GitHub repository details
$GITHUB_USERNAME = "Va2lyR"          # Your GitHub username
$GITHUB_REPO = "ValyaRssTool"        # Your repository name
$BRANCH = "main"                     # Default branch (usually "main" or "master")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.InteropServices

# ==============================================================================
# WIN32 – Rounded Corners &amp; Drag
# ==============================================================================
if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int SetWindowRgn(IntPtr hWnd, IntPtr hRgn, bool bRedraw);
    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateRoundRectRgn(int x1, int y1, int x2, int y2, int cx, int cy);
    [DllImport("user32.dll")]
    public static extern int ReleaseCapture();
    [DllImport("user32.dll")]
    public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
}
"@
}

function Make-Rounded {
    param($control, $radius = 20)
    try {
        $rgn = [Win32]::CreateRoundRectRgn(0, 0, $control.Width, $control.Height, $radius, $radius)
        [Win32]::SetWindowRgn($control.Handle, $rgn, $true)
    } catch {}
}

# ==============================================================================
# CUSTOM GRADIENT BUTTON
# ==============================================================================
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

public class GradientButton : Button {
    private Color color1 = Color.FromArgb(139, 92, 246);
    private Color color2 = Color.FromArgb(236, 72, 153);
    private Color hoverColor1 = Color.FromArgb(167, 139, 250);
    private Color hoverColor2 = Color.FromArgb(244, 114, 182);
    private int cornerRadius = 12;
    private bool isHovered = false;

    public GradientButton() {
        this.FlatStyle = FlatStyle.Flat;
        this.FlatAppearance.BorderSize = 0;
        this.BackColor = Color.Transparent;
        this.SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.ResizeRedraw | ControlStyles.DoubleBuffer, true);
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        Rectangle rect = new Rectangle(0, 0, this.Width, this.Height);
        
        GraphicsPath path = new GraphicsPath();
        int r = cornerRadius;
        int w = this.Width;
        int h = this.Height;
        path.AddArc(0, 0, r, r, 180, 90);
        path.AddArc(w - r, 0, r, r, 270, 90);
        path.AddArc(w - r, h - r, r, r, 0, 90);
        path.AddArc(0, h - r, r, r, 90, 90);
        path.CloseFigure();
        
        this.Region = new Region(path);
        
        Color c1 = isHovered ? hoverColor1 : color1;
        Color c2 = isHovered ? hoverColor2 : color2;
        LinearGradientBrush brush = new LinearGradientBrush(rect, c1, c2, LinearGradientMode.Horizontal);
        g.FillPath(brush, path);
        brush.Dispose();
        
        // Text
        StringFormat sf = new StringFormat();
        sf.Alignment = StringAlignment.Center;
        sf.LineAlignment = StringAlignment.Center;
        using (SolidBrush textBrush = new SolidBrush(Color.White)) {
            g.DrawString(this.Text, this.Font, textBrush, rect, sf);
        }
        path.Dispose();
    }

    protected override void OnMouseEnter(EventArgs e) {
        isHovered = true;
        this.Invalidate();
        base.OnMouseEnter(e);
    }

    protected override void OnMouseLeave(EventArgs e) {
        isHovered = false;
        this.Invalidate();
        base.OnMouseLeave(e);
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms.dll","System.Drawing.dll","System.dll"

# ==============================================================================
# COLOR PALETTE - DARK MODERN
# ==============================================================================
$colors = @{
    bg          = [System.Drawing.Color]::FromArgb(10, 10, 10)
    bgCard      = [System.Drawing.Color]::FromArgb(18, 18, 18)
    bgCardLight = [System.Drawing.Color]::FromArgb(26, 26, 26)
    text        = [System.Drawing.Color]::FromArgb(248, 250, 252)
    textSecondary = [System.Drawing.Color]::FromArgb(156, 163, 175)
    textMuted   = [System.Drawing.Color]::FromArgb(107, 114, 128)
    accent      = [System.Drawing.Color]::FromArgb(139, 92, 246)
    accent2     = [System.Drawing.Color]::FromArgb(236, 72, 153)
    success     = [System.Drawing.Color]::FromArgb(34, 197, 94)
    danger      = [System.Drawing.Color]::FromArgb(239, 68, 68)
    border      = [System.Drawing.Color]::FromArgb(38, 38, 38)
}

# ==============================================================================
# FORM
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "ValyaRssTool Launcher"
$form.Size = New-Object System.Drawing.Size(600, 580)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"
$form.BackColor = $colors.bg
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.TopMost = $true
$form.Add_Shown({ Make-Rounded -control $form -radius 16 })

# ==============================================================================
# TITLE BAR
# ==============================================================================
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(600, 64)
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$form.Controls.Add($titleBar)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "✨ ValyaRssTool"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $colors.text
$titleLabel.Size = New-Object System.Drawing.Size(450, 64)
$titleLabel.Location = New-Object System.Drawing.Point(24, 0)
$titleLabel.TextAlign = "MiddleLeft"
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleBar.Controls.Add($titleLabel)

$subTitle = New-Object System.Windows.Forms.Label
$subTitle.Text = "Premium Toolkit"
$subTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$subTitle.ForeColor = $colors.textMuted
$subTitle.Size = New-Object System.Drawing.Size(200, 24)
$subTitle.Location = New-Object System.Drawing.Point(220, 32)
$subTitle.TextAlign = "MiddleLeft"
$subTitle.BackColor = [System.Drawing.Color]::Transparent
$titleBar.Controls.Add($subTitle)

$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = "✕"
$closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$closeBtn.Size = New-Object System.Drawing.Size(40, 40)
$closeBtn.Location = New-Object System.Drawing.Point(550, 12)
$closeBtn.FlatStyle = "Flat"
$closeBtn.FlatAppearance.BorderSize = 0
$closeBtn.BackColor = [System.Drawing.Color]::Transparent
$closeBtn.ForeColor = $colors.textMuted
$closeBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeBtn.Add_Click({ $form.Close() })
$closeBtn.Add_MouseEnter({ 
    $closeBtn.ForeColor = $colors.danger
    $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(30, 15, 15)
})
$closeBtn.Add_MouseLeave({ 
    $closeBtn.ForeColor = $colors.textMuted
    $closeBtn.BackColor = [System.Drawing.Color]::Transparent
})
$titleBar.Controls.Add($closeBtn)

$titleBar.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        [Win32]::ReleaseCapture()
        [Win32]::SendMessage($form.Handle, 0xA1, 0x2, 0)
    }
})

# ==============================================================================
# MAIN CONTENT
# ==============================================================================
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(560, 496)
$mainPanel.Location = New-Object System.Drawing.Point(20, 76)
$mainPanel.BackColor = [System.Drawing.Color]::Transparent
$mainPanel.AutoScroll = $false
$form.Controls.Add($mainPanel)

# ==============================================================================
# GLASS CARD HELPER
# ==============================================================================
function New-GlassCard {
    param($x, $y, $w, $h)
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size($w, $h)
    $card.Location = New-Object System.Drawing.Point($x, $y)
    $card.BackColor = $colors.bgCard
    $card.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $card.Add_Paint({
        $g = $_.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = New-Object System.Drawing.Rectangle(0, 0, $card.Width, $card.Height)
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $r = 12
        $w2 = $card.Width
        $h2 = $card.Height
        $path.AddArc(0, 0, $r, $r, 180, 90)
        $path.AddArc($w2 - $r, 0, $r, $r, 270, 90)
        $path.AddArc($w2 - $r, $h2 - $r, $r, $r, 0, 90)
        $path.AddArc(0, $h2 - $r, $r, $r, 90, 90)
        $path.CloseFigure()
        
        $fillBrush = New-Object System.Drawing.SolidBrush($colors.bgCard)
        $g.FillPath($fillBrush, $path)
        $fillBrush.Dispose()
        
        $borderBrush = New-Object System.Drawing.SolidBrush($colors.border)
        $g.DrawPath((New-Object System.Drawing.Pen($borderBrush, 1)), $path)
        $borderBrush.Dispose()
        $path.Dispose()
    })
    return $card
}

function New-GlassLabel {
    param($text, $x, $y, $w, $h, $fs = 10, $bold = $false, $color = $null, $align = "MiddleLeft")
    if (-not $color) { $color = $colors.text }
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $fs, $style)
    $label.ForeColor = $color
    $label.Size = New-Object System.Drawing.Size($w, $h)
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.TextAlign = [System.Drawing.ContentAlignment]::$align
    $label.BackColor = [System.Drawing.Color]::Transparent
    return $label
}

# ==============================================================================
# CARDS
# ==============================================================================
$welcomeCard = New-GlassCard 0 0 560 80
$mainPanel.Controls.Add($welcomeCard)
$welcomeCard.Controls.Add((New-GlassLabel -text "👋 Welcome to ValyaRssTool" -x 24 -y 16 -w 520 -h 32 -fs 18 -bold $true -color $colors.text -align "MiddleLeft"))
$welcomeCard.Controls.Add((New-GlassLabel -text "Professional toolkit ready to use" -x 24 -y 48 -w 520 -h 24 -fs 11 -bold $false -color $colors.textSecondary -align "MiddleLeft"))

$toolCard = New-GlassCard 0 96 560 112
$mainPanel.Controls.Add($toolCard)
$toolCard.Controls.Add((New-GlassLabel -text "📦 TOOL INFORMATION" -x 24 -y 12 -w 520 -h 28 -fs 13 -bold $true -color $colors.accent -align "MiddleLeft"))
$toolInfo = @(
    "All tools are preserved and fully functional",
    "New modern, dark UI with smooth animations",
    "For educational and professional use"
)
$yOff = 44
foreach ($line in $toolInfo) {
    $toolCard.Controls.Add((New-GlassLabel -text "• $line" -x 24 -y $yOff -w 520 -h 22 -fs 10 -bold $false -color $colors.textSecondary -align "MiddleLeft"))
    $yOff += 22
}

$creditsCard = New-GlassCard 0 220 560 176
$mainPanel.Controls.Add($creditsCard)
$creditsCard.Controls.Add((New-GlassLabel -text "🎯 FEATURES" -x 24 -y 12 -w 520 -h 28 -fs 13 -bold $true -color $colors.accent2 -align "MiddleLeft"))
$credits = @(
    @{ Icon = "✅"; Label = "Modern UI"; Value = "Dark theme with smooth effects"; Color = $colors.text }
    @{ Icon = "🚀"; Label = "Fast Launch"; Value = "Quick access to all tools"; Color = $colors.text }
    @{ Icon = "🔧"; Label = "Full Features"; Value = "All original tools preserved"; Color = $colors.text }
)
$yOff2 = 44
foreach ($item in $credits) {
    $creditsCard.Controls.Add((New-GlassLabel -text $item.Icon -x 24 -y $yOff2 -w 30 -h 32 -fs 16 -bold $false -color $colors.text -align "MiddleLeft"))
    $creditsCard.Controls.Add((New-GlassLabel -text "$($item.Label):" -x 60 -y $yOff2 -w 120 -h 32 -fs 11 -bold $true -color $colors.text -align "MiddleLeft"))
    $creditsCard.Controls.Add((New-GlassLabel -text $item.Value -x 185 -y $yOff2 -w 360 -h 32 -fs 11 -bold $false -color $colors.textSecondary -align "MiddleLeft"))
    $yOff2 += 36
}
$creditsCard.Controls.Add((New-GlassLabel -text "⚠️ Use responsibly" -x 24 -y 136 -w 520 -h 28 -fs 12 -bold $true -color $colors.danger -align "MiddleCenter"))

# ==============================================================================
# STATUS INDICATOR
# ==============================================================================
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Size = New-Object System.Drawing.Size(560, 32)
$statusPanel.Location = New-Object System.Drawing.Point(0, 416)
$statusPanel.BackColor = [System.Drawing.Color]::Transparent
$mainPanel.Controls.Add($statusPanel)

$statusDot = New-Object System.Windows.Forms.Panel
$statusDot.Size = New-Object System.Drawing.Size(10, 10)
$statusDot.Location = New-Object System.Drawing.Point(0, 11)
$statusDot.BackColor = $colors.success
$statusDot.Add_Paint({
    $g = $_.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, 10, 10)
    $statusDot.Region = New-Object System.Drawing.Region($path)
    $path.Dispose()
})
$statusPanel.Controls.Add($statusDot)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to launch ValyaRssTool"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$statusLabel.ForeColor = $colors.textSecondary
$statusLabel.Size = New-Object System.Drawing.Size(540, 32)
$statusLabel.Location = New-Object System.Drawing.Point(20, 0)
$statusLabel.TextAlign = "MiddleLeft"
$statusLabel.BackColor = [System.Drawing.Color]::Transparent
$statusPanel.Controls.Add($statusLabel)

# ==============================================================================
# CUSTOM GRADIENT LAUNCH BUTTONS
# ==============================================================================
# Button 1: Run Local File
$launchLocalBtn = New-Object GradientButton
$launchLocalBtn.Text = "💻 RUN LOCAL FILE"
$launchLocalBtn.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$launchLocalBtn.Size = New-Object System.Drawing.Size(260, 52)
$launchLocalBtn.Location = New-Object System.Drawing.Point(20, 440)
$launchLocalBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$mainPanel.Controls.Add($launchLocalBtn)

$launchLocalBtn.Add_Click({
    $statusDot.BackColor = $colors.accent
    $statusLabel.Text = "🚀 Launching local ValyaRssTool..."
    $statusLabel.ForeColor = $colors.accent
    $scriptPath = Join-Path $PSScriptRoot "SSToolsHub.ps1"
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ep", "bypass", "-File", $scriptPath
    $form.Close()
})

# Button 2: Download from GitHub
$launchGitHubBtn = New-Object GradientButton
$launchGitHubBtn.Text = "🌐 DOWNLOAD FROM GITHUB"
$launchGitHubBtn.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$launchGitHubBtn.Size = New-Object System.Drawing.Size(260, 52)
$launchGitHubBtn.Location = New-Object System.Drawing.Point(280, 440)
$launchGitHubBtn.Cursor = [System.Windows.Forms.Cursors]::Hand
$mainPanel.Controls.Add($launchGitHubBtn)

$launchGitHubBtn.Add_Click({
    $statusDot.BackColor = $colors.accent
    $statusLabel.Text = "🌐 Downloading ValyaRssTool from GitHub..."
    $statusLabel.ForeColor = $colors.accent
    $githubUrl = "https://raw.githubusercontent.com/$GITHUB_USERNAME/$GITHUB_REPO/refs/heads/$BRANCH/SSToolsHub.ps1"
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ep", "bypass", "-c", "irm `"$githubUrl` | iex"
    $form.Close()
})

# ==============================================================================
# KEYBOARD SHORTCUTS
# ==============================================================================
$form.Add_KeyDown({
    if ($_.KeyCode -eq "Escape") { $form.Close() }
    if ($_.KeyCode -eq "Enter" -and -not $_.Control) {
        $scriptPath = Join-Path $PSScriptRoot "SSToolsHub.ps1"
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ep", "bypass", "-File", $scriptPath
        $form.Close()
    }
    if ($_.KeyCode -eq "Enter" -and $_.Control) {
        $githubUrl = "https://raw.githubusercontent.com/$GITHUB_USERNAME/$GITHUB_REPO/refs/heads/$BRANCH/SSToolsHub.ps1"
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ep", "bypass", "-c", "irm `"$githubUrl` | iex"
        $form.Close()
    }
})

# ==============================================================================
# SHOW
# ==============================================================================
$form.ShowDialog() | Out-Null
