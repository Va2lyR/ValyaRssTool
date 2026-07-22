# ==========================================
#  ValyarSS Control Center - Main Launcher
#  Repo: Va2lyR/ValyaRssTool
# ==========================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# قائمة الأدوات المربوطة بمستودع GitHub الخاص بك
$script:ToolsCatalog = @(
    # Detectors
    @{ Name = "Doomsday Detector V3";  File = "DoomsdayClientDetectorV3.ps1"; Category = "DETECTORS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/DoomsdayClientDetectorV3.ps1" },
    @{ Name = "Doomsday Finder";        File = "DoomsDayDetector.ps1";          Category = "DETECTORS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/DoomsDayDetector.ps1" },
    @{ Name = "Ghost Client Finder";    File = "GhostClientFucker.ps1";         Category = "DETECTORS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/GhostClientFucker.ps1" },
    @{ Name = "Dqrkis Detector";        File = "DqrkisFucker.ps1";              Category = "DETECTORS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/DqrkisFucker.ps1" },
    @{ Name = "Alt Detector";           File = "Alt-Detector.ps1";              Category = "DETECTORS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Alt-Detector.ps1" },

    # Analyzers
    @{ Name = "Mod Analyzer (Xkzutos)"; File = "XkzutosModAnalyzer.ps1";        Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/XkzutosModAnalyzer.ps1" },
    @{ Name = "Meow Mod Analyzer";      File = "MeowModAnalyzer.ps1";           Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/MeowModAnalyzer.ps1" },
    @{ Name = "JAR Parser";             File = "JARParser.ps1";                 Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/JARParser.ps1" },
    @{ Name = "Prefetch Integrity";     File = "RedLotusPrefetchIntegrityAnalyzer.ps1"; Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/RedLotusPrefetchIntegrityAnalyzer.ps1" },
    @{ Name = "BAM Parser (RedLotus)";  File = "RedLotusBam.ps1";               Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/RedLotusBam.ps1" },
    @{ Name = "Spokwn BAM Parser";      File = "bamparser.ps1";                 Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/bamparser.ps1" },
    @{ Name = "BAM Deleted Keys";      File = "bam.ps1";                       Category = "ANALYZERS"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/bam.ps1" },

    # Macros
    @{ Name = "Prime Macro Detector";   File = "Macro Detector.ps1";            Category = "MACROS";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Macro%20Detector.ps1" },
    @{ Name = "Nicc Macro Detector";    File = "MacroDetector.ps1";             Category = "MACROS";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/MacroDetector.ps1" },

    # System & Utilities
    @{ Name = "VPN Finder";             File = "VPNFinder.ps1";                 Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/VPNFinder.ps1" },
    @{ Name = "Scheduled Tasks";        File = "SuspiciousScheduler.ps1";       Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/SuspiciousScheduler.ps1" },
    @{ Name = "Signed Scheduled Tasks"; File = "Signed-Scheduled-Tasks.ps1";    Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Signed-Scheduled-Tasks.ps1" },
    @{ Name = "NTFS Streams";           File = "Streams.ps1";                   Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Streams.ps1" },
    @{ Name = "Digital Signatures";     File = "signatures.ps1";                Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/signatures.ps1" },
    @{ Name = "Hard Disk Converter";    File = "RedLotusHardDiskVolumeConverter.ps1"; Category = "SYSTEM"; Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/RedLotusHardDiskVolumeConverter.ps1" },
    @{ Name = "Windows Services";       File = "Services.ps1";                  Category = "SYSTEM";    Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Services.ps1" },

    # Bundles
    @{ Name = "All In One Checker";     File = "All-in-one.ps1";                Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/All-in-one.ps1" },
    @{ Name = "Mini SS Check";          File = "miniss.ps1";                    Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/miniss.ps1" },
    @{ Name = "SSToolsHub";             File = "SSToolsHub.ps1";                Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/SSToolsHub.ps1" },
    @{ Name = "Spokwn Tool Collector";  File = "Spokwn-Collect.ps1";            Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Spokwn-Collect.ps1" },
    @{ Name = "Collector (AV Exclusion)"; File = "Collector.ps1";              Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/Collector.ps1" },
    @{ Name = "AnyDesk Installer";      File = "anydesk.ps1";                   Category = "BUNDLES";   Link = "https://raw.githubusercontent.com/Va2lyR/ValyaRssTool/main/tools/anydesk.ps1" }
)

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyarSS Control Center" Height="680" Width="1050"
        WindowStartupLocation="CenterScreen" Background="#090D16"
        ResizeMode="CanMinimize">
    
    <Grid Margin="15">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="310"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar -->
        <Border Grid.Column="0" Background="#111827" CornerRadius="12" Padding="12" Margin="0,0,10,0">
            <DockPanel>
                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,15">
                    <TextBlock Text="ValyarSS" Foreground="#38BDF8" FontSize="26" FontWeight="Bold"/>
                    <TextBlock Text="Advanced SS Forensic Suite" Foreground="#64748B" FontSize="11" Margin="2,0,0,0"/>
                </StackPanel>

                <Border DockPanel.Dock="Bottom" Background="#1E293B" CornerRadius="8" Padding="10" Margin="0,10,0,0">
                    <Grid>
                        <StackPanel>
                            <TextBlock Text="Control Center" Foreground="#94A3B8" FontSize="10"/>
                            <TextBlock Text="Version 3.0" Foreground="#38BDF8" FontSize="13" FontWeight="Bold"/>
                        </StackPanel>
                        <TextBlock Text="ONLINE" Foreground="#10B981" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                </Border>

                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel Name="ToolButtonsStack"/>
                </ScrollViewer>
            </DockPanel>
        </Border>

        <!-- Main Content -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="100"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,0,0,10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Background="#111827" CornerRadius="10" Padding="12" Margin="0,0,5,0">
                    <StackPanel>
                        <TextBlock Text="Panel Status" Foreground="#64748B" FontSize="11" FontWeight="SemiBold"/>
                        <TextBlock Name="TxtStatus" Text="READY" Foreground="#10B981" FontSize="20" FontWeight="Bold" Margin="0,4,0,0"/>
                        <TextBlock Text="Ready for execution" Foreground="#475569" FontSize="10" Margin="0,2,0,0"/>
                    </StackPanel>
                </Border>

                <Border Grid.Column="1" Background="#111827" CornerRadius="10" Padding="12" Margin="5,0,5,0">
                    <StackPanel>
                        <TextBlock Text="Current Task" Foreground="#64748B" FontSize="11" FontWeight="SemiBold"/>
                        <TextBlock Name="TxtCurrentTask" Text="Idle" Foreground="#38BDF8" FontSize="16" FontWeight="Bold" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/>
                        <ProgressBar Name="ProgressBar" Height="4" Margin="0,8,0,0" Foreground="#0EA5E9" Background="#1E293B" BorderThickness="0" Value="0"/>
                    </StackPanel>
                </Border>

                <Border Grid.Column="2" Background="#111827" CornerRadius="10" Padding="12" Margin="5,0,0,0">
                    <StackPanel>
                        <TextBlock Text="Available Tools" Foreground="#64748B" FontSize="11" FontWeight="SemiBold"/>
                        <TextBlock Name="TxtToolCount" Text="0 Registered" Foreground="#F59E0B" FontSize="18" FontWeight="Bold" Margin="0,4,0,0"/>
                        <TextBlock Text="GitHub Sync Enabled" Foreground="#475569" FontSize="10" Margin="0,2,0,0"/>
                    </StackPanel>
                </Border>
            </Grid>

            <Border Grid.Row="1" Background="#050811" CornerRadius="10" Padding="12" BorderBrush="#1E293B" BorderThickness="1">
                <DockPanel>
                    <Grid DockPanel.Dock="Top" Margin="0,0,0,8">
                        <TextBlock Text="Activity Console Output" Foreground="#64748B" FontSize="12" FontWeight="Bold" VerticalAlignment="Center"/>
                        <Button Name="BtnClearConsole" Content="Clear Output" Foreground="#94A3B8" Background="#1E293B" Padding="8,3" BorderThickness="0" CornerRadius="4" HorizontalAlignment="Right" FontSize="10"/>
                    </Grid>
                    
                    <TextBox Name="TxtConsole" Background="Transparent" Foreground="#00FF66" 
                             FontFamily="Consolas" FontSize="12" BorderThickness="0" 
                             IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                             AcceptsReturn="True"/>
                </DockPanel>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

# Read Window
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$txtConsole     = $window.FindName("TxtConsole")
$txtStatus      = $window.FindName("TxtStatus")
$txtCurrentTask = $window.FindName("TxtCurrentTask")
$progressBar    = $window.FindName("ProgressBar")
$btnClear       = $window.FindName("BtnClearConsole")
$toolsStack     = $window.FindName("ToolButtonsStack")
$txtToolCount   = $window.FindName("TxtToolCount")

function Log-Activity {
    param ([string]$message, [string]$type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtConsole.AppendText("[$timestamp] [$type] $message`n")
    $txtConsole.ScrollToEnd()
}

$toolsFolder = Join-Path -Path $PSScriptRoot -ChildPath "tools"
if (-not (Test-Path -Path $toolsFolder)) {
    New-Item -ItemType Directory -Path $toolsFolder | Out-Null
}

$txtToolCount.Text = "$($script:ToolsCatalog.Count) Registered"

# Populate Sidebar
$categories = $script:ToolsCatalog | Select-Object -ExpandProperty Category -Unique

foreach ($cat in $categories) {
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = "— $cat —"
    $header.Foreground = [System.Windows.Media.Brushes]::HexColorConverter().ConvertFromString("#475569")
    $header.FontSize = 10
    $header.FontWeight = [System.Windows.FontWeights]::Bold
    $header.Margin = "5,10,5,5"
    $toolsStack.Children.Add($header) | Out-Null

    $catTools = $script:ToolsCatalog | Where-Object { $_.Category -eq $cat }
    foreach ($tool in $catTools) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "▶  $($tool.Name)"
        $btn.Height = 38
        $btn.Margin = "0,0,0,6"
        $btn.Background = [System.Windows.Media.Brushes]::HexColorConverter().ConvertFromString("#1E293B")
        $btn.Foreground = [System.Windows.Media.Brushes]::HexColorConverter().ConvertFromString("#E2E8F0")
        $btn.BorderThickness = 0
        $btn.Padding = "10,0,0,0"
        $btn.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
        $btn.FontWeight = [System.Windows.FontWeights]::SemiBold
        $btn.Tag = $tool

        $btn.Add_Click({
            $toolInfo = $this.Tag
            Invoke-ToolScript -ToolInfo $toolInfo
        })

        $toolsStack.Children.Add($btn) | Out-Null
    }
}

function Invoke-ToolScript {
    param ($ToolInfo)

    $fileName = $ToolInfo.File
    $toolName = $ToolInfo.Name
    $rawUrl   = $ToolInfo.Link
    $scriptPath = Join-Path -Path $toolsFolder -ChildPath $fileName

    $txtStatus.Text = "BUSY"
    $txtStatus.Foreground = [System.Windows.Media.Brushes]::Orange
    $txtCurrentTask.Text = $toolName
    $progressBar.Value = 25

    if (-not (Test-Path -Path $scriptPath)) {
        Log-Activity "Downloading '$toolName' from GitHub..." "NET"
        try {
            Invoke-RestMethod -Uri $rawUrl -OutFile $scriptPath
            Log-Activity "Successfully downloaded $fileName." "OK"
        }
        catch {
            Log-Activity "Failed to download $fileName : $_" "ERROR"
            $txtStatus.Text = "READY"
            $txtStatus.Foreground = [System.Windows.Media.Brushes]::HexColorConverter().ConvertFromString("#10B981")
            $txtCurrentTask.Text = "Idle"
            $progressBar.Value = 0
            return
        }
    }

    $progressBar.Value = 60
    Log-Activity "Executing: $toolName..." "RUN"

    try {
        $output = & $scriptPath 2>&1
        foreach ($line in $output) {
            Log-Activity "$line" "OUT"
        }
        Log-Activity "Finished executing '$toolName'." "SUCCESS"
    }
    catch {
        Log-Activity "Execution error on $toolName : $_" "EXCEPT"
    }
    finally {
        $txtStatus.Text = "READY"
        $txtStatus.Foreground = [System.Windows.Media.Brushes]::HexColorConverter().ConvertFromString("#10B981")
        $txtCurrentTask.Text = "Idle"
        $progressBar.Value = 100
    }
}

$btnClear.Add_Click({
    $txtConsole.Clear()
    Log-Activity "Console output cleared." "SYS"
})

Log-Activity "ValyarSS Control Center Started." "SYS"
Log-Activity "Loaded $($script:ToolsCatalog.Count) forensic tools dynamically." "SYS"

$window.ShowDialog() | Out-Null
