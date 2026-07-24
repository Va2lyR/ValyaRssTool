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
# TOOL DATA - MERGED FROM BOTH FILES WITH AUTHOR CREDITS
# ==============================================================================
$ToolData = @(
    # From CheesySSTool
    @{ Name="PrefetchView"; Desc="Parses prefetch, extracts file info"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/PrefetchView/releases/latest" },
    @{ Name="BAMReveal"; Desc="Parses BAM forensic artefact"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/BAMReveal/releases/latest" },
    @{ Name="StringsParser"; Desc="Strings + YARA + signatures scanner"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/StringsParser/releases/latest" },
    @{ Name="Fileless"; Desc="Detects fileless via eventlog + memdump"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/Fileless/releases/latest" },
    @{ Name="DPS-Analyzer"; Desc="Analyzes DPS memory"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/latest" },
    @{ Name="UserAssistView"; Desc="Parses UserAssist registry artifact"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest" },
    @{ Name="JournalParser"; Desc="Parses NTFS USNJournal entries"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/JournalParser/releases/latest" },
    @{ Name="InjGen"; Desc="Detects JNI/JVMTI memory injections"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/InjGen/releases/latest" },
    @{ Name="USBDetector"; Desc="Detects USB device history"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/USBDetector/releases/latest" },
    @{ Name="PFTrace"; Desc="Rundll32/Regsvr32 prefetch analysis"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/PFTrace/releases/latest" },
    @{ Name="CheckDeletedUSN"; Desc="Compares USN timestamp vs boot time"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest" },
    @{ Name="JARParser"; Desc="Parses JAR prefetch, DcomLaunch strings"; Category="Orbdiff"; Author="Orbdiff"; Type="GitHub"; URL="https://github.com/Orbdiff/JARParser/releases/latest" },
    @{ Name="BAM-parser"; Desc="Parses BAM entries for execution history"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/BAM-parser/releases/latest" },
    @{ Name="PathsParser"; Desc="Extracts and analyzes executable paths"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/PathsParser/releases/latest" },
    @{ Name="JournalTrace"; Desc="Traces file activity via USN journal"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/JournalTrace/releases/latest" },
    @{ Name="KernelLiveDumpTool"; Desc="Captures live kernel memory dump"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/latest" },
    @{ Name="BamDeletedKeys"; Desc="Finds deleted BAM registry keys"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/BamDeletedKeys/releases/latest" },
    @{ Name="Espouken Tool"; Desc="All-in-one SS forensics toolkit"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/Tool/releases/latest" },
    @{ Name="pcasvc-executed"; Desc="Extracts PCA service execution records"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/pcasvc-executed/releases/latest" },
    @{ Name="process-parser"; Desc="Parses process execution artefacts"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/process-parser/releases/latest" },
    @{ Name="prefetch-parser"; Desc="Parses Windows prefetch files"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/prefetch-parser/releases/latest" },
    @{ Name="ActivitiesCache"; Desc="Parses ActivitiesCache execution history"; Category="Spokwn"; Author="spokwn"; Type="GitHub"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest" },
    @{ Name="MeowDoomsdayFucker"; Desc="Detects Doomsday cheat artefacts"; Category="Tonynoh"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases/latest" },
    @{ Name="MeowModAnalyzer"; Desc="Analyzes mod files for suspicious content"; Category="Tonynoh"; Author="MeowTonynoh"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')" },
    @{ Name="MeowResolver"; Desc="Resolves obfuscated strings in binaries"; Category="Tonynoh"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest" },
    @{ Name="MeowNovowareFucker"; Desc="Detects Novoware cheat artefacts"; Category="Tonynoh"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/releases/latest" },
    @{ Name="MeowImportsChecker"; Desc="Checks PE imports for suspicious DLLs"; Category="Tonynoh"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest" },
    @{ Name="MeowClientsFucker"; Desc="Detects known cheat client artefacts"; Category="Tonynoh"; Author="MeowTonynoh"; Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowClientFucker/releases/latest" },
    @{ Name="PSHunter"; Desc="Hunts suspicious PowerShell activity"; Category="Praiselily"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/PSHunter/releases/latest" },
    @{ Name="AltDetector"; Desc="Detects alternate account artefacts"; Category="Praiselily"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/AltDetector/releases/latest" },
    @{ Name="WeHateFakers"; Desc="Checks hotspot / tethering logs"; Category="Praiselily"; Author="praiselily"; Type="Cmd"; Command="iwr https://raw.githubusercontent.com/praiselily/WeHateFakers/refs/heads/main/HotspotLogs.ps1 | iex" },
    @{ Name="CommonDirectories"; Desc="Lists files in common suspicious dirs"; Category="Praiselily"; Author="praiselily"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/CommonDirectories.ps1')" },
    @{ Name="HarddiskConverter"; Desc="Converts harddisk identifiers for review"; Category="Praiselily"; Author="praiselily"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/HarddiskConverter.ps1')" },
    @{ Name="Services"; Desc="Lists and analyzes running services"; Category="Praiselily"; Author="praiselily"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1')" },
    @{ Name="SignedScheduledTasks"; Desc="Finds unsigned / suspicious scheduled tasks"; Category="Praiselily"; Author="praiselily"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks.ps1')" },
    @{ Name="RL ModAnalyzer"; Desc="Analyzes mod files for cheat indicators"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/latest" },
    @{ Name="RL TaskSentinel"; Desc="Monitors scheduled tasks for anomalies"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/latest" },
    @{ Name="RL AltChecker"; Desc="Checks for alternate account indicators"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/latest" },
    @{ Name="ComputerActivityView"; Desc="Timeline of computer activity events"; Category="Others"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/computer_activity_view.html" },
    @{ Name="AmcacheParser"; Desc="Parses AMCache with YARA + signatures"; Category="Others"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/AmcacheParser.zip" },
    @{ Name="SystemInformer"; Desc="Advanced process and kernel inspector"; Category="Others"; Author="winsiderss"; Type="Link"; URL="https://www.systeminformer.com/canary" },
    @{ Name="DIE-engine"; Desc="Detects file type, packer, compiler"; Category="Others"; Author="horsicq"; Type="Web"; URL="https://github.com/horsicq/DIE-engine/releases" },
    @{ Name="DQRKIS-FUCKER"; Desc="Detects DQRKIS cheat artefacts"; Category="Others"; Author="cheesecatlol"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')" },
    @{ Name="MacroDetector"; Desc="Detects macro / clicker software traces"; Category="Others"; Author="NiccBlahh"; Type="Cmd"; Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1')" },
    @{ Name="Jarabel"; Desc="Locates .jar files with detailed checks"; Category="Others"; Author="nay-cat"; Type="GitHub"; URL="https://github.com/nay-cat/Jarabel/releases/latest" },
    @{ Name="Luyten"; Desc="Open source Java decompiler GUI (Procyon)"; Category="Others"; Author="deathmarine"; Type="GitHub"; URL="https://github.com/deathmarine/Luyten/releases/latest" },
    @{ Name="VMAware"; Desc="Advanced VM detection library and tool"; Category="Others"; Author="kernelwernel"; Type="GitHub"; URL="https://github.com/kernelwernel/VMAware/releases/latest" },
    @{ Name="Velociraptor"; Desc="Endpoint DFIR and threat hunting agent"; Category="Others"; Author="Velocidex"; Type="GitHub"; URL="https://github.com/Velocidex/velociraptor/releases/latest" },
    @{ Name="NTFS Parser"; Desc="NTFS forensics: MFT, Bitlocker, USN"; Category="Others"; Author="thewhiteninja"; Type="GitHub"; URL="https://github.com/thewhiteninja/ntfstool/releases/latest" },
    @{ Name="Hayabusa"; Desc="Fast forensics timeline generator"; Category="Others"; Author="Yamato-Security"; Type="GitHub"; URL="https://github.com/Yamato-Security/hayabusa/releases/latest" },
    @{ Name="Everything"; Desc="Instant filename search engine for Windows"; Category="Others"; Author="voidtools"; Type="Link"; URL="https://www.voidtools.com/downloads/" },
    @{ Name="HxD"; Desc="Fast hex editor with disk and RAM editing"; Category="Others"; Author="mh-nexus"; Type="Link"; URL="https://mh-nexus.de/en/hxd/" },
    @{ Name="bstrings"; Desc="Searches strings with regex + YARA"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/bstrings.zip" },
    @{ Name="JLECmd"; Desc="Parses Jump List files (CLI)"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/JLECmd.zip" },
    @{ Name="JumpListExplorer"; Desc="GUI explorer for Jump List artefacts"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip" },
    @{ Name="MFTECmd"; Desc="Parses MFT, UsnJrnl, LogFile, Boot"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip" },
    @{ Name="PECmd"; Desc="Parses Windows prefetch files (CLI)"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/PECmd.zip" },
    @{ Name="RecentFileCacheParser"; Desc="Parses RecentFileCache.bcf artefact"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip" },
    @{ Name="RegistryExplorer"; Desc="GUI explorer for registry hives"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip" },
    @{ Name="ShellBagsExplorer"; Desc="GUI explorer for ShellBags artefacts"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip" },
    @{ Name="SrumECmd"; Desc="Parses SRUM database for usage data"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/SrumECmd.zip" },
    @{ Name="TimelineExplorer"; Desc="GUI viewer for CSV timeline output"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="Web"; URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip" },
    @{ Name="FullEventLogView"; Desc="Views all Windows event log entries"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/fulleventlogview.zip" },
    @{ Name="NetworkUsageView"; Desc="Shows network usage per process"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/networkusageview.zip" },
    @{ Name="BrowserDownloadsView"; Desc="Lists all browser download history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/browserdownloadsview.zip" },
    @{ Name="AlternateStreamView"; Desc="Reveals hidden NTFS alternate streams"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/alternatestreamview.zip" },
    @{ Name="USBDeview"; Desc="Lists all USB devices ever connected"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/usbdeview.zip" },
    @{ Name="OpenSaveFilesView"; Desc="Shows files opened/saved via dialogs"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/opensavefilesview.zip" },
    @{ Name="ExecutedProgramsList"; Desc="Lists programs run from various sources"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/executedprogramslist.zip" },
    @{ Name="TaskSchedulerView"; Desc="Views all scheduled tasks and history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/taskschedulerview.zip" },
    @{ Name="JumpListsView"; Desc="Views Jump List recent/frequent files"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/jumplistsview.zip" },
    @{ Name="WinPrefetchView"; Desc="Views Windows prefetch file details"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/winprefetchview.zip" },
    @{ Name="RegScanner"; Desc="Scans registry for values / patterns"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/regscanner.zip" },
    @{ Name="ShellBagsView"; Desc="Views ShellBags folder access history"; Category="NirSoft"; Author="NirSoft"; Type="Web"; URL="https://www.nirsoft.net/utils/shellbagsview.zip" },
    @{ Name="NET 9.0"; Desc="Microsoft .NET 9 SDK runtime"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://download.visualstudio.microsoft.com/download/pr/92dba916-bc51-4e76-8b0e-d41d37ce5fa4/ab08f3e95bf7a3d3da336a7e8c8eca63/dotnet-sdk-9.0.203-win-x64.exe" },
    @{ Name="NET 10.0"; Desc="Microsoft .NET 10 runtime"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://download.visualstudio.microsoft.com/download/pr/b3f93f0e-9e5e-4b4c-a4c4-36db0c4b0e3e/dotnet-runtime-10.0.0-win-x64.exe" },
    @{ Name="VSRedist"; Desc="Visual C++ redistributable (x64)"; Category="Dependencies"; Author="Microsoft"; Type="Web"; URL="https://aka.ms/vs/17/release/vc_redist.x64.exe" },
    
    # Additional tools from SSToolsHub
    @{ Name="WinPrefetchView_x64.zip"; Desc="View prefetch files"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/winprefetchview-x64.zip" },
    @{ Name="LastActivityView.zip"; Desc="List recent user activity"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/lastactivityview.zip" },
    @{ Name="UsbDriveLog.zip"; Desc="Show USB drive history"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/usbdrivelog.zip" },
    @{ Name="WinDefLogView.zip"; Desc="Windows Defender log viewer"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/windeflogview.zip" },
    @{ Name="UninstallView_x64.zip"; Desc="List installed programs"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/uninstallview-x64.zip" },
    @{ Name="LoadedDllsView_x64.zip"; Desc="Loaded DLL list"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/loadeddllsview-x64.zip" },
    @{ Name="Clipboardic.zip"; Desc="Clipboard history viewer"; Category="NirSoft"; Author="NirSoft"; Type="GitHub"; URL="https://www.nirsoft.net/utils/clipboardic.zip" },
    @{ Name="WxTCmd.zip"; Desc="Windows Timeline database"; Category="Zimmerman"; Author="Eric Zimmerman"; Type="GitHub"; URL="https://download.ericzimmermanstools.com/net6/WxTCmd.zip" },
    @{ Name="Echo-Journal.exe"; Desc="Journal analysis tool"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/Echo-Anticheat/Echo-Journal/raw/main/echo-journal.exe" },
    @{ Name="UserAssist.exe"; Desc="UserAssist registry viewer"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-userassist.exe" },
    @{ Name="UsbTool.exe"; Desc="USB record analysis"; Category="Echo"; Author="Echo"; Type="GitHub"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-usb.exe" },
    @{ Name="RedLotusModAnalyzer.exe"; Desc="Mod analysis tool"; Category="RedLotus"; Author="ItzIceHere"; Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe" },
    @{ Name="PathDuzenleyicisiV2.exe"; Desc="Path organizer v2"; Category="TRSSCommunity"; Author="TRSSCommunity"; Type="GitHub"; URL="https://github.com/trSScommunity/PathDuzenleyiciV2/raw/refs/heads/main/PathDuzenleyicisiV2.exe" },
    @{ Name="MzHunter.exe"; Desc="MZ header scanner"; Category="TRSSCommunity"; Author="TRSSCommunity"; Type="GitHub"; URL="https://github.com/trSScommunity/MZHunter/raw/refs/heads/main/MzHunter.exe" },
    @{ Name="MandarinTool.jar"; Desc="Multi SS tool / JAR decompiler"; Category="TRSSCommunity"; Author="Mehmetyll"; Type="GitHub"; URL="https://github.com/Mehmetyll/Mandarin-Tool/releases/download/Mandarin-Tool/MandarinTool.jar" },
    @{ Name="MagnetEncryptedDiskDetector.exe"; Desc="Encrypted disk detector"; Category="Magnet"; Author="Magnet"; Type="GitHub"; URL="https://go.magnetforensics.com/e/52162/MagnetEncryptedDiskDetector/kpt9bg/1663239667/h/LtXFtTL-Soawv5C1oL3BIEghi7e1Lx93yesZLR--Ok0" },
    @{ Name="MRCv120.exe"; Desc="RAM dump tool"; Category="Magnet"; Author="Magnet"; Type="GitHub"; URL="https://go.magnetforensics.com/e/52162/mail-utm-campaign-UTMC-0000044/llr4bg/1663358653/h/4kZ9Y4i2yPRqBzuQMrywA_v5bfkpG3rG8gEiSWrYU70" },
    @{ Name="FTK_Imager_4.7.1.exe"; Desc="Disk imaging tool"; Category="Forensics"; Author="AccessData"; Type="GitHub"; URL="https://archive.org/download/access-data-ftk-imager-4.7.1/AccessData_FTK_Imager_4.7.1.exe" },
    @{ Name="hayabusa-3.6.0-win-aarch64.zip"; Desc="Windows event log analyzer"; Category="Forensics"; Author="Yamato-Security"; Type="GitHub"; URL="https://github.com/Yamato-Security/hayabusa/releases/download/v3.6.0/hayabusa-3.6.0-win-aarch64.zip" },
    @{ Name="ProcessHacker-Setup.exe"; Desc="Process hacker"; Category="SystemTools"; Author="winsiderss"; Type="GitHub"; URL="https://sourceforge.net/projects/processhacker/files/latest/download" },
    @{ Name="InjGen.exe"; Desc="Injection detection tool"; Category="Analysis"; Author="NotRequiem"; Type="GitHub"; URL="https://github.com/NotRequiem/InjGen/releases/download/v2.0/InjGen.exe" },
    @{ Name="dpsanalyzer.exe"; Desc="DPS analyzer"; Category="Analysis"; Author="nay-cat"; Type="GitHub"; URL="https://github.com/nay-cat/dpsanalyzer/releases/download/1.3/dpsanalyzer.exe" },
    @{ Name="DIE_engine_portable.zip"; Desc="Detect-It-Easy PE analyzer"; Category="Analysis"; Author="horsicq"; Type="GitHub"; URL="https://github.com/horsicq/DIE-engine/releases/download/3.09/die_win64_portable_3.09_x64.zip" },
    @{ Name="Jarabel.Light.exe"; Desc="JAR analysis tool"; Category="Misc"; Author="nay-cat"; Type="GitHub"; URL="https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe" },
    @{ Name="Unicode.exe"; Desc="Unicode character analyzer"; Category="Misc"; Author="RRancio"; Type="GitHub"; URL="https://github.com/RRancio/Exec/raw/main/Files/Unicode.exe" },
    @{ Name="CachedProgramsList.exe"; Desc="Cache program list"; Category="Misc"; Author="ponei"; Type="GitHub"; URL="https://github.com/ponei/CachedProgramsList/releases/download/1.1/CachedProgramsList.exe" },
    @{ Name="TimeChangeDetect.exe"; Desc="System time change detector"; Category="Misc"; Author="santiagolin"; Type="GitHub"; URL="https://github.com/santiagolin/TimeChangeDetect/releases/download/1.0/TimeChangeDetect.exe" },
    @{ Name="HardlinkFinder.exe"; Desc="Hardlink detection"; Category="Misc"; Author="praiselily"; Type="GitHub"; URL="https://github.com/praiselily/HardlinkFinder/releases/download/Tools/hardlink.exe" },
    @{ Name="TeslaPro-MacroFinder.exe"; Desc="Macro finder tool"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/TeslaProMacroFinder/releases/latest" },
    @{ Name="TeslaPro-DoomsdayDetector.exe"; Desc="Doomsday detector"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/DoomsdayDetector/releases/latest" },
    @{ Name="TeslaPro-VPNFinder.exe"; Desc="VPN finder"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/VPNChecker/releases/latest" },
    @{ Name="TeslaPro-GhostClientFucker.exe"; Desc="Ghost client detector"; Category="TeslaPro"; Author="TeslaPro"; Type="GitHub"; URL="https://github.com/TeslaPros/GhostClientFucker/releases/latest" },
    @{ Name="Xeinn-SSTools.exe"; Desc="Xeinn SS tools"; Category="Xeinn"; Author="Xeinn"; Type="GitHub"; URL="https://github.com/Xeinn-Software/Xeinn-SS-Tools-Downloader/releases/latest" }
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
        <SolidColorBrush x:Key="Accent"     Color="#8B0000"/>
        <SolidColorBrush x:Key="AccentDim"  Color="#5C0000"/>
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
                                <Setter Property="Background" Value="#2A0000"/>
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
                                <Setter Property="Background" Value="#338B0000"/>
                                <Setter Property="Foreground" Value="#8B0000"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="{StaticResource MainBg}" BorderBrush="#8B0000" BorderThickness="1" CornerRadius="12">
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
                <Border Grid.Column="0" Background="{StaticResource SidebarBg}" BorderBrush="#8B0000" BorderThickness="0,0,1,0">
                    <StackPanel Margin="10,14,10,14">

                        <Border Background="#050505" CornerRadius="10" Margin="0,0,0,14" Padding="0,10">
                            <TextBlock x:Name="CatBlock"
                                Text="   /\_____/\  &#x0a;  /  ^   ^  \ &#x0a; (  =  w  =  )&#x0a;  \  (___) / &#x0a;  /  |   |  \ &#x0a; (__|   |__)"
                                FontFamily="Consolas" FontSize="9"
                                Foreground="{StaticResource Accent}"
                                HorizontalAlignment="Center"
                                TextAlignment="Left"
                                xml:space="preserve"/>
                        </Border>

                        <TextBlock Text="ACTIONS" FontSize="9" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="4,0,0,6"/>
                        <Button x:Name="OpenFolderBtn" Content="  Open Install Folder"      Style="{StaticResource SideBtn}"/>
                        <Button x:Name="ClearCacheBtn" Content="  Clear Downloaded Files"   Style="{StaticResource SideBtn}"/>
                        <Button x:Name="OpenCmdBtn"    Content="  Open CMD"                 Style="{StaticResource SideBtn}"/>

                        <Separator Background="#8B0000" Margin="0,10,0,10"/>

                        <TextBlock Text="CREDITS" FontSize="9" FontWeight="Bold" Foreground="{StaticResource TextMuted}" Margin="4,0,0,6"/>
                        <TextBlock Text="Made by Va2lyR" FontSize="11" FontWeight="SemiBold" Foreground="{StaticResource TextMain}" Margin="4,2,0,4"/>
                        <TextBlock Text="Discord: Va2lyR" FontSize="10" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" Margin="4,1,0,0"/>
                        <TextBlock Text="GitHub: Va2lyR" FontSize="10" Foreground="{StaticResource TextMuted}" TextWrapping="Wrap" Margin="4,1,0,0"/>

                        <Separator Background="#8B0000" Margin="0,10,0,10"/>
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
                            <Border Grid.Column="1" Background="#1A0000" CornerRadius="8" Padding="10,4" VerticalAlignment="Center">
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
                                                        <Setter TargetName="TabBorder" Property="Background" Value="#2A0000"/>
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
                            <TextBlock Text="ACTIVITY CONSOLE" FontSize="9" FontWeight="Bold" Foreground="#8B0000" FontFamily="Consolas" Margin="0,0,0,4"/>
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
    <Border Background="#000000" BorderBrush="#8B0000" BorderThickness="1" CornerRadius="12" Padding="24">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="56"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0">
                <TextBlock Text="ValyaRssTool" FontSize="20" FontWeight="Bold" Foreground="#8B0000" Margin="0,0,0,12"/>
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
                        Background="Transparent" Foreground="#FFFFFF" BorderBrush="#8B0000" BorderThickness="1"
                        Cursor="Hand" FontSize="13"/>
                <Button x:Name="AcceptBtn" Grid.Column="2" Content="Accept &amp; Continue" Height="40"
                        Background="#1A1A1A" Foreground="#8B0000" BorderBrush="#8B0000" BorderThickness="1"
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

    $asset = Get-GitHubAssetUrl -ReleaseUrl $tool.URL
    if (-not $asset) {
        Write-Log "No .exe/.zip/.cmd/.bat asset found for $name - opening browser."
        Set-Status "Ready" "No asset found, opened GitHub." "IDLE"
        Start-Process $tool.URL
        return
    }

    $destDir  = "$installDir\$cat\$name"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $destFile = "$destDir\$($asset.name)"

    if (Test-Path $destFile) {
        Write-Log "Cached: $($asset.name) - skipping download."
    } else {
        Write-Log "Downloading $($asset.name)..."
        try {
            Save-UrlToFile -Uri $asset.url -OutFile $destFile
            Write-Log "Download complete: $($asset.name)"
        } catch {
            $err = $_
            Write-Log "Download failed: $err"
            Set-Status "Error" "Download failed for $name." "ERR"
            Start-Process $tool.URL
            return
        }
    }

    if ($asset.name -match "\.zip$") {
        Write-Log "Extracting $($asset.name)..."
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

    if ($url -match "\.(zip|exe|cmd|bat)$") {
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

    $flashColors = @("#8B0000", "#FFFFFF", "#8B0000", "#FF0000")
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
$Categories = @("Orbdiff","Spokwn","Tonynoh","Praiselily","RedLotus","Zimmerman","NirSoft","Dependencies","Others","Echo","TRSSCommunity","Magnet","Forensics","SystemTools","Analysis","Misc","TeslaPro","Meow","Xeinn")

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
            "Cmd"    { $btn.Background = "#1A0000" }
            "GitHub" { $btn.Background = "#1A0000" }
            "Web"    { $btn.Background = "#1A0000" }
            "Link"   { $btn.Background = "#1A0000" }
        }

        $btnBg    = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(0x1A, 0x00, 0x00))
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
                $btn.Background = "#2A0000"
            })
            $btn.Add_MouseLeave({
                $btn.Background = "#1A0000"
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

