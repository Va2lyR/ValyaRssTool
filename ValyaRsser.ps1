Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ---------------------------------------------------------
# 1. مقدمة وأنيميشن ترحيبي في CMD
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
    Start-Sleep -Milliseconds 30
}

Write-Host "`n[+] INITIALIZING VALYAR COMMAND SUITE..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 200
Write-Host "[+] LAUNCHING MODERN GUI INTERFACE..." -ForegroundColor Green
Start-Sleep -Milliseconds 300

# ---------------------------------------------------------
# 2. البيانات والأدوات
# ---------------------------------------------------------
$global:ToolsList = @(
    # Category: Mod Analyzers
    @{ Name = "TeslaPro // Doomsday Detector"; Category = "Mod Analyzers"; Desc = "Launches Doomsday client detection workflow."; Script = "iex (irm 'https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1')" },
    @{ Name = "Xkzutos // Mod Analyzer"; Category = "Mod Analyzers"; Desc = "Analyzes Minecraft mods using metadata and hashes."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/xkzuto96/xkzutos-mod-analyzer/main/XkzutosModAnalyzer.ps1')" },
    @{ Name = "TeslaPro // GhostClientFinder"; Category = "Mod Analyzers"; Desc = "Detects Ghost Client traces and modifications."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/TeslaPros/GhostClientFucker/refs/heads/main/GhostClientFucker.ps1')" },
    @{ Name = "Tonynoh // Meow Mod Analyzer"; Category = "Mod Analyzers"; Desc = "Analyzes Minecraft mods for suspicious indicators."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')" },
    @{ Name = "CheesyDqrkisFucker"; Category = "Mod Analyzers"; Desc = "Searches for Dqrkis-related traces."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')" },
    
    # Category: Macro Detectors
    @{ Name = "Sellgui // Prime Macro Detector"; Category = "Macro Detectors"; Desc = "Detects Prime macro traces and activity."; Script = "iwr 'https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1' -UseBasicParsing | iex" },
    @{ Name = "Nicc // Macro Detector"; Category = "Macro Detectors"; Desc = "Searches for macro-related traces."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1')" },

    # Category: Forensics
    @{ Name = "Jar Parser"; Category = "Forensics"; Desc = "Analyzes .jar files for suspicious classes."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NoDiff-del/JARParser/refs/heads/main/JARParser.ps1')" },
    @{ Name = "Alt Detector"; Category = "Forensics"; Desc = "Searches for alternative accounts on system."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/Alt-Detector.ps1')" },
    @{ Name = "Scheduled Tasks"; Category = "Forensics"; Desc = "Checks scheduled tasks for suspicious entries."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/nolww/project-mohr/refs/heads/main/SuspiciousScheduler.ps1')" },
    @{ Name = "BAM Parser"; Category = "Forensics"; Desc = "Parses BAM data for executed applications."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1')" },
    @{ Name = "Streams Finder"; Category = "Forensics"; Desc = "Searches for NTFS Alternate Data Streams."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/Streams.ps1')" },
    @{ Name = "Signatures Checker"; Category = "Forensics"; Desc = "Checks digital signatures of system files."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/signatures.ps1')" },
    @{ Name = "Prefetch Integrity"; Category = "Forensics"; Desc = "Analyzes Windows Prefetch files for anomalies."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1')" },
    
    # Category: Utilities
    @{ Name = "TeslaPro // VPN Finder"; Category = "Utilities"; Desc = "Searches for active VPN connections."; Script = "iex (irm 'https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1')" },
    @{ Name = "AnyDesk Installer"; Category = "Utilities"; Desc = "Downloads and installs AnyDesk automatically."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1')" },
    @{ Name = "All In One Checker"; Category = "Utilities"; Desc = "Runs comprehensive screenshare checks."; Script = "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1')" }
)

# ---------------------------------------------------------
# 3. تصميم واجهة WPF عصرية ونقية (Ultra-Modern Dark UI)
# ---------------------------------------------------------
$xamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaR Command Suite" Height="680" Width="1040"
        WindowStartupLocation="CenterScreen" Background="#0B0C10"
        Foreground="#FFFFFF" FontFamily="Segoe UI">
    
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="230"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar Panel -->
        <Border Grid.Column="0" Background="#12141D" BorderBrush="#1F2330" BorderThickness="0,0,1,0">
            <Grid Margin="15,20">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Header -->
                <StackPanel Grid.Row="0">
                    <TextBlock Text="ValyaR" FontSize="28" FontWeight="Bold" Foreground="#9D4EDD" HorizontalAlignment="Center"/>
                    <TextBlock Text="COMMAND SUITE" FontSize="11" Foreground="#5A6075" HorizontalAlignment="Center" Margin="0,3,0,30"/>
                    
                    <Button Name="BtnCmdSuite" Content="ValyaR Cmd" Height="42" Background="#9D4EDD" Foreground="#FFFFFF" BorderThickness="0" Margin="0,0,0,10" FontSize="14" FontWeight="SemiBold" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="8"/>
                            </Style>
                        </Button.Resources>
                    </Button>

                    <Button Name="BtnOverview" Content="Overview" Height="42" Background="#1A1D28" Foreground="#A0A5B5" BorderThickness="0" Margin="0,0,0,10" FontSize="14" FontWeight="SemiBold" Cursor="Hand">
                        <Button.Resources>
                            <Style TargetType="Border">
                                <Setter Property="CornerRadius" Value="8"/>
                            </Style>
                        </Button.Resources>
                    </Button>
                </StackPanel>

                <!-- Footer Info -->
                <Border Grid.Row="2" Background="#1A1D28" CornerRadius="8" Padding="12" Margin="0,10,0,0">
                    <StackPanel>
                        <TextBlock Text="Status: Online" Foreground="#00F5D4" FontSize="11" FontWeight="Bold"/>
                        <TextBlock Text="Dev: Valyar" Foreground="#5A6075" FontSize="11" Margin="0,2,0,0"/>
                    </StackPanel>
                </Border>
            </Grid>
        </Border>

        <!-- Content Area -->
        <Grid Grid.Column="1" Margin="25">
            
            <!-- OVERVIEW SECTION -->
            <Grid Name="ViewOverview" Visibility="Collapsed">
                <Border Background="#12141D" CornerRadius="12" Padding="35" BorderBrush="#1F2330" BorderThickness="1" VerticalAlignment="Center" HorizontalAlignment="Center" Width="550">
                    <StackPanel>
                        <TextBlock Text="ValyaR Control Suite" FontSize="24" FontWeight="Bold" Foreground="#9D4EDD" Margin="0,0,0,10"/>
                        <TextBlock Text="Advanced security diagnostic and forensic execution center designed for quick and seamless tool dispatching." TextWrapping="Wrap" Foreground="#8E95A5" FontSize="14" Margin="0,0,0,25"/>
                        
                        <Separator Background="#1F2330" Margin="0,0,0,20"/>

                        <Grid Margin="0,8">
                            <TextBlock Text="Developer" Foreground="#5A6075" FontSize="14"/>
                            <TextBlock Text="Valyar" Foreground="#FFFFFF" FontWeight="Bold" HorizontalAlignment="Right" FontSize="14"/>
                        </Grid>
                        <Grid Margin="0,8">
                            <TextBlock Text="Discord Contact" Foreground="#5A6075" FontSize="14"/>
                            <TextBlock Text="_iaec" Foreground="#00F5D4" FontWeight="Bold" HorizontalAlignment="Right" FontSize="14"/>
                        </Grid>
                        <Grid Margin="0,8">
                            <TextBlock Text="System Framework" Foreground="#5A6075" FontSize="14"/>
                            <TextBlock Text="WPF Core V2.5" Foreground="#FFFFFF" HorizontalAlignment="Right" FontSize="14"/>
                        </Grid>
                    </StackPanel>
                </Border>
            </Grid>

            <!-- VALYAR CMD SECTION -->
            <Grid Name="ViewCmdSuite" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Search Bar -->
                <Grid Grid.Row="0" Margin="0,0,0,20">
                    <Border Background="#12141D" BorderBrush="#1F2330" BorderThickness="1" CornerRadius="8" Padding="5">
                        <TextBox Name="TxtSearch" Height="32" Background="Transparent" Foreground="#FFFFFF" BorderThickness="0" Padding="10,5" FontSize="14" VerticalContentAlignment="Center" Text="Search tools or categories..."/>
                    </Border>
                </Grid>

                <!-- Scrollable Cards -->
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <ItemsControl Name="ToolsContainer">
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Background="#12141D" BorderBrush="#1F2330" BorderThickness="1" CornerRadius="10" Margin="0,0,0,12" Padding="16">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        
                                        <StackPanel Grid.Column="0">
                                            <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                                <TextBlock Text="{Binding Name}" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"/>
                                                <Border Background="#1A1D28" CornerRadius="4" Margin="10,0,0,0" Padding="8,2">
                                                    <TextBlock Text="{Binding Category}" FontSize="11" Foreground="#9D4EDD" FontWeight="Bold"/>
                                                </Border>
                                            </StackPanel>
                                            <TextBlock Text="{Binding Desc}" Foreground="#727A8C" FontSize="13" TextWrapping="Wrap"/>
                                        </StackPanel>

                                        <Button Grid.Column="1" Content="Run Tool" Tag="{Binding Script}" Height="36" Width="95" Background="#9D4EDD" Foreground="#FFFFFF" BorderThickness="0" FontWeight="Bold" Cursor="Hand" Click="RunTool_Click">
                                            <Button.Resources>
                                                <Style TargetType="Border">
                                                    <Setter Property="CornerRadius" Value="6"/>
                                                </Style>
                                            </Button.Resources>
                                        </Button>
                                    </Grid>
                                </Border>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                    </ItemsControl>
                </ScrollViewer>
            </Grid>

        </Grid>
    </Grid>
</Window>
"@

# ---------------------------------------------------------
# 4. المعالجة البرمجية وحل مشكلة تشغيل الأوامر
# ---------------------------------------------------------
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlString))
$Window = [Windows.Markup.XamlReader]::Load($reader)

$BtnOverview  = $Window.FindName("BtnOverview")
$BtnCmdSuite  = $Window.FindName("BtnCmdSuite")
$ViewOverview = $Window.FindName("ViewOverview")
$ViewCmdSuite = $Window.FindName("ViewCmdSuite")
$TxtSearch    = $Window.FindName("TxtSearch")
$Container    = $Window.FindName("ToolsContainer")

$Container.ItemsSource = $global:ToolsList

# Navigation Handlers
$BtnOverview.Add_Click({
    $ViewOverview.Visibility = "Visible"
    $ViewCmdSuite.Visibility = "Collapsed"
    $BtnOverview.Background  = "#9D4EDD"
    $BtnOverview.Foreground  = "#FFFFFF"
    $BtnCmdSuite.Background  = "#1A1D28"
    $BtnCmdSuite.Foreground  = "#A0A5B5"
})

$BtnCmdSuite.Add_Click({
    $ViewOverview.Visibility = "Collapsed"
    $ViewCmdSuite.Visibility = "Visible"
    $BtnCmdSuite.Background  = "#9D4EDD"
    $BtnCmdSuite.Foreground  = "#FFFFFF"
    $BtnOverview.Background  = "#1A1D28"
    $BtnOverview.Foreground  = "#A0A5B5"
})

# Search Handler
$TxtSearch.Add_GotFocus({
    if ($TxtSearch.Text -eq "Search tools or categories...") { $TxtSearch.Text = "" }
})

$TxtSearch.Add_KeyUp({
    $query = $TxtSearch.Text.ToLower()
    if ([string]::IsNullOrWhiteSpace($query)) {
        $Container.ItemsSource = $global:ToolsList
    } else {
        $filtered = $global:ToolsList | Where-Object { 
            $_.Name.ToLower().Contains($query) -or $_.Category.ToLower().Contains($query) -or $_.Desc.ToLower().Contains($query)
        }
        $Container.ItemsSource = $filtered
    }
})

# الحل الجذري لمشكلة التشغيل (Execution Fix)
$Window.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    if ($e.Source.Tag -and $e.Source.Content -eq "Run Tool") {
        $scriptToRun = $e.Source.Tag
        
        # إنشاء ملف مؤقت آمن لتنفيذ السكريبت بدون مشاكل طول النصوص في الأوامر
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        Set-Content -Path $tempFile -Value "Set-ExecutionPolicy Bypass -Scope Process -Force; $scriptToRun" -Encoding UTF8
        
        # تشغيل السكريبت في نافذة جديدة مباشرة
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempFile`""
    }
})

# Render GUI
$Window.ShowDialog() | Out-Null
