#requires -Version 5.1
# SSToolsHub - ValyaR Edition
# PowerShell GUI Application
# Author: ValyaR
# Discord: _iaec

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ═══════════════════════════════════════════════════════════════
# SPLASH SCREEN
# ═══════════════════════════════════════════════════════════════
function Show-SplashScreen {
    $splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaR" WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Width="500" Height="300" ResizeMode="NoResize" Topmost="True">
    <Grid>
        <Border CornerRadius="20" Background="#0D0D0D" BorderThickness="2" BorderBrush="#00D4FF">
            <Border.Effect>
                <DropShadowEffect Color="#00D4FF" BlurRadius="30" ShadowDepth="0" Opacity="0.6"/>
            </Border.Effect>
            <Grid>
                <TextBlock Name="SplashText" Text="ValyaR" 
                    FontFamily="Consolas" FontWeight="Bold"
                    Foreground="#00D4FF" HorizontalAlignment="Center" VerticalAlignment="Center"
                    FontSize="1" TextAlignment="Center">
                    <TextBlock.Effect>
                        <DropShadowEffect Color="#00D4FF" BlurRadius="20" ShadowDepth="0" Opacity="0.8"/>
                    </TextBlock.Effect>
                </TextBlock>
                <TextBlock Name="SubText" Text="ScreenShare Tools Hub" 
                    FontFamily="Segoe UI" FontSize="14" Foreground="#888888"
                    HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,40"
                    Opacity="0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($splashXaml))
    $splash = [System.Windows.Markup.XamlReader]::Load($reader)
    $splashText = $splash.FindName("SplashText")
    $subText = $splash.FindName("SubText")

    $splash.Show()

    # Animation: Text grows
    $fontSize = 1
    for ($i = 0; $i -le 60; $i++) {
        $fontSize = [math]::Lerp(1, 72, $i / 60)
        $splashText.FontSize = $fontSize
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
            [System.Windows.Threading.DispatcherPriority]::Background, [action]{}
        )
        Start-Sleep -Milliseconds 16
    }

    # Glow pulse
    for ($i = 0; $i -lt 3; $i++) {
        for ($j = 0; $j -le 20; $j++) {
            $opacity = [math]::Sin($j / 20 * [math]::PI)
            $splashText.Foreground = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.Color]::FromScRgb($opacity, 0, 0.83, 1)
            )
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
                [System.Windows.Threading.DispatcherPriority]::Background, [action]{}
            )
            Start-Sleep -Milliseconds 30
        }
    }

    # Fade in subtitle
    for ($i = 0; $i -le 20; $i++) {
        $subText.Opacity = $i / 20
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
            [System.Windows.Threading.DispatcherPriority]::Background, [action]{}
        )
        Start-Sleep -Milliseconds 30
    }

    Start-Sleep -Milliseconds 800

    # Fade out splash
    for ($i = 20; $i -ge 0; $i--) {
        $splash.Opacity = $i / 20
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke(
            [System.Windows.Threading.DispatcherPriority]::Background, [action]{}
        )
        Start-Sleep -Milliseconds 20
    }

    $splash.Close()
}

# ═══════════════════════════════════════════════════════════════
# MAIN GUI
# ═══════════════════════════════════════════════════════════════

# Data: All tools organized by category
$script:ToolsData = @{
    "Mod Analyzers" = @(
        @{ Name = "TeslaPro // Doomsday Detector"; Desc = "Launches the Doomsday client detection workflow."; Cmd = "powershell -NoProfile -ExecutionPolicy Bypass -Command `"iex (irm 'https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1')`"" },
        @{ Name = "Xkzutos // Mod Analyzer"; Desc = "Analyzes Minecraft mods using metadata, hashes, and known indicators."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1')`"" },
        @{ Name = "TeslaPro // GhostClientFinder"; Desc = "Detects Ghost Client traces and related modifications."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1')`"" },
        @{ Name = "Tonynoh // Meow Mod Analyzer"; Desc = "Analyzes Minecraft mods and searches for suspicious indicators."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')`"" },
        @{ Name = "CheesyDqrkisFucker"; Desc = "Searches for Dqrkis-related traces and suspicious modifications."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')`"" }
    )
    "Network & VPN" = @(
        @{ Name = "TeslaPro // VPN Finder"; Desc = "Searches for active VPN connections and related traces."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"iex (irm 'https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1')`"" },
        @{ Name = "AnyDesk Install Script"; Desc = "Downloads and installs AnyDesk using an automated PowerShell script."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1')`"" }
    )
    "Macro Detectors" = @(
        @{ Name = "Sellgui // Prime Macro Detector"; Desc = "Detects Prime macro traces and suspicious macro-related activity."; Cmd = "powershell -ExecutionPolicy Bypass -NoProfile -Command `"iwr 'https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1' -UseBasicParsing | iex`"" },
        @{ Name = "Nicc // Macro Detector"; Desc = "Searches for macro-related traces and suspicious activity."; Cmd = "powershell -ExecutionPolicy Bypass -Command `"Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1')`"" }
    )
    "System Forensics" = @(
        @{ Name = "Jar Parser"; Desc = "Analyzes .jar files for suspicious classes, strings, content, and possible cheat-related modifications."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1)" },
        @{ Name = "Alt Detector"; Desc = "Searches the system for alternative accounts and related traces."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1)" },
        @{ Name = "Scheduled Tasks"; Desc = "Checks scheduled tasks for suspicious or unusual entries."; Cmd = "powershell -Command `"Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1')`"" },
        @{ Name = "BAM Parser"; Desc = "Parses BAM data to help identify previously executed applications."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1)" },
        @{ Name = "Streams"; Desc = "Searches for NTFS Alternate Data Streams and other hidden data streams."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1)" },
        @{ Name = "Signatures"; Desc = "Checks digital signatures and helps identify unsigned or suspicious files."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1)" },
        @{ Name = "BAM Deleted Keys"; Desc = "Searches BAM data for deleted, missing, or unusual Registry entries."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Florinyoq/Screenshare/refs/heads/main/bam.ps1)" },
        @{ Name = "Hard Disk Converter"; Desc = "Converts hard-disk volume identifiers into readable drive and path information."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusHardDiskVolumeConverter.ps1)" },
        @{ Name = "All In One"; Desc = "Runs multiple screenshare and forensic checks through one PowerShell script."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1)" },
        @{ Name = "Prefetch Integrity"; Desc = "Checks Windows Prefetch files for inconsistencies, modifications, or suspicious characteristics."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1)" },
        @{ Name = "AnyDesk Reset"; Desc = "Resets or restores certain AnyDesk settings and files."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/anydesk.ps1)" },
        @{ Name = "Spokwn BAM"; Desc = "Analyzes BAM data using Spokwn's BAM parser."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1)" },
        @{ Name = "Mini SS"; Desc = "Runs a small and quick screenshare check."; Cmd = "powershell -Command `"Set-ExecutionPolicy Bypass -Scope Process; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/miniss.ps1')`"" },
        @{ Name = "Spokwn Tool Downloader"; Desc = "Downloads multiple Spokwn screenshare tools through one script."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Spokwn-Collect.ps1)" },
        @{ Name = "Services"; Desc = "Checks important Windows services and their current configuration."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1)" },
        @{ Name = "Signed Scheduled Tasks"; Desc = "Checks scheduled tasks and reviews their digital signatures."; Cmd = "powershell -Command `"Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks')`"" },
        @{ Name = "Collector with AV Exclusion"; Desc = "Collects system information and forensic data while attempting to add an antivirus exclusion."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Collector.ps1)" },
        @{ Name = "DoomsDay Finder"; Desc = "Searches for files and indicators associated with the DoomsDay client."; Cmd = "powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1)" }
    )
    "Extra Tools" = @(
        @{ Name = "Process Hacker Info"; Desc = "Gathers detailed process information using native PowerShell."; Cmd = "Get-Process | Select-Object Name, Id, CPU, WorkingSet, Path | Out-GridView" },
        @{ Name = "Startup Programs"; Desc = "Lists all startup programs and their locations."; Cmd = "Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Out-GridView" },
        @{ Name = "Network Connections"; Desc = "Shows active network connections and listening ports."; Cmd = "Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Out-GridView" },
        @{ Name = "Recent Files"; Desc = "Lists recently accessed files from various locations."; Cmd = "Get-ChildItem `$env:APPDATA\Microsoft\Windows\Recent | Select-Object Name, LastWriteTime | Out-GridView" },
        @{ Name = "USB History"; Desc = "Shows USB device connection history from registry."; Cmd = "Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\* | Select-Object FriendlyName, DeviceDesc, Mfg | Out-GridView" },
        @{ Name = "Browser History"; Desc = "Extracts browser history paths for manual review."; Cmd = "`$paths = @(`"`$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History`", `"`$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History`"); `$paths | ForEach-Object { if (Test-Path `$_) { Write-Host `"Found: `$_`" -ForegroundColor Green } else { Write-Host `"Not found: `$_`" -ForegroundColor Red } }; pause" }
    )
}

# Flatten for search
$script:AllTools = @()
foreach ($cat in $script:ToolsData.Keys) {
    foreach ($tool in $script:ToolsData[$cat]) {
        $toolObj = $tool.Clone()
        $toolObj["Category"] = $cat
        $script:AllTools += $toolObj
    }
}

# Main Window XAML
$mainXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaR // SSToolsHub" Height="750" Width="1200"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        Background="#0A0A0F" MinWidth="900" MinHeight="600">
    <Window.Resources>
        <!-- Colors -->
        <SolidColorBrush x:Key="PrimaryColor" Color="#00D4FF"/>
        <SolidColorBrush x:Key="SecondaryColor" Color="#FF006E"/>
        <SolidColorBrush x:Key="AccentColor" Color="#8338EC"/>
        <SolidColorBrush x:Key="BgDark" Color="#0A0A0F"/>
        <SolidColorBrush x:Key="BgCard" Color="#12121A"/>
        <SolidColorBrush x:Key="BgCardHover" Color="#1A1A2E"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#888888"/>
        <SolidColorBrush x:Key="BorderColor" Color="#1E1E2E"/>

        <!-- Sidebar Button Style -->
        <Style x:Key="SidebarBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#888888"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1A1A2E"/>
                    <Setter Property="Foreground" Value="#00D4FF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Active Sidebar Button -->
        <Style x:Key="SidebarBtnActive" TargetType="Button" BasedOn="{StaticResource SidebarBtn}">
            <Setter Property="Background" Value="#00D4FF"/>
            <Setter Property="Foreground" Value="#0A0A0F"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <!-- Tool Card Style -->
        <Style x:Key="ToolCard" TargetType="Border">
            <Setter Property="Background" Value="#12121A"/>
            <Setter Property="BorderBrush" Value="#1E1E2E"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1A1A2E"/>
                    <Setter Property="BorderBrush" Value="#00D4FF"/>
                    <Setter Property="Effect">
                        <Setter.Value>
                            <DropShadowEffect Color="#00D4FF" BlurRadius="15" ShadowDepth="0" Opacity="0.3"/>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Run Button -->
        <Style x:Key="RunBtn" TargetType="Button">
            <Setter Property="Background" Value="#00D4FF"/>
            <Setter Property="Foreground" Value="#0A0A0F"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#33DDFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Copy Button -->
        <Style x:Key="CopyBtn" TargetType="Button">
            <Setter Property="Background" Value="#1E1E2E"/>
            <Setter Property="Foreground" Value="#888888"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2E2E3E"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#2A2A3E"/>
                    <Setter Property="Foreground" Value="#00D4FF"/>
                    <Setter Property="BorderBrush" Value="#00D4FF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Search Box -->
        <Style x:Key="SearchBox" TargetType="TextBox">
            <Setter Property="Background" Value="#12121A"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#1E1E2E"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="15,12"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="CaretBrush" Value="#00D4FF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ScrollViewer Style -->
        <Style x:Key="CustomScroll" TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <ScrollContentPresenter />
                            <ScrollBar x:Name="PART_VerticalScrollBar" 
                                Width="6" Margin="0,4,4,4"
                                Background="Transparent"
                                Foreground="#00D4FF"
                                Opacity="0.6"
                                HorizontalAlignment="Right"
                                VerticalAlignment="Stretch"
                                Value="{TemplateBinding VerticalOffset}"
                                Maximum="{TemplateBinding ScrollableHeight}"
                                ViewportSize="{TemplateBinding ViewportHeight}"
                                Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="260"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar -->
        <Border Grid.Column="0" Background="#0D0D15" BorderBrush="#1E1E2E" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Logo -->
                <Border Grid.Row="0" Padding="20,25">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="ValyaR" FontFamily="Consolas" FontSize="24" FontWeight="Bold" Foreground="#00D4FF">
                            <TextBlock.Effect>
                                <DropShadowEffect Color="#00D4FF" BlurRadius="15" ShadowDepth="0" Opacity="0.5"/>
                            </TextBlock.Effect>
                        </TextBlock>
                        <TextBlock Text=" //" FontFamily="Consolas" FontSize="24" FontWeight="Bold" Foreground="#FF006E" Margin="4,0,0,0"/>
                    </StackPanel>
                </Border>

                <!-- Version -->
                <TextBlock Grid.Row="1" Text="SSToolsHub v2.0" FontSize="11" Foreground="#444444" 
                           Margin="20,0,0,15" FontFamily="Consolas"/>

                <!-- Navigation -->
                <StackPanel Grid.Row="2" Margin="10,0">
                    <Button Name="BtnOverview" Style="{StaticResource SidebarBtnActive}" Content="📊  Overview" Margin="0,4"/>
                    <Button Name="BtnTools" Style="{StaticResource SidebarBtn}" Content="🛠️  ValyaR Cmd" Margin="0,4"/>
                    <Button Name="BtnExtra" Style="{StaticResource SidebarBtn}" Content="⚡  Extra Tools" Margin="0,4"/>
                    <Button Name="BtnAbout" Style="{StaticResource SidebarBtn}" Content="ℹ️  About" Margin="0,4"/>
                </StackPanel>

                <!-- Footer -->
                <Border Grid.Row="3" Padding="20" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Made by ValyaR" FontSize="11" Foreground="#444444" FontFamily="Consolas"/>
                        <TextBlock Text="Discord: _iaec" FontSize="10" Foreground="#333333" FontFamily="Consolas" Margin="0,2,0,0"/>
                    </StackPanel>
                </Border>
            </Grid>
        </Border>

        <!-- Main Content -->
        <Grid Grid.Column="1" Name="MainContent">
            <!-- OVERVIEW PAGE -->
            <Grid Name="PageOverview" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Header -->
                <Border Grid.Row="0" Padding="30,25" Background="#0D0D15">
                    <StackPanel>
                        <TextBlock Text="Welcome to ValyaR SSToolsHub" FontSize="28" FontWeight="Bold" Foreground="#FFFFFF">
                            <TextBlock.Effect>
                                <DropShadowEffect Color="#00D4FF" BlurRadius="10" ShadowDepth="0" Opacity="0.2"/>
                            </TextBlock.Effect>
                        </TextBlock>
                        <TextBlock Text="Advanced ScreenShare &amp; Forensic Tools Collection" FontSize="14" Foreground="#888888" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>

                <!-- Content -->
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Style="{StaticResource CustomScroll}">
                    <StackPanel Margin="30,20">
                        <!-- Stats Cards -->
                        <UniformGrid Columns="3" Margin="0,0,0,25">
                            <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="20">
                                <StackPanel>
                                    <TextBlock Text="🛠️" FontSize="28" Margin="0,0,0,10"/>
                                    <TextBlock Name="StatTools" Text="31" FontSize="32" FontWeight="Bold" Foreground="#00D4FF"/>
                                    <TextBlock Text="Total Tools" FontSize="12" Foreground="#888888" Margin="0,4,0,0"/>
                                </StackPanel>
                            </Border>
                            <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="20">
                                <StackPanel>
                                    <TextBlock Text="📂" FontSize="28" Margin="0,0,0,10"/>
                                    <TextBlock Name="StatCats" Text="5" FontSize="32" FontWeight="Bold" Foreground="#FF006E"/>
                                    <TextBlock Text="Categories" FontSize="12" Foreground="#888888" Margin="0,4,0,0"/>
                                </StackPanel>
                            </Border>
                            <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="20">
                                <StackPanel>
                                    <TextBlock Text="⚡" FontSize="28" Margin="0,0,0,10"/>
                                    <TextBlock Text="v2.0" FontSize="32" FontWeight="Bold" Foreground="#8338EC"/>
                                    <TextBlock Text="Version" FontSize="12" Foreground="#888888" Margin="0,4,0,0"/>
                                </StackPanel>
                            </Border>
                        </UniformGrid>

                        <!-- Info Section -->
                        <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="25" Margin="0,0,0,20">
                            <StackPanel>
                                <TextBlock Text="About This Tool" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,15"/>
                                <TextBlock Text="ValyaR SSToolsHub is a comprehensive collection of ScreenShare and forensic analysis tools designed for Minecraft server administrators and security professionals. All tools are sourced from trusted developers in the community." 
                                    FontSize="13" Foreground="#AAAAAA" TextWrapping="Wrap" LineHeight="22"/>
                                <TextBlock Text="Features:" FontSize="14" FontWeight="Bold" Foreground="#00D4FF" Margin="0,15,0,8"/>
                                <TextBlock Text="• One-click execution of forensic scripts&#x0a;• Organized by category for easy navigation&#x0a;• Built-in search functionality&#x0a;• Copy commands to clipboard&#x0a;• Modern dark-themed UI with animations" 
                                    FontSize="13" Foreground="#888888" TextWrapping="Wrap" LineHeight="22"/>
                            </StackPanel>
                        </Border>

                        <!-- Discord Card -->
                        <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="25" Margin="0,0,0,20">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0">
                                    <TextBlock Text="💬 Developer Discord" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,8"/>
                                    <TextBlock Text="Join the community for support, updates, and new tool releases." 
                                        FontSize="13" Foreground="#888888" TextWrapping="Wrap"/>
                                    <TextBlock Text="Discord: _iaec" FontSize="14" FontWeight="Bold" Foreground="#00D4FF" Margin="0,10,0,0" FontFamily="Consolas"/>
                                    <TextBlock Text="Dev: ValyaR" FontSize="12" Foreground="#666666" Margin="0,4,0,0" FontFamily="Consolas"/>
                                </StackPanel>
                                <Border Grid.Column="1" Width="60" Height="60" CornerRadius="30" Background="#5865F2" 
                                        VerticalAlignment="Center" HorizontalAlignment="Center">
                                    <TextBlock Text="🎮" FontSize="28" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </Grid>
                        </Border>

                        <!-- Categories Preview -->
                        <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="25">
                            <StackPanel>
                                <TextBlock Text="Available Categories" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,15"/>
                                <WrapPanel>
                                    <Border Background="#1A1A2E" BorderBrush="#00D4FF" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="4">
                                        <TextBlock Text="🔍 Mod Analyzers" Foreground="#00D4FF" FontSize="12" FontWeight="SemiBold"/>
                                    </Border>
                                    <Border Background="#1A1A2E" BorderBrush="#FF006E" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="4">
                                        <TextBlock Text="🌐 Network &amp; VPN" Foreground="#FF006E" FontSize="12" FontWeight="SemiBold"/>
                                    </Border>
                                    <Border Background="#1A1A2E" BorderBrush="#8338EC" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="4">
                                        <TextBlock Text="🖱️ Macro Detectors" Foreground="#8338EC" FontSize="12" FontWeight="SemiBold"/>
                                    </Border>
                                    <Border Background="#1A1A2E" BorderBrush="#FB5607" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="4">
                                        <TextBlock Text="🔬 System Forensics" Foreground="#FB5607" FontSize="12" FontWeight="SemiBold"/>
                                    </Border>
                                    <Border Background="#1A1A2E" BorderBrush="#38B000" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="4">
                                        <TextBlock Text="⚡ Extra Tools" Foreground="#38B000" FontSize="12" FontWeight="SemiBold"/>
                                    </Border>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- TOOLS PAGE -->
            <Grid Name="PageTools" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Header -->
                <Border Grid.Row="0" Padding="30,25" Background="#0D0D15">
                    <StackPanel>
                        <TextBlock Text="ValyaR Cmd" FontSize="28" FontWeight="Bold" Foreground="#FFFFFF">
                            <TextBlock.Effect>
                                <DropShadowEffect Color="#00D4FF" BlurRadius="10" ShadowDepth="0" Opacity="0.2"/>
                            </TextBlock.Effect>
                        </TextBlock>
                        <TextBlock Text="Execute forensic &amp; screenshare tools with one click" FontSize="14" Foreground="#888888" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>

                <!-- Search Bar -->
                <Border Grid.Row="1" Padding="30,15" Background="#0D0D15">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox Name="SearchBox" Style="{StaticResource SearchBox}" 
                                 Text="Search tools..." Foreground="#555555" Grid.Column="0"/>
                        <Button Name="BtnClearSearch" Content="✕" Grid.Column="1" Margin="10,0,0,0"
                                Style="{StaticResource CopyBtn}" Visibility="Collapsed"/>
                    </Grid>
                </Border>

                <!-- Tools Content -->
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Style="{StaticResource CustomScroll}">
                    <StackPanel Name="ToolsContainer" Margin="20,10">
                        <!-- Categories will be populated here -->
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- EXTRA TOOLS PAGE -->
            <Grid Name="PageExtra" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Padding="30,25" Background="#0D0D15">
                    <StackPanel>
                        <TextBlock Text="Extra Tools" FontSize="28" FontWeight="Bold" Foreground="#FFFFFF">
                            <TextBlock.Effect>
                                <DropShadowEffect Color="#38B000" BlurRadius="10" ShadowDepth="0" Opacity="0.2"/>
                            </TextBlock.Effect>
                        </TextBlock>
                        <TextBlock Text="Additional native PowerShell forensic utilities" FontSize="14" Foreground="#888888" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>

                <Border Grid.Row="1" Padding="30,15" Background="#0D0D15">
                    <TextBox Name="SearchBoxExtra" Style="{StaticResource SearchBox}" 
                             Text="Search extra tools..." Foreground="#555555"/>
                </Border>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" Style="{StaticResource CustomScroll}">
                    <StackPanel Name="ExtraContainer" Margin="20,10">
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- ABOUT PAGE -->
            <Grid Name="PageAbout" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Padding="30,25" Background="#0D0D15">
                    <StackPanel>
                        <TextBlock Text="About" FontSize="28" FontWeight="Bold" Foreground="#FFFFFF"/>
                        <TextBlock Text="Information about the tool and credits" FontSize="14" Foreground="#888888" Margin="0,8,0,0"/>
                    </StackPanel>
                </Border>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Style="{StaticResource CustomScroll}">
                    <StackPanel Margin="30,20">
                        <Border Background="#12121A" BorderBrush="#1E1E2E" BorderThickness="1" CornerRadius="12" Padding="30" Margin="0,0,0,20">
                            <StackPanel>
                                <TextBlock Text="ValyaR // SSToolsHub" FontSize="24" FontWeight="Bold" Foreground="#00D4FF" FontFamily="Consolas"/>
                                <TextBlock Text="Version 2.0 | PowerShell GUI Application" FontSize="12" Foreground="#666666" Margin="0,5,0,20" FontFamily="Consolas"/>

                                <TextBlock Text="A modern, dark-themed GUI wrapper for ScreenShare and forensic analysis tools. This application provides easy one-click access to a curated collection of PowerShell scripts used by Minecraft server administrators and security professionals." 
                                    FontSize="13" Foreground="#AAAAAA" TextWrapping="Wrap" LineHeight="22" Margin="0,0,0,20"/>

                                <TextBlock Text="Developer" FontSize="16" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,10"/>
                                <TextBlock Text="ValyaR" FontSize="14" Foreground="#00D4FF" FontWeight="SemiBold"/>
                                <TextBlock Text="Discord: _iaec" FontSize="13" Foreground="#888888" Margin="0,2,0,15"/>

                                <TextBlock Text="Credits" FontSize="16" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,10"/>
                                <TextBlock Text="• TeslaPro - Doomsday Detector, GhostClientFinder, VPN Finder&#x0a;• Xkzutos - Mod Analyzer&#x0a;• Tonynoh - Meow Mod Analyzer&#x0a;• Cheesecatlol - DqrkisFucker&#x0a;• Sellgui - Prime Macro Detector&#x0a;• Nicc - Macro Detector&#x0a;• NoDiff-del - JAR Parser&#x0a;• Enr1c0o - Alt Detector, All-in-One&#x0a;• Nolww - SuspiciousScheduler&#x0a;• PureIntent - RedLotus BAM&#x0a;• Spokwn - Streams, Signatures, AnyDesk, BAM Parser&#x0a;• Florinyoq - BAM Deleted Keys&#x0a;• Bacanoicua - Hard Disk Converter, Prefetch Integrity&#x0a;• L4rpsucks - Mini SS&#x0a;• Praiselily - Spokwn-Collect, Services, Signed Tasks, Collector&#x0a;• Zedoonvm1 - DoomsDay Detector&#x0a;• And all other contributors in the SS community" 
                                    FontSize="12" Foreground="#888888" TextWrapping="Wrap" LineHeight="20"/>

                                <TextBlock Text="Disclaimer" FontSize="16" FontWeight="Bold" Foreground="#FF006E" Margin="0,20,0,10"/>
                                <TextBlock Text="This tool is intended for legitimate security analysis and screenshare purposes only. The developer is not responsible for misuse of any scripts or tools accessed through this application. Use at your own risk." 
                                    FontSize="12" Foreground="#888888" TextWrapping="Wrap" LineHeight="20"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# ═══════════════════════════════════════════════════════════════
# BUILD & SHOW
# ═══════════════════════════════════════════════════════════════

# Show splash
Show-SplashScreen

# Load main window
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($mainXaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Get elements
$btnOverview = $window.FindName("BtnOverview")
$btnTools = $window.FindName("BtnTools")
$btnExtra = $window.FindName("BtnExtra")
$btnAbout = $window.FindName("BtnAbout")
$pageOverview = $window.FindName("PageOverview")
$pageTools = $window.FindName("PageTools")
$pageExtra = $window.FindName("PageExtra")
$pageAbout = $window.FindName("PageAbout")
$toolsContainer = $window.FindName("ToolsContainer")
$extraContainer = $window.FindName("ExtraContainer")
$searchBox = $window.FindName("SearchBox")
$searchBoxExtra = $window.FindName("SearchBoxExtra")
$btnClearSearch = $window.FindName("BtnClearSearch")
$statTools = $window.FindName("StatTools")

# Update stats
$statTools.Text = $script:AllTools.Count.ToString()

# Navigation function
function Switch-Page($pageName) {
    $pageOverview.Visibility = "Collapsed"
    $pageTools.Visibility = "Collapsed"
    $pageExtra.Visibility = "Collapsed"
    $pageAbout.Visibility = "Collapsed"

    $btnOverview.Style = $window.FindResource("SidebarBtn")
    $btnTools.Style = $window.FindResource("SidebarBtn")
    $btnExtra.Style = $window.FindResource("SidebarBtn")
    $btnAbout.Style = $window.FindResource("SidebarBtn")

    switch ($pageName) {
        "Overview" { 
            $pageOverview.Visibility = "Visible"
            $btnOverview.Style = $window.FindResource("SidebarBtnActive")
        }
        "Tools" { 
            $pageTools.Visibility = "Visible"
            $btnTools.Style = $window.FindResource("SidebarBtnActive")
        }
        "Extra" { 
            $pageExtra.Visibility = "Visible"
            $btnExtra.Style = $window.FindResource("SidebarBtnActive")
        }
        "About" { 
            $pageAbout.Visibility = "Visible"
            $btnAbout.Style = $window.FindResource("SidebarBtnActive")
        }
    }
}

# Build tool cards
function Build-ToolCards($container, $tools, $isExtra = $false) {
    $container.Children.Clear()

    # Group by category
    $grouped = $tools | Group-Object -Property Category

    foreach ($group in $grouped) {
        # Category header
        $catBorder = New-Object System.Windows.Controls.Border
        $catBorder.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(18, 18, 26))
        $catBorder.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(30, 30, 46))
        $catBorder.BorderThickness = [System.Windows.Thickness]::new(1)
        $catBorder.CornerRadius = [System.Windows.CornerRadius]::new(12)
        $catBorder.Padding = [System.Windows.Thickness]::new(20)
        $catBorder.Margin = [System.Windows.Thickness]::new(0, 0, 0, 15)

        $catStack = New-Object System.Windows.Controls.StackPanel

        $catHeader = New-Object System.Windows.Controls.TextBlock
        $catHeader.Text = $group.Name
        $catHeader.FontSize = 18
        $catHeader.FontWeight = [System.Windows.FontWeights]::Bold
        $catHeader.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0, 212, 255))
        $catHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 15)
        $catStack.Children.Add($catHeader)

        # Tools in this category
        $wrapPanel = New-Object System.Windows.Controls.WrapPanel

        foreach ($tool in $group.Group) {
            $card = New-Object System.Windows.Controls.Border
            $card.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(18, 18, 26))
            $card.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(30, 30, 46))
            $card.BorderThickness = [System.Windows.Thickness]::new(1)
            $card.CornerRadius = [System.Windows.CornerRadius]::new(12)
            $card.Padding = [System.Windows.Thickness]::new(20)
            $card.Margin = [System.Windows.Thickness]::new(0, 0, 10, 10)
            $card.MinWidth = 380
            $card.MaxWidth = 420

            # Hover effects via events
            $card.Add_MouseEnter({
                $this.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(26, 26, 46))
                $this.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0, 212, 255))
            })
            $card.Add_MouseLeave({
                $this.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(18, 18, 26))
                $this.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(30, 30, 46))
            })

            $cardStack = New-Object System.Windows.Controls.StackPanel

            $nameBlock = New-Object System.Windows.Controls.TextBlock
            $nameBlock.Text = $tool.Name
            $nameBlock.FontSize = 14
            $nameBlock.FontWeight = [System.Windows.FontWeights]::Bold
            $nameBlock.Foreground = [System.Windows.Media.Brushes]::White
            $nameBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $nameBlock.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
            $cardStack.Children.Add($nameBlock)

            $descBlock = New-Object System.Windows.Controls.TextBlock
            $descBlock.Text = $tool.Desc
            $descBlock.FontSize = 11
            $descBlock.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(136, 136, 136))
            $descBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $descBlock.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
            $descBlock.MaxHeight = 50
            $cardStack.Children.Add($descBlock)

            $btnPanel = New-Object System.Windows.Controls.StackPanel
            $btnPanel.Orientation = "Horizontal"

            $runBtn = New-Object System.Windows.Controls.Button
            $runBtn.Content = "▶ RUN"
            $runBtn.Style = $window.FindResource("RunBtn")
            $runBtn.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
            $cmd = $tool.Cmd
            $runBtn.Add_Click({
                try {
                    Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
                } catch {
                    [System.Windows.MessageBox]::Show("Failed to run: $_", "Error", "OK", "Error")
                }
            }.GetNewClosure())
            $btnPanel.Children.Add($runBtn)

            $copyBtn = New-Object System.Windows.Controls.Button
            $copyBtn.Content = "📋 COPY CMD"
            $copyBtn.Style = $window.FindResource("CopyBtn")
            $cmdCopy = $tool.Cmd
            $copyBtn.Add_Click({
                [System.Windows.Forms.Clipboard]::SetText($cmdCopy)
                $this.Content = "✅ COPIED!"
                Start-Job -ScriptBlock {
                    Start-Sleep -Seconds 2
                } | Wait-Job
                $this.Content = "📋 COPY CMD"
            }.GetNewClosure())
            $btnPanel.Children.Add($copyBtn)

            $cardStack.Children.Add($btnPanel)
            $card.Child = $cardStack
            $wrapPanel.Children.Add($card)
        }

        $catStack.Children.Add($wrapPanel)
        $catBorder.Child = $catStack
        $container.Children.Add($catBorder)
    }
}

# Populate tools
Build-ToolCards $toolsContainer $script:AllTools

# Populate extra tools
$extraTools = $script:ToolsData["Extra Tools"] | ForEach-Object { 
    $t = $_.Clone(); $t["Category"] = "Extra Tools"; $t 
}
Build-ToolCards $extraContainer $extraTools

# Search functionality
$searchBox.Add_GotFocus({
    if ($this.Text -eq "Search tools...") {
        $this.Text = ""
        $this.Foreground = [System.Windows.Media.Brushes]::White
    }
})

$searchBox.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($this.Text)) {
        $this.Text = "Search tools..."
        $this.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(85, 85, 85))
        Build-ToolCards $toolsContainer $script:AllTools
        $btnClearSearch.Visibility = "Collapsed"
    }
})

$searchBox.Add_TextChanged({
    $query = $this.Text.ToLower()
    if ($query -eq "search tools..." -or [string]::IsNullOrWhiteSpace($query)) {
        Build-ToolCards $toolsContainer $script:AllTools
        $btnClearSearch.Visibility = "Collapsed"
        return
    }
    $btnClearSearch.Visibility = "Visible"
    $filtered = $script:AllTools | Where-Object { 
        $_.Name.ToLower().Contains($query) -or 
        $_.Desc.ToLower().Contains($query) -or
        $_.Category.ToLower().Contains($query)
    }
    Build-ToolCards $toolsContainer $filtered
})

$btnClearSearch.Add_Click({
    $searchBox.Text = "Search tools..."
    $searchBox.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(85, 85, 85))
    Build-ToolCards $toolsContainer $script:AllTools
    $btnClearSearch.Visibility = "Collapsed"
})

# Extra search
$searchBoxExtra.Add_GotFocus({
    if ($this.Text -eq "Search extra tools...") {
        $this.Text = ""
        $this.Foreground = [System.Windows.Media.Brushes]::White
    }
})

$searchBoxExtra.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($this.Text)) {
        $this.Text = "Search extra tools..."
        $this.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(85, 85, 85))
        Build-ToolCards $extraContainer $extraTools
    }
})

$searchBoxExtra.Add_TextChanged({
    $query = $this.Text.ToLower()
    if ($query -eq "search extra tools..." -or [string]::IsNullOrWhiteSpace($query)) {
        Build-ToolCards $extraContainer $extraTools
        return
    }
    $filtered = $extraTools | Where-Object { 
        $_.Name.ToLower().Contains($query) -or $_.Desc.ToLower().Contains($query)
    }
    Build-ToolCards $extraContainer $filtered
})

# Navigation events
$btnOverview.Add_Click({ Switch-Page "Overview" })
$btnTools.Add_Click({ Switch-Page "Tools" })
$btnExtra.Add_Click({ Switch-Page "Extra" })
$btnAbout.Add_Click({ Switch-Page "About" })

# Show window
$window.ShowDialog() | Out-Null
