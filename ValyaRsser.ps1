Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ---------------------------------------------------------
# قائمة البيانات والأدوات (Data Structure)
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

    # Category: Forensics & System
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
# تصميم الواجهة باستخدام XAML (WPF)
# ---------------------------------------------------------
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaR Command Suite" Height="650" Width="1000"
        WindowStartupLocation="CenterScreen" Background="#0F0F12"
        Foreground="#FFFFFF" FontFamily="Segoe UI">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar -->
        <Border Grid.Column="0" Background="#16161D" BorderBrush="#2A2A36" BorderThickness="0,0,1,0">
            <StackPanel Margin="15">
                <!-- Logo Header -->
                <TextBlock Text="ValyaR" FontSize="26" FontWeight="Bold" Foreground="#8A2BE2" HorizontalAlignment="Center" Margin="0,10,0,2"/>
                <TextBlock Text="COMMAND SUITE" FontSize="10" Foreground="#6C6C80" HorizontalAlignment="Center" LetterSpacing="3" Margin="0,0,0,30"/>

                <!-- Navigation Buttons -->
                <Button Name="BtnOverview" Content=" Overview" Height="40" Background="#22222E" Foreground="#FFFFFF" BorderThickness="0" Margin="0,0,0,10" HorizontalContentAlignment="Left" Padding="15,0,0,0" FontSize="14" Cursor="Hand"/>
                <Button Name="BtnCmdSuite" Content=" ValyaR Cmd" Height="40" Background="#8A2BE2" Foreground="#FFFFFF" BorderThickness="0" Margin="0,0,0,10" HorizontalContentAlignment="Left" Padding="15,0,0,0" FontSize="14" FontWeight="SemiBold" Cursor="Hand"/>
            </StackPanel>
        </Border>

        <!-- Main Content Area -->
        <Grid Grid.Column="1" Margin="25">
            
            <!-- OVERVIEW VIEW -->
            <Grid Name="ViewOverview" Visibility="Collapsed">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="500">
                    <Border Background="#16161D" CornerRadius="12" Padding="30" BorderBrush="#2A2A36" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="ValyaR Control Center" FontSize="22" FontWeight="Bold" Foreground="#8A2BE2" Margin="0,0,0,15"/>
                            <TextBlock Text="A modern utility launcher designed for quick execution of diagnostics, analyzers, and security verification tools." TextWrapping="Wrap" Foreground="#A0A0B0" FontSize="14" Margin="0,0,0,20"/>
                            
                            <Separator Background="#2A2A36" Margin="0,0,0,20"/>

                            <Grid Margin="0,5">
                                <TextBlock Text="Developer:" Foreground="#6C6C80" FontSize="14"/>
                                <TextBlock Text="Valyar" Foreground="#FFFFFF" FontWeight="Bold" HorizontalAlignment="Right" FontSize="14"/>
                            </Grid>
                            <Grid Margin="0,5">
                                <TextBlock Text="Discord Contact:" Foreground="#6C6C80" FontSize="14"/>
                                <TextBlock Text="_iaec" Foreground="#00E5FF" FontWeight="Bold" HorizontalAlignment="Right" FontSize="14"/>
                            </Grid>
                            <Grid Margin="0,5">
                                <TextBlock Text="Version:" Foreground="#6C6C80" FontSize="14"/>
                                <TextBlock Text="v2.0 Modern CLI" Foreground="#FFFFFF" HorizontalAlignment="Right" FontSize="14"/>
                            </Grid>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Grid>

            <!-- VALYAR CMD VIEW -->
            <Grid Name="ViewCmdSuite" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Search & Filters -->
                <Grid Grid.Row="0" Margin="0,0,0,20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="TxtSearch" Height="40" Background="#16161D" Foreground="#FFFFFF" BorderBrush="#2A2A36" BorderThickness="1" Padding="12,8" FontSize="14" VerticalContentAlignment="Center" Text="Search tools or categories..."/>
                </Grid>

                <!-- Tools Scrollable List -->
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <ItemsControl Name="ToolsContainer">
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Background="#16161D" BorderBrush="#2A2A36" BorderThickness="1" CornerRadius="8" Margin="0,0,0,12" Padding="15">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel Grid.Column="0">
                                            <StackPanel Orientation="Horizontal" Margin="0,0,0,5">
                                                <TextBlock Text="{Binding Name}" FontSize="16" FontWeight="Bold" Foreground="#FFFFFF"/>
                                                <Border Background="#252538" CornerRadius="4" Margin="10,0,0,0" Padding="6,2">
                                                    <TextBlock Text="{Binding Category}" FontSize="11" Foreground="#8A2BE2" FontWeight="SemiBold"/>
                                                </Border>
                                            </StackPanel>
                                            <TextBlock Text="{Binding Desc}" Foreground="#808095" FontSize="13" TextWrapping="Wrap"/>
                                        </StackPanel>
                                        <Button Grid.Column="1" Content="Run Tool" Tag="{Binding Cmd}" Height="35" Width="100" Background="#8A2BE2" Foreground="#FFFFFF" BorderThickness="0" FontWeight="SemiBold" Cursor="Hand" Click="RunTool_Click"/>
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
# تهيئة النافذة والمعالجة البرمجية
# ---------------------------------------------------------
$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# ربط العناصر
$BtnOverview  = $Window.FindName("BtnOverview")
$BtnCmdSuite  = $Window.FindName("BtnCmdSuite")
$ViewOverview = $Window.FindName("ViewOverview")
$ViewCmdSuite = $Window.FindName("ViewCmdSuite")
$TxtSearch    = $Window.FindName("TxtSearch")
$Container    = $Window.FindName("ToolsContainer")

# ربط البيانات بالشاشة
$Container.ItemsSource = $global:ToolsList

# التنقل بين الأقسام
$BtnOverview.Add_Click({
    $ViewOverview.Visibility = "Visible"
    $ViewCmdSuite.Visibility = "Collapsed"
    $BtnOverview.Background  = "#8A2BE2"
    $BtnCmdSuite.Background  = "#22222E"
})

$BtnCmdSuite.Add_Click({
    $ViewOverview.Visibility = "Collapsed"
    $ViewCmdSuite.Visibility = "Visible"
    $BtnCmdSuite.Background  = "#8A2BE2"
    $BtnOverview.Background  = "#22222E"
})

# خاصية البحث والتصفية
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

# تشغيل الأوامر عند الضغط على الزر
$script:RunTool_Click = {
    param($sender, $e)
    $cmdToRun = $sender.Tag
    Start-Process powershell -ArgumentList "-NoExit -Command $cmdToRun"
}

# إضافة الحدث للأزرار المنشأة ديناميكياً
$Window.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    if ($e.Source.Tag -and $e.Source.Content -eq "Run Tool") {
        Start-Process powershell -ArgumentList "-NoExit -Command `"$($e.Source.Tag)`""
    }
})

# عرض النافذة
$Window.ShowDialog() | Out-Null
