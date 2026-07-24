<#
================================================================================
  ValyaRSSer.ps1  —  Ultimate SS Forensics Suite  —  v2.0 Premium
================================================================================
  ONE-LINER CMD COMMAND (for GitHub deployment):
    powershell.exe -NoP -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/YOURUSER/ValyaRSSer/main/ValyaRSSer.ps1 | iex"

  DISCORD:  _iaec
================================================================================
#>

[CmdletBinding()]
param(
    [switch]$SkipDisclaimer,
    [string]$RemoteRepo = ""
)

$VRS_GitHubUser   = "Va2lyR"
$VRS_GitHubRepo   = "ValyaRssTool"
$VRS_GitHubBranch = "main"
$VRS_DefaultRawUrl = "https://raw.githubusercontent.com/$VRS_GitHubUser/$VRS_GitHubRepo/$VRS_GitHubBranch/ValyaRSSer.ps1"

# ==============================================================================
# STAGE 1: BOOTSTRAP - if running from inline (iex), write a local cache copy
# ==============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($RemoteRepo) {
    $Script:RemoteBase = $RemoteRepo.TrimEnd('/')
}

$Bootstrap_Mode = -not $MyInvocation.MyCommand.Path
if ($Bootstrap_Mode) {
    $localCache = Join-Path $env:TEMP "ValyaRSSer_Latest.ps1"
    if ($Script:RemoteBase) {
        $dlUrl = "$Script:RemoteBase/ValyaRSSer.ps1"
    } else {
        $dlUrl = $VRS_DefaultRawUrl
    }
    try {
        Write-Host "[ValyaRSSer] Bootstrap mode - fetching latest build..." -ForegroundColor Cyan
        Write-Host "[ValyaRSSer] Source: $dlUrl" -ForegroundColor Gray
        $content = Invoke-RestMethod -Uri $dlUrl -UseBasicParsing -ErrorAction Stop
        Set-Content -LiteralPath $localCache -Value $content -Encoding UTF8 -Force
        Write-Host "[ValyaRSSer] Cached locally - launching UI..." -ForegroundColor Green
        & powershell.exe -NoExit -ExecutionPolicy Bypass -File "`"$localCache`"" -SkipDisclaimer:$SkipDisclaimer.IsPresent
        exit
    } catch {
        Write-Warning "Remote bootstrap failed. Running embedded copy..."
    }
}

# ==============================================================================
# STAGE 2: ASSEMBLIES & ENVIRONMENT
# ==============================================================================
try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Xaml
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
} catch {
    Write-Warning "Some assemblies failed to load: $_"
}

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

$installDir = "$env:USERPROFILE\Downloads\ValyaRSSer"
$logPath    = Join-Path $env:TEMP "valyarser_$(Get-Date -Format 'yyyyMMdd').log"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# ==============================================================================
# STAGE 3: MASTER TOOL DATABASE  —  Merged CheesySSTool + SSToolsHub + Extras
# ==============================================================================

$global:VRS_ToolData = @(
    # ──────────────── BUILT-IN SCANNERS (Premium) ────────────────
    @{ Name="Doomsday Finder v3";       Desc="Prefetch + USN Byte-Signature Anti-Cheat Scanner"; Category="Scanners"; Type="BuiltIn"; BuiltIn="DoomsdayFinder"; Icon="☢️" },
    @{ Name="Ghost Client Scanner";     Desc="Mod Pattern + Modrinth Verified Cheat Detector";   Category="Scanners"; Type="BuiltIn"; BuiltIn="GhostClientScanner"; Icon="👻" },
    @{ Name="Cyemer Scanner v2";        Desc="Cyemer Slither Client Detection + USN Journal";    Category="Scanners"; Type="BuiltIn"; BuiltIn="CyemerScanner"; Icon="🐍" },
    @{ Name="Velaris Scanner";          Desc="Velaris + Generic Cheat Multi-Signature Scanner";   Category="Scanners"; Type="BuiltIn"; BuiltIn="VelarisScanner"; Icon="⚡" },
    @{ Name="Heated Mod Analyzer";      Desc="Deep Mod File Source + Reputation Scanner";         Category="Scanners"; Type="BuiltIn"; BuiltIn="HeatedModAnalyzer"; Icon="🔥" },
    @{ Name="Hacked Clients Detector";  Desc="Multi-Client Signature DB (Meteor/Aristois/Wurst…)";Category="Scanners"; Type="BuiltIn"; BuiltIn="HackedClientsDetector"; Icon="🛡️" },
    @{ Name="DQRKIS Detector";          Desc="DQRKIS Cheat Client Real-Time Detector";           Category="Scanners"; Type="BuiltIn"; BuiltIn="DQRKISDetector"; Icon="🟣" },
    @{ Name="Journal Trace Analyzer";   Desc="USN Journal Activity Download + Analyzer";         Category="Scanners"; Type="BuiltIn"; BuiltIn="JournalTrace"; Icon="📜" },

    # ──────────────── ORBDIFF TOOLS ────────────────
    @{ Name="PrefetchView pv++";        Desc="Detailed Prefetch Analyzer";                         Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/PrefetchView/releases/latest"; Icon="📂" },
    @{ Name="BAMReveal";                Desc="Parses BAM Forensic Artefact";                        Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/BAMReveal/releases/latest"; Icon="🔑" },
    @{ Name="StringsParser";            Desc="Strings + YARA + Signatures Scanner";                 Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/StringsParser/releases/latest"; Icon="🔍" },
    @{ Name="Fileless Detector";        Desc="Fileless via Eventlog + Memdump";                    Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/Fileless/releases/latest"; Icon="📡" },
    @{ Name="DPS-Analyzer";             Desc="Analyzes DPS Memory";                                 Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/latest"; Icon="💾" },
    @{ Name="UserAssistView";           Desc="Parses UserAssist Registry Artifact";                Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest"; Icon="👤" },
    @{ Name="JournalParser";            Desc="Parses NTFS USNJournal Entries";                     Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/JournalParser/releases/latest"; Icon="📰" },
    @{ Name="InjGen v2";                Desc="JNI/JVMTI Memory Injection Detector";                Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/InjGen/releases/latest"; Icon="💉" },
    @{ Name="USBDetector";              Desc="Detects USB Device History";                          Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/USBDetector/releases/latest"; Icon="🔌" },
    @{ Name="PFTrace";                  Desc="Rundll32/Regsvr32 Prefetch Analysis";                 Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/PFTrace/releases/latest"; Icon="🧭" },
    @{ Name="CheckDeletedUSN";          Desc="Compares USN Timestamp vs Boot Time";                 Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest"; Icon="🗑️" },
    @{ Name="JARParser";                Desc="Parses JAR Prefetch + DcomLaunch Strings";            Category="Orbdiff";     Type="GitHub"; URL="https://github.com/Orbdiff/JARParser/releases/latest"; Icon="☕" },

    # ──────────────── SPOKWN TOOLS ────────────────
    @{ Name="BAM-parser";               Desc="Parses BAM Entries for Execution History";           Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/BAM-parser/releases/latest"; Icon="📖" },
    @{ Name="PathsParser";              Desc="Extracts and Analyzes Executable Paths";              Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/PathsParser/releases/latest"; Icon="🛤️" },
    @{ Name="JournalTrace";             Desc="Traces File Activity via USN Journal";               Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/JournalTrace/releases/latest"; Icon="🗺️" },
    @{ Name="KernelLiveDumpTool";       Desc="Captures Live Kernel Memory Dump";                    Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/latest"; Icon="🧠" },
    @{ Name="BamDeletedKeys";           Desc="Finds Deleted BAM Registry Keys";                     Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/BamDeletedKeys/releases/latest"; Icon="🔎" },
    @{ Name="Espouken Tool";            Desc="All-in-One SS Forensics Toolkit";                     Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/Tool/releases/latest"; Icon="🛠️" },
    @{ Name="pcasvc-executed";          Desc="Extracts PCA Service Execution Records";             Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/pcasvc-executed/releases/latest"; Icon="📊" },
    @{ Name="process-parser";           Desc="Parses Process Execution Artefacts";                  Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/process-parser/releases/latest"; Icon="⚙️" },
    @{ Name="prefetch-parser";          Desc="Parses Windows Prefetch Files";                       Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/prefetch-parser/releases/latest"; Icon="⏱️" },
    @{ Name="ActivitiesCache";          Desc="Parses ActivitiesCache Execution History";           Category="Spokwn";      Type="GitHub"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest"; Icon="📅" },

    # ──────────────── TONYNOH TOOLS ────────────────
    @{ Name="MeowDoomsdayFucker";       Desc="Doomsday Cheat Artefacts Detector";                   Category="Tonynoh";     Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases/latest"; Icon="😼" },
    @{ Name="MeowModAnalyzer";          Desc="Suspicious Mod Content Analyzer (Cloud)";             Category="Tonynoh";     Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')"; Icon="📋" },
    @{ Name="MeowResolver";             Desc="Obfuscated Strings in Binaries Resolver";             Category="Tonynoh";     Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest"; Icon="🧩" },
    @{ Name="MeowNovowareFucker";       Desc="Novoware Cheat Artefacts Detector";                   Category="Tonynoh";     Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/releases/latest"; Icon="🛸" },
    @{ Name="MeowImportsChecker";       Desc="PE Imports Suspicious DLL Checker";                   Category="Tonynoh";     Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest"; Icon="📦" },
    @{ Name="MeowClientsFucker";        Desc="Known Cheat Client Artefacts Detector";               Category="Tonynoh";     Type="GitHub"; URL="https://github.com/MeowTonynoh/MeowClientFucker/releases/latest"; Icon="🚫" },

    # ──────────────── PRAISELILY (lilith-ps) ────────────────
    @{ Name="PSHunter";                 Desc="Hunts Suspicious PowerShell Activity";                Category="Praiselily";  Type="GitHub"; URL="https://github.com/praiselily/PSHunter/releases/latest"; Icon="🔫" },
    @{ Name="AltDetector";              Desc="Detects Alternate Account Artefacts";                 Category="Praiselily";  Type="GitHub"; URL="https://github.com/praiselily/AltDetector/releases/latest"; Icon="🎭" },
    @{ Name="WeHateFakers";             Desc="Checks Hotspot / Tethering Logs (Cloud)";             Category="Praiselily";  Type="Cmd";    Command="iwr https://raw.githubusercontent.com/praiselily/WeHateFakers/refs/heads/main/HotspotLogs.ps1 | iex"; Icon="📶" },
    @{ Name="CommonDirectories";        Desc="Lists Files in Common Suspicious Dirs";               Category="Praiselily";  Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/CommonDirectories.ps1')"; Icon="📁" },
    @{ Name="HarddiskConverter";        Desc="Harddisk Identifiers Converter";                      Category="Praiselily";  Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/HarddiskConverter.ps1')"; Icon="💿" },
    @{ Name="Services Inspector";       Desc="Lists + Analyzes Running Services";                   Category="Praiselily";  Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1')"; Icon="🔧" },
    @{ Name="SignedScheduledTasks";     Desc="Unsigned / Suspicious Scheduled Tasks Finder";        Category="Praiselily";  Type="Cmd";    Command="Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks.ps1')"; Icon="📆" },

    # ──────────────── REDLOTUS TOOLS ────────────────
    @{ Name="RL ModAnalyzer";           Desc="Cheat Indicators Mod Analyzer";                       Category="RedLotus";    Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/latest"; Icon="🔴" },
    @{ Name="RL TaskSentinel";          Desc="Scheduled Tasks Anomalies Monitor";                   Category="RedLotus";    Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/latest"; Icon="🛡" },
    @{ Name="RL AltChecker";            Desc="Alternate Account Indicators Checker";                Category="RedLotus";    Type="GitHub"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/latest"; Icon="❓" },

    # ──────────────── ECHO TOOLS ────────────────
    @{ Name="Echo Journal";             Desc="Echo AntiCheat Journal Analyzer";                     Category="Echo";        Type="Web";    URL="https://github.com/Echo-Anticheat/Echo-Journal/raw/main/echo-journal.exe"; Icon="🌀" },
    @{ Name="Echo UserAssist";          Desc="Echo UserAssist Registry Viewer";                     Category="Echo";        Type="Web";    URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-userassist.exe"; Icon="📑" },
    @{ Name="Echo USB Tool";            Desc="Echo USB Record Analysis";                            Category="Echo";        Type="Web";    URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-usb.exe"; Icon="💽" },

    # ──────────────── TRSS COMMUNITY ────────────────
    @{ Name="PathDuzenleyici V2";       Desc="Advanced Path Organizer";                             Category="Community";   Type="Web";    URL="https://github.com/trSScommunity/PathDuzenleyiciV2/raw/refs/heads/main/PathDuzenleyicisiV2.exe"; Icon="🧭" },
    @{ Name="MzHunter";                 Desc="MZ Header Suspicious Scanner";                        Category="Community";   Type="Web";    URL="https://github.com/trSScommunity/MZHunter/raw/refs/heads/main/MzHunter.exe"; Icon="🎯" },
    @{ Name="Mandarin Tool";            Desc="Multi-SS JAR Decompiler";                             Category="Community";   Type="Web";    URL="https://github.com/Mehmetyll/Mandarin-Tool/releases/download/Mandarin-Tool/MandarinTool.jar"; Icon="🏮" },

    # ──────────────── ZIMMERMAN TOOLS ────────────────
    @{ Name="bstrings";                 Desc="Search Strings with Regex + YARA";                    Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/bstrings.zip"; Icon="🔤" },
    @{ Name="JLECmd";                   Desc="Parses Jump List Files (CLI)";                        Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/JLECmd.zip"; Icon="➡️" },
    @{ Name="JumpListExplorer";         Desc="GUI Explorer for Jump List Artefacts";                Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip"; Icon="🪂" },
    @{ Name="MFTECmd";                  Desc="Parses MFT, UsnJrnl, LogFile, Boot";                 Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip"; Icon="🗃️" },
    @{ Name="PECmd";                    Desc="Parses Windows Prefetch Files (CLI)";                 Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/PECmd.zip"; Icon="🏃" },
    @{ Name="RecentFileCacheParser";    Desc="Parses RecentFileCache.bcf Artefact";                 Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip"; Icon="🕒" },
    @{ Name="RegistryExplorer";         Desc="GUI Explorer for Registry Hives";                     Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip"; Icon="🗝️" },
    @{ Name="ShellBagsExplorer";        Desc="GUI Explorer for ShellBags Artefacts";                Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip"; Icon="👜" },
    @{ Name="SrumECmd";                 Desc="Parses SRUM Database for Usage Data";                 Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/SrumECmd.zip"; Icon="📡" },
    @{ Name="TimelineExplorer";         Desc="GUI Viewer for CSV Timeline Output";                  Category="Zimmerman";   Type="Web";    URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip"; Icon="📈" },

    # ──────────────── NIRSOFT TOOLS ────────────────
    @{ Name="FullEventLogView";         Desc="Views All Windows Event Log Entries";                 Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/fulleventlogview.zip"; Icon="📜" },
    @{ Name="NetworkUsageView";         Desc="Shows Network Usage per Process";                     Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/networkusageview.zip"; Icon="🌐" },
    @{ Name="BrowserDownloadsView";     Desc="Lists All Browser Download History";                  Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/browserdownloadsview.zip"; Icon="⬇️" },
    @{ Name="AlternateStreamView";      Desc="Reveals Hidden NTFS Alternate Streams";               Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/alternatestreamview.zip"; Icon="🎚️" },
    @{ Name="USBDeview";                Desc="Lists All USB Devices Ever Connected";               Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/usbdeview.zip"; Icon="🔌" },
    @{ Name="OpenSaveFilesView";        Desc="Shows Files Opened/Saved via Dialogs";                Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/opensavefilesview.zip"; Icon="💾" },
    @{ Name="ExecutedProgramsList";     Desc="Lists Programs Run from Various Sources";             Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/executedprogramslist.zip"; Icon="▶️" },
    @{ Name="TaskSchedulerView";        Desc="Views All Scheduled Tasks + History";                 Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/taskschedulerview.zip"; Icon="🗓️" },
    @{ Name="JumpListsView";            Desc="Views Jump List Recent/Frequent Files";               Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/jumplistsview.zip"; Icon="📋" },
    @{ Name="WinPrefetchView";          Desc="Views Windows Prefetch File Details";                 Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/winprefetchview.zip"; Icon="⏱️" },
    @{ Name="RegScanner";               Desc="Scans Registry for Values / Patterns";               Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/regscanner.zip"; Icon="🔍" },
    @{ Name="ShellBagsView";            Desc="Views ShellBags Folder Access History";              Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/shellbagsview.zip"; Icon="👜" },
    @{ Name="LastActivityView";         Desc="List Recent User Activity Timeline";                  Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/lastactivityview.zip"; Icon="⚪" },
    @{ Name="UsbDriveLog";              Desc="Show USB Drive Connection History";                   Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/usbdrivelog.zip"; Icon="💾" },
    @{ Name="UninstallView";            Desc="List Installed Programs with Details";               Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/uninstallview-x64.zip"; Icon="🗑️" },
    @{ Name="LoadedDllsView";           Desc="View Loaded DLL per Process";                         Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/loadeddllsview-x64.zip"; Icon="🔗" },
    @{ Name="Clipboardic";              Desc="Clipboard History Viewer";                            Category="NirSoft";     Type="Web";    URL="https://www.nirsoft.net/utils/clipboardic.zip"; Icon="📋" },

    # ──────────────── OTHERS ────────────────
    @{ Name="ComputerActivityView";     Desc="Timeline of Computer Activity Events";                Category="Others";      Type="Web";    URL="https://www.nirsoft.net/utils/computer_activity_view.html"; Icon="📊" },
    @{ Name="SystemInformer";           Desc="Advanced Process and Kernel Inspector";              Category="Others";      Type="Link";   URL="https://www.systeminformer.com/canary"; Icon="⚙️" },
    @{ Name="DIE-engine";               Desc="Detects File Type, Packer, Compiler";                 Category="Others";      Type="Web";    URL="https://github.com/horsicq/DIE-engine/releases"; Icon="🆔" },
    @{ Name="Jarabel Light";            Desc="Locates .jar Files with Detailed Checks";            Category="Others";      Type="GitHub"; URL="https://github.com/nay-cat/Jarabel/releases/latest"; Icon="☕" },
    @{ Name="Luyten";                   Desc="Java Decompiler GUI (Procyon)";                       Category="Others";      Type="GitHub"; URL="https://github.com/deathmarine/Luyten/releases/latest"; Icon="🔓" },
    @{ Name="VMAware";                  Desc="Advanced VM Detection Library + Tool";                Category="Others";      Type="GitHub"; URL="https://github.com/kernelwernel/VMAware/releases/latest"; Icon="🖥️" },
    @{ Name="Velociraptor";             Desc="Endpoint DFIR and Threat Hunting Agent";             Category="Others";      Type="GitHub"; URL="https://github.com/Velocidex/velociraptor/releases/latest"; Icon="🦖" },
    @{ Name="NTFS Parser";              Desc="NTFS Forensics: MFT, Bitlocker, USN";                 Category="Others";      Type="GitHub"; URL="https://github.com/thewhiteninja/ntfstool/releases/latest"; Icon="🔩" },
    @{ Name="Hayabusa";                 Desc="Fast Forensics Timeline Generator";                   Category="Others";      Type="GitHub"; URL="https://github.com/Yamato-Security/hayabusa/releases/latest"; Icon="🕵️" },
    @{ Name="Everything";               Desc="Instant Filename Search Engine for Windows";         Category="Others";      Type="Link";   URL="https://www.voidtools.com/downloads/"; Icon="🔎" },
    @{ Name="HxD";                      Desc="Fast Hex Editor with Disk + RAM Editing";            Category="Others";      Type="Link";   URL="https://mh-nexus.de/en/hxd/"; Icon="✏️" },
    @{ Name="CachedProgramsList";       Desc="Cached Program Enumeration List";                     Category="Others";      Type="Web";    URL="https://github.com/ponei/CachedProgramsList/releases/download/1.1/CachedProgramsList.exe"; Icon="📚" },
    @{ Name="TimeChangeDetect";         Desc="System Time Change Detector";                         Category="Others";      Type="Web";    URL="https://github.com/santiagolin/TimeChangeDetect/releases/download/1.0/TimeChangeDetect.exe"; Icon="⌚" },
    @{ Name="Unicode Analyzer";         Desc="Unicode Character Analyzer Tool";                     Category="Others";      Type="Web";    URL="https://github.com/RRancio/Exec/raw/main/Files/Unicode.exe"; Icon="🔤" },

    # ──────────────── DEPENDENCIES ────────────────
    @{ Name="NET 9.0 SDK";              Desc="Microsoft .NET 9 SDK Runtime";                        Category="Dependencies";Type="Web";    URL="https://download.visualstudio.microsoft.com/download/pr/92dba916-bc51-4e76-8b0e-d41d37ce5fa4/ab08f3e95bf7a3d3da336a7e8c8eca63/dotnet-sdk-9.0.203-win-x64.exe"; Icon="🔷" },
    @{ Name="NET 10.0 Runtime";         Desc="Microsoft .NET 10 Runtime";                           Category="Dependencies";Type="Web";    URL="https://download.visualstudio.microsoft.com/download/pr/b3f93f0e-9e5e-4b4c-a4c4-36db0c4b0e3e/dotnet-runtime-10.0.0-win-x64.exe"; Icon="🔷" },
    @{ Name="VSRedist x64";             Desc="Visual C++ Redistributable (x64)";                    Category="Dependencies";Type="Web";    URL="https://aka.ms/vs/17/release/vc_redist.x64.exe"; Icon="🔶" }
)

$global:VRS_Categories = @("Scanners","Orbdiff","Spokwn","Tonynoh","Praiselily","RedLotus","Echo","Community","Zimmerman","NirSoft","Dependencies","Others")

# ==============================================================================
# STAGE 4: DISCLAIMER WINDOW (Premium)
# ==============================================================================

function Show-VRDisclaimer {
    [xml]$dx = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ValyaRSSer" Width="640" Height="660" WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
    WindowStyle="None" AllowsTransparency="True" Background="Transparent" FontFamily="Segoe UI">
  <Border Background="#05050F" BorderBrush="#3730A3" BorderThickness="1" CornerRadius="16" Padding="30">
    <Border.Effect><DropShadowEffect Color="#6366F1" BlurRadius="50" ShadowDepth="0" Opacity="0.55"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="64"/></Grid.RowDefinitions>
      <StackPanel Grid.Row="0">
        <Border Background="#0E0E22" CornerRadius="12" Padding="18,14" Margin="0,0,0,18">
          <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#6366F1" Offset="0"/><GradientStop Color="#06B6D4" Offset="0.5"/><GradientStop Color="#8B5CF6" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
          <Border.BorderThickness>1.5</Border.BorderThickness>
          <StackPanel>
            <StackPanel Orientation="Horizontal"><TextBlock Text="✦" FontSize="32" FontWeight="Bold" Foreground="#06B6D4"/><TextBlock Text="  ValyaRSSer" FontSize="28" FontWeight="Bold" Foreground="#FFFFFF" Margin="4,0,0,0" VerticalAlignment="Center"/><TextBlock Text=" v2.0" FontSize="15" Foreground="#A5B4FC" VerticalAlignment="Bottom" Margin="6,0,0,4"/></StackPanel>
            <TextBlock Text="ULTIMATE SS FORENSICS SUITE  •  PREMIUM EDITION" FontSize="10" FontWeight="SemiBold" Foreground="#8B5CF6" Margin="2,8,0,0"/>
          </StackPanel>
        </Border>
        <Border Height="1.5" CornerRadius="1" Margin="0,0,0,18"><Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="Transparent" Offset="0"/><GradientStop Color="#4338CA" Offset="0.5"/><GradientStop Color="Transparent" Offset="1"/></LinearGradientBrush></Border.Background></Border>
        <TextBlock TextWrapping="Wrap" Foreground="#E5E7EB" FontSize="13.5" Margin="0,0,0,14" LineHeight="22"
          Text="All programs are downloaded automatically from their official GitHub repositories and saved in a neatly organised folder. None of your information is ever collected or modified."/>
        <TextBlock TextWrapping="Wrap" Foreground="#E5E7EB" FontSize="13.5" Margin="0,0,0,18" LineHeight="22"
          Text="Each tool is developed and maintained by its own author. We take no responsibility for anything that may be found regarding these tools in the future."/>
        <Border Background="#0A0F1F" CornerRadius="10" Padding="16,14" Margin="0,0,0,10">
          <Border.BorderBrush><SolidColorBrush Color="#1E293B"/></Border.BorderBrush>
          <StackPanel>
            <TextBlock Text="⚡  8 BUILT-IN PREMIUM SCANNERS" FontSize="11" FontWeight="Bold" Foreground="#22D3EE" Margin="0,0,0,10"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <StackPanel Grid.Column="0">
                <TextBlock Text="☢  Doomsday Finder v3" Foreground="#FCA5A5" FontSize="11.5"/>
                <TextBlock Text="👻  Ghost Client Scanner" Foreground="#A78BFA" FontSize="11.5" Margin="0,4,0,0"/>
                <TextBlock Text="🐍  Cyemer Scanner" Foreground="#6EE7B7" FontSize="11.5" Margin="0,4,0,0"/>
                <TextBlock Text="⚡  Velaris Scanner" Foreground="#FCD34D" FontSize="11.5" Margin="0,4,0,0"/>
              </StackPanel>
              <StackPanel Grid.Column="1">
                <TextBlock Text="🔥  Heated Mod Analyzer" Foreground="#FB923C" FontSize="11.5"/>
                <TextBlock Text="🛡  Hacked Clients DB" Foreground="#93C5FD" FontSize="11.5" Margin="0,4,0,0"/>
                <TextBlock Text="🟣  DQRKIS Detector" Foreground="#F0ABFC" FontSize="11.5" Margin="0,4,0,0"/>
                <TextBlock Text="📜  Journal Trace" Foreground="#C4B5FD" FontSize="11.5" Margin="0,4,0,0"/>
              </StackPanel>
            </Grid>
          </StackPanel>
        </Border>
        <Border Background="#0F0E1F" CornerRadius="10" Padding="14,12" Margin="0,0,0,16">
          <StackPanel Orientation="Horizontal">
            <TextBlock Text="👤  Author Discord:" FontSize="12" Foreground="#94A3B8" VerticalAlignment="Center"/>
            <TextBlock Text="  _iaec" FontSize="14" FontWeight="Bold" Foreground="#FBBF24" VerticalAlignment="Center"/>
          </StackPanel>
        </Border>
        <TextBlock TextWrapping="Wrap" Foreground="#FFFFFF" FontSize="13.5" FontWeight="SemiBold"
          Text="To continue, you must agree with everything stated above."/>
      </StackPanel>
      <Grid Grid.Row="1" VerticalAlignment="Bottom">
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Button x:Name="VRCancel" Grid.Column="0" Content="Cancel" Height="48" Background="Transparent" Foreground="#94A3B8"
          BorderBrush="#2D2D5A" BorderThickness="1" Cursor="Hand" FontSize="14" FontWeight="SemiBold"/>
        <Button x:Name="VRAccept" Grid.Column="2" Content="✓  Accept &amp; Continue" Height="48" Cursor="Hand" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" BorderBrush="#6366F1" BorderThickness="1">
          <Button.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#4F46E5" Offset="0"/><GradientStop Color="#0891B2" Offset="1"/></LinearGradientBrush></Button.Background>
        </Button>
      </Grid>
    </Grid>
  </Border>
</Window>
"@
    $rdr = New-Object System.Xml.XmlNodeReader $dx
    $win = [Windows.Markup.XamlReader]::Load($rdr)
    $win.Add_MouseLeftButtonDown({ try { $win.DragMove() } catch {} })
    $cb = $win.FindName("VRCancel")
    $ab = $win.FindName("VRAccept")
    $res = $false
    $ab.Add_Click({ $script:VRS_DiscRes = $true; $win.Close() })
    $cb.Add_Click({ $script:VRS_DiscRes = $false; $win.Close() })
    $ab.Add_MouseEnter({ $ab.Background = [Windows.Media.BrushConverter]::new().ConvertFrom("#6366F1") })
    $ab.Add_MouseLeave({
        $b = New-Object System.Windows.Media.LinearGradientBrush
        $b.StartPoint = "0,0"; $b.EndPoint = "1,0"
        $b.GradientStops.Add((New-Object System.Windows.Media.GradientStop([Windows.Media.Color]::FromRgb(0x4F,0x46,0xE5), 0))) | Out-Null
        $b.GradientStops.Add((New-Object System.Windows.Media.GradientStop([Windows.Media.Color]::FromRgb(0x08,0x91,0xB2), 1))) | Out-Null
        $ab.Background = $b
    })
    $cb.Add_MouseEnter({ $cb.Foreground = "#FFFFFF"; $cb.Background = "#1A1A3D"; $cb.BorderBrush = "#64748B" })
    $cb.Add_MouseLeave({ $cb.Foreground = "#94A3B8"; $cb.Background = "Transparent"; $cb.BorderBrush = "#2D2D5A" })
    $win.ShowDialog() | Out-Null
    return $script:VRS_DiscRes
}

if (-not $SkipDisclaimer.IsPresent) {
    if (-not (Show-VRDisclaimer)) { exit }
}

# ==============================================================================
# STAGE 5: MAIN WINDOW XAML — GLASSMORPHISM + MODERN NAVIGATION
# ==============================================================================

[xml]$VRS_Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="ValyaRSSer v2.0" Width="1340" Height="860" MinWidth="1100" MinHeight="720"
  WindowStartupLocation="CenterScreen" ResizeMode="CanResizeWithGrip"
  WindowStyle="None" AllowsTransparency="True" Background="Transparent" FontFamily="Segoe UI">
  <Window.Resources>
    <SolidColorBrush x:Key="BgDeep"        Color="#050510"/>
    <SolidColorBrush x:Key="BgMid"         Color="#0B0B1F"/>
    <SolidColorBrush x:Key="BgRaise"       Color="#131330"/>
    <SolidColorBrush x:Key="BgCard"        Color="#161635"/>
    <SolidColorBrush x:Key="BorderSoft"    Color="#27275A"/>
    <SolidColorBrush x:Key="Accent1"       Color="#6366F1"/>
    <SolidColorBrush x:Key="Accent2"       Color="#06B6D4"/>
    <SolidColorBrush x:Key="Accent3"       Color="#8B5CF6"/>
    <SolidColorBrush x:Key="Gold"          Color="#FBBF24"/>
    <SolidColorBrush x:Key="Text1"         Color="#F8FAFC"/>
    <SolidColorBrush x:Key="Text2"         Color="#CBD5E1"/>
    <SolidColorBrush x:Key="Text3"         Color="#94A3B8"/>
    <SolidColorBrush x:Key="Text4"         Color="#64748B"/>
    <SolidColorBrush x:Key="ConsoleBg"     Color="#03030A"/>
    <SolidColorBrush x:Key="Ok"            Color="#10B981"/>
    <SolidColorBrush x:Key="Warn"          Color="#F59E0B"/>
    <SolidColorBrush x:Key="Fail"          Color="#EF4444"/>

    <Style x:Key="NavBtn" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{StaticResource Text3}"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Height" Value="42"/>
      <Setter Property="Margin" Value="0,2,0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="NB" Background="{TemplateBinding Background}" CornerRadius="9" Padding="14,0,10,0">
              <Border.RenderTransform><ScaleTransform CenterX="0.5" CenterY="0.5" ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="NB" Property="Background" Value="#1C1C40"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TTBtn" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{StaticResource Text4}"/>
      <Setter Property="Width" Value="46"/>
      <Setter Property="Height" Value="38"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="TB" Background="{TemplateBinding Background}" CornerRadius="7">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="TB" Property="Background" Value="#1F1F45"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="VRS_MainBorder" Background="{StaticResource BgDeep}" BorderBrush="#27275A" BorderThickness="1" CornerRadius="14">
    <Border.Effect><DropShadowEffect Color="#6366F1" BlurRadius="40" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="48"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="28"/>
      </Grid.RowDefinitions>

      <!-- ═══════════════ TITLE BAR ═══════════════ -->
      <Border Grid.Row="0" Background="#08081A" CornerRadius="14,14,0,0">
        <Grid Margin="16,0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
            <Border Width="30" Height="30" CornerRadius="8" Background="#0F172A" VerticalAlignment="Center">
              <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#6366F1" Offset="0"/><GradientStop Color="#06B6D4" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
              <Border.BorderThickness>1.5</Border.BorderThickness>
              <TextBlock Text="✦" FontSize="16" Foreground="#22D3EE" HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold"/>
            </Border>
            <TextBlock Text="  ValyaRSSer" FontSize="14" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center" Margin="8,0,0,0"/>
            <Border Background="#1E293B" CornerRadius="4" Padding="6,2" VerticalAlignment="Center" Margin="10,0,0,0">
              <TextBlock Text="PREMIUM v2.0" FontSize="9" FontWeight="Bold" Foreground="#22D3EE"/>
            </Border>
            <TextBlock Text="  Ultimate SS Forensics Suite" FontSize="11" Foreground="#64748B" VerticalAlignment="Center" Margin="6,1,0,0"/>
          </StackPanel>
          <StackPanel Grid.Column="1" Orientation="Horizontal">
            <Button x:Name="VRS_MinBtn" Style="{StaticResource TTBtn}" Content="—"/>
            <Button x:Name="VRS_MaxBtn" Style="{StaticResource TTBtn}" Content="▢"/>
            <Button x:Name="VRS_CloseBtn" Style="{StaticResource TTBtn}" Content="✕"/>
          </StackPanel>
        </Grid>
      </Border>

      <!-- ═══════════════ MAIN BODY ═══════════════ -->
      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions><ColumnDefinition Width="256"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

        <!-- ─────── SIDEBAR ─────── -->
        <Border Grid.Column="0" Background="#08081A" BorderBrush="{StaticResource BorderSoft}" BorderThickness="0,0,1,0" CornerRadius="0,0,0,14">
          <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Background="Transparent">
            <StackPanel Margin="14,16,14,16">

              <!-- Profile Card -->
              <Border Background="#0B0F24" CornerRadius="12" Padding="14,14" Margin="0,0,0,16">
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#6366F1" Offset="0"/><GradientStop Color="#06B6D4" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <Border.BorderThickness>1</Border.BorderThickness>
                <StackPanel>
                  <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                    <Ellipse Width="42" Height="42" Stroke="#22D3EE" StrokeThickness="1.5">
                      <Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#1E1B4B" Offset="0"/><GradientStop Color="#312E81" Offset="1"/></LinearGradientBrush></Ellipse.Fill>
                    </Ellipse>
                    <StackPanel Margin="10,2,0,0">
                      <TextBlock Text="_iaec" FontSize="15" FontWeight="Bold" Foreground="#FBBF24"/>
                      <TextBlock Text="ValyaRSSer Dev" FontSize="10" Foreground="#94A3B8"/>
                    </StackPanel>
                  </StackPanel>
                  <Border Height="1" Background="#1E293B" CornerRadius="1" Margin="0,0,0,10"/>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0">
                      <TextBlock x:Name="VRS_ToolCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#22D3EE"/>
                      <TextBlock Text="Tools" FontSize="9" Foreground="#64748B"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1">
                      <TextBlock x:Name="VRS_CatCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#A78BFA"/>
                      <TextBlock Text="Categories" FontSize="9" Foreground="#64748B"/>
                    </StackPanel>
                  </Grid>
                </StackPanel>
              </Border>

              <TextBlock Text="QUICK ACTIONS" FontSize="9" FontWeight="Bold" Foreground="{StaticResource Text4}" Margin="4,0,0,8"/>
              <Button x:Name="VRS_OpenFolderBtn" Content="📁   Open Install Folder"     Style="{StaticResource NavBtn}"/>
              <Button x:Name="VRS_ClearCacheBtn" Content="🗑️   Clear Downloaded Files"  Style="{StaticResource NavBtn}"/>
              <Button x:Name="VRS_OpenPSBtn"     Content="💻   Open PowerShell"         Style="{StaticResource NavBtn}"/>
              <Button x:Name="VRS_RefreshBtn"    Content="🔄   Refresh All"              Style="{StaticResource NavBtn}"/>
              <Button x:Name="VRS_OneLinerBtn"   Content="📋   Copy One-Liner CMD"      Style="{StaticResource NavBtn}"/>

              <Border Height="1" Background="#1E293B" CornerRadius="1" Margin="4,14,4,14"/>

              <TextBlock Text="INFO" FontSize="9" FontWeight="Bold" Foreground="{StaticResource Text4}" Margin="4,0,0,8"/>
              <Border Background="#0B0F24" CornerRadius="10" Padding="12,12" Margin="0,0,0,8">
                <StackPanel>
                  <TextBlock Text="💬 Discord" FontSize="10" Foreground="#64748B"/>
                  <TextBlock Text="_iaec" FontSize="13" FontWeight="Bold" Foreground="#FBBF24" Margin="0,2,0,0"/>
                </StackPanel>
              </Border>
              <Border Background="#0B0F24" CornerRadius="10" Padding="12,12" Margin="0,0,0,8">
                <StackPanel>
                  <TextBlock Text="📦 Install Path" FontSize="10" Foreground="#64748B"/>
                  <TextBlock x:Name="VRS_InstallLbl" Text="" FontSize="10" Foreground="#93C5FD" Margin="0,2,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>
              <Border Background="#0B0F24" CornerRadius="10" Padding="12,12" Margin="0,0,0,8">
                <StackPanel>
                  <TextBlock Text="🎯 Categories" FontSize="10" Foreground="#64748B"/>
                  <TextBlock Text="8 Scanners + 11 Tool Groups" FontSize="10.5" Foreground="#A5B4FC" Margin="0,2,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>

            </StackPanel>
          </ScrollViewer>
        </Border>

        <!-- ─────── MAIN CONTENT ─────── -->
        <Grid Grid.Column="1" Margin="18,16,18,16">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="12"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="12"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="12"/>
            <RowDefinition Height="180"/>
          </Grid.RowDefinitions>

          <!-- Status Hero Card -->
          <Border Grid.Row="0" Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderSoft}" BorderThickness="1" CornerRadius="12" Padding="20,16">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock x:Name="VRS_StatusTitle" Text="Welcome to ValyaRSSer" FontSize="24" FontWeight="Bold" Foreground="#FFFFFF"/>
                <TextBlock x:Name="VRS_StatusSub"   Text="Premium SS Forensics Suite — Loading tools..." FontSize="12" Foreground="#94A3B8" Margin="0,5,0,0"/>
              </StackPanel>
              <Border Grid.Column="2" Background="#0B1024" CornerRadius="8" Padding="16,8" VerticalAlignment="Center">
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#6366F1" Offset="0"/><GradientStop Color="#06B6D4" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <Border.BorderThickness>1</Border.BorderThickness>
                <StackPanel Orientation="Horizontal">
                  <Ellipse Width="10" Height="10" Fill="#10B981" VerticalAlignment="Center" Margin="0,0,10,0">
                    <Ellipse.Style>
                      <Style TargetType="Ellipse">
                        <Style.Triggers>
                          <EventTrigger RoutedEvent="Loaded">
                            <BeginStoryboard><Storyboard>
                              <DoubleAnimation Storyboard.TargetProperty="Opacity" From="1" To="0.25" Duration="0:0:1.4" RepeatBehavior="Forever" AutoReverse="True"/>
                            </Storyboard></BeginStoryboard>
                          </EventTrigger>
                        </Style.Triggers>
                      </Style>
                    </Ellipse.Style>
                  </Ellipse>
                  <TextBlock x:Name="VRS_StatusBadge" Text="IDLE" FontSize="12.5" FontWeight="Bold" Foreground="#10B981" VerticalAlignment="Center"/>
                </StackPanel>
              </Border>
            </Grid>
          </Border>

          <!-- Search + Quick Filter Bar -->
          <Border Grid.Row="2" Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderSoft}" BorderThickness="1" CornerRadius="12" Padding="14,12">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Border Background="#0B0F24" CornerRadius="8" Padding="10,8">
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <TextBlock Text="🔍" FontSize="16" VerticalAlignment="Center" Foreground="#64748B"/>
                  <TextBox x:Name="VRS_SearchBox" Grid.Column="1" Background="Transparent" Foreground="#F1F5F9"
                    BorderThickness="0" FontSize="13" VerticalContentAlignment="Center" Padding="8,0,8,0"
                    Text="Search tools (name, desc, type, category)..." CaretBrush="#22D3EE"/>
                </Grid>
              </Border>
              <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                <TextBlock Text="👁   Quick Launch:" FontSize="11" Foreground="#94A3B8" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <Button x:Name="VRS_QDoom"   Content="☢ Doomsday" Height="34" Padding="12,0"  Margin="2,0" Background="#1E1B4B" Foreground="#FCA5A5" FontSize="11" FontWeight="SemiBold" BorderBrush="#7F1D1D" BorderThickness="1" Cursor="Hand"/>
                <Button x:Name="VRS_QGhost"  Content="👻 Ghost"    Height="34" Padding="12,0"  Margin="2,0" Background="#1E1B4B" Foreground="#C4B5FD" FontSize="11" FontWeight="SemiBold" BorderBrush="#5B21B6" BorderThickness="1" Cursor="Hand"/>
                <Button x:Name="VRS_QVel"    Content="⚡ Velaris"  Height="34" Padding="12,0"  Margin="2,0" Background="#1E1B4B" Foreground="#FCD34D" FontSize="11" FontWeight="SemiBold" BorderBrush="#B45309" BorderThickness="1" Cursor="Hand"/>
                <Button x:Name="VRS_QHack"   Content="🛡 Clients"  Height="34" Padding="12,0"  Margin="2,0" Background="#1E1B4B" Foreground="#93C5FD" FontSize="11" FontWeight="SemiBold" BorderBrush="#1D4ED8" BorderThickness="1" Cursor="Hand"/>
              </StackPanel>
            </Grid>
          </Border>

          <!-- TABS -->
          <Border Grid.Row="4" Background="{StaticResource BgCard}" BorderBrush="{StaticResource BorderSoft}" BorderThickness="1" CornerRadius="12">
            <TabControl x:Name="VRS_ToolsTab" Background="Transparent" BorderThickness="0" Padding="10,10,10,10">
              <TabControl.Resources>
                <Style TargetType="TabItem">
                  <Setter Property="Foreground" Value="#94A3B8"/>
                  <Setter Property="FontSize" Value="11"/>
                  <Setter Property="FontWeight" Value="SemiBold"/>
                  <Setter Property="Margin" Value="2,2,4,2"/>
                  <Setter Property="Cursor" Value="Hand"/>
                  <Setter Property="Template">
                    <Setter.Value>
                      <ControlTemplate TargetType="TabItem">
                        <Border x:Name="TiBr" Background="Transparent" CornerRadius="8" Padding="14,7,14,7">
                          <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                          <Trigger Property="IsSelected" Value="True">
                            <Setter TargetName="TiBr" Property="Background">
                              <Setter.Value><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#4F46E5" Offset="0"/><GradientStop Color="#0891B2" Offset="1"/></LinearGradientBrush></Setter.Value>
                            </Setter>
                            <Setter Property="Foreground" Value="#FFFFFF"/>
                          </Trigger>
                          <MultiTrigger>
                            <MultiTrigger.Conditions>
                              <Condition Property="IsMouseOver" Value="True"/>
                              <Condition Property="IsSelected" Value="False"/>
                            </MultiTrigger.Conditions>
                            <Setter TargetName="TiBr" Property="Background" Value="#1C1C40"/>
                            <Setter Property="Foreground" Value="#F8FAFC"/>
                          </MultiTrigger>
                        </ControlTemplate.Triggers>
                      </ControlTemplate>
                    </Setter.Value>
                  </Setter>
                </Style>
              </TabControl.Resources>
            </TabControl>
          </Border>

          <!-- CONSOLE -->
          <Border Grid.Row="6" Background="{StaticResource ConsoleBg}" BorderBrush="{StaticResource BorderSoft}" BorderThickness="1" CornerRadius="12" Padding="14,10">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="6"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="⚡ ACTIVITY CONSOLE" FontSize="9" FontWeight="Bold" Foreground="#22D3EE" FontFamily="Consolas"/>
                  <TextBlock x:Name="VRS_ConsoleStat" Text="  • Ready" FontSize="9" Foreground="#475569" FontFamily="Consolas" VerticalAlignment="Center"/>
                </StackPanel>
                <Button Grid.Column="1" x:Name="VRS_ClrLog" Content="Clear" Height="22" Padding="10,0" Background="Transparent" Foreground="#64748B"
                  FontSize="9" FontWeight="SemiBold" BorderBrush="#1E293B" BorderThickness="1" Cursor="Hand"/>
              </Grid>
              <TextBox x:Name="VRS_LogBox" Grid.Row="2" Background="Transparent" Foreground="#67E8F9"
                BorderThickness="0" FontFamily="Consolas" FontSize="11" IsReadOnly="True"
                VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                TextWrapping="NoWrap" Padding="4,2"/>
            </Grid>
          </Border>
        </Grid>
      </Grid>

      <!-- ═══════════════ STATUS BAR ═══════════════ -->
      <Border Grid.Row="2" Background="#08081A" BorderBrush="{StaticResource BorderSoft}" BorderThickness="0,1,0,0" CornerRadius="0,0,14,14">
        <Grid Margin="16,0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="16"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <TextBlock Text="© ValyaRSSer Premium  •  Crafted for SS Forensics" FontSize="10" Foreground="#475569" VerticalAlignment="Center"/>
          <TextBlock Grid.Column="1" Text="👤 _iaec" FontSize="10" FontWeight="Bold" Foreground="#FBBF24" VerticalAlignment="Center"/>
          <TextBlock Grid.Column="3" x:Name="VRS_Clock" Text="--:--:--" FontSize="10" Foreground="#64748B" FontFamily="Consolas" VerticalAlignment="Center"/>
        </Grid>
      </Border>
    </Grid>
  </Border>
</Window>
"@

# ==============================================================================
# STAGE 6: LOAD MAIN WINDOW & HOOK CONTROLS
# ==============================================================================

$VRS_reader = New-Object System.Xml.XmlNodeReader $VRS_Xaml
$global:VRS_Win = [Windows.Markup.XamlReader]::Load($VRS_reader)
$global:VRS_Win.Add_MouseLeftButtonDown({
    try { if ($_.Button -eq [System.Windows.Input.MouseButton]::Left) { $global:VRS_Win.DragMove() } } catch {}
})

function VRS-Get($n) { $global:VRS_Win.FindName($n) }

$VRS_CloseBtn    = VRS-Get "VRS_CloseBtn"
$VRS_MaxBtn      = VRS-Get "VRS_MaxBtn"
$VRS_MinBtn      = VRS-Get "VRS_MinBtn"
$VRS_StatusTitle = VRS-Get "VRS_StatusTitle"
$VRS_StatusSub   = VRS-Get "VRS_StatusSub"
$VRS_StatusBadge = VRS-Get "VRS_StatusBadge"
$VRS_LogBox      = VRS-Get "VRS_LogBox"
$VRS_ToolsTab    = VRS-Get "VRS_ToolsTab"
$VRS_SearchBox   = VRS-Get "VRS_SearchBox"
$VRS_InstallLbl  = VRS-Get "VRS_InstallLbl"
$VRS_ToolCount   = VRS-Get "VRS_ToolCount"
$VRS_CatCount    = VRS-Get "VRS_CatCount"
$VRS_ConsoleStat = VRS-Get "VRS_ConsoleStat"
$VRS_Clock       = VRS-Get "VRS_Clock"
$VRS_ClrLog      = VRS-Get "VRS_ClrLog"

$VRS_OpenFolderBtn = VRS-Get "VRS_OpenFolderBtn"
$VRS_ClearCacheBtn = VRS-Get "VRS_ClearCacheBtn"
$VRS_OpenPSBtn     = VRS-Get "VRS_OpenPSBtn"
$VRS_RefreshBtn    = VRS-Get "VRS_RefreshBtn"
$VRS_OneLinerBtn   = VRS-Get "VRS_OneLinerBtn"

$VRS_QDoom  = VRS-Get "VRS_QDoom"
$VRS_QGhost = VRS-Get "VRS_QGhost"
$VRS_QVel   = VRS-Get "VRS_QVel"
$VRS_QHack  = VRS-Get "VRS_QHack"

$VRS_InstallLbl.Text = $installDir
$VRS_ToolCount.Text  = $global:VRS_ToolData.Count
$VRS_CatCount.Text   = $global:VRS_Categories.Count

# ==============================================================================
# STAGE 7: CORE HELPERS
# ==============================================================================

function VRS-Log {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    $line = "[$time] $msg`r`n"
    if ($VRS_LogBox -and $VRS_LogBox.Dispatcher) {
        $VRS_LogBox.Dispatcher.Invoke([Action]{
            $VRS_LogBox.AppendText($line)
            $VRS_LogBox.ScrollToEnd()
            $VRS_ConsoleStat.Text = "  • Line: " + ($VRS_LogBox.LineCount)
        }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
    }
    Add-Content -Path $script:logPath -Value $line.TrimEnd() -ErrorAction SilentlyContinue
}

function VRS-SetStatus {
    param(
        [string]$title,
        [string]$sub,
        [string]$badge = "BUSY",
        [string]$fg    = "#F59E0B"
    )
    if (-not $VRS_StatusTitle) { return }
    $VRS_StatusTitle.Dispatcher.Invoke([Action]{
        $VRS_StatusTitle.Text = $title
        $VRS_StatusSub.Text   = $sub
        $VRS_StatusBadge.Text = $badge
        $VRS_StatusBadge.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom($fg)
    }) | Out-Null
}

function VRS-StartExe {
    param([string]$Path, [string]$wd)
    if (-not $wd) { $wd = Split-Path -Parent $Path }
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    switch ($ext) {
        { $_ -in ".cmd",".bat" } {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "`"$Path`"" -WorkingDirectory $wd -WindowStyle Normal
        }
        ".ps1" {
            Start-Process powershell.exe -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File","`"$Path`"" -WorkingDirectory $wd
        }
        default { Start-Process -FilePath $Path -WorkingDirectory $wd -WindowStyle Normal }
    }
}

function VRS-RunCmd {
    param([Parameter(Mandatory=$true)][string]$Command)
    $tmp = [System.IO.Path]::Combine($env:TEMP, "VRS_$([guid]::NewGuid().ToString('N')).ps1")
    Set-Content -LiteralPath $tmp -Value $Command -Encoding UTF8 -Force
    $sa = '/c start "ValyaRSSer Tool" powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File "' + $tmp + '"'
    Start-Process -FilePath "cmd.exe" -ArgumentList $sa -WindowStyle Hidden
}

function VRS-SaveFile {
    param([string]$Uri, [string]$OutFile)
    $tmp = "$OutFile.downloading"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "ValyaRSSer/2.0")
    try {
        $wc.DownloadFile($Uri, $tmp)
        if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force -ErrorAction Stop }
        Move-Item -LiteralPath $tmp -Destination $OutFile -Force -ErrorAction Stop
        return $true
    } catch {
        VRS-Log "Download ERROR: $($_.Exception.Message)"
        return $false
    } finally {
        $wc.Dispose()
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
}

function VRS-LaunchDir {
    param([string]$Directory, [string]$PreferredFile)
    if ($PreferredFile -and (Test-Path -LiteralPath $PreferredFile) -and ($PreferredFile -notmatch "\.zip$")) {
        VRS-Log "Launching: $(Split-Path -Leaf $PreferredFile)"
        VRS-StartExe -Path $PreferredFile
        return $true
    }
    $launchable = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match "^\.(exe|cmd|bat|ps1)$" } |
        Sort-Object @{ Expression = { if ($_.Extension -eq ".exe") { 0 } else { 1 } } }, FullName |
        Select-Object -First 1
    if ($launchable) {
        VRS-Log "Launching: $($launchable.Name)"
        VRS-StartExe -Path $launchable.FullName -wd $launchable.DirectoryName
        return $true
    }
    VRS-Log "No executable found, opening folder: $Directory"
    Start-Process -FilePath explorer.exe -ArgumentList "`"$Directory`""
    return $false
}

function VRS-GetGHAsset {
    param([string]$ReleaseUrl)
    if ($ReleaseUrl -match "github\.com/([^/]+)/([^/]+)/releases/tag/(.+)$") {
        $user = $Matches[1]; $repo = $Matches[2]
        $tag  = [Uri]::EscapeDataString(([Uri]::UnescapeDataString($Matches[3])).TrimEnd("/"))
        $api  = "https://api.github.com/repos/$user/$repo/releases/tags/$tag"
        try {
            $rel = Invoke-RestMethod -Uri $api -Headers @{"User-Agent"="ValyaRSSer/2.0"} -ErrorAction Stop
            $ast = $rel.assets | Where-Object { $_.name -match "\.(exe|zip|cmd|bat|ps1|msi)$" } | Select-Object -First 1
            if (-not $ast -and $rel.assets.Count -gt 0) { $ast = $rel.assets[0] }
            if ($ast) { return @{ url = $ast.browser_download_url; name = $ast.name } }
        } catch {
            VRS-Log "GitHub lookup: $($_.Exception.Message)"
        }
    }
    return $null
}

function VRS-RunGitHub {
    param($tool)
    VRS-Log "Fetching GitHub asset: $($tool.Name)..."
    $asset = VRS-GetGHAsset -ReleaseUrl $tool.URL
    if (-not $asset) {
        VRS-Log "No auto-asset, opening browser."
        VRS-SetStatus "Browser" "Opened $($tool.Name) release page" "IDLE" "#10B981"
        Start-Process $tool.URL
        return
    }
    $destDir  = "$installDir\$($tool.Category)\$($tool.Name)"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $destFile = "$destDir\$($asset.name)"
    if (Test-Path $destFile) {
        VRS-Log "Cached, skipped download: $($asset.name)"
    } else {
        VRS-Log "Downloading: $($asset.name)"
        VRS-SetStatus "Downloading" "Downloading $($tool.Name)..." "DL" "#F59E0B"
        if (-not (VRS-SaveFile -Uri $asset.url -OutFile $destFile)) {
            VRS-SetStatus "Error" "Download failed: $($tool.Name)" "ERROR" "#EF4444"
            Start-Process $tool.URL
            return
        }
        VRS-Log "Download complete."
    }
    if ($asset.name -match "\.zip$") {
        VRS-Log "Extracting archive..."
        try { Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop }
        catch { VRS-Log "Extract failed: $($_.Exception.Message)"; VRS-SetStatus "Error" "Extract failed" "ERROR" "#EF4444"; Start-Process explorer "`"$destDir`""; return }
    }
    [void](VRS-LaunchDir -Directory $destDir -PreferredFile $(if($asset.name -notmatch "\.zip$"){$destFile}else{$null}))
    VRS-SetStatus "Ready" "$($tool.Name) launched successfully" "IDLE" "#10B981"
}

function VRS-RunWeb {
    param($tool)
    $url = $tool.URL
    if ($url -match "\.(zip|exe|cmd|bat|ps1|msi|jar)$") {
        $fname = ($url -split "/")[-1]
        $destDir  = "$installDir\$($tool.Category)\$($tool.Name)"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        $destFile = "$destDir\$fname"
        if (Test-Path $destFile) { VRS-Log "Cached: $fname" }
        else {
            VRS-Log "Downloading: $fname"
            VRS-SetStatus "Downloading" "Downloading $($tool.Name)..." "DL" "#F59E0B"
            if (-not (VRS-SaveFile -Uri $url -OutFile $destFile)) {
                VRS-SetStatus "Error" "Download failed" "ERROR" "#EF4444"
                Start-Process $url
                return
            }
        }
        if ($fname -match "\.zip$") {
            try { Expand-Archive -Path $destFile -DestinationPath $destDir -Force -ErrorAction Stop }
            catch { VRS-Log "Extract failed"; VRS-SetStatus "Error" "Extract failed" "ERROR" "#EF4444"; return }
        }
        [void](VRS-LaunchDir -Directory $destDir -PreferredFile $(if($fname -notmatch "\.zip$"){$destFile}else{$null}))
        VRS-SetStatus "Ready" "$($tool.Name) launched" "IDLE" "#10B981"
    } else {
        VRS-Log "Opening browser: $url"
        VRS-SetStatus "Browser" "Opened $($tool.Name)" "IDLE" "#10B981"
        Start-Process $url
    }
}

# ==============================================================================
# STAGE 8: BUILT-IN PREMIUM SCANNERS
# ==============================================================================

function VRS-RunBuiltIn {
    param([Parameter(Mandatory=$true)][string]$Id, [string]$Name)
    switch ($Id) {
        "DoomsdayFinder"        { VRS-RunDoomsday }
        "GhostClientScanner"    { VRS-RunGhostScanner }
        "CyemerScanner"         { VRS-RunCyemer }
        "VelarisScanner"        { VRS-RunVelaris }
        "HeatedModAnalyzer"     { VRS-RunHeated }
        "HackedClientsDetector" { VRS-RunHackedClients }
        "DQRKISDetector"        { VRS-RunDqrkis }
        "JournalTrace"          { VRS-RunJournalTrace }
        default { VRS-Log "Unknown built-in ID: $Id" }
    }
}

function VRS-LaunchScript {
    param([string]$ScriptBody, [string]$TempName, [switch]$AsAdmin)
    $tmp = Join-Path $env:TEMP $TempName
    Set-Content -LiteralPath $tmp -Value $ScriptBody -Encoding UTF8 -Force
    if ($AsAdmin) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File","`"$tmp`""
    } else {
        Start-Process powershell.exe -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-File","`"$tmp`""
    }
}

# ───────────── 1) DOOMSDAY FINDER v3 ─────────────
$VRS_DoomsdayScript = @'
#Requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║          ✦ VALYARSSER — DOOMSDAY FINDER v3 (PREMIUM) ✦            ║" -ForegroundColor Magenta
Write-Host "    ║          Prefetch + USN Journal + Byte-Signature Scan              ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
function Test-Admin {
    $i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($i)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) { Write-Host "  [ERROR] Run as ADMINISTRATOR!" -ForegroundColor Red; Read-Host "`nPress Enter"; exit }
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class NtdllD {
    [DllImport("ntdll.dll")] public static extern uint RtlDecompressBufferEx(ushort F,byte[] U,int UZ,byte[] C,int CZ,out int FS,IntPtr W);
    [DllImport("ntdll.dll")] public static extern uint RtlGetCompressionWorkSpaceSize(ushort F,out uint A,out uint B);
    public static byte[] D(byte[] c){
        if(c.Length<8||c[0]!=0x4D||c[1]!=0x41||c[2]!=0x4D) return null;
        int s=BitConverter.ToInt32(c,4); uint a,b;
        if(RtlGetCompressionWorkSpaceSize(4,out a,out b)!=0) return null;
        IntPtr w=Marshal.AllocHGlobal((int)b); byte[] r=new byte[s];
        try { int fs; byte[] cd=new byte[c.Length-8]; Array.Copy(c,8,cd,0,cd.Length);
            if(RtlDecompressBufferEx(4,r,s,cd,cd.Length,out fs,w)!=0) return null; return r;
        } finally { Marshal.FreeHGlobal(w); }
    }
}
"@
$BP=@{
    P1="6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A160C14005C6588B800";
    P2="0C1504851D85160A6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A16";
    P3="5910071088544C2A2BB8004D3B033DA7000A2B1C03548402011C1008A1FFF61A9E000C1A110800A2000503AC04AC00000000000A0005004E000101FA000001D3"
}
$CP=@("net/java/f","net/java/g","net/java/h","net/java/i","net/java/k","net/java/l","net/java/m","net/java/r","net/java/s","net/java/t","net/java/y")
function H2B($h){ $b=New-Object byte[] ($h.Length/2); for($i=0;$i -lt $h.Length;$i+=2){$b[$i/2]=[Convert]::ToByte($h.Substring($i,2),16)}; return $b}
function BM($d,$p){$pl=$p.Length;$dl=$d.Length; for($i=0;$i -le $dl-$pl;$i++){$ok=$true; for($j=0;$j -lt $pl;$j++){if($d[$i+$j] -ne $p[$j]){$ok=$false;break}}; if($ok){return $true}}; return $false}
function GPV($d){if($d.Length -lt 8){return 0}; $s=[Text.Encoding]::ASCII.GetString($d,4,4); if($s -ne "SCCA"){return 0}; return [BitConverter]::ToUInt32($d,0)}
function GSI($f){
    try {
        $d=[IO.File]::ReadAllBytes($f)
        if($d[0] -eq 0x4D -and $d[1] -eq 0x41 -and $d[2] -eq 0x4D){ $d=[NtdllD]::D($d); if($d -eq $null){return @()} }
        if($d.Length -lt 108){return @()}
        $so=[BitConverter]::ToUInt32($d,100); $sz=[BitConverter]::ToUInt32($d,104)
        if($so -eq 0 -or $sz -eq 0 -or $so -ge $d.Length){return @()}
        $fs=@(); $pos=$so; $end=$so+$sz
        while($pos -lt $end -and $pos -lt $d.Length - 2){
            $np=$pos; while($np -lt $d.Length - 1){if($d[$np] -eq 0 -and $d[$np+1] -eq 0){break}; $np+=2}
            if($np -gt $pos){ $sl=$np-$pos; if($sl -gt 0 -and $sl -lt 2048){ try{$fn=[Text.Encoding]::Unicode.GetString($d,$pos,$sl); if($fn){$fs+=$fn}}catch{} } }
            $pos=$np+2; if($fs.Count -gt 1000){break}
        }
        return $fs
    } catch { return @() }
}
function TestZip($p){try{$s=[IO.File]::OpenRead($p);$r=New-Object IO.BinaryReader($s); if($s.Length -lt 2){$r.Close();$s.Close();return $false}; $a=$r.ReadByte();$b=$r.ReadByte(); $r.Close();$s.Close(); return ($a -eq 0x50 -and $b -eq 0x4B)}catch{return $false}}
function SLC($p){$out=@(); try{Add-Type -AN System.IO.Compression.FileSystem; $j=[IO.Compression.ZipFile]::OpenRead($p); foreach($e in $j.Entries){ if($e.FullName -like "*.class"){ $pr=$e.FullName -split '/'; $fn=$pr[-1]; $cn=$fn -replace '\.class$',''; if($cn -match '^[a-zA-Z]$'){$fp=($pr[0..($pr.Length-2)] -join '/')+"/"+$cn; $out+=$fp} }}; $j.Dispose()}catch{}; return $out}
function TDC($p){
    $r=[PSCustomObject]@{D=$false;C="NONE";B=@();CL=@();S=@();R=$false;E=$null}
    if(-not (Test-Path $p -PathType Leaf)){$r.E="missing"; return $r}
    try {
        $ext=[IO.Path]::GetExtension($p).ToLower(); $pk=TestZip $p
        if($pk -and $ext -ne ".jar"){$r.R=$true;$r.D=$true;$r.C="HIGH"}
        if(-not $pk){$r.E="nozip"; return $r}
        Add-Type -AN System.IO.Compression.FileSystem
        $j=[IO.Compression.ZipFile]::OpenRead($p); $cf=$j.Entries | ? {$_.FullName -like "*.class"}; $cc=$cf.Count
        if($cc -gt 30){$j.Dispose();$r.E="skip:$cc"; return $r}
        if($cc -eq 0){$j.Dispose();$r.E="noclass"; return $r}
        $all=@(); foreach($e in $cf){$st=$e.Open();$ms=New-Object IO.MemoryStream;$st.CopyTo($ms);$st.Close();$all+=$ms.ToArray()}
        $j.Dispose()
        foreach($k in $BP.Keys){$pb=H2B $BP[$k]; if(BM $all $pb){$r.B+=$k}}
        foreach($c in $CP){$cb=[Text.Encoding]::ASCII.GetBytes($c); if(BM $all $cb){$r.CL+=$c}}
        $r.S = SLC $p
        $b=$r.B.Count;$c=$r.CL.Count;$s=$r.S.Count
        if($b -ge 2){$r.D=$true;$r.C="HIGH"}
        elseif($b -eq 1 -and ($c -ge 5 -or $s -ge 5)){$r.D=$true;$r.C="MEDIUM"}
        elseif($b -eq 1){$r.D=$true;$r.C="LOW"}
        elseif($s -ge 8 -and $c -ge 3){$r.D=$true;$r.C="MEDIUM"}
        elseif($s -ge 5 -or $c -ge 5){$r.D=$true;$r.C="LOW"}
        if($r.R -and $r.C -eq "NONE"){$r.C="MEDIUM"}
    } catch {$r.E=$_.Exception.Message}
    return $r
}
$SP="C:\Windows\"+"Pre"+"fetch"
if(-not (Test-Path $SP)){ Write-Host "  [!] Prefetch dir missing" -ForegroundColor Red; Read-Host; exit }
$jf = Get-ChildItem -Path $SP -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue
if($jf.Count -eq 0){ Write-Host "  [!] No JAVA*.pf files found" -ForegroundColor Yellow; Read-Host; exit }
Write-Host "  [+] JAVA Prefetch files: $($jf.Count)" -ForegroundColor Green
Write-Host "  [*] Extracting file indexes..." -ForegroundColor Cyan
$all=@(); $mt=@{}; $ok=0
for($i=0;$i -lt $jf.Count;$i++){
    $f=$jf[$i]
    Write-Progress -Activity "Extracting Indexes" -Status "[$($i+1)/$($jf.Count)] $($f.Name)" -PercentComplete ((($i+1)/$jf.Count)*100)
    $idx=GSI $f.FullName
    if($idx.Count -eq 0){continue}; $ok++; $n=0
    foreach($p in $idx){ $n++
        if($p -match '\\VOLUME\{[^\}]+\}\\(.*)$'){$ap="C:\$($Matches[1])"; $all+=$ap; if(-not $mt.ContainsKey($ap)){$mt[$ap]=@{$f.Name=$n}}}
        else {$all+=$p; if(-not $mt.ContainsKey($p)){$mt[$p]=@{$f.Name=$n}}}
    }
}
Write-Progress -Activity "Extracting" -Completed
Write-Host "  [+] Parsed: $ok / $($jf.Count) | Paths: $($all.Count)" -ForegroundColor Green
$unique=$all | Select-Object -Unique
Write-Host "  [+] Unique paths: $($unique.Count)" -ForegroundColor Green
Write-Host "  [*] Resolving on-disk..." -ForegroundColor Cyan
$ex=@(); $drv=Get-PSDrive -PSProvider FileSystem | ? {$_.Root -match '^[A-Z]:\\$'} | % {$_.Root.Substring(0,1)}
for($i=0;$i -lt $unique.Count;$i++){
    $p=$unique[$i]; $fp=$null
    Write-Progress -Activity "Resolving Paths" -Status "[$($i+1)/$($unique.Count)]" -PercentComplete ((($i+1)/$unique.Count)*100)
    if(Test-Path $p -PathType Leaf){$fp=$p}
    else {
        if($p -match '^[A-Z]:\\(.*)$'){$rel=$Matches[1]; foreach($d in $drv){$tp="$d`:\$rel"; if(Test-Path $tp -PathType Leaf){$fp=$tp; break}}}
    }
    if($fp){ $sz=(Get-Item $fp -ErrorAction SilentlyContinue).Length; if($sz -ge 200KB -and $sz -le 15MB){$ex[$p]=$fp} }
}
Write-Progress -Activity "Resolving" -Completed
Write-Host "  [+] Existing in-range: $($ex.Count)" -ForegroundColor Green
if($ex.Count -eq 0){ Write-Host "  [!] Nothing to scan" -ForegroundColor Yellow; Read-Host; exit }
Write-Host ""; Write-Host "  [*] Scanning for Doomsday..." -ForegroundColor Cyan
$D=@(); $sc=0; $sk=0; $keys=@($ex.Keys)
for($i=0;$i -lt $keys.Count;$i++){
    $k=$keys[$i]; $ap=$ex[$k]; $sc++
    Write-Progress -Activity "Scanning" -Status "[$sc/$($keys.Count)]" -PercentComplete ((($sc)/$keys.Count)*100)
    Write-Host "`r  [$sc/$($keys.Count)]" -NoNewline -ForegroundColor Cyan
    try {
        $res = TDC $ap
        if($res.E -like "skip:*"){$sk++}
        if($res.D){
            Write-Host "`r                                              `r" -NoNewline
            $src = ($mt[$k].Keys -join ", ")
            $D += [PSCustomObject]@{P=$ap;Src=$src;C=$res.C;R=$res.R;B=$res.B.Count;CL=$res.CL.Count;S=$res.S.Count}
            Write-Host "  [!] DETECTED: $ap" -ForegroundColor Red
            $col = if($res.C -eq "HIGH"){"Red"} elseif($res.C -eq "MEDIUM"){"Yellow"} else {"Gray"}
            Write-Host "      Confidence: $($res.C)" -ForegroundColor $col
            if($res.R){Write-Host "      Renamed JAR: YES" -ForegroundColor Red}
            if($res.B.Count -gt 0){Write-Host "      Byte signatures: $($res.B.Count)" -ForegroundColor Red}
            if($res.CL.Count -gt 0){Write-Host "      Class patterns: $($res.CL.Count)" -ForegroundColor Yellow}
            if($res.S.Count -gt 0){Write-Host "      Single-letter classes: $($res.S.Count)" -ForegroundColor Yellow}
        }
    } catch {}
}
Write-Host "`r                                              `r"
Write-Progress -Activity "Scanning" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SCAN COMPLETE • $sc scanned • $sk skipped • $($D.Count) flagged" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
if($D.Count -gt 0){
    Write-Host "  ⛔ DOOMSDAY CLIENT DETECTED — $($D.Count) finding(s)" -ForegroundColor Red
    $z=1
    foreach($d in $D){
        Write-Host ""; Write-Host "  [$z] $($d.P)" -ForegroundColor White
        Write-Host "      Sources: $($d.Src)" -ForegroundColor Gray
        $col = if($d.C -eq "HIGH"){"Red"} elseif($d.C -eq "MEDIUM"){"Yellow"} else {"Gray"}
        Write-Host "      Confidence: $($d.C)" -ForegroundColor $col
        if($d.R){Write-Host "      ⚠ Renamed JAR" -ForegroundColor Red}
        if($d.B -gt 0){Write-Host "      Byte patterns: $($d.B)" -ForegroundColor Red}
        if($d.CL -gt 0){Write-Host "      Class matches: $($d.CL)" -ForegroundColor Yellow}
        if($d.S -gt 0){Write-Host "      Single-letter: $($d.S)" -ForegroundColor Yellow}
        $z++
    }
} else {
    Write-Host "  ✅ No Doomsday Client signatures found" -ForegroundColor Green
}
Write-Host ""; Read-Host "  Press Enter to close"
'@

function VRS-RunDoomsday {
    VRS-Log "[>] Launching Doomsday Finder v3 (Admin)"
    VRS-SetStatus "Running" "Doomsday Finder v3 scanning..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_DoomsdayScript -TempName "VRS_Doomsday_v3.ps1" -AsAdmin
    VRS-SetStatus "Ready" "Doomsday Finder v3 launched (Admin)" "IDLE" "#10B981"
}

# ───────────── 2) GHOST CLIENT SCANNER ─────────────
$VRS_GhostScript = @'
[Console]::OutputEncoding = [Text.Encoding]::UTF8; chcp 65001 | Out-Null; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║        ✦ VALYARSSER — GHOST CLIENT SCANNER (PREMIUM) ✦            ║" -ForegroundColor Magenta
Write-Host "    ║        Mod Pattern DB + Modrinth Verification + Source Scan        ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
$def="$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
Write-Host "  [?] Mods folder (Enter = default)" -ForegroundColor Gray
Write-Host "      Default: $def" -ForegroundColor DarkGray
$in = Read-Host "  Path"
$MP = if([string]::IsNullOrWhiteSpace($in)){$def}else{$in.Trim()}
Write-Host ""
if(-not (Test-Path $MP -PathType Container)){ Write-Host "  [ERROR] Path invalid!" -ForegroundColor Red; Read-Host; exit }
Write-Host "  [►] Scanning: $MP" -ForegroundColor Green; Write-Host ""
Add-Type -AssemblyName System.IO.Compression.FileSystem
$PATS=@("AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","AutoHitCrystal","AutoPot","AutoTotem","AutoArmor","InventoryTotem",
    "JumpReset","LegitTotem","PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","AxeSpam","WebMacro","FastPlace","WalksyOptimizer",
    "WalskyOptimizer","WalksyCrystalOptimizerMod","Donut","Replace Mod","ShieldDisabler","SilentAim","Totem Hit","Wtap","FakeLag",
    "BlockESP","dev.krypton","Virgin","AntiMissClick","LagReach","PopSwitch","SprintReset","ChestSteal","AntiBot","ElytraSwap","FastXP",
    "Refill","AirAnchor","jnativehook","FakeInv","HoverTotem","AutoClicker","AutoFirework","PackSpoof","Antiknockback","catlean","Argon",
    "AuthBypass","Asteria","Prestige","AutoEat","AutoMine","MaceSwap","DoubleAnchor","AutoTPA","BaseFinder","Xenon","gypsy","DubbelKeybinds",
    "Grim","grim","BowAim","Criticals","Fakenick","FakeItem","invsee","ItemExploit","Hellion","hellion","dev.gambleclient","obfuscatedAuth","xyz.greaj")
$CSTR=@("AutoCrystal","AutoAnchor","DoubleAnchor","anchortweaks","AirAnchor","AutoTotem","autototem","InventoryTotem","HoverTotem","AutoPot",
    "AutoArmor","ShieldDisabler","ShieldBreaker","AutoDoubleHand","AutoClicker","AutoMace","MaceSwap","SpearSwap","Donut","JumpReset",
    "axespam","AimAssist","aimassist","triggerbot","SilentRotations","FakeInv","FakeLag","pingspoof","webmacro","AntiWeb","AutoWeb",
    "selfdestruct","WalksyCrystalOptimizerMod","WalksyOptimizer","AutoFirework","ElytraSwap","FastXP","FastExp","PackSpoof","AuthBypass",
    "BaseFinder","invsee","ItemExploit","FreezePlayer")
$FRAME=@{"meteor-client"="Meteor";"meteorclient"="Meteor";"meteordevelopment"="Meteor";"vape.gg"="Vape";"vapeclient"="Vape";
    "novaclient"="Nova";"liquidbounce"="LiquidBounce";"fdp-client"="FDP";"aristois"="Aristois";"impactclient"="Impact";
    "futureClient"="Future";"rusherhack"="RusherHack";"DubbelKeybinds"="DubbelKeybinds";"doublekeybinds"="DubbelKeybinds"}
$RX=[regex]::new('(?<![A-Za-z])('+($PATS -join '|')+')(?![A-Za-z])',[Text.RegularExpressions.RegexOptions]::Compiled)
function SHA1($p){return (Get-FileHash $p -Algorithm SHA1).Hash}
function MODRINTH($h){
    try { $v=Invoke-RestMethod "https://api.modrinth.com/v2/version_file/$h" -UseBasicParsing -EA Stop
        if($v.project_id){ $p=Invoke-RestMethod "https://api.modrinth.com/v2/project/$($v.project_id)" -UseBasicParsing -EA Stop; return @{N=$p.title;S=$p.slug}} } catch {}
    return @{N="";S=""}
}
function SRC($p){
    try { $z = Get-Content -Raw -Stream Zone.Identifier $p -EA 0
        if($z -match "HostUrl=(.+)"){$u=$Matches[1].Trim()
            if($u -match "mediafire\.com"){return "MediaFire"}
            if($u -match "discord\.com|discordapp\.com|cdn\.discordapp\.com"){return "Discord CDN"}
            if($u -match "dropbox\.com"){return "Dropbox"}
            if($u -match "drive\.google\.com"){return "Google Drive"}
            if($u -match "mega\.nz|mega\.co\.nz"){return "MEGA"}
            if($u -match "github\.com"){return "GitHub"}
            if($u -match "modrinth\.com"){return "Modrinth"}
            if($u -match "curseforge\.com"){return "CurseForge"}
            if($u -match "https?://(?:www\.)?([^/]+)"){return $Matches[1]}
            return $u
        }
    } catch {}
    return "Unknown / Local"
}
function SCAN($p){
    $PA=New-Object 'System.Collections.Generic.HashSet[string]'
    $ST=New-Object 'System.Collections.Generic.HashSet[string]'
    $FR=New-Object 'System.Collections.Generic.HashSet[string]'
    try {
        $z=[IO.Compression.ZipFile]::OpenRead($p)
        foreach($e in $z.Entries){foreach($m in $RX.Matches($e.FullName)){[void]$PA.Add($m.Value)}}
        foreach($e in $z.Entries){
            if($e.FullName -match '\.(class|json)$' -or $e.FullName -match 'MANIFEST\.MF'){
                try { $st=$e.Open();$ms=New-Object IO.MemoryStream;$st.CopyTo($ms);$st.Close();$a=[Text.Encoding]::ASCII.GetString($ms.ToArray())
                    foreach($s in $CSTR){if($a.IndexOf($s,[StringComparison]::OrdinalIgnoreCase) -ge 0){[void]$ST.Add($s)}}
                    foreach($k in $FRAME.Keys){if($a.IndexOf($k,[StringComparison]::Ordinal) -ge 0){[void]$FR.Add($FRAME[$k])}}
                } catch {}
            }
        }
        $z.Dispose()
    } catch {}
    return @{P=$PA;S=$ST;F=$FR}
}
$mods = Get-ChildItem $MP -File -EA SilentlyContinue | ? {$_.Extension -in @('.jar','.zip')}
if($mods.Count -eq 0){ Write-Host "  [!] No mods found" -ForegroundColor Yellow; Read-Host; exit }
Write-Host "  [+] Mods found: $($mods.Count)" -ForegroundColor Green; Write-Host ""
$FLG=@(); $ok=0
foreach($m in $mods){
    $ok++; Write-Progress -Activity "Scanning Mods" -Status "[$ok/$($mods.Count)] $($m.Name)" -PercentComplete (($ok/$mods.Count)*100)
    $h = SHA1 $m.FullName
    $src = SRC $m.FullName
    $mod = MODRINTH $h
    if($mod.N){ continue }
    $r = SCAN $m.FullName
    $score = $r.P.Count * 2 + $r.S.Count + $r.F.Count * 5
    if($score -gt 0){
        $L = "LOW"; $LC = "Gray"
        if($score -ge 8){$L="HIGH";$LC="Red"}
        elseif($score -ge 4){$L="MEDIUM";$LC="Yellow"}
        $FLG += [PSCustomObject]@{F=$m.Name;SZ=$m.Length;SRC=$src;MOD=$mod.N;L=$L;LC=$LC;P=$r.P.Count;S=$r.S.Count;FR=$r.F.Count;PL=$r.P;SL=$r.S;FL=$r.F}
    }
}
Write-Progress -Activity "Scanning" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RESULTS • $($FLG.Count) suspicious / $($mods.Count) total" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan; Write-Host ""
if($FLG.Count -eq 0){ Write-Host "  ✅ No suspicious mods detected (or all Modrinth-verified)" -ForegroundColor Green }
else {
    $i=1
    foreach($f in $FLG){
        Write-Host "  [$i] $($f.F)" -ForegroundColor White
        $szKB=[math]::Round($f.SZ/1KB,1)
        Write-Host "      Size: ${szKB} KB • Source: $($f.SRC) • Level: " -ForegroundColor Gray -NoNewline
        Write-Host $f.L -ForegroundColor $f.LC
        if($f.MOD){Write-Host "      Modrinth match: $($f.MOD)" -ForegroundColor Cyan}
        if($f.FR.Count -gt 0){Write-Host "      ⚠ CLIENT FRAMEWORK: $($f.FL -join ', ')" -ForegroundColor Red}
        if($f.P.Count -gt 0){$pl=$f.PL -join ', '; if($pl.Length -gt 260){$pl=$pl.Substring(0,260)+"..."}; Write-Host "      File Patterns: $pl" -ForegroundColor Yellow}
        if($f.S.Count -gt 0 -and $f.S.Count -le 15){$sl=$f.SL -join ', '; Write-Host "      Strings: $sl" -ForegroundColor DarkYellow}
        elseif($f.S.Count -gt 15){Write-Host "      Suspicious strings: $($f.S)" -ForegroundColor DarkYellow}
        Write-Host ""; $i++
    }
}
Write-Host ""; Read-Host "  Press Enter to close"
'@

function VRS-RunGhostScanner {
    VRS-Log "▶ Launching Ghost Client Scanner"
    VRS-SetStatus "Running" "Ghost Scanner analyzing mods..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_GhostScript -TempName "VRS_GhostScanner.ps1"
    VRS-SetStatus "Ready" "Ghost Client Scanner launched" "IDLE" "#10B981"
}

# ───────────── 3) CYEMER SCANNER ─────────────
$VRS_CyemerScript = @'
$ErrorActionPreference="SilentlyContinue"; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║          ✦ VALYARSSER — CYEMER SCANNER v2 (PREMIUM) ✦             ║" -ForegroundColor Magenta
Write-Host "    ║          Slither Client + com.slither USN Prefetch Scanner          ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
function Test-Admin {$i=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($i); return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
if(-not (Test-Admin)){ Write-Host "  [ERROR] Administrator required!" -ForegroundColor Red; Read-Host; exit }
$NDL=@("com/slither/cyemer","com.slither.cyemer","CyemerClient","cyemer.client.mixins.json","dynamic_fps",
    "AimAssist","TriggerBot","AutoCrystal","AutoAnchor","AutoShieldBreak","BowAimbot","ESP","Effectesp","AutoTotem","AutoXP",
    "AutoClicker","Scaffold","Reach","Velocity","Fly","Speed","Jesus","Spider","NoFall","Phase","Aura","KillAura","FastPlace","ChestSteal","BaseFinder","AutoEat")
$STRONG=@("com/slither/cyemer","CyemerClient","com.slither.cyemer","cyemer.client.mixins.json")
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class CyD {
    [DllImport("ntdll.dll")] public static extern uint RtlDecompressBufferEx(ushort F,byte[] U,int UZ,byte[] C,int CZ,out int FS,IntPtr W);
    [DllImport("ntdll.dll")] public static extern uint RtlGetCompressionWorkSpaceSize(ushort F,out uint A,out uint B);
    public static byte[] D(byte[] c){
        if(c.Length<8||c[0]!=0x4D||c[1]!=0x41||c[2]!=0x4D) return null;
        int s=BitConverter.ToInt32(c,4); uint a,b; if(RtlGetCompressionWorkSpaceSize(4,out a,out b)!=0) return null;
        IntPtr w=Marshal.AllocHGlobal((int)b); byte[] r=new byte[s];
        try { int fs; byte[] cd=new byte[c.Length-8]; Array.Copy(c,8,cd,0,cd.Length);
            if(RtlDecompressBufferEx(4,r,s,cd,cd.Length,out fs,w)!=0) return null; return r;
        } finally { Marshal.FreeHGlobal(w); }
    }
}
"@
function GSI($f){
    try {
        $d=[IO.File]::ReadAllBytes($f)
        if($d[0] -eq 0x4D -and $d[1] -eq 0x41 -and $d[2] -eq 0x4D){$d=[CyD]::D($d); if($d -eq $null){return @()}}
        if($d.Length -lt 108){return @()}
        $so=[BitConverter]::ToUInt32($d,100); $sz=[BitConverter]::ToUInt32($d,104)
        if($so -eq 0 -or $sz -eq 0 -or $so -ge $d.Length){return @()}
        $fs=@(); $pos=$so; $end=$so+$sz
        while($pos -lt $end -and $pos -lt $d.Length - 2){
            $np=$pos; while($np -lt $d.Length - 1){if($d[$np] -eq 0 -and $d[$np+1] -eq 0){break}; $np+=2}
            if($np -gt $pos){$sl=$np-$pos; if($sl -gt 0 -and $sl -lt 2048){try{$fn=[Text.Encoding]::Unicode.GetString($d,$pos,$sl); if($fn){$fs+=$fn}}catch{}} }
            $pos=$np+2; if($fs.Count -gt 2000){break}
        }
        return $fs
    } catch { return @() }
}
function BM($d,$p){for($i=0;$i -le $d.Length-$p.Length;$i++){$ok=$true; for($j=0;$j -lt $p.Length;$j++){if($d[$i+$j] -ne $p[$j]){$ok=$false;break}}; if($ok){return $true}}; return $false}
$SP="C:\Windows\Prefetch"
$J = Get-ChildItem $SP -Filter "JAVA*.EXE-*.pf" -EA SilentlyContinue
if($J.Count -eq 0){ Write-Host "  [!] No JAVA prefetch files found" -ForegroundColor Yellow; Read-Host; exit }
Write-Host "  [+] JAVA Prefetch: $($J.Count)" -ForegroundColor Green
Write-Host "  [*] Extracting paths..." -ForegroundColor Cyan
$ALL=@()
foreach($f in $J){ $ALL += GSI $f.FullName }
Write-Host "  [+] Extracted paths: $($ALL.Count)" -ForegroundColor Green
$U=$ALL | Select-Object -Unique | ? {$_ -match '\.(JAR|jar|EXE|exe)$'}
Write-Host "  [+] JAR/EXE targets: $($U.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "  [*] Scanning for Cyemer..." -ForegroundColor Cyan
$FLG=@()
Add-Type -AssemblyName System.IO.Compression.FileSystem
$c=0
foreach($p in $U){
    $c++; Write-Progress -Activity "Cyemer Scan" -Status "[$c/$($U.Count)]" -PercentComplete (($c/$U.Count)*100)
    if(-not (Test-Path $p)){
        $drv="CDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray() | % { if(Test-Path "$($_):$($p.Substring(2))" -PathType Leaf){ "$($_):$($p.Substring(2))" } } | Select-Object -First 1
        if($drv){ $p=$drv } else { continue }
    }
    if(-not (Test-Path $p -PathType Leaf)){ continue }
    try {
        $h = [Text.Encoding]::ASCII.GetBytes([IO.File]::ReadAllText($p))
        $head = $h[0..1]
        if($head -join '' -ne '8075'){
            $bytes=[IO.File]::ReadAllBytes($p); if($bytes[0] -ne 0x50){continue}
        }
        $z=[IO.Compression.ZipFile]::OpenRead($p); $found=$false; $sigs=@(); $str=$false
        foreach($e in $z.Entries){
            foreach($n in $STRONG){ if($e.FullName -like "*$n*"){$sigs += $n; $found=$true; $str=$true} }
            if(-not $str -and $e.FullName -like "*.class"){
                try {
                    $st=$e.Open();$ms=New-Object IO.MemoryStream;$st.CopyTo($ms);$st.Close(); $a=$ms.ToArray()
                    foreach($n in $NDL){$nb=[Text.Encoding]::ASCII.GetBytes($n); if(BM $a $nb){$sigs += $n; $found=$true}}
                } catch {}
            }
        }
        $z.Dispose()
        if($found){
            Write-Progress -Activity "Cyemer Scan" -Completed
            $sigs = $sigs | Select-Object -Unique
            $FLG += [PSCustomObject]@{P=$p;S=$sigs}
            Write-Host "  [!] CYEMER DETECTED: $p" -ForegroundColor Red
            Write-Host "      Signatures: $($sigs -join ', ')" -ForegroundColor Yellow
        }
    } catch {}
}
Write-Progress -Activity "Cyemer Scan" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SCAN COMPLETE • $($U.Count) examined • $($FLG.Count) Cyemer hits" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if($FLG.Count -eq 0){ Write-Host "`n  ✅ No Cyemer signatures detected" -ForegroundColor Green }
Write-Host ""; Read-Host "  Press Enter"
'@

function VRS-RunCyemer {
    VRS-Log "▶ Launching Cyemer Scanner (Admin)"
    VRS-SetStatus "Running" "Cyemer v2 scanning..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_CyemerScript -TempName "VRS_Cyemer_v2.ps1" -AsAdmin
    VRS-SetStatus "Ready" "Cyemer Scanner launched (Admin)" "IDLE" "#10B981"
}

# ───────────── 4) VELARIS SCANNER ─────────────
$VRS_VelarisScript = @'
$ErrorActionPreference="SilentlyContinue"; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║          ✦ VALYARSSER — VELARIS SCANNER (PREMIUM) ✦              ║" -ForegroundColor Magenta
Write-Host "    ║          Velaris + 50 Generic Cheat Needle + Self-Destruct DB      ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
$VNDL=@("velaris","Velaris","VELARIS","com/velaris","com.velaris","VelarisClient","velaris-client","velaris_client","VelarisMod",
    ".velaris-cache","config/velaris","velaris.mixins.json","velaris-auth","velaris-license","velaris-hwid","velaris-login",
    "VelarisModule","VelarisCommand","VelarisGui","VelarisRender","velaris/module","velaris/command","velaris/mixin",
    "velaris_chams","velaris_esp","velaris_outline","velaris_glow","velaris_shader","velaris/discord")
$GEN=@("meteor","MeteorClient","meteor-client","impact","ImpactClient","wurst","WurstClient","aristois","liquidbounce","LiquidBounce",
    "rusherhack","RusherHack","novoline","NovoLine","sigma","SigmaClient","future","FutureClient","inertia","InertiaClient",
    "ghostware","GhostWare","vape","VapeClient","vapelite","dragonfly","DragonflyClient","ares","AresClient","xodus","XodusClient",
    "datura","DaturaClient","ModuleManager","CommandManager","hack/module","hack/command","client/module","client/command")
$AUTO=@("AutoMace","automace","AutoCrystal","CrystalAura","crystalaura","AutoTotem","autototem","TotemPop","SurroundBreaker","HoleFill",
    "AutoPlace","CrystalPlace","Anchor","AnchorAura","BedAura","bedaura","Surround","AutoSurround","CrystalESP","AnchorESP",
    "MaceAura","AutoBow","AutoCrossbow","Trident","TridentAura","WindBurst","BreezeAura")
$LEGI=@("fabric","fabricloader","fabric-api","forge","neoforge","quilt","sodium","lithium","phosphor","starlight","ferritecore",
    "iris","malilib","minihud","tweakeroo","jei","rei","emi","journeymap","xaeros-minimap","optifabric","modmenu","cloth-config",
    "minecraft","java","javax","com/google","org/apache","net/java","com/mojang","org/lwjgl")
$def="$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
Write-Host "  [?] Mods folder (Enter = default): $def" -ForegroundColor Gray
$in = Read-Host "  Path"; $MP = if([string]::IsNullOrWhiteSpace($in)){$def}else{$in.Trim()}
Write-Host ""
if(-not (Test-Path $MP -PathType Container)){ Write-Host "  [ERROR] Path invalid!" -ForegroundColor Red; Read-Host; exit }
Write-Host "  [►] Scanning: $MP" -ForegroundColor Green
Add-Type -AssemblyName System.IO.Compression.FileSystem
$mods = Get-ChildItem $MP -File -EA SilentlyContinue | ? {$_.Extension -eq ".jar"}
if($mods.Count -eq 0){ Write-Host "  [!] No .jar mods found" -ForegroundColor Yellow; Read-Host; exit }
Write-Host "  [+] Mods found: $($mods.Count)" -ForegroundColor Green; Write-Host ""
$FLG=@(); $ok=0
foreach($m in $mods){
    $ok++; Write-Progress -Activity "Velaris Scan" -Status "[$ok/$($mods.Count)] $($m.Name)" -PercentComplete (($ok/$mods.Count)*100)
    try {
        $z=[IO.Compression.ZipFile]::OpenRead($m.FullName)
        $hits=@{V=0;G=0;A=0;L=0}; $hit=@()
        foreach($e in $z.Entries){
            foreach($n in $VNDL){ if($e.FullName -like "*$n*"){$hits.V++; $hit += "V:$n"}}
            foreach($n in $GEN){ if($e.FullName -like "*$n*"){$hits.G++; $hit += "G:$n"}}
            foreach($n in $AUTO){ if($e.FullName -like "*$n*"){$hits.A++; $hit += "A:$n"}}
            foreach($n in $LEGI){ if($e.FullName -like "*$n*"){$hits.L++}}
            if($e.FullName -match '\.(class|json)$' -or $e.FullName -match 'MANIFEST\.MF'){
                try {
                    $st=$e.Open();$ms=New-Object IO.MemoryStream;$st.CopyTo($ms);$st.Close();$a=[Text.Encoding]::ASCII.GetString($ms.ToArray())
                    foreach($n in $VNDL){ if($a.IndexOf($n,[StringComparison]::Ordinal) -ge 0){$hits.V++; $hit += "VS:$n"}}
                    foreach($n in $GEN){ if($a.IndexOf($n,[StringComparison]::Ordinal) -ge 0){$hits.G++; $hit += "GS:$n"}}
                } catch {}
            }
        }
        $z.Dispose()
        $score = $hits.V * 5 + $hits.G * 2 + $hits.A * 2 - [Math]::Min($hits.L, 5)
        if($score -gt 2){
            $L = "LOW"; $LC = "Gray"; if($hits.V -gt 0 -or $score -ge 10){$L="HIGH";$LC="Red"} elseif($score -ge 5){$L="MEDIUM";$LC="Yellow"}
            $FLG += [PSCustomObject]@{F=$m.Name;SC=$score;V=$hits.V;G=$hits.G;A=$hits.A;L=$L;LC=$LC;H=($hit | Select-Object -Unique | Select-Object -First 30)}
        }
    } catch {}
}
Write-Progress -Activity "Velaris Scan" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SCAN COMPLETE • Velaris: $($FLG.Count) flagged / $($mods.Count) total" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if($FLG.Count -eq 0){ Write-Host "`n  ✅ No Velaris or generic cheat indicators found" -ForegroundColor Green }
else {
    $i=1
    foreach($f in $FLG){
        Write-Host "`n  [$i] $($f.F)" -ForegroundColor White
        Write-Host "      Score: $($f.SC) (Velaris=$($f.V) | Generic=$($f.G) | Combat=$($f.A)) • Level: " -ForegroundColor Gray -NoNewline
        Write-Host $f.L -ForegroundColor $f.LC
        Write-Host "      Top Hits: $(($f.H -join ', '))" -ForegroundColor Yellow
        $i++
    }
}
Write-Host ""; Read-Host "  Press Enter"
'@

function VRS-RunVelaris {
    VRS-Log "▶ Launching Velaris Scanner"
    VRS-SetStatus "Running" "Velaris Scanner analyzing mods..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_VelarisScript -TempName "VRS_Velaris.ps1"
    VRS-SetStatus "Ready" "Velaris Scanner launched" "IDLE" "#10B981"
}

# ───────────── 5) HEATED MOD ANALYZER ─────────────
$VRS_HeatedScript = @'
$ErrorActionPreference="SilentlyContinue"; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║       ✦ VALYARSSER — HEATED MOD ANALYZER (PREMIUM) ✦             ║" -ForegroundColor Magenta
Write-Host "    ║       Zone.Identifier / SHA1 / Dates / Size / Reputation Scan      ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
$def="$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
Write-Host "  [?] Mods folder (Enter = default): $def" -ForegroundColor Gray
$in = Read-Host "  Path"; $MP = if([string]::IsNullOrWhiteSpace($in)){$def}else{$in.Trim()}
Write-Host ""
if(-not (Test-Path $MP -PathType Container)){ Write-Host "  [ERROR] Path invalid!" -ForegroundColor Red; Read-Host; exit }
Write-Host "  [►] Analyzing: $MP" -ForegroundColor Green
Add-Type -AssemblyName System.IO.Compression.FileSystem
function MODRINTH($h){ try { $v=Invoke-RestMethod "https://api.modrinth.com/v2/version_file/$h" -UseBasicParsing -EA Stop
    if($v.project_id){ $p=Invoke-RestMethod "https://api.modrinth.com/v2/project/$($v.project_id)" -UseBasicParsing -EA Stop; return @{N=$p.title;S=$p.slug;T=$p.project_type}} } catch {}; return @{N="";S="";T=""} }
function ZONE($p){ try { $z=Get-Content -Raw -Stream Zone.Identifier $p -EA 0
    if($z -match "HostUrl=(.+)"){$u=$Matches[1].Trim()
        if($u -match "mediafire"){return @("MediaFire",3)}
        if($u -match "discord\.com|discordapp\.com|cdn\.discordapp\.com|cdn\.discord\.gg"){return @("Discord CDN",3)}
        if($u -match "dropbox\.com"){return @("Dropbox",2)}
        if($u -match "drive\.google\.com"){return @("Google Drive",2)}
        if($u -match "mega\.nz"){return @("MEGA",3)}
        if($u -match "github\.com"){return @("GitHub",0)}
        if($u -match "modrinth\.com"){return @("Modrinth",0)}
        if($u -match "curseforge\.com"){return @("CurseForge",1)}
        if($u -match "https?://(?:www\.)?([^/]+)"){return @($Matches[1],1)}
    } } catch {}; return @("Unknown / No Zone",2) }
$FLAGGED_SIZES=@(524288,1048576,2097152,3145728,4194304,6291456)
$FILES = Get-ChildItem $MP -File -EA SilentlyContinue | ? {$_.Extension -in @('.jar','.zip')}
if($FILES.Count -eq 0){ Write-Host "  [!] Nothing to analyze" -ForegroundColor Yellow; Read-Host; exit }
Write-Host "  [+] Files: $($FILES.Count)" -ForegroundColor Green; Write-Host ""
$Results = @(); $i=0
foreach($f in $FILES){
    $i++; Write-Progress -Activity "Heated Analysis" -Status "[$i/$($FILES.Count)] $($f.Name)" -PercentComplete (($i/$FILES.Count)*100)
    $item = [ordered]@{ File=$f.Name; SizeKB=[math]::Round($f.Length/1KB,1); Created=$f.CreationTime; Modified=$f.LastWriteTime; SHA1=""; Zone=""; Rep=0; RepScore=0; Modrinth=""; Suspicious=@(); Level="SAFE" }
    try {
        $item.SHA1 = (Get-FileHash $f.FullName -Algorithm SHA1).Hash
        $mod = MODRINTH $item.SHA1
        $item.Modrinth = if($mod.N){$mod.N}else{""}
        if($mod.N){ $item.Rep += 1; $item.RepScore += 50 }
        $z = ZONE $f.FullName; $item.Zone = $z[0]; $item.RepScore -= ($z[1] * 5)
        if($z[1] -ge 3){ $item.Suspicious += "Unvetted source: $($z[0])" }
        if($f.Length -lt 10KB -or $f.Length -gt 30MB){ $item.Suspicious += "Size anomaly ($([math]::Round($f.Length/1MB,2)) MB)" }
        if($f.Length -in $FLAGGED_SIZES){ $item.Suspicious += "Common cheat size marker" }
        try {
            $z=[IO.Compression.ZipFile]::OpenRead($f.FullName)
            $classes = ($z.Entries | ? {$_.FullName -like "*.class"}).Count
            $entryCount = $z.Entries.Count
            $z.Dispose()
            if($classes -eq 0){ $item.Suspicious += "Zero .class files in JAR" }
            if($classes -gt 50 -and -not $mod.N){ $item.Suspicious += "High class count ($classes), not Modrinth-verified" }
            $item.ClassCount = $classes
        } catch {}
        $ageDays = ((Get-Date) - $f.CreationTime).TotalDays
        if($ageDays -lt 1){ $item.Suspicious += "Recently created (<24h)" }
        if($item.RepScore -ge 30){ $item.Level = "SAFE"; $LC="Green" }
        elseif($item.RepScore -ge 0){ $item.Level = "LOW RISK"; $LC="Yellow" }
        elseif($item.RepScore -ge -15){ $item.Level = "MEDIUM"; $LC="Yellow" }
        else { $item.Level = "SUSPICIOUS"; $LC="Red" }
        if($item.Suspicious.Count -ge 3 -and $item.Level -ne "SAFE"){ $item.Level = "SUSPICIOUS"; $LC="Red" }
        $item.LevelColor = $LC
        $Results += [PSCustomObject]$item
    } catch {}
}
Write-Progress -Activity "Heated Analysis" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ANALYSIS COMPLETE • $($FILES.Count) files processed" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan; Write-Host ""
foreach($r in $Results){
    Write-Host "  ┌─────────────────────────────────────────────────────"
    Write-Host "  │📄 $($r.File)" -ForegroundColor White
    Write-Host "  │   Size: $($r.SizeKB) KB | Classes: $($r.ClassCount) | Age: $([math]::Round(((Get-Date)-$r.Created).TotalDays,1)) days" -ForegroundColor Gray
    Write-Host "  │   SHA1: $($r.SHA1.Substring(0,16))..." -ForegroundColor Gray
    if($r.Modrinth){ Write-Host "  │   ✅ Modrinth Verified: $($r.Modrinth)" -ForegroundColor Green }
    Write-Host "  │   Zone: $($r.Zone) • Rep: $($r.RepScore) pts • Level: " -ForegroundColor Gray -NoNewline
    Write-Host $r.Level -ForegroundColor $r.LevelColor
    if($r.Suspicious.Count -gt 0){ Write-Host "  │   ⚠ Flags: $($r.Suspicious -join ' | ')" -ForegroundColor Yellow }
    Write-Host "  └─────────────────────────────────────────────────────"
}
Write-Host ""; Read-Host "  Press Enter"
'@

function VRS-RunHeated {
    VRS-Log "▶ Launching Heated Mod Analyzer"
    VRS-SetStatus "Running" "Heated Analyzer deep-scanning..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_HeatedScript -TempName "VRS_HeatedAnalyzer.ps1"
    VRS-SetStatus "Ready" "Heated Mod Analyzer launched" "IDLE" "#10B981"
}

# ───────────── 6) HACKED CLIENTS DETECTOR ─────────────
$VRS_HackedScript = @'
$ErrorActionPreference="SilentlyContinue"; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║       ✦ VALYARSSER — HACKED CLIENTS DATABASE SCAN ✦              ║" -ForegroundColor Magenta
Write-Host "    ║       12-Client Module Signature DB • Recursive Multi-Path         ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
$DB=@{}
$DB.Meteor    = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","Scaffold","TriggerBot","Reach","Criticals","AutoMine","FastPlace","ChestSteal","AutoCrystal","Surround","HoleFill")
$DB.Doomsday  = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","Criticals","Scaffold","FastPlace","AutoXP","InventoryManipulation","MaceSwap")
$DB.Aristois  = @("KillAura","AutoTotem","AutoArmor","Speed","Flight","TriggerBot","Velocity","ChestSteal","FastPlace","AutoMine")
$DB.Wurst     = @("KillAura","AutoTotem","AutoArmor","Speed","Flight","Reach","AutoClicker","FastPlace","InventoryTweaks")
$DB.ThunderHack=@("KillAura","AutoTotem","AutoArmor","Flight","Velocity","Criticals","TriggerBot","FastPlace","AutoMine","ChestSteal","AutoEat")
$DB.LiquidBounce=@("KillAura","Velocity","Flight","Scaffold","FastPlace","ChestSteal","AutoMine","NoFall","Jesus","Sprint")
$DB.Asteria   = @("KillAura","AutoArmor","Velocity","Flight","Scaffold","FastPlace","AutoTotem","Phase","Blink","Freecam")
$DB.Prestige  = @("KillAura","AutoTotem","AutoArmor","Flight","Criticals","AutoMine","ChestSteal","AutoCrystal","AutoPot")
$DB.Xenon     = @("KillAura","AutoArmor","AutoTotem","Flight","FastPlace","InventoryTweaks","AutoMace","AutoCrystal")
$DB.Argon     = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","FastPlace","AutoXP","SilentAim","TargetHUD")
$DB.Krypton   = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","FastPlace","AutoXP","BlockESP","Tracers")
$DB.Nova      = @("KillAura","AutoTotem","AutoArmor","Flight","AutoCrystal","TriggerBot","ESP","Speed","AntiKB")
$PATHS=@("$env:USERPROFILE\Downloads","$env:USERPROFILE\Desktop","$env:TEMP","$env:APPDATA\.minecraft\mods","$env:USERPROFILE\.minecraft\mods","$env:USERPROFILE\curseforge\minecraft\Instances")
Write-Host "  [*] Scan paths:" -ForegroundColor Cyan
$SCAN=@(); foreach($p in $PATHS){ if(Test-Path $p){ $SCAN += $p; Write-Host "      • $p" -ForegroundColor Gray } }
Write-Host ""
Write-Host "  [*] Collecting JAR files..." -ForegroundColor Cyan
$JARS = Get-ChildItem -Path $SCAN -Recurse -Filter *.jar -File -EA SilentlyContinue -ErrorAction SilentlyContinue
Write-Host "  [+] Target JARs: $($JARS.Count)" -ForegroundColor Green; Write-Host ""
Add-Type -AssemblyName System.IO.Compression.FileSystem
$RESULTS=@(); $c=0
foreach($j in $JARS){
    $c++; Write-Progress -Activity "Client DB Scan" -Status "[$c/$($JARS.Count)] $($j.Name)" -PercentComplete (($c/$JARS.Count)*100)
    try {
        $z=[IO.Compression.ZipFile]::OpenRead($j.FullName); $names = $z.Entries.FullName; $z.Dispose()
        $best=@(); $bestScore=0; $bestClient=""
        foreach($client in $DB.Keys){
            $sc=0; $mods=@()
            foreach($pat in $DB[$client]){
                foreach($n in $names){ if($n -match [regex]::Escape($pat)){ $sc += 10; $mods += $pat; break } }
                if($j.Name -match [regex]::Escape($client)){ $sc += 25 }
            }
            if($sc -gt $bestScore){ $bestScore = $sc; $bestClient = $client; $best = $mods | Select-Object -Unique }
        }
        if($bestScore -ge 50){
            $L="HIGH"; $LC="Red"
            if($bestScore -lt 80){$L="MEDIUM"; $LC="Yellow"}
            Write-Progress -Activity "Client DB Scan" -Completed
            Write-Host "  [!] CLIENT DETECTED:" -ForegroundColor Red
            Write-Host "      File: $($j.FullName)" -ForegroundColor White
            Write-Host "      Client: $bestClient (score: $bestScore) • Level: " -ForegroundColor Gray -NoNewline
            Write-Host $L -ForegroundColor $LC
            Write-Host "      Modules: $($best -join ', ')" -ForegroundColor Yellow
            $RESULTS += [PSCustomObject]@{P=$j.FullName;C=$bestClient;S=$bestScore;L=$L;M=$best}
            Write-Progress -Activity "Client DB Scan" -Status "[$c/$($JARS.Count)] $($j.Name)" -PercentComplete (($c/$JARS.Count)*100)
        }
    } catch {}
}
Write-Progress -Activity "Client DB Scan" -Completed
Write-Host ""
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SCAN COMPLETE • $($JARS.Count) JARs • $($RESULTS.Count) client signatures" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if($RESULTS.Count -eq 0){ Write-Host "`n  ✅ No known hacked client signatures detected" -ForegroundColor Green }
Write-Host ""; Read-Host "  Press Enter"
'@

function VRS-RunHackedClients {
    VRS-Log "▶ Launching Hacked Clients Detector (DB Scan)"
    VRS-SetStatus "Running" "Client DB scan across paths..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_HackedScript -TempName "VRS_HackedClients.ps1"
    VRS-SetStatus "Ready" "Hacked Clients Detector launched" "IDLE" "#10B981"
}

# ───────────── 7) DQRKIS DETECTOR ─────────────
$VRS_DqrkisScript = @'
$ErrorActionPreference="SilentlyContinue"; Clear-Host
Write-Host ""
Write-Host "    ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "    ║           ✦ VALYARSSER — DQRKIS CLIENT DETECTOR ✦                ║" -ForegroundColor Magenta
Write-Host "    ║           Live upstream signature engine (cheesecatlol)            ║" -ForegroundColor Cyan
Write-Host "    ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "    Author Discord: _iaec" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [*] Pulling latest upstream DQRKIS detector..." -ForegroundColor Cyan
try {
    $upstream = "https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1"
    $script = Invoke-RestMethod -Uri $upstream -UseBasicParsing -ErrorAction Stop
    $tmp = Join-Path $env:TEMP "VRS_DQRKIS_UPSTREAM.ps1"
    Set-Content -LiteralPath $tmp -Value $script -Encoding UTF8 -Force
    Write-Host "  [+] Upstream OK. Executing detector..." -ForegroundColor Green
    Write-Host ""
    & powershell.exe -NoExit -ExecutionPolicy Bypass -File $tmp
} catch {
    Write-Host "  [!] Upstream pull failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  [*] Running built-in fallback signatures..." -ForegroundColor Yellow
    $PATHS=@("$env:USERPROFILE\Downloads","$env:APPDATA\.minecraft\mods","$env:USERPROFILE\Desktop","$env:TEMP")
    $J = Get-ChildItem -Path $PATHS -Recurse -Filter *.jar -File -EA SilentlyContinue
    Write-Host "  [+] Targets: $($J.Count)" -ForegroundColor Green
    $NEED=@("dqrkis","DQRKIS","Dqrkis","dqrk_is","dqrkis.dev","com/dqrkis","dev/dqrkis","DqrkisMod","dqrkis-client",
        "DqrkisMixins","dqrkis_module","DqrkisAura","DqrkisESP","DqrkisHUD","dqrkis/config")
    $hits=0
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach($j in $J){
        try {
            $z=[IO.Compression.ZipFile]::OpenRead($j.FullName)
            foreach($e in $z.Entries){
                foreach($n in $NEED){ if($e.FullName -like "*$n*"){
                    Write-Host "  [!] DQRKIS HIT: $($j.FullName) | Entry: $($e.FullName)" -ForegroundColor Red; $hits++; break
                }}
            }
            $z.Dispose()
        } catch {}
    }
    Write-Host ""
    if($hits -eq 0){ Write-Host "  ✅ No DQRKIS fallback hits" -ForegroundColor Green }
    else { Write-Host "  ⛔ DQRKIS signatures found: $hits" -ForegroundColor Red }
}
Write-Host ""; Read-Host "  Press Enter"
'@

function VRS-RunDqrkis {
    VRS-Log "▶ Launching DQRKIS Detector (upstream + fallback)"
    VRS-SetStatus "Running" "DQRKIS detector active..." "SCANNING" "#F59E0B"
    VRS-LaunchScript -ScriptBody $VRS_DqrkisScript -TempName "VRS_Dqrkis.ps1"
    VRS-SetStatus "Ready" "DQRKIS Detector launched" "IDLE" "#10B981"
}

# ───────────── 8) JOURNAL TRACE ─────────────
function VRS-RunJournalTrace {
    VRS-Log "▶ Journal Trace Analyzer (spokwn) — Download"
    VRS-SetStatus "Running" "Fetching JournalTrace..." "DL" "#F59E0B"
    $dest = "$installDir\Spokwn\JournalTrace\JournalTrace.exe"
    $dir  = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $dest) {
        VRS-Log "Cached JournalTrace.exe, launching..."
        Start-Process $dest
    } else {
        $url = "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe"
        $fallback = "https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTraceNormal.exe"
        VRS-Log "Downloading JournalTrace..."
        if (-not (VRS-SaveFile -Uri $url -OutFile $dest)) {
            VRS-Log "Primary URL failed, trying fallback..."
            if (VRS-SaveFile -Uri $fallback -OutFile $dest) {
                Start-Process $dest
            }
        } else { Start-Process $dest }
    }
    VRS-SetStatus "Ready" "JournalTrace launched" "IDLE" "#10B981"
}

# ==============================================================================
# STAGE 9: TOOL CARD UI BUILDER
# ==============================================================================

function VRS-TypeStyle($t){
    switch($t){
        "BuiltIn" { return @("#0F1E23","#22D3EE","Built-in") }
        "Cmd"     { return @("#0F172A","#60A5FA","CMD") }
        "GitHub"  { return @("#141026","#A78BFA","GitHub") }
        "Web"     { return @("#191520","#F59E0B","Web") }
        "Link"    { return @("#0F1B1F","#34D399","Link") }
        default   { return @("#171731","#94A3B8",$t) }
    }
}

function VRS-MakeButton($tool){
    $style = VRS-TypeStyle $tool.Type
    $bgHex   = $style[0]; $accent = $style[1]; $typeLbl = $style[2]
    $icon = if($tool.Icon){$tool.Icon}else{"🔧"}

    $btn = New-Object System.Windows.Controls.Button
    $btn.Width = 252; $btn.Height = 100
    $btn.Margin = "8"
    $btn.Cursor = "Hand"
    $btn.Foreground = "#E2E8F0"
    $btn.Background = [Windows.Media.BrushConverter]::new().ConvertFrom($bgHex)
    $btn.Tag = $tool.Name

    $root = New-Object System.Windows.Controls.Grid
    $root.Margin = "12,10,12,10"
    $rd1 = New-Object System.Windows.Controls.RowDefinition
    $rd2 = New-Object System.Windows.Controls.RowDefinition
    $root.RowDefinitions.Add($rd1) | Out-Null
    $root.RowDefinitions.Add($rd2) | Out-Null

    $top = New-Object System.Windows.Controls.Grid
    $cd1 = New-Object System.Windows.Controls.ColumnDefinition
    $cd2 = New-Object System.Windows.Controls.ColumnDefinition
    $cd1.Width = [Windows.GridLength]::new(1,[Windows.GridUnitType]::Star)
    $cd2.Width = [Windows.GridLength]::new(1,[Windows.GridUnitType]::Auto)
    $top.ColumnDefinitions.Add($cd1) | Out-Null
    $top.ColumnDefinitions.Add($cd2) | Out-Null

    $nameStack = New-Object System.Windows.Controls.StackPanel
    $nameStack.Orientation = "Horizontal"
    $nameStack.VerticalAlignment = "Center"
    $icn = New-Object System.Windows.Controls.TextBlock
    $icn.Text = $icon; $icn.FontSize = 14; $icn.Foreground = $accent
    $icn.VerticalAlignment = "Center"
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $tool.Name; $tb.FontSize = 12; $tb.FontWeight = "Bold"
    $tb.Foreground = "#FFFFFF"; $tb.TextWrapping = "Wrap"
    $tb.VerticalAlignment = "Center"; $tb.Margin = "6,0,0,0"
    $nameStack.Children.Add($icn) | Out-Null
    $nameStack.Children.Add($tb)  | Out-Null
    [Windows.Controls.Grid]::SetColumn($nameStack, 0)
    $top.Children.Add($nameStack) | Out-Null

    $bdg = New-Object System.Windows.Controls.Border
    $bdg.CornerRadius = 6
    $bdg.Background = [Windows.Media.BrushConverter]::new().ConvertFrom("$accent"+"22")
    $bdg.Padding = "8,2"
    $bdg.VerticalAlignment = "Center"
    $bdg.HorizontalAlignment = "Right"
    $bdg.MaxWidth = 72
    $bt = New-Object System.Windows.Controls.TextBlock
    $bt.Text = $typeLbl
    $bt.FontSize = 9; $bt.FontWeight = "Bold"; $bt.Foreground = $accent
    $bt.TextAlignment = "Center"
    $bdg.Child = $bt
    [Windows.Controls.Grid]::SetColumn($bdg, 1)
    $top.Children.Add($bdg) | Out-Null

    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = $tool.Desc
    $desc.FontSize = 10
    $desc.Opacity = 0.68
    $desc.TextWrapping = "Wrap"
    $desc.Foreground = "#94A3B8"
    $desc.Margin = "0,6,0,0"

    [Windows.Controls.Grid]::SetRow($top, 0)
    $root.Children.Add($top)  | Out-Null
    [Windows.Controls.Grid]::SetRow($desc, 1)
    $root.Children.Add($desc) | Out-Null

    $btn.Content = $root

    $btnBg    = [Windows.Media.SolidColorBrush]::new([Windows.Media.ColorConverter]::ConvertFromString($bgHex))
    $btnScale = [Windows.Media.ScaleTransform]::new(1.0, 1.0)
    $btnGlow  = [Windows.Media.Effects.DropShadowEffect]::new()
    $accentColor = [Windows.Media.ColorConverter]::ConvertFromString($accent)
    $btnGlow.Color       = $accentColor
    $btnGlow.BlurRadius  = 0
    $btnGlow.ShadowDepth = 0
    $btnGlow.Opacity     = 0

    $btn.Template = [Windows.Markup.XamlReader]::Parse(
        "<ControlTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' TargetType='Button'>" +
        "  <Border x:Name='BB' CornerRadius='11' BorderThickness='1.2' RenderTransformOrigin='0.5,0.5' Background='{TemplateBinding Background}' RenderTransform='{TemplateBinding Tag}' BorderBrush='#2A2A55'>" +
        "    <ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center'/>" +
        "  </Border>" +
        "</ControlTemplate>"
    )
    $btn.Background = $btnBg
    $btn.Tag        = $btnScale
    $btn.Resources["glow"] = $btnGlow

    $btn.Add_Loaded({
        $b = $args[0].Source
        if ([Windows.Media.VisualTreeHelper]::GetChildrenCount($b) -gt 0) {
            $brd = [Windows.Media.VisualTreeHelper]::GetChild($b, 0)
            if ($brd) { $brd.Effect = $b.Resources["glow"] }
        }
    })

    $origBg = [Windows.Media.ColorConverter]::ConvertFromString($bgHex)

    $btn.Add_MouseEnter({
        $b = $_.Source; $bg = $b.Background; $sc = $b.Tag; $glw = $b.Resources["glow"]
        if (-not $bg -or -not $sc) { return }
        $d = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(120))
        $ea = [Windows.Media.Animation.CubicEase]::new()
        $a = [Windows.Media.Animation.ColorAnimation]::new($accentColor, $d)
        $bg.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, $a)
        $ax = [Windows.Media.Animation.DoubleAnimation]::new(1.055, $d); $ax.EasingFunction = $ea
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleXProperty, $ax)
        $ay = [Windows.Media.Animation.DoubleAnimation]::new(1.055, $d); $ay.EasingFunction = $ea
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleYProperty, $ay)
        if ($glw) {
            $ab = [Windows.Media.Animation.DoubleAnimation]::new(28.0, $d)
            $glw.BeginAnimation([Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty, $ab)
            $ao = [Windows.Media.Animation.DoubleAnimation]::new(0.9, $d)
            $glw.BeginAnimation([Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $ao)
        }
        $b.Foreground = [Windows.Media.Brushes]::Black
    })

    $btn.Add_MouseLeave({
        $b = $_.Source; $bg = $b.Background; $sc = $b.Tag; $glw = $b.Resources["glow"]
        if (-not $bg -or -not $sc) { return }
        $d = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
        $ea = [Windows.Media.Animation.CubicEase]::new()
        $a = [Windows.Media.Animation.ColorAnimation]::new($origBg, $d)
        $bg.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, $a)
        $ax = [Windows.Media.Animation.DoubleAnimation]::new(1.0, $d); $ax.EasingFunction = $ea
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleXProperty, $ax)
        $ay = [Windows.Media.Animation.DoubleAnimation]::new(1.0, $d); $ay.EasingFunction = $ea
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleYProperty, $ay)
        if ($glw) {
            $ab = [Windows.Media.Animation.DoubleAnimation]::new(0.0, $d)
            $glw.BeginAnimation([Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty, $ab)
            $ao = [Windows.Media.Animation.DoubleAnimation]::new(0.0, $d)
            $glw.BeginAnimation([Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $ao)
        }
        $b.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#E2E8F0")
    })

    $btn.Add_PreviewMouseDown({
        $b = $_.Source; $sc = $b.Tag
        if (-not $sc) { return }
        $d = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(70))
        $ax = [Windows.Media.Animation.DoubleAnimation]::new(0.955, $d)
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleXProperty, $ax)
        $ay = [Windows.Media.Animation.DoubleAnimation]::new(0.955, $d)
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleYProperty, $ay)
    })
    $btn.Add_PreviewMouseUp({
        $b = $_.Source; $sc = $b.Tag
        if (-not $sc) { return }
        $d = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(90))
        $ax = [Windows.Media.Animation.DoubleAnimation]::new(1.055, $d)
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleXProperty, $ax)
        $ay = [Windows.Media.Animation.DoubleAnimation]::new(1.055, $d)
        $sc.BeginAnimation([Windows.Media.ScaleTransform]::ScaleYProperty, $ay)
    })

    $btn.Add_Click({
        $cb = $args[0].Source
        $tName = $cb.Tag
        $cb.IsEnabled = $false

        # Flash animation
        $origBg2 = $cb.Background
        $origW   = $cb.Width; $origH = $cb.Height
        $flashes = @("#6366F1","#06B6D4","#8B5CF6")
        for ($i=0; $i -lt $flashes.Count; $i++){
            $cb.Dispatcher.Invoke([Action]{
                $cb.Background = [Windows.Media.BrushConverter]::new().ConvertFrom($flashes[$i])
            },[Windows.Threading.DispatcherPriority]::Render) | Out-Null
            Start-Sleep -Milliseconds 60
        }
        $cb.Dispatcher.Invoke([Action]{
            $cb.Background = $origBg2; $cb.IsEnabled = $true
        },[Windows.Threading.DispatcherPriority]::Render) | Out-Null

        $tData = $global:VRS_ToolData | Where-Object { $_.Name -eq $tName } | Select-Object -First 1
        if (-not $tData) { return }
        VRS-Log "▶ SELECT: $($tData.Name) [$($tData.Type)]"
        switch ($tData.Type) {
            "BuiltIn" { VRS-RunBuiltIn -Id $tData.BuiltIn -Name $tData.Name }
            "Cmd"     {
                VRS-SetStatus "Running" "Executing $($tData.Name)..." "RUNNING" "#F59E0B"
                VRS-RunCmd -Command $tData.Command
                VRS-SetStatus "Ready" "$($tData.Name) launched" "IDLE" "#10B981"
            }
            "GitHub"  { VRS-RunGitHub -tool $tData }
            "Web"     { VRS-RunWeb -tool $tData }
            "Link"    {
                VRS-Log "Opening browser link: $($tData.URL)"
                VRS-SetStatus "Browser" "Opened $($tData.Name)" "IDLE" "#10B981"
                Start-Process $tData.URL
            }
        }
    })

    return $btn
}

function VRS-BuildTabs {
    param($OverrideList = $null, $Header = $null)
    $VRS_ToolsTab.Items.Clear()
    $Cats = if($Header){@($Header)} else {$global:VRS_Categories}
    foreach ($cat in $Cats) {
        $tab = New-Object System.Windows.Controls.TabItem
        $tab.Header = $cat

        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = "Auto"
        $scroll.HorizontalScrollBarVisibility = "Disabled"
        $scroll.Background = [Windows.Media.Brushes]::Transparent

        $wrap = New-Object System.Windows.Controls.WrapPanel
        $wrap.Margin = "6,6,6,6"

        $list = if($OverrideList){$OverrideList}else{ $global:VRS_ToolData | Where-Object { $_.Category -eq $cat } }
        foreach ($tool in $list) {
            if (-not $Header -and $tool.Category -ne $cat) { continue }
            $wrap.Children.Add((VRS-MakeButton $tool)) | Out-Null
        }
        if ($wrap.Children.Count -eq 0) {
            $empty = New-Object System.Windows.Controls.TextBlock
            $empty.Text = "No tools in this category yet."
            $empty.Foreground = "#64748B"; $empty.FontSize = 14; $empty.Margin = "24,40,0,0"
            $wrap.Children.Add($empty) | Out-Null
        }

        $scroll.Content = $wrap
        $tab.Content = $scroll
        $VRS_ToolsTab.Items.Add($tab) | Out-Null
    }
}

# ==============================================================================
# STAGE 10: WINDOW EVENTS + NAV
# ==============================================================================

# Title bar
$VRS_CloseBtn.Add_Click({ $global:VRS_Win.Close() })
$VRS_MinBtn.Add_Click({ $global:VRS_Win.WindowState = 'Minimized' })
$script:VRS_Max = $false
$VRS_MaxBtn.Add_Click({
    if ($script:VRS_Max) { $global:VRS_Win.WindowState = 'Normal'; $script:VRS_Max = $false }
    else { $global:VRS_Win.WindowState = 'Maximized'; $script:VRS_Max = $true }
})
$VRS_CloseBtn.Add_MouseEnter({
    $VRS_CloseBtn.Foreground = [Windows.Media.Brushes]::White
    [Windows.Media.VisualTreeHelper]::GetChild($VRS_CloseBtn,0).Background = [Windows.Media.BrushConverter]::new().ConvertFrom("#4C1D1D")
})
$VRS_CloseBtn.Add_MouseLeave({
    $VRS_CloseBtn.Foreground = [Windows.Media.BrushConverter]::new().ConvertFrom("#64748B")
    [Windows.Media.VisualTreeHelper]::GetChild($VRS_CloseBtn,0).Background = [Windows.Media.Brushes]::Transparent
})

# Sidebar actions
$VRS_OpenFolderBtn.Add_Click({
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }
    Start-Process explorer "`"$installDir`""
    VRS-Log "📂 Opened install folder: $installDir"
})
$VRS_ClearCacheBtn.Add_Click({
    if (Test-Path $installDir) {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    VRS-Log "🗑️ Cache cleared (all downloaded files removed)"
    VRS-SetStatus "Cache Cleared" "All downloaded tools have been removed." "IDLE" "#10B981"
})
$VRS_OpenPSBtn.Add_Click({
    $wd = if (Test-Path $installDir) { $installDir } else { (Get-Location).Path }
    Start-Process powershell.exe -ArgumentList "-NoExit","-ExecutionPolicy","Bypass" -WorkingDirectory $wd
    VRS-Log "💻 PowerShell launched at: $wd"
})
$VRS_RefreshBtn.Add_Click({
    VRS-Log "🔄 Reloading tool UI..."
    VRS-BuildTabs
    VRS-SetStatus "Ready" "Tools list refreshed. $($global:VRS_ToolData.Count) tools available." "IDLE" "#10B981"
})
$VRS_OneLinerBtn.Add_Click({
    $gu = $script:VRS_GitHubUser
    $gr = $script:VRS_GitHubRepo
    $gb = $script:VRS_GitHubBranch
    $rawUrl = "https://raw.githubusercontent.com/$gu/$gr/$gb/ValyaRSSer.ps1"
    $oneliner = 'powershell.exe -NoP -ExecutionPolicy Bypass -Command "irm ''https://raw.githubusercontent.com/' + $gu + '/' + $gr + '/' + $gb + '/ValyaRSSer.ps1'' | iex"'
    $shortOneLiner = 'powershell -NoP -ep Bypass -C "irm ' + $rawUrl + ' | iex"'
    try {
        [System.Windows.Forms.Clipboard]::SetText($oneliner)
        VRS-Log "[-] One-liner CMD copied to clipboard."
        if ($gu -eq "YOURUSER") {
            VRS-Log "[!] IMPORTANT: Remember to set VRS_GitHubUser = your actual GitHub username!"
            VRS-SetStatus "Config Needed!" "Change YOURUSER to your GitHub username in the script first." "WARN" "#F59E0B"
        } else {
            VRS-SetStatus "Copied!" "One-liner copied. Paste in CMD or PowerShell to run from anywhere." "OK" "#22D3EE"
        }
        VRS-Log "[=] Short form: $shortOneLiner"
    } catch {
        VRS-Log "[!] Clipboard access failed. Command: $oneliner"
    }
})
$VRS_ClrLog.Add_Click({
    $VRS_LogBox.Clear()
    $VRS_ConsoleStat.Text = "  • Cleared"
})

# Quick launch buttons
$VRS_QDoom.Add_Click({  VRS-RunDoomsday })
$VRS_QGhost.Add_Click({ VRS-RunGhostScanner })
$VRS_QVel.Add_Click({   VRS-RunVelaris })
$VRS_QHack.Add_Click({  VRS-RunHackedClients })

# Search
$VRS_SearchBox.Add_GotFocus({
    if ($VRS_SearchBox.Text -eq "Search tools (name, desc, type, category)...") {
        $VRS_SearchBox.Text = ""
    }
})
$VRS_SearchBox.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($VRS_SearchBox.Text)) {
        $VRS_SearchBox.Text = "Search tools (name, desc, type, category)..."
    }
})
$VRS_SearchBox.Add_TextChanged({
    $q = $VRS_SearchBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($q) -or $q -like "*Search tools*") {
        VRS-BuildTabs
        return
    }
    $filtered = $global:VRS_ToolData | Where-Object {
        $_.Name -like "*$q*" -or
        $_.Desc -like "*$q*" -or
        $_.Category -like "*$q*" -or
        $_.Type -like "*$q*"
    }
    $headerText = "🔍 Results for `"$q`" — $($filtered.Count) found"
    VRS-BuildTabs -OverrideList $filtered -Header $headerText
})

# Clock timer
$VRS_Timer = New-Object System.Windows.Threading.DispatcherTimer
$VRS_Timer.Interval = [TimeSpan]::FromSeconds(1)
$VRS_Timer.Add_Tick({
    $VRS_Clock.Text = Get-Date -Format "HH:mm:ss   ddd MMM dd"
})
$VRS_Timer.Start()

# ==============================================================================
# STAGE 11: BOOT & SHOW
# ==============================================================================

VRS-Log "==========================================="
VRS-Log "ValyaRSSer v2.1 Premium - Boot OK"
VRS-Log "Loaded $($global:VRS_ToolData.Count) tools in $($global:VRS_Categories.Count) categories"
VRS-Log "Author Discord: _iaec"
VRS-Log "One-liner: powershell -NoP -ep Bypass -C `"irm <raw-url> | iex`""
VRS-Log "==========================================="

VRS-BuildTabs
VRS-SetStatus "Welcome to ValyaRSSer +" "$($global:VRS_ToolData.Count) premium tools and 8 built-in scanners ready. Discord: _iaec" "IDLE" "#10B981"

# Run the window
$null = $global:VRS_Win.ShowDialog()
VRS-Log "Session ended."
exit 0
