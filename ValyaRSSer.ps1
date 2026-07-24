Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==============================================================================
# ADMIN CHECK
# ==============================================================================
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    [System.Windows.MessageBox]::Show(
        "This tool requires Administrator privileges to run.`n`nPlease right-click and select 'Run as Administrator'.",
        "Admin Required",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
    exit
}

$installDir = "$env:USERPROFILE\Downloads\ValyaRssTool"

# ==============================================================================
# TOOL DATA
# ==============================================================================
$ToolData = @(
    @{ Name="WinPrefetchView_x64.zip"; Desc="View prefetch files"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/winprefetchview-x64.zip" },
    @{ Name="LastActivityView.zip"; Desc="List recent user activity"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/lastactivityview.zip" },
    @{ Name="UsbDriveLog.zip"; Desc="Show USB drive history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/usbdrivelog.zip" },
    @{ Name="WinDefLogView.zip"; Desc="Windows Defender log viewer"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/windeflogview.zip" },
    @{ Name="ShellBagsView.zip"; Desc="Shell bags / folder history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/shellbagsview.zip" },
    @{ Name="UninstallView_x64.zip"; Desc="List installed programs"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/uninstallview-x64.zip" },
    @{ Name="LoadedDllsView_x64.zip"; Desc="Loaded DLL list"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/loadeddllsview-x64.zip" },
    @{ Name="JumpListsView.zip"; Desc="Jump list history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/jumplistsview.zip" },
    @{ Name="Clipboardic.zip"; Desc="Clipboard history viewer"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/clipboardic.zip" },
    @{ Name="TimelineExplorer.zip"; Desc="Timeline analysis"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip" },
    @{ Name="SrumECmd.zip"; Desc="SRUM database parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/SrumECmd.zip" },
    @{ Name="AmcacheParser.zip"; Desc="Amcache analysis tool"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/AmcacheParser.zip" },
    @{ Name="WxTCmd.zip"; Desc="Windows Timeline database"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net6/WxTCmd.zip" },
    @{ Name="RegistryExplorer.zip"; Desc="Registry explorer"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip" },
    @{ Name="MFTECmd.zip"; Desc="MFT filesystem parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip" },
    @{ Name="JLECmd.zip"; Desc="JumpList CSV parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/JLECmd.zip" },
    @{ Name="JumpListExplorer.zip"; Desc="JumpList GUI parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip" },
    @{ Name="PECmd.zip"; Desc="Prefetch parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/PECmd.zip" },
    @{ Name="RecentFileCacheParser.zip"; Desc="Recent file cache parser"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip" },
    @{ Name="ShellBagsExplorer.zip"; Desc="Shell bags explorer"; Category="EricZimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip" },
    @{ Name="BAMParser.exe"; Desc="BAM record parser"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe" },
    @{ Name="PrefetchParser.exe"; Desc="Prefetch parser"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe" },
    @{ Name="ProcessParser.exe"; Desc="Process information parser"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/process-parser/releases/download/v0.5.5/ProcessParser.exe" },
    @{ Name="PcaSvcExecuted.exe"; Desc="PCA service execution record"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/pcasvc-executed/releases/download/v0.8.7/PcaSvcExecuted.exe" },
    @{ Name="JournalTraceNormal.exe"; Desc="USN Journal trace"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTraceNormal.exe" },
    @{ Name="PathsParser.exe"; Desc="File path history"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe" },
    @{ Name="KernelLiveDumpTool.exe"; Desc="Kernel live dump tool"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe" },
    @{ Name="espouken.exe"; Desc="Espouken analysis tool"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/Tool/releases/download/v1.1.2/espouken.exe" },
    @{ Name="BamDeletedKeys.exe"; Desc="Deleted BAM records"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/BamDeletedKeys/releases/download/v1.0/BamDeletedKeys.exe" },
    @{ Name="ActivitiesCache.exe"; Desc="Activities cache execution"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest" },
    @{ Name="Echo-Journal.exe"; Desc="Journal analysis tool"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/Echo-Anticheat/Echo-Journal/raw/main/echo-journal.exe" },
    @{ Name="UserAssist.exe"; Desc="UserAssist registry viewer"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-userassist.exe" },
    @{ Name="UsbTool.exe"; Desc="USB record analysis"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-usb.exe" },
    @{ Name="pv++.exe"; Desc="Detailed Prefetch analyzer"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.6/pv++.exe" },
    @{ Name="OrbDiff-AmcacheParser.exe"; Desc="Detailed Amcache analyzer"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/AmcacheParser/releases/download/v1.0/AmcacheParser.exe" },
    @{ Name="JARParser.exe"; Desc="JAR scanner"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/JARParser/releases/download/v1.2/JARParser.exe" },
    @{ Name="fileless.exe"; Desc="Fileless malware detector"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/Fileless/releases/download/v1.3/fileless.exe" },
    @{ Name="BAMReveal.exe"; Desc="BAM records viewer"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/BAMReveal/releases/download/v1.3/BAMReveal.exe" },
    @{ Name="OrbDiff-DPSAnalyzer.exe"; Desc="DPS analysis tool"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/download/v1.1/dpsanalyzer.exe" },
    @{ Name="OrbDiff-UserAssistView.exe"; Desc="UserAssist viewer"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest" },
    @{ Name="OrbDiff-JournalParser.exe"; Desc="Journal parser"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/JournalParser/releases/latest" },
    @{ Name="OrbDiff-InjGen.exe"; Desc="Injection detection"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/InjGen/releases/latest" },
    @{ Name="OrbDiff-USBDetector.exe"; Desc="USB detection"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/USBDetector/releases/latest" },
    @{ Name="OrbDiff-PFTrace.exe"; Desc="Prefetch trace"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/PFTrace/releases/latest" },
    @{ Name="OrbDiff-CheckDeletedUSN.exe"; Desc="Deleted USN check"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest" },
    @{ Name="OrbDiff-StringsParser.exe"; Desc="Strings parser"; Category="OrbDiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/StringsParser/releases/latest" },
    @{ Name="RedLotusModAnalyzer.exe"; Desc="Mod analysis tool"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe" },
    @{ Name="RedLotusAltChecker.exe"; Desc="Alt account checker"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe" },
    @{ Name="RedLotusTaskSentinel.exe"; Desc="Task monitor sentinel"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/download/RL/RedLotusTaskSentinel.exe" },
    @{ Name="PathDuzenleyicisiV2.exe"; Desc="Path organizer v2"; Category="TRSSCommunity"; Author="TRSSCommunity"; Type="GitHub"; URL="https://github.com/trSScommunity/PathDuzenleyiciV2/raw/refs/heads/main/PathDuzenleyicisiV2.exe" },
    @{ Name="MzHunter.exe"; Desc="MZ header scanner"; Category="TRSSCommunity"; Author="TRSSCommunity"; Type="GitHub"; URL="https://github.com/trSScommunity/MZHunter/raw/refs/heads/main/MzHunter.exe" },
    @{ Name="MandarinTool.jar"; Desc="Multi SS tool / JAR decompiler"; Category="TRSSCommunity"; Author="TRSSCommunity"; Type="GitHub"; URL="https://github.com/Mehmetyll/Mandarin-Tool/releases/download/Mandarin-Tool/MandarinTool.jar" },
    @{ Name="MagnetEncryptedDiskDetector.exe"; Desc="Encrypted disk detector"; Category="Magnet"; Author="Magnet"; Type="Web"; URL="https://go.magnetforensics.com/e/52162/MagnetEncryptedDiskDetector/kpt9bg/1663239667/h/LtXFtTL-Soawv5C1oL3BIEghi7e1Lx93yesZLR--Ok0" },
    @{ Name="MRCv120.exe"; Desc="RAM dump tool"; Category="Magnet"; Author="Magnet"; Type="Web"; URL="https://go.magnetforensics.com/e/52162/mail-utm-campaign-UTMC-0000044/llr4bg/1663358653/h/4kZ9Y4i2yPRqBzuQMrywA_v5bfkpG3rG8gEiSWrYU70" },
    @{ Name="FTK_Imager_4.7.1.exe"; Desc="Disk imaging tool"; Category="Forensics"; Author="AccessData"; Type="Web"; URL="https://archive.org/download/access-data-ftk-imager-4.7.1/AccessData_FTK_Imager_4.7.1.exe" },
    @{ Name="hayabusa-3.6.0-win-aarch64.zip"; Desc="Windows event log analyzer"; Category="Forensics"; Author="Yamato-Security"; Type="GitHub"; URL="https://github.com/Yamato-Security/hayabusa/releases/download/v3.6.0/hayabusa-3.6.0-win-aarch64.zip" },
    @{ Name="Velocidace.exe"; Desc="Digital forensics platform"; Category="Forensics"; Author="Velocidex"; Type="GitHub"; URL="https://github.com/Velocidex/velociraptor/releases/download/v0.75/velociraptor-v0.75.1-windows-amd64.exe" },
    @{ Name="SystemInformer_Canary_Setup.exe"; Desc="Advanced system monitor"; Category="SystemTools"; Author="winsiderss"; Type="GitHub"; URL="https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe" },
    @{ Name="Everything-Setup.exe"; Desc="Instant file search engine"; Category="SystemTools"; Author="voidtools"; Type="Web"; URL="https://www.voidtools.com/Everything-1.4.1.1032.x64-Setup.exe" },
    @{ Name="ProcessHacker-Setup.exe"; Desc="Process hacker"; Category="SystemTools"; Author="winsiderss"; Type="Web"; URL="https://sourceforge.net/projects/processhacker/files/latest/download" },
    @{ Name="InjGen.exe"; Desc="Injection detection tool"; Category="Analysis"; Author="NotRequiem"; Type="GitHub"; URL="https://github.com/NotRequiem/InjGen/releases/download/v2.0/InjGen.exe" },
    @{ Name="Luyten.exe"; Desc="Java decompiler"; Category="Analysis"; Author="deathmarine"; Type="GitHub"; URL="https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe" },
    @{ Name="dpsanalyzer.exe"; Desc="DPS analyzer"; Category="Analysis"; Author="nay-cat"; Type="GitHub"; URL="https://github.com/nay-cat/dpsanalyzer/releases/download/1.3/dpsanalyzer.exe" },
    @{ Name="DIE_engine_portable.zip"; Desc="Detect-It-Easy PE analyzer"; Category="Analysis"; Author="horsicq"; Type="GitHub"; URL="https://github.com/horsicq/DIE-engine/releases/download/3.09/die_win64_portable_3.09_x64.zip" },
    @{ Name="Jarabel.Light.exe"; Desc="JAR analysis tool"; Category="Misc"; Author="nay-cat"; Type="GitHub"; URL="https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe" },
    @{ Name="Unicode.exe"; Desc="Unicode character analyzer"; Category="Misc"; Author="RRancio"; Type="GitHub"; URL="https://github.com/RRancio/Exec/raw/main/Files/Unicode.exe" },
    @{ Name="CachedProgramsList.exe"; Desc="Cache program list"; Category="Misc"; Author="ponei"; Type="GitHub"; URL="https://github.com/ponei/CachedProgramsList/releases/download/1.1/CachedProgramsList.exe" },
    @{ Name="TimeChangeDetect.exe"; Desc="System time change detector"; Category="Misc"; Author="santiagolin"; Type="GitHub"; URL="https://github.com/santiagolin/TimeChangeDetect/releases/download/1.0/TimeChangeDetect.exe" },
    @{ Name="HardlinkFinder.exe"; Desc="Hardlink detection"; Category="Misc"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/HardlinkFinder/releases/download/Tools/hardlink.exe" },
    @{ Name="MeowNovowareFucker.exe"; Desc="Novoware client detector"; Category="Meow"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/raw/refs/heads/main/MeowNovowareFucker.exe" },
    @{ Name="MeowDoomsdayFucker.exe"; Desc="Doomsday client detector"; Category="Meow"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/raw/refs/heads/main/MeowDoomsdayFucker.exe" },
    @{ Name="MeowResolver.exe"; Desc="Meow resolver"; Category="Meow"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest" },
    @{ Name="MeowImportsChecker.exe"; Desc="Imports checker"; Category="Meow"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest" },
    @{ Name="PSHunter.exe"; Desc="PS hunter tool"; Category="Praiselily"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/PSHunter/releases/latest" },
    @{ Name="AltDetector.exe"; Desc="Alt account detector"; Category="Praiselily"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/AltDetector/releases/latest" },
    @{ Name="TeslaPro-MacroFinder.exe"; Desc="Macro finder tool"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/TeslaProMacroFinder/releases/latest" },
    @{ Name="TeslaPro-DoomsdayDetector.exe"; Desc="Doomsday detector"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/DoomsdayDetector/releases/latest" },
    @{ Name="TeslaPro-VPNFinder.exe"; Desc="VPN finder"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/VPNChecker/releases/latest" },
    @{ Name="TeslaPro-GhostClientFucker.exe"; Desc="Ghost client detector"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/GhostClientFucker/releases/latest" },
    @{ Name="Xeinn-SSTools.exe"; Desc="Xeinn SS tools"; Category="Xeinn"; Author="Xeinn"; Type="GitHub"; URL="https://github.com/Xeinn-Software/Xeinn-SS-Tools-Downloader/releases/latest" },
    @{ Name="NET-9.0-SDK.exe"; Desc=".NET 9.0 SDK"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/9.0" },
    @{ Name="NET-10.0-Runtime.exe"; Desc=".NET 10.0 Runtime"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/10.0" },
    @{ Name="VC_Redist.exe"; Desc="Visual C++ Redistributable"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://aka.ms/vs/17/release/vc_redist.x64.exe" }
)

# ==============================================================================
# UI - BLACK, WHITE, BLOOD RED THEME WITH ROUNDED BUTTONS
# ==============================================================================
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ValyaRssTool"
    Width="1200" Height="760"
    MinWidth="1200" MinHeight="760"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI">

    <Window.Resources>
        <SolidColorBrush x:Key="MainBg"     Color="#000000"/>
        <SolidColorBrush x:Key="SidebarBg"  Color="#0A0A0A"/>
        <SolidColorBrush x:Key="CardBg"     Color="#1A1A1A"/>
        <SolidColorBrush x:Key="Accent"     Color="#B8860B"/>
        <SolidColorBrush x:Key="AccentDim"  Color="#7A5A08"/>
        <SolidColorBrush x:Key="TextMain"   Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextMuted"  Color="#808080"/>
        <SolidColorBrush x:Key="ConsoleBg"  Color="#050505"/>
        <SolidColorBrush x:Key="GhBg"       Color="#1A1A1A"/>
        <SolidColorBrush x:Key="Ps1Bg"      Color="#1A1A1A"/>
        <SolidColorBrush x:Key="WebBg"      Color="#1A1A1A"/>

        <Style x:Key="SideBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Margin" Value="0,0,0,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" BorderThickness="0">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" Margin="14,0"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#241C08"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TitleBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="8" BorderThickness="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#33B8860B"/>
                                <Setter Property="Foreground" Value="#B8860B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="{StaticResource MainBg}" BorderBrush="#B8860B" BorderThickness="1" CornerRadius="12">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="42"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar -->
            <Border Grid.Row="0" Background="{StaticResource SidebarBg}" CornerRadius="12,12,0,0">
                <Grid Margin="16,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Image x:Name="DiscordIcon" Source="https://github.com/Va2lyR/ValyaRssTool/blob/main/ValyaR.jpg?raw=true" Width="24" Height="24" Margin="0,0,8,0"/>
                        <TextBlock Text="ValyaRssTool" FontSize="14" FontWeight="SemiBold" Foreground="{StaticResource TextMain}"/>
                        <TextBlock Text="  -  by Va2lyR" FontSize="11" Foreground="{StaticResource TextMuted}" VerticalAlignment="Center" Margin="4,0,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                        <Button x:Name="MinBtn"   Style="{StaticResource TitleBtn}" Content="_"/>
                        <Button x:Name="CloseBtn" Style="{StaticResource TitleBtn}" Content="X"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Body -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="210"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Sidebar -->
                <Border Grid.Column="0" Background="{StaticResource SidebarBg}" BorderBrush="#B8860B" BorderThickness="0,0,1,0">
                    <StackPanel Margin="10,14,10,14">

                        <Border Background="#050505" CornerRadius="10" Margin="0,0,0,14" Padding="0,16">
                            <StackPanel HorizontalAlignment="Center">
                                <TextBlock x:Name="CatBlock" Text="VRT"
                                    FontFamily="Consolas" FontSize="26" FontWeight="Bold"
                                    Foreground="{StaticResource Accent}"
                                    HorizontalAlignment="Center"/>
                                <TextBlock Text="v1.0" FontFamily="Consolas" FontSize="9"
                                    Foreground="{StaticResource TextMuted}"
                                    HorizontalAlignment="Center" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Border>

                        <TextBlock Text="ACTIONS" FontSize="9" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="4,0,0,6"/>
                        <Button x:Name="OpenFolderBtn" Content="  Open Install Folder"      Style="{StaticResource SideBtn}"/>
                        <Button x:Name="ClearCacheBtn" Content="  Clear Downloaded Files"   Style="{StaticResource SideBtn}"/>
                        <Button x:Name="OpenCmdBtn"    Content="  Open CMD"                 Style="{StaticResource SideBtn}"/>

                        <Separator Background="#B8860B" Margin="0,10,0,10"/>

                        <TextBlock Text="CREDITS" FontSize="9" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="4,0,0,6"/>
                        <TextBlock Text="Made by Va2lyR" FontSize="11" FontWeight="SemiBold" Foreground="{StaticResource TextMain}" Margin="4,2,0,4"/>
                        <TextBlock Text="Discord: Va2lyR" FontSize="10" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" Margin="4,1,0,0"/>
                        <TextBlock Text="GitHub: Va2lyR" FontSize="10" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" Margin="4,1,0,0"/>

                        <Separator Background="#B8860B" Margin="0,10,0,10"/>
                        <TextBlock x:Name="InstPathBlock" Text="" FontSize="9" Foreground="#404040" TextWrapping="Wrap" Margin="4,0"/>
                    </StackPanel>
                </Border>

                <!-- Main Panel -->
                <Grid Grid.Column="1" Margin="16,14,16,14">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="10"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="10"/>
                        <RowDefinition Height="160"/>
                    </Grid.RowDefinitions>

                    <!-- Status card -->
                    <Border Grid.Row="0" Background="{StaticResource CardBg}" CornerRadius="10" Padding="16,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock x:Name="StatusTitle" Text="Ready" FontSize="20" FontWeight="SemiBold" Foreground="{StaticResource TextMain}"/>
                                <TextBlock x:Name="StatusSub"   Text="Select a tool to launch or download it." FontSize="11" Foreground="{StaticResource TextMuted}"/>
                            </StackPanel>
                            <Border Grid.Column="1" Background="#1C1C1C" CornerRadius="8" Padding="10,4" VerticalAlignment="Center">
                                <TextBlock x:Name="StatusBadge" Text="IDLE" FontSize="12" FontWeight="Bold" Foreground="{StaticResource Accent}"/>
                            </Border>
                        </Grid>
                    </Border>

                    <!-- Tab control -->
                    <Border Grid.Row="2" Background="{StaticResource CardBg}" CornerRadius="10">
                        <TabControl x:Name="ToolsTab" Background="Transparent" BorderThickness="0" Padding="0">
                            <TabControl.Resources>
                                <Style TargetType="TabItem">
                                    <Setter Property="Foreground" Value="{StaticResource TextMuted}"/>
                                    <Setter Property="FontSize" Value="11"/>
                                    <Setter Property="Padding" Value="12,6"/>
                                    <Setter Property="Cursor" Value="Hand"/>
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="TabItem">
                                                <Border x:Name="TabBorder" Background="Transparent" CornerRadius="8" Margin="3,4,3,0" Padding="12,5" BorderThickness="0">
                                                    <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsSelected" Value="True">
                                                        <Setter TargetName="TabBorder" Property="Background" Value="{StaticResource Accent}"/>
                                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                                    </Trigger>
                                                    <MultiTrigger>
                                                        <MultiTrigger.Conditions>
                                                            <Condition Property="IsMouseOver" Value="True"/>
                                                            <Condition Property="IsSelected" Value="False"/>
                                                        </MultiTrigger.Conditions>
                                                        <Setter TargetName="TabBorder" Property="Background" Value="#241C08"/>
                                                        <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
                                                    </MultiTrigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </TabControl.Resources>
                        </TabControl>
                    </Border>

                    <!-- Console -->
                    <Border Grid.Row="4" Background="{StaticResource ConsoleBg}" CornerRadius="10" Padding="12,8">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Text="ACTIVITY CONSOLE" FontSize="9" FontWeight="Bold" Foreground="#B8860B" FontFamily="Consolas" Margin="0,0,0,4"/>
                            <TextBox x:Name="LogBox"
                                Grid.Row="1"
                                Background="Transparent"
                                Foreground="{StaticResource Accent}"
                                BorderThickness="0"
                                FontFamily="Consolas"
                                FontSize="11"
                                IsReadOnly="True"
                                VerticalScrollBarVisibility="Auto"
                                TextWrapping="Wrap"/>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# ==============================================================================
# DISCLAIMER DIALOG
# ==============================================================================
[xml]$disclaimerXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ValyaRssTool"
    Width="560" Height="560"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI">
    <Border Background="#000000" BorderBrush="#B8860B" BorderThickness="1" CornerRadius="12" Padding="24">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="56"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0">
                <TextBlock Text="ValyaRssTool" FontSize="20" FontWeight="Bold" Foreground="#B8860B" Margin="0,0,0,12"/>
                <TextBlock TextWrapping="Wrap" Foreground="#FFFFFF" FontSize="13" Margin="0,0,0,12"
                           Text="All programs are downloaded automatically from their official GitHub repositories and saved in a neatly organized folder. None of your information is ever collected or modified."/>
                <TextBlock TextWrapping="Wrap" Foreground="#FFFFFF" FontSize="13" Margin="0,0,0,16"
                           Text="Each tool is developed and maintained by its own author. I take no responsibility for anything that may be found regarding these tools in the future."/>
                <TextBlock TextWrapping="Wrap" Foreground="#FFFFFF" FontSize="13" FontWeight="SemiBold"
                           Text="To continue, you must agree with everything stated above."/>
            </StackPanel>
            <Grid Grid.Row="1" VerticalAlignment="Bottom">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="CancelBtn" Grid.Column="0" Content="Cancel" Height="40"
                        Background="Transparent" Foreground="#FFFFFF" BorderBrush="#B8860B" BorderThickness="1"
                        Cursor="Hand" FontSize="13"/>
                <Button x:Name="AcceptBtn" Grid.Column="2" Content="Accept &amp; Continue" Height="40"
                        Background="#1A1A1A" Foreground="#B8860B" BorderBrush="#B8860B" BorderThickness="1"
                        Cursor="Hand" FontSize="13" FontWeight="SemiBold"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$disclaimerReader = New-Object System.Xml.XmlNodeReader $disclaimerXaml
$disclaimerWindow = [Windows.Markup.XamlReader]::Load($disclaimerReader)
$disclaimerWindow.Add_MouseLeftButtonDown({ try { $disclaimerWindow.DragMove() } catch {} })

$CancelBtn = $disclaimerWindow.FindName("CancelBtn")
$AcceptBtn = $disclaimerWindow.FindName("AcceptBtn")

$script:disclaimerAccepted = $false

$AcceptBtn.Add_Click({
    $script:disclaimerAccepted = $true
    $disclaimerWindow.Close()
})
$CancelBtn.Add_Click({
    $script:disclaimerAccepted = $false
    $disclaimerWindow.Close()
})

$disclaimerWindow.ShowDialog() | Out-Null

if (-not $script:disclaimerAccepted) {
    exit
}

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$MinBtn        = $window.FindName("MinBtn")
$CloseBtn      = $window.FindName("CloseBtn")
$StatusTitle   = $window.FindName("StatusTitle")
$StatusSub     = $window.FindName("StatusSub")
$StatusBadge   = $window.FindName("StatusBadge")
$LogBox        = $window.FindName("LogBox")
$ToolsTab      = $window.FindName("ToolsTab")
$OpenFolderBtn = $window.FindName("OpenFolderBtn")
$ClearCacheBtn = $window.FindName("ClearCacheBtn")
$OpenCmdBtn    = $window.FindName("OpenCmdBtn")
$CatBlock      = $window.FindName("CatBlock")
$InstPathBlock = $window.FindName("InstPathBlock")
$DiscordIcon   = $window.FindName("DiscordIcon")

$InstPathBlock.Text = "Install path:`n$installDir"

# ==============================================================================
# LOAD DISCORD ICON
# ==============================================================================
try {
    $iconUrl = "https://github.com/Va2lyR/ValyaRssTool/blob/main/ValyaR.jpg?raw=true"
    $iconPath = Join-Path $env:TEMP "ValyaR_Icon.jpg"
    if (-not (Test-Path $iconPath)) {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($iconUrl, $iconPath)
        $webClient.Dispose()
    }
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.CacheOption = "OnLoad"
    $bitmap.UriSource = [System.Uri]$iconPath
    $bitmap.EndInit()
    $bitmap.Freeze()
    $DiscordIcon.Source = $bitmap
} catch {
    Write-Log "Failed to load Discord icon: $_"
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    $LogBox.Dispatcher.Invoke([Action]{
        $LogBox.AppendText("[$time] $msg`r`n")
        $LogBox.ScrollToEnd()
    })
}

function Set-Status {
    param($title, $sub, $badge = "BUSY")
    $window.Dispatcher.Invoke([Action]{
        $StatusTitle.Text = $title
        $StatusSub.Text   = $sub
        $StatusBadge.Text = $badge
    })
}

function Start-AppOrScript {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$WorkingDirectory
    )

    if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path -Parent $Path }
    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    $quotedPath = '"' + $Path + '"'

    switch ($extension) {
        ".cmd" { Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $quotedPath -WorkingDirectory $WorkingDirectory -WindowStyle Normal }
        ".bat" { Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $quotedPath -WorkingDirectory $WorkingDirectory -WindowStyle Normal }
        default { Start-Process -FilePath $Path -WorkingDirectory $WorkingDirectory -WindowStyle Normal }
    }
}

function Start-CmdToolCommand {
    param([Parameter(Mandatory=$true)][string]$Command)

    $tempScript = [System.IO.Path]::Combine($env:TEMP, "valya_$([guid]::NewGuid().ToString('N')).ps1")
    Set-Content -LiteralPath $tempScript -Value $Command -Encoding UTF8 -Force

    $startArgs = '/c start "ValyaRssTool" powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "' + $tempScript + '"'
    Start-Process -FilePath "cmd.exe" -ArgumentList $startArgs -WindowStyle Hidden
}

function Save-UrlToFile {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile
    )

    $tempFile = "$OutFile.download"
    if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue }

    $client = New-Object System.Net.WebClient
    $client.Headers.Add("User-Agent", "ValyaRssTool")
    try {
        $client.DownloadFile($Uri, $tempFile)
        if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force -ErrorAction Stop }
        Move-Item -LiteralPath $tempFile -Destination $OutFile -Force -ErrorAction Stop
    } finally {
        $client.Dispose()
        if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue }
    }
}

function Start-DownloadedTool {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [string]$PreferredFile
    )

    if ($PreferredFile -and (Test-Path -LiteralPath $PreferredFile) -and ($PreferredFile -notmatch "\.zip$")) {
        Write-Log "Launching $(Split-Path -Leaf $PreferredFile)"
        Start-AppOrScript -Path $PreferredFile -WorkingDirectory (Split-Path -Parent $PreferredFile)
        return $true
    }

    $launchable = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match "^\.(exe|cmd|bat)$" } |
        Sort-Object @{ Expression = { if ($_.Extension -eq ".exe") { 0 } else { 1 } } }, FullName |
        Select-Object -First 1

    if ($launchable) {
        Write-Log "Launching $($launchable.Name)"
        Start-AppOrScript -Path $launchable.FullName -WorkingDirectory $launchable.DirectoryName
        return $true
    }

    Write-Log "No .exe, .cmd, or .bat found - opening folder."
    Start-Process -FilePath explorer.exe -ArgumentList "`"$Directory`""
    return $false
}

function Get-GitHubAssetUrl {
    param([string]$ReleaseUrl)

    if ($ReleaseUrl -match "github\.com/([^/]+)/([^/]+)/releases/tag/(.+)$") {
        $user = $Matches[1]
        $repo = $Matches[2]
        $tag = [Uri]::EscapeDataString(([Uri]::UnescapeDataString($Matches[3])).TrimEnd("/"))
        $api  = "https://api.github.com/repos/$user/$repo/releases/tags/$tag"
        try {
            $rel   = Invoke-RestMethod -Uri $api -Headers @{"User-Agent"="ValyaRssTool"} -ErrorAction Stop
            $asset = $rel.assets | Where-Object { $_.name -match "\.(exe|zip|cmd|bat)$" } | Select-Object -First 1
            if ($asset) { return @{ url=$asset.browser_download_url; name=$asset.name } }
        } catch {
            Write-Log "GitHub lookup failed: $($_.Exception.Message)"
        }
    }

    return $null
}

function Invoke-ToolDownloadAndRun {
    param($tool)
    $name = $tool.Name
    $cat  = $tool.Category

    Write-Log "Fetching asset info for $name..."

    if ($tool.URL -match "github\.com/[^/]+/[^/]+/releases/latest$") {
        $downloadUrl = $tool.URL -replace "/releases/latest$", "/releases"
        try {
            $apiUrl = $tool.URL -replace "github\.com/([^/]+)/([^/]+)/releases/latest$", 'api.github.com/repos/$1/$2/releases/latest'
            $apiUrl = $apiUrl -replace "^github", "https://github" -replace "^https://https://", "https://"
            $rel = Invoke-RestMethod -Uri $apiUrl -Headers @{"User-Agent"="ValyaRssTool"} -ErrorAction Stop
            $asset = $rel.assets | Where-Object { $_.name -match "\.(exe|zip|cmd|bat|jar)$" } | Select-Object -First 1
            if ($asset) {
                $downloadUrl = $asset.browser_download_url
                $assetName = $asset.name
            } else {
                Write-Log "No downloadable asset found for $name - opening browser."
                Set-Status "Ready" "No asset found, opened GitHub." "IDLE"
                Start-Process $tool.URL
                return
            }
        } catch {
            Write-Log "GitHub API lookup failed: $($_.Exception.Message) - opening browser."
            Set-Status "Ready" "Could not resolve asset, opened GitHub." "IDLE"
            Start-Process $tool.URL
            return
        }
    } else {
        $asset = Get-GitHubAssetUrl -ReleaseUrl $tool.URL
        if (-not $asset) {
            Write-Log "No .exe/.zip/.cmd/.bat asset found for $name - opening browser."
            Set-Status "Ready" "No asset found, opened GitHub." "IDLE"
            Start-Process $tool.URL
            return
        }
        $downloadUrl = $asset.url
        $assetName = $asset.name
    }

    $destDir  = "$installDir\$cat\$name"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $destFile = "$destDir\$assetName"

    if (Test-Path $destFile) {
        Write-Log "Cached: $assetName - skipping download."
    } else {
        Write-Log "Downloading $assetName..."
        try {
            Save-UrlToFile -Uri $downloadUrl -OutFile $destFile
            Write-Log "Download complete: $assetName"
        } catch {
            $err = $_
            Write-Log "Download failed: $err"
            Set-Status "Error" "Download failed for $name." "ERR"
            Start-Process $tool.URL
            return
        }
    }

    if ($assetName -match "\.zip$") {
        Write-Log "Extracting $assetName..."
        try {
            Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop
        } catch {
            Write-Log "Extract failed: $($_.Exception.Message)"
            Set-Status "Error" "Could not extract $name." "ERR"
            Start-Process -FilePath explorer.exe -ArgumentList "`"$destDir`""
            return
        }
        [void](Start-DownloadedTool -Directory $destDir)
    } else {
        [void](Start-DownloadedTool -Directory $destDir -PreferredFile $destFile)
    }

    Set-Status "Ready" "$name launched successfully." "IDLE"
}

function Invoke-WebToolDownload {
    param($tool)
    $name = $tool.Name
    $url  = $tool.URL

    if ($url -match "\.(zip|exe|cmd|bat|jar)$") {
        $fileName = ($url -split "/")[-1]
        $destDir  = "$installDir\$($tool.Category)\$name"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        $destFile = "$destDir\$fileName"

        if (Test-Path $destFile) {
            Write-Log "Cached: $fileName - skipping download."
        } else {
            Write-Log "Downloading $fileName..."
            try {
                Save-UrlToFile -Uri $url -OutFile $destFile
                Write-Log "Download complete: $fileName"
            } catch {
                $err = $_
                Write-Log "Download failed: $err"
                Set-Status "Error" "Download failed." "ERR"
                Start-Process $url
                return
            }
        }

        if ($fileName -match "\.zip$") {
            try {
                Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop
            } catch {
                Write-Log "Extract failed: $($_.Exception.Message)"
                Set-Status "Error" "Could not extract $name." "ERR"
                Start-Process -FilePath explorer.exe -ArgumentList "`"$destDir`""
                return
            }
            [void](Start-DownloadedTool -Directory $destDir)
        } else {
            [void](Start-DownloadedTool -Directory $destDir -PreferredFile $destFile)
        }
        Set-Status "Ready" "$name launched." "IDLE"
    } else {
        Write-Log "Opening browser for $name"
        Set-Status "Browser" "Opening $name in browser." "IDLE"
        Start-Process $url
    }
}

# ==============================================================================
# BUTTON ANIMATION
# ==============================================================================
function Start-ButtonAnimation {
    param([System.Windows.Controls.Button]$Button)

    $origBg  = $Button.Background
    $origFg  = $Button.Foreground
    $origW   = $Button.Width
    $origH   = $Button.Height

    $flashColors = @("#B8860B", "#FFFFFF", "#B8860B", "#FF0000")
    $flashFg     = "#000000"
    $scales      = @(0.93, 0.96, 1.04, 1.0)
    $delays      = @(0, 80, 160, 250)

    $Button.IsEnabled = $false

    for ($i = 0; $i -lt $flashColors.Count; $i++) {
        $color   = $flashColors[$i]
        $scale   = $scales[$i]
        $delay   = $delays[$i]
        $w       = [Math]::Round($origW * $scale)
        $h       = [Math]::Round($origH * $scale)

        $Button.Dispatcher.Invoke([Action]{
            $Button.Background = $color
            $Button.Foreground = $flashFg
            $Button.Width      = $w
            $Button.Height     = $h
        }, [System.Windows.Threading.DispatcherPriority]::Render)

        Start-Sleep -Milliseconds 80
    }

    $Button.Dispatcher.Invoke([Action]{
        $Button.Background = $origBg
        $Button.Foreground = $origFg
        $Button.Width      = $origW
        $Button.Height     = $origH
        $Button.IsEnabled  = true
    }, [System.Windows.Threading.DispatcherPriority]::Render)
}

# ==============================================================================
# TABS AND BUTTONS
# ==============================================================================
$Categories = $ToolData | Select-Object -ExpandProperty Category -Unique | Sort-Object

foreach ($cat in $Categories) {
    $tab = New-Object System.Windows.Controls.TabItem
    $tab.Header = $cat

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility   = "Auto"
    $scroll.HorizontalScrollBarVisibility = "Disabled"

    $wrap = New-Object System.Windows.Controls.WrapPanel
    $wrap.Margin = "8"

    $catTools = $ToolData | Where-Object { $_.Category -eq $cat }

    foreach ($tool in $catTools) {
        $t = $tool

        $btn             = New-Object System.Windows.Controls.Button
        $btn.Width       = 210
        $btn.Height      = 80
        $btn.FontSize    = 12
        $btn.Margin      = "6"
        $btn.Cursor      = "Hand"
        $btn.Foreground  = "#FFFFFF"

        $btnStack = New-Object System.Windows.Controls.StackPanel
        $btnStack.Margin = "10,8"
        $nameBlock = New-Object System.Windows.Controls.TextBlock
        $nameBlock.Text = $t.Name
        $nameBlock.FontSize = 12
        $nameBlock.FontWeight = "SemiBold"
        $nameBlock.TextWrapping = "Wrap"
        $authorBlock = New-Object System.Windows.Controls.TextBlock
        $authorBlock.Text = "by $($t.Author)"
        $authorBlock.FontSize = 9
        $authorBlock.Opacity = 0.7
        $authorBlock.TextWrapping = "Wrap"
        $authorBlock.Margin = "0,2,0,0"
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = $t.Desc
        $descBlock.FontSize = 10
        $descBlock.Opacity = 0.5
        $descBlock.TextWrapping = "Wrap"
        $descBlock.Margin = "0,3,0,0"
        $btnStack.Children.Add($nameBlock) | Out-Null
        $btnStack.Children.Add($authorBlock) | Out-Null
        $btnStack.Children.Add($descBlock) | Out-Null
        $btn.Content = $btnStack

        switch ($t.Type) {
            "Cmd"    { $btn.Background = "#1C1C1C" }
            "GitHub" { $btn.Background = "#1C1C1C" }
            "Web"    { $btn.Background = "#1C1C1C" }
            "Link"   { $btn.Background = "#1C1C1C" }
        }

        $btnBg    = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(0x1C, 0x1C, 0x1C))
        $btnScale = [Windows.Media.ScaleTransform]::new(1.0, 1.0)

        $btn.Template = [Windows.Markup.XamlReader]::Parse(
            "<ControlTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' TargetType='Button'>" +
            "  <Border CornerRadius='12' BorderThickness='0' RenderTransformOrigin='0.5,0.5'" +
            "          Background='{TemplateBinding Background}'" +
            "          RenderTransform='{TemplateBinding Tag}'>" +
            "    <ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center'/>" +
            "  </Border>" +
            "</ControlTemplate>"
        )
        $btn.Background = $btnBg
        $btn.Tag        = $btnScale

        $btn.Add_Loaded({
            param($sender, $e)
            $btn = $sender
            $btn.Add_MouseEnter({
                $btn.Background = "#241C08"
            })
            $btn.Add_MouseLeave({
                $btn.Background = "#1C1C1C"
            })
        })

        $btn.Add_Click({
            Start-ButtonAnimation -Button $btn
            switch ($t.Type) {
                "Cmd" {
                    Write-Log "Running command: $($t.Name)"
                    Set-Status "Running" "Executing $($t.Name)..." "BUSY"
                    Start-CmdToolCommand -Command $t.Command
                    Set-Status "Ready" "$($t.Name) executed." "IDLE"
                }
                "GitHub" {
                    Write-Log "Launching: $($t.Name)"
                    Set-Status "Downloading" "Getting $($t.Name)..." "BUSY"
                    Invoke-ToolDownloadAndRun -tool $t
                }
                "Web" {
                    Write-Log "Downloading: $($t.Name)"
                    Set-Status "Downloading" "Getting $($t.Name)..." "BUSY"
                    Invoke-WebToolDownload -tool $t
                }
                "Link" {
                    Write-Log "Opening: $($t.Name)"
                    Set-Status "Browser" "Opening $($t.Name)..." "IDLE"
                    Start-Process $t.URL
                }
            }
        })

        $wrap.Children.Add($btn) | Out-Null
    }

    $scroll.Content = $wrap
    $tab.Content = $scroll
    $ToolsTab.Items.Add($tab) | Out-Null
}

# ==============================================================================
# EVENT HANDLERS
# ==============================================================================
$window.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })

$MinBtn.Add_Click({
    $window.WindowState = "Minimized"
})

$CloseBtn.Add_Click({
    $window.Close()
})

$OpenFolderBtn.Add_Click({
    if (Test-Path $installDir) {
        Start-Process explorer.exe -ArgumentList "`"$installDir`""
    } else {
        [System.Windows.MessageBox]::Show("Install folder does not exist yet.", "Folder Not Found", "OK", "Information")
    }
})

$ClearCacheBtn.Add_Click({
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
        Write-Log "Cache cleared."
        [System.Windows.MessageBox]::Show("Download cache cleared.", "Cache Cleared", "OK", "Information")
    } else {
        [System.Windows.MessageBox]::Show("No cache to clear.", "Cache Empty", "OK", "Information")
    }
})

$OpenCmdBtn.Add_Click({
    Start-Process cmd.exe
})

# ==============================================================================
# SHOW WINDOW
# ==============================================================================
$window.ShowDialog() | Out-Null
