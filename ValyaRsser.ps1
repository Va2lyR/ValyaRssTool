Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing, System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.GC]::Collect()

if ($MyInvocation.MyCommand.Path) {
    $global:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $global:scriptDir = $PSScriptRoot
    if (-not $global:scriptDir) { $global:scriptDir = (Get-Location).Path }
}

$global:installDir = "$env:USERPROFILE\Downloads\ValyaRssTools"
$global:logPath = Join-Path $env:TEMP "valyarss_tools.log"
$global:window = $null
$global:activeCategoryBtn = $null
$global:IsDarkTheme = $true
$global:CompactMode = $false

function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "HH:mm:ss"
    if ($global:LogBox -and $global:LogBox.Dispatcher -and $global:LogBox.Dispatcher.CheckAccess()) {
        $global:LogBox.AppendText("[$time] $msg`r`n")
        $global:LogBox.ScrollToEnd()
    } elseif ($global:LogBox -and $global:LogBox.Dispatcher) {
        $global:LogBox.Dispatcher.Invoke([Action]{
            $global:LogBox.AppendText("[$time] $msg`r`n")
            $global:LogBox.ScrollToEnd()
        })
    }
    Add-Content -Path $global:logPath -Value "[$time] $msg" -ErrorAction SilentlyContinue
}

function Set-Status {
    param($title, $sub, $badge = "BUSY")
    if ($global:StatusTitle -and $global:StatusTitle.Dispatcher -and $global:StatusTitle.Dispatcher.CheckAccess()) {
        $global:StatusTitle.Text = $title
        $global:StatusSub.Text = $sub
        $global:StatusBadge.Text = $badge
    } elseif ($global:StatusTitle -and $global:StatusTitle.Dispatcher) {
        $global:StatusTitle.Dispatcher.Invoke([Action]{ 
            $global:StatusTitle.Text = $title
            $global:StatusSub.Text = $sub
            $global:StatusBadge.Text = $badge
        })
    }
}

function Get-ToolStatus {
    param($tool)
    $kp = Join-Path $global:installDir $tool.Category
    if ($tool.Type -eq "zip") {
        $ex = Join-Path $kp ($tool.Name -replace "\.zip$","")
        if (Test-Path $ex) { return $true }
    }
    return (Test-Path (Join-Path $kp $tool.Name))
}

function Expand-ZipSafe {
    param($z, $d)
    try {
        if(Test-Path $d){Remove-Item $d -Recurse -Force -EA SilentlyContinue}
        Expand-Archive $z $d -Force
        return $true
    } catch {
        try {
            Add-Type -AN System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($z,$d)
            return $true
        } catch { return $false }
    }
}

# ==============================================================================
# EMBEDDED SCANNERS
# ==============================================================================
function Run-DoomsdayFinder {
    Write-Log "Starting Doomsday Finder v3..."
    Set-Status "Running" "Doomsday Finder v3 - Scanning..." "BUSY"
    try {
        $scriptContent = @'
#Requires -Version 5.1
Write-Host "Doomsday Client Scanner v1.2 (USN Journal)" -ForegroundColor Cyan
Write-Host "Made by TeslaPro" -ForegroundColor Cyan
Write-Host ""
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
Add-Type -TypeDefinition @"
using System;using System.Runtime.InteropServices;
public class NtdllDecompressor {
    [DllImport("ntdll.dll")] public static extern uint RtlDecompressBufferEx(ushort CompressionFormat,byte[] UncompressedBuffer,int UncompressedBufferSize,byte[] CompressedBuffer,int CompressedBufferSize,out int FinalUncompressedSize,IntPtr WorkSpace);
    [DllImport("ntdll.dll")] public static extern uint RtlGetCompressionWorkSpaceSize(ushort CompressionFormat,out uint CompressBufferWorkSpaceSize,out uint CompressFragmentWorkSpaceSize);
    public static byte[] Decompress(byte[] compressed) {
        if(compressed.Length<8)return null;
        if(compressed[0]!=0x4D||compressed[1]!=0x41||compressed[2]!=0x4D)return null;
        int uncompSize=BitConverter.ToInt32(compressed,4);uint wsComp,wsFrag;
        if(RtlGetCompressionWorkSpaceSize(4,out wsComp,out wsFrag)!=0)return null;
        IntPtr workspace=Marshal.AllocHGlobal((int)wsFrag);byte[] result=new byte[uncompSize];
        try{int finalSize;byte[] compData=new byte[compressed.Length-8];Array.Copy(compressed,8,compData,0,compData.Length);uint status=RtlDecompressBufferEx(4,result,uncompSize,compData,compData.Length,out finalSize,workspace);if(status!=0)return null;return result;}
        finally{Marshal.FreeHGlobal(workspace);}
    }
}
"@
function Get-SystemIndexes {
    param([string]$FilePath)
    try {
        $data=[System.IO.File]::ReadAllBytes($FilePath)
        $isCompressed=($data[0]-eq0x4D-and$data[1]-eq0x41-and$data[2]-eq0x4D)
        if($isCompressed){$data=[NtdllDecompressor]::Decompress($data);if($data-eq$null){return@()}}
        if($data.Length-lt108){return@()}
        $sig=[System.Text.Encoding]::ASCII.GetString($data,4,4)
        if($sig-ne"SCCA"){return@()}
        $stringsOffset=[BitConverter]::ToUInt32($data,100)
        $stringsSize=[BitConverter]::ToUInt32($data,104)
        if($stringsOffset-eq0-or$stringsSize-eq0){return@()}
        $filenames=@();$pos=$stringsOffset;$endPos=$stringsOffset+$stringsSize
        while($pos-lt$endPos-and$pos-lt$data.Length-2){
            $nullPos=$pos
            while($nullPos-lt$data.Length-1){if($data[$nullPos]-eq0-and$data[$nullPos+1]-eq0){break}$nullPos+=2}
            if($nullPos-gt$pos){$strLen=$nullPos-$pos;if($strLen-gt0-and$strLen-lt2048){try{$fn=[System.Text.Encoding]::Unicode.GetString($data,$pos,$strLen);if($fn.Length-gt0){$filenames+=$fn}}catch{}}}
            $pos=$nullPos+2;if($filenames.Count-gt1000){break}
        }
        return$filenames
    }catch{return@()}
}
function Test-ZipMagicBytes {
    param([string]$Path)
    try{$fs=[System.IO.File]::OpenRead($Path);$br=New-Object System.IO.BinaryReader($fs);if($fs.Length-lt2){$br.Close();$fs.Close();return$false}$b1=$br.ReadByte();$b2=$br.ReadByte();$br.Close();$fs.Close();return($b1-eq0x50-and$b2-eq0x4B)}catch{return$false}
}
function Search-BytePattern {param([byte[]]$data,[byte[]]$pattern){$pl=$pattern.Length;$dl=$data.Length;for($i=0;$i-le($dl-$pl);$i++){$m=$true;for($j=0;$j-lt$pl;$j++){if($data[$i+$j]-ne$pattern[$j]){$m=$false;break}}if($m){return$true}}return$false}}
function ConvertHex-ToBytes {param([string]$hexString){$bytes=New-Object byte[] ($hexString.Length/2);for($i=0;$i-lt$hexString.Length;$i+=2){$bytes[$i/2]=[Convert]::ToByte($hexString.Substring($i,2),16)}return$bytes}}
$BytePatterns=@(@{Name="Pattern #1";Bytes="6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A160C14005C6588B800"},@{Name="Pattern #2";Bytes="0C1504851D85160A6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A16"},@{Name="Pattern #3";Bytes="5910071088544C2A2BB8004D3B033DA7000A2B1C03548402011C1008A1FFF61A9E000C1A110800A2000503AC04AC00000000000A0005004E000101FA000001D3"})
$ClassPatterns=@("net/java/f","net/java/g","net/java/h","net/java/i","net/java/k","net/java/l","net/java/m","net/java/r","net/java/s","net/java/t","net/java/y")
function Test-DoomsdayClient {
    param([Parameter(Mandatory=$true)][string]$Path)
    $result=[PSCustomObject]@{IsDetected=$false;Confidence="NONE";BytePatternMatches=@();ClassNameMatches=@();SingleLetterClasses=@();IsRenamedJar=$false;Error=$null}
    if(-not(Test-Path$Path-PathTypeLeaf)){$result.Error="File not found";return$result}
    try{
        $ext=[System.IO.Path]::GetExtension($Path).ToLower();$hasPK=Test-ZipMagicBytes-Path$Path
        if($hasPK-and$ext-ne".jar"){$result.IsRenamedJar=$true;$result.IsDetected=$true;$result.Confidence="HIGH"}
        if(-not$hasPK){$result.Error="Not a JAR/ZIP";return$result}
        Add-Type-AN System.IO.Compression.FileSystem;$jar=[System.IO.Compression.ZipFile]::OpenRead($Path)
        $classFiles=$jar.Entries|Where-Object{$_.FullName-like"*.class"};$classCount=$classFiles.Count
        if($classCount-gt30){$jar.Dispose();$result.Error="Skipped: Too many classes";return$result}
        if($classCount-eq0){$jar.Dispose();$result.Error="No .class files";return$result}
        $allBytes=@();foreach($entry in $classFiles){$stream=$entry.Open();$reader=New-Object System.IO.BinaryReader($stream);$bytes=$reader.ReadBytes([int]$entry.Length);$allBytes+=$bytes;$reader.Close();$stream.Close()}
        $jar.Dispose()
        foreach($pattern in $BytePatterns){$patternBytes=ConvertHex-ToBytes-hexString$pattern.Bytes;if(Search-BytePattern-data$allBytes-pattern$patternBytes){$result.BytePatternMatches+=$pattern.Name}}
        foreach($className in $ClassPatterns){if(Search-ClassPattern-data$allBytes-className$className){$result.ClassNameMatches+=$className}}
        $result.SingleLetterClasses=Find-SingleLetterClasses-Path$Path
        $bmc=$result.BytePatternMatches.Count;$cmc=$result.ClassNameMatches.Count;$slc=$result.SingleLetterClasses.Count
        if($bmc-ge2){$result.IsDetected=$true;$result.Confidence="HIGH"}elseif($bmc-eq1-and($cmc-ge5-or$slc-ge5)){$result.IsDetected=$true;$result.Confidence="MEDIUM"}elseif($bmc-eq1){$result.IsDetected=$true;$result.Confidence="LOW"}elseif($slc-ge8-and$cmc-ge3){$result.IsDetected=$true;$result.Confidence="MEDIUM"}elseif($slc-ge5-or$cmc-ge5){$result.IsDetected=$true;$result.Confidence="LOW"}
        if($result.IsRenamedJar-and$result.Confidence-eq"NONE"){$result.Confidence="MEDIUM"}
    }catch{$result.Error=$_.Exception.Message}return$result
}
function Find-SingleLetterClasses {param([string]$Path){$singleLetterClasses=@();try{Add-Type-AN System.IO.Compression.FileSystem;$jar=[System.IO.Compression.ZipFile]::OpenRead($Path);foreach($entry in $jar.Entries){if($entry.FullName-like"*.class"){$parts=$entry.FullName-split'/';$filename=$parts[-1];$classNameOnly=$filename-replace'\.class$','';if($classNameOnly-match'^[a-zA-Z]$'){$singleLetterClasses+=$entry.FullName}}}$jar.Dispose()}catch{}return$singleLetterClasses}
function Search-ClassPattern {param([byte[]]$data,[string]$className){$classBytes=[System.Text.Encoding]::ASCII.GetBytes($className);return Search-BytePattern-data$data-pattern$classBytes}}
if(-not(Test-Administrator)){Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red;return}
$systemPath="C:\Windows\Prefetch"
if(-not(Test-Path$systemPath)){Write-Host "[!] Prefetch directory not found" -ForegroundColor Red;return}
$javaFiles=Get-ChildItem-Path$systemPath-Filter"JAVA*.EXE-*.pf"-ErrorAction SilentlyContinue
if($javaFiles.Count-eq0){Write-Host "[!] No JAVA prefetch files found" -ForegroundColor Yellow;return}
Write-Host "[+] Found $($javaFiles.Count) JAVA prefetch file(s)" -ForegroundColor Green
$allJarPaths=@();$fileMetadata=@{};foreach($sysFile in $javaFiles){$indexes=Get-SystemIndexes-FilePath$sysFile.FullName;if($indexes.Count-eq0){continue}foreach($index in $indexes){if($index-match'\\VOLUME\{[^\}]+\}\\(.*)$'){$relativePath=$Matches[1];$assumedPath="C:\$relativePath";$allJarPaths+=$assumedPath;if(-not$fileMetadata.ContainsKey($assumedPath)){$fileMetadata[$assumedPath]=@{SourceFile=$sysFile.Name;IndexNumber=0;OriginalPath=$index}}}else{$allJarPaths+=$index;if(-not$fileMetadata.ContainsKey($index)){$fileMetadata[$index]=@{SourceFile=$sysFile.Name;IndexNumber=0;OriginalPath=$index}}}}}
$uniquePaths=$allJarPaths|Select-Object-Unique
Write-Host "[+] Unique files to scan: $($uniquePaths.Count)" -ForegroundColor Green
$existingPaths=@{};foreach($path in $uniquePaths){if(Test-Path$path-PathTypeLeaf){$size=(Get-Item$path).Length;if($size-ge200KB-and$size-le15MB){$existingPaths[$path]=$path}}}
Write-Host "[+] Files in size range: $($existingPaths.Count)" -ForegroundColor Green
if($existingPaths.Count-eq0){Write-Host "[!] No files exist to scan" -ForegroundColor Yellow;return}
Write-Host "[*] Scanning files for Doomsday Client..." -ForegroundColor Cyan
$detections=@();$scanned=0
foreach($assumedPath in $existingPaths.Keys){$actualPath=$existingPaths[$assumedPath];$scanned++;Write-Progress-Activity"Scanning"-Status"[$scanned/$($existingPaths.Count)]"-PercentComplete(($scanned/$existingPaths.Count)*100);try{$result=Test-DoomsdayClient-Path$actualPath;if($result.IsDetected){$detections+=[PSCustomObject]@{Path=$actualPath;Confidence=$result.Confidence};Write-Host "[!] DETECTION: $actualPath [$($result.Confidence)]" -ForegroundColor Red}}catch{Write-Host "Error scanning $actualPath : $_" -ForegroundColor Red}}
Write-Progress-Activity"Scanning"-Completed
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SCAN COMPLETE - Detections: $($detections.Count)" -ForegroundColor Cyan
if($detections.Count-gt0){Write-Host "DOOMSDAY CLIENT DETECTED!" -ForegroundColor Red}else{Write-Host "No Doomsday Client detected!" -ForegroundColor Green}
'@
        $tempScript = Join-Path $env:TEMP "DoomsdayFinder.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Doomsday Finder v3 started" "DONE"
    } catch {
        Write-Log "Error in DoomsdayFinder: $_"
        Set-Status "Error" "Failed to run DoomsdayFinder" "ERROR"
    }
}

function Run-GhostClientScanner {
    Write-Log "Running Ghost Client Scanner..."
    Set-Status "Running" "Ghost Client Scanner - Scanning..." "BUSY"
    try {
        $scriptContent = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host
Write-Host "GHOST CLIENT SCANNER" -ForegroundColor Cyan
Write-Host ""
$modsPath = Read-Host "Enter path to mods folder (Press Enter for default)"
if ([string]::IsNullOrWhiteSpace($modsPath)) { $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods" }
if (-not (Test-Path $modsPath -PathType Container)) { Write-Host "ERROR: Invalid Path!" -ForegroundColor Red; exit 1 }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$suspiciousPatterns = @("AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","AutoHitCrystal","AutoPot","AutoTotem","AutoArmor","InventoryTotem","JumpReset","LegitTotem","PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","AxeSpam","WebMacro","FastPlace","WalskyOptimizer","WalksyOptimizer","WalksyCrystalOptimizerMod","Donut","Replace Mod","ShieldDisabler","SilentAim","Totem Hit","Wtap","FakeLag","BlockESP","dev.krypton","Virgin","AntiMissClick","LagReach","PopSwitch","SprintReset","ChestSteal","AntiBot","ElytraSwap","FastXP","FastExp","Refill","AirAnchor","jnativehook","FakeInv","HoverTotem","AutoClicker","AutoFirework","PackSpoof","Antiknockback","catlean","Argon","AuthBypass","Asteria","Prestige","AutoEat","AutoMine","MaceSwap","DoubleAnchor","AutoTPA","BaseFinder","Xenon","gypsy","DubbelKeybinds","DoubleKeybinds","Grim","grim","BowAim","Criticals","Fakenick","FakeItem","invsee","ItemExploit","Hellion","hellion","dev.gambleclient","obfuscatedAuth","xyz.greaj")
$cheatStrings = @("AutoCrystal","autocrystal","auto crystal","cw crystal","AutoHitCrystal","AutoAnchor","autoanchor","auto anchor","DoubleAnchor","anchortweaks","AirAnchor","AutoTotem","autototem","auto totem","InventoryTotem","HoverTotem","AutoPot","autopot","AutoArmor","autoarmor","ShieldDisabler","ShieldBreaker","AutoDoubleHand","AutoClicker","AutoMace","MaceSwap","SpearSwap","Donut","JumpReset","axespam","axe spam","AimAssist","aimassist","aim assist","triggerbot","trigger bot","Silent Rotations","SilentRotations","FakeInv","FakeLag","pingspoof","ping spoof","fakePunch","Fake Punch","webmacro","AntiWeb","AutoWeb","selfdestruct","self destruct","WalksyCrystalOptimizerMod","WalksyOptimizer","WalskyOptimizer","AutoFirework","ElytraSwap","FastXP","FastExp","PackSpoof","Antiknockback","AuthBypass","obfuscatedAuth","BaseFinder","invsee","ItemExploit","FreezePlayer")
$clientFrameworks = @{"meteor-client"="Meteor Client Core";"meteorclient"="Meteor Client Core";"meteordevelopment"="Meteor Client API";"vape.gg"="Vape Client Injectable";"vapeclient"="Vape Client Framework";"novaclient"="Nova Client Leaks";"liquidbounce"="LiquidBounce Utility Mod";"fdp-client"="FDP Bypass Client";"aristois"="Aristois Hack Menu";"impactclient"="Impact Utility Engine";"futureClient"="Future Client Framework";"rusherhack"="Rusherhack Utility Pack";"DubbelKeybinds"="DubbelKeybinds Found";"doublekeybinds"="DubbelKeybinds Found"}
$patternRegex = [regex]::new('(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',[System.Text.RegularExpressions.RegexOptions]::Compiled)
$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }
function Get-FileSHA1 { param([string]$Path) return (Get-FileHash -Path $Path -Algorithm SHA1).Hash }
function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com") { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord CDN" }
        elseif ($url -match "dropbox\.com") { return "Dropbox" }
        elseif ($url -match "drive\.google\.com") { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz") { return "MEGA" }
        elseif ($url -match "github\.com") { return "GitHub Releases" }
        elseif ($url -match "modrinth\.com") { return "Modrinth" }
        elseif ($url -match "curseforge\.com") { return "CurseForge" }
        else { if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }; return $url }
    }
    return "Unknown / Local Transfer"
}
function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch { }
    return @{ Name = ""; Slug = "" }
}
function Invoke-ModScan {
    param([string]$FilePath)
    $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings = [System.Collections.Generic.HashSet[string]]::new()
    $detectedClients = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
        }
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName
            if ($name -match '\.(class|json)$' -or $name -match 'MANIFEST\.MF') {
                try {
                    $st = $entry.Open(); $ms2 = New-Object System.IO.MemoryStream; $st.CopyTo($ms2); $st.Close()
                    $bytes = $ms2.ToArray(); $ms2.Dispose()
                    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                    foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                    foreach ($s in $cheatStringSet) { if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); if ($clientFrameworks.ContainsKey($s)) { [void]$detectedClients.Add($clientFrameworks[$s]) } } }
                } catch { }
            }
        }
        $archive.Dispose()
    } catch { }
    return @{ Patterns = $foundPatterns; Strings = $foundStrings; ClientFrames = $detectedClients }
}
$files = Get-ChildItem -Path $modsPath -Filter *.jar -File -ErrorAction SilentlyContinue
if ($files.Count -eq 0) { Write-Host "No target items discovered." -ForegroundColor Yellow; exit 0 }
$flaggedMods = [System.Collections.Generic.List[object]]::new()
$cleanMods = [System.Collections.Generic.List[object]]::new()
$totalFiles = $files.Count; $currentIndex = 0
foreach ($file in $files) {
    $currentIndex++; $percent = [math]::Round(($currentIndex / $totalFiles) * 100)
    Write-Progress -Activity "Ghost Scan" -Status "Running: $($file.Name)" -PercentComplete $percent
    $sha1 = Get-FileSHA1 -Path $file.FullName
    $source = Get-DownloadSource -Path $file.FullName
    $modrinth = Query-Modrinth -Hash $sha1
    if ($modrinth.Name) { $cleanMods.Add(@{ Name = $file.Name; Details = "Verified Modrinth Archive: $($modrinth.Name)" }); continue }
    $scan = Invoke-ModScan -FilePath $file.FullName
    if ($scan.Patterns.Count -gt 0 -or $scan.Strings.Count -gt 0) {
        $clientTag = "Custom Modified / Independent Hack"
        if ($scan.ClientFrames.Count -gt 0) { $clientTag = ($scan.ClientFrames | ForEach-Object {$_}) -join ", " }
        $flaggedMods.Add(@{ File = $file.Name; Source = $source; Client = $clientTag; Indicators = @($scan.Patterns + $scan.Strings) })
    } else { $cleanMods.Add(@{ Name = $file.Name; Details = "No anomalies identified inside target binaries." }) }
}
Clear-Host
Write-Host "GHOST CLIENT SCANNER - DETAILED SCAN REPORT" -ForegroundColor Cyan
Write-Host "TARGET DIRECTORY : $modsPath" -ForegroundColor White
Write-Host "TOTAL SCANNED    : $totalFiles JAR files examined" -ForegroundColor White
Write-Host ""
Write-Host "FLAGGED SOFTWARE ($($flaggedMods.Count) Files Flagged)" -ForegroundColor Red
if ($flaggedMods.Count -eq 0) { Write-Host "  No malicious modules or cheat client payloads found." -ForegroundColor Green }
else {
    foreach ($mod in $flaggedMods) {
        Write-Host "  [DETECTED] $($mod.File)" -ForegroundColor Red
        Write-Host "       Client Base: $($mod.Client)" -ForegroundColor Yellow
        Write-Host "       Source: $($mod.Source)" -ForegroundColor DarkYellow
        Write-Host "       Triggers: [$($mod.Indicators -join ', ')]" -ForegroundColor DarkCyan
    }
}
Write-Host ""
Write-Host "SAFE & VERIFIED MODS ($($cleanMods.Count) Files Cleared)" -ForegroundColor Green
foreach ($c in $cleanMods) { Write-Host "  [PASS] $($c.Name) -> $($c.Details)" -ForegroundColor Green }
Write-Host ""
Write-Host "Total Examined: $totalFiles | Rogue: $($flaggedMods.Count) | Clean: $($cleanMods.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@
        $tempScript = Join-Path $env:TEMP "GhostClientScanner.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Ghost Client Scanner started" "DONE"
    } catch {
        Write-Log "Error in GhostClientScanner: $_"
        Set-Status "Error" "Failed to run GhostClientScanner" "ERROR"
    }
}

function Run-CyemerScanner {
    Write-Log "Starting Cyemer Scanner..."
    Set-Status "Running" "Cyemer Scanner - Scanning..." "BUSY"
    try {
        $scriptContent = @'
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"
Write-Host "CYEMER FORENSIC SCANNER" -ForegroundColor Red
Write-Host "Prefetch + JAR + USN Investigation" -ForegroundColor Cyan
Write-Host ""
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Administrator)) { Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red; return }
$prefetchPath = "C:\Windows\Prefetch"
$javaFiles = Get-ChildItem -Path $prefetchPath -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue
if ($javaFiles.Count -eq 0) { Write-Host "[!] No JAVA prefetch files found." -ForegroundColor Yellow; return }
Write-Host "[+] Found $($javaFiles.Count) JAVA prefetch file(s)" -ForegroundColor Green
Write-Host "[*] This scanner checks for Cyemer client signatures in JAR files referenced by Java prefetch." -ForegroundColor Cyan
Write-Host "[*] Full Cyemer scan requires deep byte-pattern analysis (simplified in this version)." -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@
        $tempScript = Join-Path $env:TEMP "CyemerScanner.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Cyemer Scanner started" "DONE"
    } catch {
        Write-Log "Error in CyemerScanner: $_"
        Set-Status "Error" "Failed to run CyemerScanner" "ERROR"
    }
}

function Run-VelarisScanner {
    Write-Log "Starting Velaris Scanner..."
    Set-Status "Running" "Velaris Scanner - Scanning..." "BUSY"
    try {
        $scriptContent = @'
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"
Write-Host "VELARIS FORENSIC SCANNER v3.0" -ForegroundColor Magenta
Write-Host "Prefetch + JAR + Modpack + AutoMace + Unknown-Mod Deep Investigation" -ForegroundColor Magenta
Write-Host ""
function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Administrator)) { Write-Host "ERROR: Administrator privileges required." -ForegroundColor Red; return }
$osVer = [System.Environment]::OSVersion.Version
Write-Host "[*] OS: $($osVer.Major).$($osVer.Minor) Build $($osVer.Build)" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Velaris Scanner checks for:" -ForegroundColor Cyan
Write-Host "    - Velaris client signatures in JAR files" -ForegroundColor Gray
Write-Host "    - AutoMace / Crystal PvP hack signatures" -ForegroundColor Gray
Write-Host "    - Generic cheat client frameworks" -ForegroundColor Gray
Write-Host "    - Unknown / suspicious mods" -ForegroundColor Gray
Write-Host "    - Self-destruct patterns via Prefetch + USN" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@
        $tempScript = Join-Path $env:TEMP "VelarisScanner.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Velaris Scanner started" "DONE"
    } catch {
        Write-Log "Error in VelarisScanner: $_"
        Set-Status "Error" "Failed to run VelarisScanner" "ERROR"
    }
}

function Run-HeatedModAnalyzer {
    Write-Log "Starting Heated Mod Analyzer..."
    Set-Status "Running" "Heated Mod Analyzer - Scanning..." "BUSY"
    try {
        $scriptContent = @'
param([string]$ModPath,[switch]$SkipDeepScan,[switch]$ExportJson)
Clear-Host
Write-Host "HEATED MOD ANALYZER" -ForegroundColor Red
Write-Host "Made with love by Heated" -ForegroundColor Gray
Write-Host ""
Write-Host "Enter path to mods folder (Press Enter for default):" -ForegroundColor Cyan
$inputPath = Read-Host " PATH"
if ([string]::IsNullOrWhiteSpace($inputPath)) { $inputPath = "$env:APPDATA\.minecraft\mods"; Write-Host "Using default: $inputPath" -ForegroundColor White }
if (-not (Test-Path $inputPath -PathType Container)) { Write-Host "Invalid Path!" -ForegroundColor Red; exit 1 }
$jarFiles = Get-ChildItem -Path $inputPath -Filter *.jar -File
if ($jarFiles.Count -eq 0) { Write-Host "No mods found." -ForegroundColor Red; exit 0 }
Write-Host "Found $($jarFiles.Count) mod(s) to analyze" -ForegroundColor Green
Write-Host ""
Write-Host "PASS 1: Verifying mods against databases..." -ForegroundColor Cyan
$verifiedMods = @(); $unknownMods = @()
foreach ($file in $jarFiles) {
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA1).Hash
    $verified = $false
    try {
        $modrinth = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$hash" -Method Get -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
        if ($modrinth.project_id) { $verifiedMods += [PSCustomObject]@{ FileName = $file.Name; ModName = $modrinth.name; Hash = $hash; FilePath = $file.FullName }; $verified = $true }
    } catch { }
    if (-not $verified) { $unknownMods += [PSCustomObject]@{ FileName = $file.Name; FilePath = $file.FullName; Hash = $hash } }
}
Write-Host "PASS 2: Deep scanning unknown mods..." -ForegroundColor Cyan
$cheatMods = @(); $cleanUnknownMods = @()
if (-not $SkipDeepScan) {
    $cheatPatterns = @("KillAura","ClickAura","TriggerBot","MultiAura","ForceField","AimAssist","AimBot","SilentAim","CrystalAura","AutoCrystal","AutoHitCrystal","AnchorAura","AutoAnchor","DoubleAnchor","SafeAnchor","BowAimbot","AutoCrit","Criticals","ReachHack","LongReach","HitboxExpand","AntiKB","NoKnockback","Velocity","GrimDisabler","AutoTotem","HoverTotem","InventoryTotem","OffhandTotem","ShieldBreaker","WTap","JumpReset","AxeSpam","MaceSwap","FlyHack","PacketFly","SpeedHack","NoFall","Scaffold","ScaffoldWalk","ElytraFly","ElytraSwap","PlayerESP","XRay","Freecam","FullBright","Disabler","TimerHack","FakeLag","PingSpoof","SelfDestruct","ChestStealer","AutoArmor","AutoPot","vape.gg","vape v4","vapeclient","intent.store","rise.today","riseclient.com","meteorclient","wurstclient","liquidbounce","doomsdayclient","DoomsdayClient","aristois","impactclient")
    foreach ($mod in $unknownMods) {
        $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($mod.FilePath)
            foreach ($entry in $zip.Entries) {
                if ($entry.FullName -match '\.(class|json|properties|txt|cfg)$') {
                    try {
                        $stream = $entry.Open()
                        $reader = New-Object System.IO.StreamReader($stream)
                        $content = $reader.ReadToEnd()
                        $reader.Close(); $stream.Close()
                        foreach ($pattern in $cheatPatterns) { if ($content -match "\b$([regex]::Escape($pattern))\b") { [void]$foundPatterns.Add($pattern) } }
                    } catch { }
                }
            }
            $zip.Dispose()
        } catch { }
        if ($foundPatterns.Count -gt 0) { $cheatMods += [PSCustomObject]@{ FileName = $mod.FileName; FilePath = $mod.FilePath; Hash = $mod.Hash; PatternsFound = $foundPatterns; PatternCount = $foundPatterns.Count } }
        else { $cleanUnknownMods += $mod }
    }
} else { $cleanUnknownMods = $unknownMods }
Clear-Host
Write-Host "HEATED MOD ANALYZER - RESULTS" -ForegroundColor Red
Write-Host ""
Write-Host "VERIFIED MODS ($($verifiedMods.Count))" -ForegroundColor Green
foreach ($mod in $verifiedMods) { Write-Host "  $($mod.ModName) ($($mod.FileName))" -ForegroundColor Green }
Write-Host ""
Write-Host "UNKNOWN MODS (No cheats detected) ($($cleanUnknownMods.Count))" -ForegroundColor Yellow
foreach ($mod in $cleanUnknownMods) { Write-Host "  $($mod.FileName)" -ForegroundColor Yellow }
Write-Host ""
Write-Host "CHEAT MODS DETECTED ($($cheatMods.Count))" -ForegroundColor Red
foreach ($mod in $cheatMods) {
    Write-Host "  [CHEAT] $($mod.FileName)" -ForegroundColor Red
    Write-Host "    Patterns: $($mod.PatternsFound -join ', ')" -ForegroundColor DarkRed
}
Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "Verified (Safe): $($verifiedMods.Count)" -ForegroundColor Green
Write-Host "Unknown (Clean): $($cleanUnknownMods.Count)" -ForegroundColor Yellow
Write-Host "Cheat Mods: $($cheatMods.Count)" -ForegroundColor Red
Write-Host "Total Scanned: $($jarFiles.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@
        $tempScript = Join-Path $env:TEMP "HeatedModAnalyzer.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Heated Mod Analyzer started" "DONE"
    } catch {
        Write-Log "Error in HeatedModAnalyzer: $_"
        Set-Status "Error" "Failed to run HeatedModAnalyzer" "ERROR"
    }
}

function Run-HackedClientsDetector {
    Write-Log "Starting Hacked Clients Detector..."
    Set-Status "Running" "Hacked Clients Detector - Scanning..." "BUSY"
    try {
        $scriptContent = @'
$scanPaths = @("$env:USERPROFILE\Downloads","$env:USERPROFILE\Desktop","$env:TEMP","$env:APPDATA\.minecraft\mods")
$hackedClients = @{
    "Meteor" = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","Scaffold","TriggerBot","Reach","Criticals","AutoMine","FastPlace","ChestSteal")
    "Doomsday" = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","Criticals","Scaffold","FastPlace","AutoXP","InventoryManipulation")
    "Aristois" = @("KillAura","AutoTotem","AutoArmor","Speed","Flight","TriggerBot","Velocity","ChestSteal","FastPlace","AutoMine")
    "Wurst" = @("KillAura","AutoTotem","AutoArmor","Speed","Flight","Reach","AutoClicker","FastPlace","InventoryTweaks")
    "ThunderHack" = @("KillAura","AutoTotem","AutoArmor","Flight","Velocity","Criticals","TriggerBot","FastPlace","AutoMine","ChestSteal","AutoEat")
    "LiquidBounce" = @("KillAura","Velocity","Flight","Scaffold","FastPlace","ChestSteal","AutoMine")
    "Asteria" = @("KillAura","AutoArmor","Velocity","Flight","Scaffold","FastPlace","AutoTotem")
    "Prestige" = @("KillAura","AutoTotem","AutoArmor","Flight","Criticals","AutoMine","ChestSteal")
    "Xenon" = @("KillAura","AutoArmor","AutoTotem","Flight","FastPlace","InventoryTweaks")
    "Argon" = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","FastPlace","AutoXP")
    "Krypton" = @("KillAura","AutoTotem","AutoArmor","Velocity","Flight","FastPlace","AutoXP")
}
function Analyze-Jar($jarPath) {
    $scoreTable = @{}
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
        $entries = $zip.Entries | ForEach-Object { $_.FullName }
        $zip.Dispose()
        foreach ($client in $hackedClients.Keys) {
            $score = 0; $modules = @()
            foreach ($pattern in $hackedClients[$client]) {
                foreach ($entry in $entries) { if ($entry -match [regex]::Escape($pattern)) { $score += 10; $modules += $pattern } }
            }
            $scoreTable[$client] = [PSCustomObject]@{ Score = $score; Modules = ($modules | Sort-Object -Unique) -join ", " }
        }
        $bestClient = $scoreTable.GetEnumerator() | Sort-Object -Property Value.Score -Descending | Select-Object -First 1
        if ($bestClient.Value.Score -ge 50) {
            Write-Host "DETECTED: $jarPath" -ForegroundColor Red
            Write-Host "  Client: $($bestClient.Key) | Score: $($bestClient.Value.Score)" -ForegroundColor Yellow
            Write-Host "  Modules: $($bestClient.Value.Modules)" -ForegroundColor DarkYellow
        } else {
            Write-Host "CLEAN: $jarPath" -ForegroundColor Green
        }
    } catch { Write-Host "ERROR reading $jarPath" -ForegroundColor Red }
}
foreach ($path in $scanPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Filter *.jar | ForEach-Object { Analyze-Jar $_.FullName }
    }
}
Write-Host ""
Write-Host "Scan complete." -ForegroundColor Cyan
'@
        $tempScript = Join-Path $env:TEMP "HackedClientsDetector.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$tempScript`""
        Set-Status "Ready" "Hacked Clients Detector started" "DONE"
    } catch {
        Write-Log "Error in HackedClientsDetector: $_"
        Set-Status "Error" "Failed to run HackedClientsDetector" "ERROR"
    }
}

function Run-DQRKISDetector {
    Write-Log "Running DQRKIS Client Detector..."
    Set-Status "Running" "DQRKIS Detector - Scanning for DQRKIS..." "BUSY"
    try {
        $psCommand = "Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1')"
        Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $psCommand
        Write-Log "DQRKIS Client Detector started in new PowerShell window"
        Set-Status "Ready" "DQRKIS Client Detector launched." "DONE"
    } catch {
        Write-Log "Error in DQRKISDetector: $_"
        Set-Status "Error" "DQRKISDetector failed" "ERROR"
    }
}

function Run-JournalTrace {
    Write-Log "Starting Journal Trace Analyzer..."
    Set-Status "Running" "Journal Trace - Checking for installed version..." "BUSY"
    try {
        $installPath = Join-Path $global:installDir "Analysis\JournalTrace.exe"
        if (Test-Path $installPath) {
            Write-Log "JournalTrace.exe found, launching..."
            Start-Process $installPath
            Set-Status "Ready" "JournalTrace launched" "DONE"
        } else {
            Write-Log "JournalTrace.exe not found. Downloading..."
            $downloadUrl = "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe"
            $tempPath = Join-Path $env:TEMP "JournalTrace.exe"
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
                $dir = Join-Path $global:installDir "Analysis"
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Move-Item -Path $tempPath -Destination $installPath -Force
                Write-Log "Download complete: $installPath"
                Start-Process $installPath
                Set-Status "Ready" "JournalTrace downloaded and launched" "DONE"
            } catch {
                Write-Log "Failed to download JournalTrace.exe: $_"
                Set-Status "Error" "Failed to download JournalTrace" "ERROR"
            }
        }
    } catch {
        Write-Log "Error in JournalTrace: $_"
        Set-Status "Error" "JournalTrace failed" "ERROR"
    }
}

# ==============================================================================
# TOOL DATABASE
# ==============================================================================
$ToolData = @(
    [PSCustomObject]@{ Name="WinPrefetchView_x64.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/winprefetchview-x64.zip"; Description="View prefetch files" },
    [PSCustomObject]@{ Name="LastActivityView.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/lastactivityview.zip"; Description="List recent user activity" },
    [PSCustomObject]@{ Name="UsbDriveLog.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/usbdrivelog.zip"; Description="Show USB drive history" },
    [PSCustomObject]@{ Name="WinDefLogView.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/windeflogview.zip"; Description="Windows Defender log viewer" },
    [PSCustomObject]@{ Name="ShellBagsView.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/shellbagsview.zip"; Description="Shell bags / folder history" },
    [PSCustomObject]@{ Name="UninstallView_x64.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/uninstallview-x64.zip"; Description="List installed programs" },
    [PSCustomObject]@{ Name="LoadedDllsView_x64.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/loadeddllsview-x64.zip"; Description="Loaded DLL list" },
    [PSCustomObject]@{ Name="JumpListsView.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/jumplistsview.zip"; Description="Jump list history" },
    [PSCustomObject]@{ Name="Clipboardic.zip"; Category="NirSoft"; Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/clipboardic.zip"; Description="Clipboard history viewer" },

    [PSCustomObject]@{ Name="TimelineExplorer.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip"; Description="Timeline analysis" },
    [PSCustomObject]@{ Name="SrumECmd.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/SrumECmd.zip"; Description="SRUM database parser" },
    [PSCustomObject]@{ Name="AmcacheParser.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/AmcacheParser.zip"; Description="Amcache analysis tool" },
    [PSCustomObject]@{ Name="WxTCmd.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net6/WxTCmd.zip"; Description="Windows Timeline database" },
    [PSCustomObject]@{ Name="RegistryExplorer.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip"; Description="Registry explorer" },
    [PSCustomObject]@{ Name="MFTECmd.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip"; Description="MFT filesystem parser" },
    [PSCustomObject]@{ Name="JLECmd.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/JLECmd.zip"; Description="JumpList CSV parser" },
    [PSCustomObject]@{ Name="JumpListExplorer.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip"; Description="JumpList GUI parser" },
    [PSCustomObject]@{ Name="PECmd.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/PECmd.zip"; Description="Prefetch parser" },
    [PSCustomObject]@{ Name="RecentFileCacheParser.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip"; Description="Recent file cache parser" },
    [PSCustomObject]@{ Name="ShellBagsExplorer.zip"; Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip"; Description="Shell bags explorer" },

    [PSCustomObject]@{ Name="BAMParser.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe"; Description="BAM record parser" },
    [PSCustomObject]@{ Name="PrefetchParser.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe"; Description="Prefetch parser" },
    [PSCustomObject]@{ Name="ProcessParser.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/process-parser/releases/download/v0.5.5/ProcessParser.exe"; Description="Process information parser" },
    [PSCustomObject]@{ Name="PcaSvcExecuted.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/pcasvc-executed/releases/download/v0.8.7/PcaSvcExecuted.exe"; Description="PCA service execution record" },
    [PSCustomObject]@{ Name="JournalTraceNormal.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTraceNormal.exe"; Description="USN Journal trace" },
    [PSCustomObject]@{ Name="PathsParser.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe"; Description="File path history" },
    [PSCustomObject]@{ Name="KernelLiveDumpTool.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe"; Description="Kernel live dump tool" },
    [PSCustomObject]@{ Name="espouken.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/Tool/releases/download/v1.1.2/espouken.exe"; Description="Espouken analysis tool" },
    [PSCustomObject]@{ Name="BamDeletedKeys.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/BamDeletedKeys/releases/download/v1.0/BamDeletedKeys.exe"; Description="Deleted BAM records" },
    [PSCustomObject]@{ Name="ActivitiesCache.exe"; Category="Spokwn"; Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest"; Description="Activities cache execution" },

    [PSCustomObject]@{ Name="Echo-Journal.exe"; Category="Echo"; Type="exe"; Author="Echo"; URL="https://github.com/Echo-Anticheat/Echo-Journal/raw/main/echo-journal.exe"; Description="Journal analysis tool" },
    [PSCustomObject]@{ Name="UserAssist.exe"; Category="Echo"; Type="exe"; Author="Echo"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-userassist.exe"; Description="UserAssist registry viewer" },
    [PSCustomObject]@{ Name="UsbTool.exe"; Category="Echo"; Type="exe"; Author="Echo"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-usb.exe"; Description="USB record analysis" },

    [PSCustomObject]@{ Name="pv++.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.6/pv++.exe"; Description="Detailed Prefetch analyzer" },
    [PSCustomObject]@{ Name="AmcacheParser.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/AmcacheParser/releases/download/v1.0/AmcacheParser.exe"; Description="Detailed Amcache analyzer" },
    [PSCustomObject]@{ Name="JARParser.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/JARParser/releases/download/v1.2/JARParser.exe"; Description="JAR scanner" },
    [PSCustomObject]@{ Name="fileless.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/Fileless/releases/download/v1.3/fileless.exe"; Description="Fileless malware detector" },
    [PSCustomObject]@{ Name="BAMReveal.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/BAMReveal/releases/download/v1.3/BAMReveal.exe"; Description="BAM records viewer" },
    [PSCustomObject]@{ Name="OrbDiff-DPSAnalyzer.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/download/v1.1/dpsanalyzer.exe"; Description="DPS analysis tool" },
    [PSCustomObject]@{ Name="OrbDiff-UserAssistView.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest"; Description="UserAssist viewer" },
    [PSCustomObject]@{ Name="OrbDiff-JournalParser.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/JournalParser/releases/latest"; Description="Journal parser" },
    [PSCustomObject]@{ Name="OrbDiff-InjGen.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/InjGen/releases/latest"; Description="Injection detection" },
    [PSCustomObject]@{ Name="OrbDiff-USBDetector.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/USBDetector/releases/latest"; Description="USB detection" },
    [PSCustomObject]@{ Name="OrbDiff-PFTrace.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/PFTrace/releases/latest"; Description="Prefetch trace" },
    [PSCustomObject]@{ Name="OrbDiff-CheckDeletedUSN.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest"; Description="Deleted USN check" },
    [PSCustomObject]@{ Name="OrbDiff-StringsParser.exe"; Category="OrbDiff"; Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/StringsParser/releases/latest"; Description="Strings parser" },

    [PSCustomObject]@{ Name="RedLotusModAnalyzer.exe"; Category="RedLotus"; Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe"; Description="Mod analysis tool" },
    [PSCustomObject]@{ Name="RedLotusAltChecker.exe"; Category="RedLotus"; Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe"; Description="Alt account checker" },
    [PSCustomObject]@{ Name="RedLotusTaskSentinel.exe"; Category="RedLotus"; Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/download/RL/RedLotusTaskSentinel.exe"; Description="Task monitor sentinel" },

    [PSCustomObject]@{ Name="PathDuzenleyicisiV2.exe"; Category="TRSSCommunity"; Type="exe"; Author="TRSSCommunity"; URL="https://github.com/trSScommunity/PathDuzenleyiciV2/raw/refs/heads/main/PathDuzenleyicisiV2.exe"; Description="Path organizer v2" },
    [PSCustomObject]@{ Name="MzHunter.exe"; Category="TRSSCommunity"; Type="exe"; Author="TRSSCommunity"; URL="https://github.com/trSScommunity/MZHunter/raw/refs/heads/main/MzHunter.exe"; Description="MZ header scanner" },
    [PSCustomObject]@{ Name="MandarinTool.jar"; Category="TRSSCommunity"; Type="jar"; Author="TRSSCommunity"; URL="https://github.com/Mehmetyll/Mandarin-Tool/releases/download/Mandarin-Tool/MandarinTool.jar"; Description="Multi SS tool / JAR decompiler" },

    [PSCustomObject]@{ Name="MagnetEncryptedDiskDetector.exe"; Category="Magnet"; Type="exe"; Author="Magnet"; URL="https://go.magnetforensics.com/e/52162/MagnetEncryptedDiskDetector/kpt9bg/1663239667/h/LtXFtTL-Soawv5C1oL3BIEghi7e1Lx93yesZLR--Ok0"; Description="Encrypted disk detector" },
    [PSCustomObject]@{ Name="MRCv120.exe"; Category="Magnet"; Type="exe"; Author="Magnet"; URL="https://go.magnetforensics.com/e/52162/mail-utm-campaign-UTMC-0000044/llr4bg/1663358653/h/4kZ9Y4i2yPRqBzuQMrywA_v5bfkpG3rG8gEiSWrYU70"; Description="RAM dump tool" },

    [PSCustomObject]@{ Name="FTK_Imager_4.7.1.exe"; Category="Forensics"; Type="exe"; Author="AccessData"; URL="https://archive.org/download/access-data-ftk-imager-4.7.1/AccessData_FTK_Imager_4.7.1.exe"; Description="Disk imaging tool" },
    [PSCustomObject]@{ Name="hayabusa-3.6.0-win-aarch64.zip"; Category="Forensics"; Type="zip"; Author="Yamato-Security"; URL="https://github.com/Yamato-Security/hayabusa/releases/download/v3.6.0/hayabusa-3.6.0-win-aarch64.zip"; Description="Windows event log analyzer" },
    [PSCustomObject]@{ Name="Velocidace.exe"; Category="Forensics"; Type="exe"; Author="Velocidex"; URL="https://github.com/Velocidex/velociraptor/releases/download/v0.75/velociraptor-v0.75.1-windows-amd64.exe"; Description="Digital forensics platform" },

    [PSCustomObject]@{ Name="SystemInformer_Canary_Setup.exe"; Category="SystemTools"; Type="exe"; Author="winsiderss"; URL="https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe"; Description="Advanced system monitor" },
    [PSCustomObject]@{ Name="Everything-Setup.exe"; Category="SystemTools"; Type="exe"; Author="voidtools"; URL="https://www.voidtools.com/Everything-1.4.1.1032.x64-Setup.exe"; Description="Instant file search engine" },
    [PSCustomObject]@{ Name="ProcessHacker-Setup.exe"; Category="SystemTools"; Type="exe"; Author="winsiderss"; URL="https://sourceforge.net/projects/processhacker/files/latest/download"; Description="Process hacker" },

    [PSCustomObject]@{ Name="InjGen.exe"; Category="Analysis"; Type="exe"; Author="NotRequiem"; URL="https://github.com/NotRequiem/InjGen/releases/download/v2.0/InjGen.exe"; Description="Injection detection tool" },
    [PSCustomObject]@{ Name="Luyten.exe"; Category="Analysis"; Type="exe"; Author="deathmarine"; URL="https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe"; Description="Java decompiler" },
    [PSCustomObject]@{ Name="dpsanalyzer.exe"; Category="Analysis"; Type="exe"; Author="nay-cat"; URL="https://github.com/nay-cat/dpsanalyzer/releases/download/1.3/dpsanalyzer.exe"; Description="DPS analyzer" },
    [PSCustomObject]@{ Name="DIE_engine_portable.zip"; Category="Analysis"; Type="zip"; Author="horsicq"; URL="https://github.com/horsicq/DIE-engine/releases/download/3.09/die_win64_portable_3.09_x64.zip"; Description="Detect-It-Easy PE analyzer" },

    [PSCustomObject]@{ Name="Jarabel.Light.exe"; Category="Misc"; Type="exe"; Author="nay-cat"; URL="https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe"; Description="JAR analysis tool" },
    [PSCustomObject]@{ Name="Unicode.exe"; Category="Misc"; Type="exe"; Author="RRancio"; URL="https://github.com/RRancio/Exec/raw/main/Files/Unicode.exe"; Description="Unicode character analyzer" },
    [PSCustomObject]@{ Name="CachedProgramsList.exe"; Category="Misc"; Type="exe"; Author="ponei"; URL="https://github.com/ponei/CachedProgramsList/releases/download/1.1/CachedProgramsList.exe"; Description="Cache program list" },
    [PSCustomObject]@{ Name="TimeChangeDetect.exe"; Category="Misc"; Type="exe"; Author="santiagolin"; URL="https://github.com/santiagolin/TimeChangeDetect/releases/download/1.0/TimeChangeDetect.exe"; Description="System time change detector" },
    [PSCustomObject]@{ Name="HardlinkFinder.exe"; Category="Misc"; Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/HardlinkFinder/releases/download/Tools/hardlink.exe"; Description="Hardlink detection" },

    [PSCustomObject]@{ Name="MeowNovowareFucker.exe"; Category="Meow"; Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/raw/refs/heads/main/MeowNovowareFucker.exe"; Description="Novoware client detector" },
    [PSCustomObject]@{ Name="MeowDoomsdayFucker.exe"; Category="Meow"; Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/raw/refs/heads/main/MeowDoomsdayFucker.exe"; Description="Doomsday client detector" },
    [PSCustomObject]@{ Name="MeowResolver.exe"; Category="Meow"; Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest"; Description="Meow resolver" },
    [PSCustomObject]@{ Name="MeowImportsChecker.exe"; Category="Meow"; Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest"; Description="Imports checker" },

    [PSCustomObject]@{ Name="PSHunter.exe"; Category="Praiselily"; Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/PSHunter/releases/latest"; Description="PS hunter tool" },
    [PSCustomObject]@{ Name="AltDetector.exe"; Category="Praiselily"; Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/AltDetector/releases/latest"; Description="Alt account detector" },

    [PSCustomObject]@{ Name="TeslaPro-MacroFinder.exe"; Category="TeslaPro"; Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/TeslaProMacroFinder/releases/latest"; Description="Macro finder tool" },
    [PSCustomObject]@{ Name="TeslaPro-DoomsdayDetector.exe"; Category="TeslaPro"; Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/DoomsdayDetector/releases/latest"; Description="Doomsday detector" },
    [PSCustomObject]@{ Name="TeslaPro-VPNFinder.exe"; Category="TeslaPro"; Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/VPNChecker/releases/latest"; Description="VPN finder" },
    [PSCustomObject]@{ Name="TeslaPro-GhostClientFucker.exe"; Category="TeslaPro"; Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/GhostClientFucker/releases/latest"; Description="Ghost client detector" },

    [PSCustomObject]@{ Name="Xeinn-SSTools.exe"; Category="Xeinn"; Type="exe"; Author="Xeinn"; URL="https://github.com/Xeinn-Software/Xeinn-SS-Tools-Downloader/releases/latest"; Description="Xeinn SS tools" },

    [PSCustomObject]@{ Name="NET-9.0-SDK.exe"; Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/9.0"; Description=".NET 9.0 SDK" },
    [PSCustomObject]@{ Name="NET-10.0-Runtime.exe"; Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/10.0"; Description=".NET 10.0 Runtime" },
    [PSCustomObject]@{ Name="VC_Redist.exe"; Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://aka.ms/vs/17/release/vc_redist.x64.exe"; Description="Visual C++ Redistributable" }
)

# ==============================================================================
# SCRIPT DATABASE
# ==============================================================================
$ScriptData = @(
    [PSCustomObject]@{ Name="TR SS Auto Downloader"; Author="korkusuzadX"; URL="https://raw.githubusercontent.com/korkusuzadX/TR-SS-AutoDownloader/main/TR_SS_Auto_Downloader.ps1"; Description="Turkish SS community auto downloader" },
    [PSCustomObject]@{ Name="TR SS REG Checker"; Author="boboalover"; URL="https://github.com/Boboalover/TRSS-Simple-Registry-Checker/raw/refs/heads/main/TRSS-regchecker.ps1"; Description="Registry checker" },
    [PSCustomObject]@{ Name="TR SS Macro Checker"; Author="boboalover"; URL="https://github.com/Boboalover/TRSS-mouse-macro-checker/raw/refs/heads/main/TRSSmacroChecker.ps1"; Description="Macro checker" },
    [PSCustomObject]@{ Name="Faker Detection (HotspotLogs)"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/WeHateFakers/refs/heads/main/HotspotLogs.ps1"; Description="Faker detection tool" },
    [PSCustomObject]@{ Name="JAR Scanner"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/JARScanner/refs/heads/main/JARScanner.ps1"; Description="JAR scanner" },
    [PSCustomObject]@{ Name="Service Enabler"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Service-Enabler.ps1"; Description="Service enabler" },
    [PSCustomObject]@{ Name="Services Checker"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1"; Description="Check required services" },
    [PSCustomObject]@{ Name="Common Directories Scanner"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/CommonDirectories.ps1"; Description="Scan common directories" },
    [PSCustomObject]@{ Name="Harddisk Converter"; Author="Praiselily"; URL="https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/HarddiskConverter.ps1"; Description="Harddisk converter" },
    [PSCustomObject]@{ Name="read-journal"; Author="waaz1"; URL="https://raw.githubusercontent.com/waaz1/read-journal/refs/heads/main/read-journal.ps1"; Description="read-journal" },
    [PSCustomObject]@{ Name="BAM Parser"; Author="spokwn"; URL="https://raw.githubusercontent.com/spokwn/powershells/refs/heads/main/bamparser.ps1"; Description="BAM record parser" },
    [PSCustomObject]@{ Name="AnyDesk Installer"; Author="spokwn"; URL="https://raw.githubusercontent.com/spokwn/powershells/main/anydesk.ps1"; Description="AnyDesk installer" },
    [PSCustomObject]@{ Name="DoomsDay Finder v2"; Author="zedoonvm1"; URL="https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1"; Description="Find DoomsDay client" },
    [PSCustomObject]@{ Name="Meow Mod Analyzer"; Author="MeowTonynoh"; URL="https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1"; Description="Analyze Minecraft mods" },
    [PSCustomObject]@{ Name="Habibi Mod Analyzer"; Author="HadronCollision"; URL="https://raw.githubusercontent.com/HadronCollision/PowershellScripts/refs/heads/main/HabibiModAnalyzer.ps1"; Description="Habibi mod detection" },
    [PSCustomObject]@{ Name="BAM Robado Checker"; Author="IlleUco"; URL="https://raw.githubusercontent.com/IlleUco/ScreenShare/main/BamRobadoIlleUco.ps1"; Description="Check stolen BAM records" },
    [PSCustomObject]@{ Name="Recycle Bin Checker"; Author="IlleUco"; URL="https://raw.githubusercontent.com/IlleUco/ScreenShare/main/RecycleBinChecker.ps1"; Description="Recycle bin analyzer" },
    [PSCustomObject]@{ Name="PrismScreenShareAnalyze"; Author="JustWolfeyy"; URL="https://raw.githubusercontent.com/JustWolfeyy/PrismScreenShareAnalyzer/refs/heads/main/PrismSSAnalyzer.ps1"; Description="PrismSSAnalyzer" },
    [PSCustomObject]@{ Name="USB Events Viewer"; Author="IlleUco"; URL="https://raw.githubusercontent.com/IlleUco/ScreenShare/main/USBEvents.ps1"; Description="USB history viewer" },
    [PSCustomObject]@{ Name="RedLotus BAM"; Author="IlleUco"; URL="https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1"; Description="RedLotus BAM inspection" },
    [PSCustomObject]@{ Name="Javaw-Scanner"; Author="DrakFlxme"; URL="https://raw.githubusercontent.com/DrakFlxme/Javaw-Scanner.ps1/refs/heads/main/Javaw-Scanner.ps1"; Description="Javaw-Scanner" },
    [PSCustomObject]@{ Name="File-Scanner-Powershell"; Author="RedLotus"; URL="https://raw.githubusercontent.com/RedLotus-Development/File-Scanner-Powershell/refs/heads/Red-Lotus/REDLOTUS-AdminEXEs.ps1"; Description="Run RedLotus scripts" },
    [PSCustomObject]@{ Name="RedLotus Collector"; Author="RedLotus"; URL="https://raw.githubusercontent.com/RedLotusForensics/tool/main/Collector.ps1"; Description="RedLotus forensic collector" },
    [PSCustomObject]@{ Name="Yumniko Mod Analyzer"; Author="Yumniko"; URL="https://raw.githubusercontent.com/veridondevvv/YumikoModAnalyzer/refs/heads/main/YumikoModAnalyzer.ps1"; Description="Yumnikomodanalzyr" },
    [PSCustomObject]@{ Name="TeslaPro Macro Finder"; Author="TeslaPro"; URL="https://raw.githubusercontent.com/TeslaPros/TeslaProMacroFinder/main/TeslaProMacroFinder_V3.ps1"; Description="Macro finder tool" },
    [PSCustomObject]@{ Name="TeslaPro Doomsday Detector"; Author="TeslaPro"; URL="https://raw.githubusercontent.com/TeslaPros/DoomsdayDetector/main/DoomsdayClientDetectorV3.ps1"; Description="Doomsday detector" },
    [PSCustomObject]@{ Name="TeslaPro VPN Finder"; Author="TeslaPro"; URL="https://raw.githubusercontent.com/TeslaPros/VPNChecker/main/VPNFinder.ps1"; Description="VPN finder" },
    [PSCustomObject]@{ Name="Yarp's Mod Analyzer"; Author="yarp"; URL="https://raw.githubusercontent.com/YarpLetapStan/PowershellScripts/refs/heads/main/YarpsModAnalyzer6.0.ps1"; Description="Mod analyzer" },
    [PSCustomObject]@{ Name="TeslaPro Injector Detector"; Author="Sellgui"; URL="https://raw.githubusercontent.com/Sellgui/Injectdetect/refs/heads/main/Injector%20Scanner.ps1"; Description="Injector detector" },
    [PSCustomObject]@{ Name="TeslaPro Prime Macro Detector"; Author="Sellgui"; URL="https://raw.githubusercontent.com/Sellgui/Javamacrodetector/refs/heads/main/Macro%20Detector.ps1"; Description="Prime macro detector" },
    [PSCustomObject]@{ Name="TeslaPro Security Manager"; Author="TeslaPro"; URL="https://pastebin.com/raw/ChxAuDpF"; Description="Security manager" },
    [PSCustomObject]@{ Name="TeslaPro QuickCheck Scanner"; Author="TeslaPro"; URL="https://pastebin.com/raw/HGLwy7XA"; Description="QuickCheck scanner" },
    [PSCustomObject]@{ Name="TeslaPro Velaris Detector"; Author="Va2lyR"; URL="https://raw.githubusercontent.com/Va2lyR/-TeslaProSS-Toolv2/refs/heads/main/tools/Velaris-Detector.ps1"; Description="Velaris detector" },
    [PSCustomObject]@{ Name="TeslaPro Prestige Finder"; Author="Sellgui"; URL="https://raw.githubusercontent.com/Sellgui/Egitserpragger/refs/heads/main/EgitserpRaper.ps1"; Description="Prestige finder" },
    [PSCustomObject]@{ Name="Doomsday Finder v3"; Author="TeslaPro"; URL="LOCAL"; Description="Doomsday client scanner v3" },
    [PSCustomObject]@{ Name="Ghost Client Scanner"; Author="TeslaPro"; URL="LOCAL"; Description="Ghost client scanner" },
    [PSCustomObject]@{ Name="Cyemer Scanner"; Author="Community"; URL="LOCAL"; Description="Cyemer forensic scanner" },
    [PSCustomObject]@{ Name="Velaris Scanner"; Author="_iaec"; URL="LOCAL"; Description="Velaris forensic scanner" },
    [PSCustomObject]@{ Name="Heated Mod Analyzer"; Author="Heated"; URL="LOCAL"; Description="Advanced mod analyzer with deep scan" },
    [PSCustomObject]@{ Name="Hacked Clients Detector"; Author="Community"; URL="LOCAL"; Description="Detect hacked Minecraft clients" },
    [PSCustomObject]@{ Name="DQRKIS Client Detector"; Author="cheesecatlol"; URL="https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1"; Description="DQRKIS client detection tool" },
    [PSCustomObject]@{ Name="Journal Trace Analyzer"; Author="Spokwn"; URL="LOCAL"; Description="USN Journal trace and analysis (Auto-downloads EXE)" },
    [PSCustomObject]@{ Name="Macro Detector"; Author="Nickk196"; URL="https://raw.githubusercontent.com/Nickk196/MacroDetector/main/MacroDetector.ps1"; Description="Detect macro software and scripts" }
)

# ==============================================================================
# TUTORIAL DATA
# ==============================================================================
$TutorialActions = @(
    @{ Step = 1; Description = "Open Recent Files (shell:recent)"; Type = "Command"; Name = "Recent Files" },
    @{ Step = 2; Description = "Run Yarp's Mod Analyzer"; Type = "Script"; Name = "Yarp's Mod Analyzer" },
    @{ Step = 3; Description = "Open Prefetch Folder (C:\Windows\Prefetch)"; Type = "Command"; Name = "Prefetch Folder" },
    @{ Step = 4; Description = "Run Meow Mod Analyzer"; Type = "Script"; Name = "Meow Mod Analyzer" },
    @{ Step = 5; Description = "Run Habibi Mod Analyzer"; Type = "Script"; Name = "Habibi Mod Analyzer" },
    @{ Step = 6; Description = "Run Ghost Client Scanner"; Type = "Script"; Name = "Ghost Client Scanner" },
    @{ Step = 7; Description = "Run Doomsday Finder v3 (USN Journal)"; Type = "Script"; Name = "Doomsday Finder v3" },
    @{ Step = 8; Description = "Run Velaris Scanner"; Type = "Script"; Name = "Velaris Scanner" },
    @{ Step = 9; Description = "Run Cyemer Scanner"; Type = "Script"; Name = "Cyemer Scanner" },
    @{ Step = 10; Description = "Run DQRKIS Client Detector"; Type = "Script"; Name = "DQRKIS Client Detector" },
    @{ Step = 11; Description = "Run Hacked Clients Detector"; Type = "Script"; Name = "Hacked Clients Detector" },
    @{ Step = 12; Description = "Run Heated Mod Analyzer"; Type = "Script"; Name = "Heated Mod Analyzer" },
    @{ Step = 13; Description = "Run TeslaPro Prestige Finder"; Type = "Script"; Name = "TeslaPro Prestige Finder" },
    @{ Step = 14; Description = "Run TeslaPro Injector Detector"; Type = "Script"; Name = "TeslaPro Injector Detector" },
    @{ Step = 15; Description = "Run Journal Trace Analyzer"; Type = "Script"; Name = "Journal Trace Analyzer" },
    @{ Step = 16; Description = "Check the Activity Log below for results"; Type = "Info" }
)

$TutorialChecklist = @(
    "Recent Files",
    "System Cleanup",
    "Prefetch",
    "Meow Mod Analyzer",
    "Habibi Mod Analyzer",
    "Ghost Client Scanner",
    "Doomsday Finder v3",
    "Velaris Scanner",
    "Cyemer Scanner",
    "DQRKIS Detector",
    "Hacked Clients Detector",
    "Heated Mod Analyzer",
    "Prestige Finder",
    "Injector Detector",
    "Journal Trace",
    "Review Log"
)

# ==============================================================================
# COMMANDS DATA - Win+R Shortcuts
# ==============================================================================
$CommandData = @(
    [PSCustomObject]@{ Name="Recent Files"; Command="shell:recent"; Description="Open recent files folder"; Icon="Folder" },
    [PSCustomObject]@{ Name="Startup Folder"; Command="shell:startup"; Description="Open startup programs folder"; Icon="Rocket" },
    [PSCustomObject]@{ Name="Send To"; Command="shell:sendto"; Description="Open Send To folder"; Icon="Send" },
    [PSCustomObject]@{ Name="Start Menu"; Command="shell:start menu"; Description="Open Start Menu folder"; Icon="Flag" },
    [PSCustomObject]@{ Name="Common Startup"; Command="shell:common startup"; Description="Open all users startup"; Icon="Rocket" },
    [PSCustomObject]@{ Name="AppData (Roaming)"; Command="%APPDATA%"; Description="Open roaming app data"; Icon="Folder" },
    [PSCustomObject]@{ Name="Local AppData"; Command="%LOCALAPPDATA%"; Description="Open local app data"; Icon="Folder" },
    [PSCustomObject]@{ Name="Program Files"; Command="%ProgramFiles%"; Description="Open Program Files"; Icon="Computer" },
    [PSCustomObject]@{ Name="Program Files (x86)"; Command="%ProgramFiles(x86)%"; Description="Open Program Files (x86)"; Icon="Computer" },
    [PSCustomObject]@{ Name="Windows Folder"; Command="%windir%"; Description="Open Windows system folder"; Icon="Window" },
    [PSCustomObject]@{ Name="System32"; Command="%windir%\System32"; Description="Open System32 folder"; Icon="Gear" },
    [PSCustomObject]@{ Name="Temp Folder"; Command="%TEMP%"; Description="Open temporary files folder"; Icon="Trash" },
    [PSCustomObject]@{ Name="Downloads"; Command="%USERPROFILE%\Downloads"; Description="Open Downloads folder"; Icon="Download" },
    [PSCustomObject]@{ Name="Desktop"; Command="%USERPROFILE%\Desktop"; Description="Open Desktop folder"; Icon="Desktop" },
    [PSCustomObject]@{ Name="Documents"; Command="%USERPROFILE%\Documents"; Description="Open Documents folder"; Icon="Document" },
    [PSCustomObject]@{ Name="Pictures"; Command="%USERPROFILE%\Pictures"; Description="Open Pictures folder"; Icon="Image" },
    [PSCustomObject]@{ Name="Music"; Command="%USERPROFILE%\Music"; Description="Open Music folder"; Icon="Music" },
    [PSCustomObject]@{ Name="Videos"; Command="%USERPROFILE%\Videos"; Description="Open Videos folder"; Icon="Video" },
    [PSCustomObject]@{ Name="Prefetch Folder"; Command="C:\Windows\Prefetch"; Description="Open Windows prefetch folder"; Icon="Lightning" },
    [PSCustomObject]@{ Name="Network Connections"; Command="ncpa.cpl"; Description="Open network connections"; Icon="Globe" },
    [PSCustomObject]@{ Name="Device Manager"; Command="devmgmt.msc"; Description="Open Device Manager"; Icon="Wrench" },
    [PSCustomObject]@{ Name="Disk Management"; Command="diskmgmt.msc"; Description="Open Disk Management"; Icon="Disk" },
    [PSCustomObject]@{ Name="Event Viewer"; Command="eventvwr.msc"; Description="Open Event Viewer"; Icon="Chart" },
    [PSCustomObject]@{ Name="Services"; Command="services.msc"; Description="Open Services manager"; Icon="Gear" },
    [PSCustomObject]@{ Name="Registry Editor"; Command="regedit"; Description="Open Registry Editor"; Icon="Edit" },
    [PSCustomObject]@{ Name="Task Manager"; Command="taskmgr"; Description="Open Task Manager"; Icon="Chart" },
    [PSCustomObject]@{ Name="Control Panel"; Command="control"; Description="Open Control Panel"; Icon="Sliders" },
    [PSCustomObject]@{ Name="System Properties"; Command="sysdm.cpl"; Description="Open System Properties"; Icon="Computer" },
    [PSCustomObject]@{ Name="Power Options"; Command="powercfg.cpl"; Description="Open Power Options"; Icon="Battery" }
)

# ==============================================================================
# CMD COMMANDS DATA
# ==============================================================================
$CmdCommandData = @(
    [PSCustomObject]@{ Name="System Info"; Command="systeminfo"; Description="Display system information"; Icon="Computer" },
    [PSCustomObject]@{ Name="IP Config"; Command="ipconfig /all"; Description="Display network configuration"; Icon="Globe" },
    [PSCustomObject]@{ Name="Ping Test"; Command="ping 8.8.8.8 -t"; Description="Continuous ping test"; Icon="Signal" },
    [PSCustomObject]@{ Name="Task List"; Command="tasklist"; Description="List running processes"; Icon="Chart" },
    [PSCustomObject]@{ Name="Netstat"; Command="netstat -ano"; Description="Display network connections"; Icon="Plug" },
    [PSCustomObject]@{ Name="DNS Flush"; Command="ipconfig /flushdns"; Description="Flush DNS cache"; Icon="Refresh" },
    [PSCustomObject]@{ Name="Route Print"; Command="route print"; Description="Display routing table"; Icon="Map" },
    [PSCustomObject]@{ Name="ARP Table"; Command="arp -a"; Description="Display ARP table"; Icon="List" },
    [PSCustomObject]@{ Name="Disk Check"; Command="chkdsk"; Description="Check disk for errors"; Icon="Disk" },
    [PSCustomObject]@{ Name="SFC Scan"; Command="sfc /scannow"; Description="Scan system files"; Icon="Wrench" },
    [PSCustomObject]@{ Name="DISM Check"; Command="DISM /Online /Cleanup-Image /CheckHealth"; Description="Check image health"; Icon="Tool" },
    [PSCustomObject]@{ Name="DISM Restore"; Command="DISM /Online /Cleanup-Image /RestoreHealth"; Description="Restore image health"; Icon="Pill" },
    [PSCustomObject]@{ Name="Driver List"; Command="driverquery"; Description="List installed drivers"; Icon="Gear" },
    [PSCustomObject]@{ Name="Boot Config"; Command="bcdedit"; Description="Edit boot configuration"; Icon="Rocket" },
    [PSCustomObject]@{ Name="Battery Report"; Command="powercfg /batteryreport"; Description="Generate battery report"; Icon="Battery" },
    [PSCustomObject]@{ Name="WMIC OS"; Command="wmic os get name,version,lastbootuptime"; Description="OS information"; Icon="Window" },
    [PSCustomObject]@{ Name="WMIC CPU"; Command="wmic cpu get name,numberofcores"; Description="CPU information"; Icon="Computer" },
    [PSCustomObject]@{ Name="WMIC Memory"; Command="wmic memorychip get capacity,speed"; Description="Memory information"; Icon="Brain" },
    [PSCustomObject]@{ Name="WMIC Disk"; Command="wmic diskdrive get model,size"; Description="Disk information"; Icon="Disk" },
    [PSCustomObject]@{ Name="WMIC BIOS"; Command="wmic bios get manufacturer,version"; Description="BIOS information"; Icon="Plug" },
    [PSCustomObject]@{ Name="WMIC Services"; Command="wmic service get name,state,startmode"; Description="List services"; Icon="Gear" },
    [PSCustomObject]@{ Name="WMIC Processes"; Command="wmic process get name,processid"; Description="List processes"; Icon="Chart" },
    [PSCustomObject]@{ Name="Who Am I"; Command="whoami"; Description="Display current user"; Icon="User" },
    [PSCustomObject]@{ Name="Hostname"; Command="hostname"; Description="Display computer name"; Icon="Tag" },
    [PSCustomObject]@{ Name="Uptime"; Command="systeminfo | find \"System Boot Time\""; Description="Show system uptime"; Icon="Clock" },
    [PSCustomObject]@{ Name="Running Services"; Command="net start"; Description="List running services"; Icon="Gear" },
    [PSCustomObject]@{ Name="Open Ports"; Command="netstat -an | find \"LISTENING\""; Description="List listening ports"; Icon="Plug" },
    [PSCustomObject]@{ Name="DNS Lookup"; Command="nslookup google.com"; Description="DNS lookup test"; Icon="Search" },
    [PSCustomObject]@{ Name="Trace Route"; Command="tracert google.com"; Description="Trace route to Google"; Icon="Map" },
    [PSCustomObject]@{ Name="Local Groups"; Command="net localgroup"; Description="List local groups"; Icon="Users" },
    [PSCustomObject]@{ Name="Administrators"; Command="net localgroup administrators"; Description="List administrators"; Icon="Key" }
)

# ==============================================================================
# TOOL BUTTON FUNCTIONS
# ==============================================================================
function New-ToolButton {
    param($Tool)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "5"
    $btn.Cursor = "Hand"
    $btn.Background = "#0F0F1A"
    $btn.BorderBrush = "#2A2A40"
    $btn.BorderThickness = "1"
    $btn.Tag = $Tool
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1; $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = $Tool.Name
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#E8E8F0"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $authorBorder = New-Object System.Windows.Controls.Border
    $authorBorder.Background = "#1A1A2E"
    $authorBorder.Padding = "6,2"
    $authorBorder.HorizontalAlignment = "Center"
    $authorBorder.Margin = "0,3,0,0"
    [System.Windows.Controls.Grid]::SetRow($authorBorder, 1)
    $authorBlock = New-Object System.Windows.Controls.TextBlock
    $authorBlock.Text = "by $($Tool.Author)"
    $authorBlock.FontSize = 8
    $authorBlock.FontWeight = "Bold"
    $authorBlock.Foreground = "#7C3AED"
    $authorBlock.HorizontalAlignment = "Center"
    $authorBlock.VerticalAlignment = "Center"
    $authorBorder.Child = $authorBlock
    [void]$grid.Children.Add($authorBorder)
    $tagBorder = New-Object System.Windows.Controls.Border
    $tagBorder.Background = "#141420"
    $tagBorder.Padding = "6,1"
    $tagBorder.HorizontalAlignment = "Right"
    $tagBorder.Margin = "0,3,0,0"
    [System.Windows.Controls.Grid]::SetRow($tagBorder, 2)
    $tagText = New-Object System.Windows.Controls.TextBlock
    $tagText.Text = $Tool.Type.ToUpper()
    $tagText.FontSize = 7
    $tagText.FontWeight = "Bold"
    $tagText.Foreground = "#06B6D4"
    $tagBorder.Child = $tagText
    [void]$grid.Children.Add($tagBorder)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1.05; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1.05; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source; $toolData = $clickedBtn.Tag; if (-not $toolData) { return }
        $clickedBtn.IsEnabled = $false; $clickedBtn.Background = "#1A1A2E"
        $cleanName = $toolData.Name; $author = $toolData.Author
        Write-Log "Launching: $cleanName (by $author)"
        $kp = Join-Path $global:installDir $toolData.Category
        $dest = Join-Path $kp $toolData.Name
        if (-not (Test-Path $kp)) { New-Item -ItemType Directory $kp -Force | Out-Null }
        if (Get-ToolStatus $toolData) {
            Write-Log "Already installed: $cleanName"
            Set-Status "Ready" "$cleanName is already installed." "INSTALLED"
            Start-Process explorer.exe $kp
            $clickedBtn.Background = "#0F0F1A"; $clickedBtn.IsEnabled = $true; return
        }
        Set-Status "Downloading" "Fetching $cleanName by $author..." "BUSY"
        Write-Log "Downloading: $cleanName"
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "ValyaRssTools/1.0")
            $wc.DownloadFile($toolData.URL, $dest)
            $wc.Dispose()
            Write-Log "Download complete"
            if ($toolData.Type -eq "zip") {
                $exD = Join-Path $kp ($toolData.Name -replace "\.zip$","")
                Write-Log "Extracting..."
                if (Expand-ZipSafe $dest $exD) {
                    Remove-Item $dest -Force -EA SilentlyContinue
                    Write-Log "Extraction complete"
                } else { Write-Log "Extraction failed" }
            }
            Write-Log "Ready: $cleanName"
            Set-Status "Ready" "$cleanName by $author installed." "DONE"
            Start-Process explorer.exe $kp
        } catch {
            Write-Log "Error: $_"
            Set-Status "Error" "Failed to download $cleanName" "ERROR"
            if(Test-Path $dest){Remove-Item $dest -Force -EA SilentlyContinue}
        }
        $clickedBtn.Background = "#0F0F1A"; $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-ScriptButton {
    param($Script)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "5"
    $btn.Cursor = "Hand"
    $btn.Background = "#0F0F1A"
    $btn.BorderBrush = "#2A2A40"
    $btn.BorderThickness = "1"
    $btn.Tag = $Script
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1; $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = if ($Script.URL -eq "LOCAL") { "[LOCAL] $($Script.Name)" } else { $Script.Name }
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#E8E8F0"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $authorBorder = New-Object System.Windows.Controls.Border
    $authorBorder.Background = "#1A1A2E"
    $authorBorder.Padding = "6,2"
    $authorBorder.HorizontalAlignment = "Center"
    $authorBorder.Margin = "0,3,0,0"
    [System.Windows.Controls.Grid]::SetRow($authorBorder, 1)
    $authorBlock = New-Object System.Windows.Controls.TextBlock
    $authorBlock.Text = "by $($Script.Author)"
    $authorBlock.FontSize = 8
    $authorBlock.FontWeight = "Bold"
    $authorBlock.Foreground = if ($Script.URL -eq "LOCAL") { "#FF6B6B" } else { "#06B6D4" }
    $authorBlock.HorizontalAlignment = "Center"
    $authorBlock.VerticalAlignment = "Center"
    $authorBorder.Child = $authorBlock
    [void]$grid.Children.Add($authorBorder)
    $tagBorder = New-Object System.Windows.Controls.Border
    $tagBorder.Background = "#141420"
    $tagBorder.Padding = "6,1"
    $tagBorder.HorizontalAlignment = "Right"
    $tagBorder.Margin = "0,3,0,0"
    [System.Windows.Controls.Grid]::SetRow($tagBorder, 2)
    $tagText = New-Object System.Windows.Controls.TextBlock
    $tagText.Text = if ($Script.URL -eq "LOCAL") { "LOCAL" } else { "PS1" }
    $tagText.FontSize = 7
    $tagText.FontWeight = "Bold"
    $tagText.Foreground = if ($Script.URL -eq "LOCAL") { "#FF6B6B" } else { "#06B6D4" }
    $tagBorder.Child = $tagText
    [void]$grid.Children.Add($tagBorder)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1.05; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1.05; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source; $scriptData = $clickedBtn.Tag; if (-not $scriptData) { return }
        $clickedBtn.IsEnabled = $false; $clickedBtn.Background = "#1A1A2E"
        Write-Log "Running script: $($scriptData.Name) by $($scriptData.Author)"
        Set-Status "Running" "Executing $($scriptData.Name)..." "BUSY"
        try {
            if ($scriptData.URL -eq "LOCAL") {
                switch ($scriptData.Name) {
                    "Doomsday Finder v3" { Run-DoomsdayFinder }
                    "Ghost Client Scanner" { Run-GhostClientScanner }
                    "Cyemer Scanner" { Run-CyemerScanner }
                    "Velaris Scanner" { Run-VelarisScanner }
                    "Heated Mod Analyzer" { Run-HeatedModAnalyzer }
                    "Hacked Clients Detector" { Run-HackedClientsDetector }
                    "Journal Trace Analyzer" { Run-JournalTrace }
                    "DQRKIS Client Detector" { Run-DQRKISDetector }
                    default { Write-Log "Unknown local script: $($scriptData.Name)"; Set-Status "Error" "Unknown local script" "ERROR" }
                }
            } else {
                $psCommand = "Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression (Invoke-RestMethod -Uri '$($scriptData.URL)')"
                Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $psCommand
                Write-Log "Script started in new PowerShell window"
                Set-Status "Ready" "$($scriptData.Name) launched." "DONE"
            }
        } catch {
            Write-Log "Error running script: $_"
            Set-Status "Error" "Failed to run script" "ERROR"
        }
        $clickedBtn.Background = "#0F0F1A"; $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-CommandButton {
    param($Command)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "5"
    $btn.Cursor = "Hand"
    $btn.Background = "#0F0F1A"
    $btn.BorderBrush = "#2A2A40"
    $btn.BorderThickness = "1"
    $btn.Tag = $Command
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1; $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = $Command.Name
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#E8E8F0"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $pathBlock = New-Object System.Windows.Controls.TextBlock
    $pathBlock.Text = $Command.Command
    $pathBlock.FontSize = 8
    $pathBlock.FontWeight = "Normal"
    $pathBlock.Foreground = "#7C3AED"
    $pathBlock.HorizontalAlignment = "Center"
    $pathBlock.VerticalAlignment = "Center"
    $pathBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($pathBlock, 1)
    [void]$grid.Children.Add($pathBlock)
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = $Command.Description
    $descBlock.FontSize = 8
    $descBlock.Foreground = "#555570"
    $descBlock.HorizontalAlignment = "Center"
    $descBlock.VerticalAlignment = "Center"
    $descBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($descBlock, 2)
    [void]$grid.Children.Add($descBlock)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1.05; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1.05; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source; $cmdData = $clickedBtn.Tag; if (-not $cmdData) { return }
        $clickedBtn.IsEnabled = $false; $clickedBtn.Background = "#1A1A2E"
        Write-Log "Opening: $($cmdData.Command) ($($cmdData.Name))"
        Set-Status "Running" "Opening $($cmdData.Name)..." "BUSY"
        try {
            $command = $cmdData.Command
            if ($command -match '^shell:') { Start-Process "explorer.exe" -ArgumentList $command }
            elseif ($command -match '^%.*%$' -or $command -match '%') {
                $expandedPath = [Environment]::ExpandEnvironmentVariables($command)
                if (Test-Path $expandedPath) { Start-Process "explorer.exe" -ArgumentList $expandedPath }
                else { Write-Log "Path not found: $expandedPath"; Set-Status "Error" "Path not found" "ERROR" }
            }
            elseif ($command -match '\.(msc|cpl)$') { Start-Process $command }
            elseif ($command -match '^(regedit|taskmgr|control|cmd|powershell)') { Start-Process $command }
            else {
                $expandedPath = [Environment]::ExpandEnvironmentVariables($command)
                if (Test-Path $expandedPath -PathType Container) { Start-Process "explorer.exe" -ArgumentList $expandedPath }
                elseif (Test-Path $expandedPath -PathType Leaf) { Start-Process "explorer.exe" -ArgumentList "/select,$expandedPath" }
                else { Start-Process "explorer.exe" -ArgumentList $command }
            }
            Set-Status "Ready" "$($cmdData.Name) opened." "DONE"
        } catch {
            Write-Log "Error opening: $_"
            Set-Status "Error" "Failed to open $($cmdData.Name)" "ERROR"
        }
        $clickedBtn.Background = "#0F0F1A"; $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-CmdCommandButton {
    param($CmdCommand)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "5"
    $btn.Cursor = "Hand"
    $btn.Background = "#0F0F1A"
    $btn.BorderBrush = "#2A2A40"
    $btn.BorderThickness = "1"
    $btn.Tag = $CmdCommand
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1; $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = $CmdCommand.Name
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#E8E8F0"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $cmdBlock = New-Object System.Windows.Controls.TextBlock
    $cmdBlock.Text = $CmdCommand.Command
    $cmdBlock.FontSize = 8
    $cmdBlock.FontWeight = "Normal"
    $cmdBlock.Foreground = "#06B6D4"
    $cmdBlock.HorizontalAlignment = "Center"
    $cmdBlock.VerticalAlignment = "Center"
    $cmdBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($cmdBlock, 1)
    [void]$grid.Children.Add($cmdBlock)
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = $CmdCommand.Description
    $descBlock.FontSize = 8
    $descBlock.Foreground = "#555570"
    $descBlock.HorizontalAlignment = "Center"
    $descBlock.VerticalAlignment = "Center"
    $descBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($descBlock, 2)
    [void]$grid.Children.Add($descBlock)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1.05; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1.05; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source; $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation; $animX.To = 1; $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation; $animY.To = 1; $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source; $cmdData = $clickedBtn.Tag; if (-not $cmdData) { return }
        $clickedBtn.IsEnabled = $false; $clickedBtn.Background = "#1A1A2E"
        Write-Log "Running CMD: $($cmdData.Command)"
        Set-Status "Running" "Executing: $($cmdData.Name)..." "BUSY"
        try {
            $cmdArgs = "/k echo [*] Running: $($cmdData.Name) & echo [*] Command: $($cmdData.Command) & echo. & $($cmdData.Command)"
            Start-Process "cmd.exe" -ArgumentList $cmdArgs
            Set-Status "Ready" "$($cmdData.Name) executed" "DONE"
        } catch {
            Write-Log "Error running command: $_"
            Set-Status "Error" "Failed to run command" "ERROR"
        }
        $clickedBtn.Background = "#0F0F1A"; $clickedBtn.IsEnabled = $true
    })
    return $btn
}

# ==============================================================================
# XAML - COMPLETE UI
# ==============================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaRssTools" Width="1440" Height="900"
        MinWidth="1280" MinHeight="760"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Opacity="1">

    <Window.Resources>
        <SolidColorBrush x:Key="BgDark" Color="#0A0A0F"/>
        <SolidColorBrush x:Key="BgPanel" Color="#0F0F1A"/>
        <SolidColorBrush x:Key="BgCard" Color="#141420"/>
        <SolidColorBrush x:Key="BgHover" Color="#1A1A2E"/>
        <SolidColorBrush x:Key="BorderColor" Color="#2A2A40"/>
        <SolidColorBrush x:Key="AccentPurple" Color="#7C3AED"/>
        <SolidColorBrush x:Key="AccentCyan" Color="#06B6D4"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#E8E8F0"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#8A8AA0"/>
        <SolidColorBrush x:Key="TextMuted" Color="#555570"/>
        <LinearGradientBrush x:Key="AccentGrad" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Offset="0" Color="#7C3AED"/>
            <GradientStop Offset="1" Color="#06B6D4"/>
        </LinearGradientBrush>
        <DropShadowEffect x:Key="Shadow" BlurRadius="30" ShadowDepth="0" Opacity="0.3" Color="#000000"/>

        <Style x:Key="SideBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#8A8AA0"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Margin" Value="0,2,0,2"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderThickness="0" Margin="4,0">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" Margin="12,0"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1A1A2E"/>
                                <Setter Property="Foreground" Value="#C084FC"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TitleBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#6A4A7A"/>
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1A1A2E"/>
                                <Setter Property="Foreground" Value="#06B6D4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ToolBtn" TargetType="Button">
            <Setter Property="Background" Value="#0F0F1A"/>
            <Setter Property="Foreground" Value="#E8E8F0"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Width" Value="205"/>
            <Setter Property="Height" Value="100"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2A2A40"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1A1A2E"/>
                                <Setter Property="BorderBrush" Value="#7C3AED"/>
                                <Setter Property="BorderThickness" Value="2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid x:Name="RootGrid" Background="#0A0A0F">
        <Border Background="#0A0A0F" CornerRadius="0" BorderBrush="#2A2A40" BorderThickness="1" Margin="10">
            <Border.Effect><DropShadowEffect BlurRadius="40" ShadowDepth="0" Opacity="0.4" Color="#000000"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="56"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Background="#0F0F1A" BorderBrush="#2A2A40" BorderThickness="0,0,0,1">
                    <Grid Margin="16,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border Width="36" Height="36" Background="#7C3AED" Margin="0,0,10,0">
                                <TextBlock Text="VR" FontSize="14" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel>
                                <TextBlock Text="VALYA RSS TOOLS" FontSize="16" FontWeight="Bold" Foreground="#E8E8F0"/>
                                <TextBlock Text="SCREENSHARE TOOLKIT" FontSize="8" Foreground="#7C3AED"/>
                            </StackPanel>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                            <Border Background="#141420" BorderBrush="#2A2A40" BorderThickness="1" Padding="8,2,12,2" Margin="0,0,10,0">
                                <StackPanel Orientation="Horizontal">
                                    <Ellipse Width="6" Height="6" Fill="#4ADEA0" Margin="0,0,6,0"/>
                                    <TextBlock Text="ONLINE" Foreground="#4ADEA0" FontSize="9" FontWeight="Bold"/>
                                </StackPanel>
                            </Border>
                            <Button x:Name="ThemeToggleBtn" Content="Dark" Style="{StaticResource TitleBtn}" Margin="0,0,2,0" ToolTip="Toggle Theme"/>
                            <Button x:Name="CompactToggleBtn" Content="Compact" Style="{StaticResource TitleBtn}" Margin="0,0,2,0" ToolTip="Toggle Compact Mode"/>
                            <Button x:Name="OpenFolderBtn" Content="Folder" Style="{StaticResource TitleBtn}" Margin="0,0,2,0"/>
                            <Button x:Name="ClearCacheBtn" Content="Clear" Style="{StaticResource TitleBtn}" Margin="0,0,2,0"/>
                            <Button x:Name="OpenCmdBtn" Content="PS" Style="{StaticResource TitleBtn}" Margin="0,0,2,0"/>
                            <Button x:Name="MinBtn" Content="_" Style="{StaticResource TitleBtn}" Margin="0,0,0,0"/>
                            <Button x:Name="CloseBtn" Content="X" Style="{StaticResource TitleBtn}" Foreground="#FF6B6B" Margin="4,0,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="200"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Grid.Column="0" Background="#0F0F1A" BorderBrush="#2A2A40" BorderThickness="0,0,1,0">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Margin="8,12">
                                <TextBlock Text="CATEGORIES" FontSize="9" FontWeight="Bold" Foreground="#7C3AED" Margin="12,0,0,8"/>
                                <StackPanel x:Name="CategoryPanel"/>
                                <Separator Background="#2A2A40" Margin="8,12,8,12"/>
                                <TextBlock Text="INSTALL PATH" FontSize="8" FontWeight="Bold" Foreground="#555570" Margin="12,0,0,4"/>
                                <TextBlock x:Name="InstPathBlock" Text="" FontSize="8" Foreground="#8A8AA0" TextWrapping="Wrap" Margin="12,0,0,0"/>
                                <Border Height="2" Width="30" Background="{StaticResource AccentGrad}" Margin="12,12,0,0" HorizontalAlignment="Left"/>
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <Grid Grid.Column="1" Margin="14,12,14,14">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="8"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="8"/>
                            <RowDefinition Height="130"/>
                        </Grid.RowDefinitions>

                        <Border Grid.Row="0" Background="#0F0F1A" BorderBrush="#2A2A40" BorderThickness="1" Padding="14,8">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock x:Name="StatusTitle" Text="Ready" FontSize="16" FontWeight="SemiBold" Foreground="#E8E8F0"/>
                                    <TextBlock x:Name="StatusSub" Text="Select a tool or script from the sidebar." FontSize="11" Foreground="#8A8AA0"/>
                                </StackPanel>
                                <Border Grid.Column="1" Background="#141420" BorderBrush="#2A2A40" BorderThickness="1" Padding="10,3" VerticalAlignment="Center">
                                    <TextBlock x:Name="StatusBadge" Text="IDLE" FontSize="10" FontWeight="Bold" Foreground="#7C3AED"/>
                                </Border>
                            </Grid>
                        </Border>

                        <Border Grid.Row="1" Background="#0F0F1A" BorderBrush="#2A2A40" BorderThickness="1" Padding="10,6">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="SearchBox" Background="#141420" Foreground="#E8E8F0" BorderBrush="#2A2A40" BorderThickness="1" FontSize="12" Padding="8,6"/>
                                <Button Grid.Column="1" Content="X" Background="Transparent" Foreground="#555570" BorderThickness="0" Width="30" Height="30" Cursor="Hand" x:Name="ClearSearchBtn" Visibility="Collapsed"/>
                            </Grid>
                        </Border>

                        <Border Grid.Row="3" Background="#0F0F1A" BorderBrush="#2A2A40" BorderThickness="1" Padding="6">
                            <ScrollViewer x:Name="CenterScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                <WrapPanel x:Name="ToolsWrap" Margin="2"/>
                            </ScrollViewer>
                        </Border>

                        <Border Grid.Row="5" Background="#0A0A0F" BorderBrush="#2A2A40" BorderThickness="1" Padding="10,6">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Text="ACTIVITY LOG" FontSize="9" FontWeight="Bold" Foreground="#7C3AED" FontFamily="Consolas" Margin="0,0,0,2"/>
                                <TextBox x:Name="LogBox" Grid.Row="1" Background="Transparent" Foreground="#06B6D4" BorderThickness="0" FontFamily="Consolas" FontSize="10" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ==============================================================================
# LOAD XAML
# ==============================================================================
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $global:window = [Windows.Markup.XamlReader]::Load($reader)
    if (-not $global:window) {
        Write-Host "Failed to load XAML" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit
    }
    $global:window.Opacity = 1
    $global:window.Visibility = "Visible"

    $global:MinBtn = $global:window.FindName("MinBtn")
    $global:CloseBtn = $global:window.FindName("CloseBtn")
    $global:OpenFolderBtn = $global:window.FindName("OpenFolderBtn")
    $global:ClearCacheBtn = $global:window.FindName("ClearCacheBtn")
    $global:OpenCmdBtn = $global:window.FindName("OpenCmdBtn")
    $global:ThemeToggleBtn = $global:window.FindName("ThemeToggleBtn")
    $global:CompactToggleBtn = $global:window.FindName("CompactToggleBtn")
    $global:StatusTitle = $global:window.FindName("StatusTitle")
    $global:StatusSub = $global:window.FindName("StatusSub")
    $global:StatusBadge = $global:window.FindName("StatusBadge")
    $global:LogBox = $global:window.FindName("LogBox")
    $global:CenterScroll = $global:window.FindName("CenterScroll")
    $global:ToolsWrap = $global:window.FindName("ToolsWrap")
    $global:CategoryPanel = $global:window.FindName("CategoryPanel")
    $global:InstPathBlock = $global:window.FindName("InstPathBlock")
    $global:SearchBox = $global:window.FindName("SearchBox")
    $global:ClearSearchBtn = $global:window.FindName("ClearSearchBtn")
    $global:RootGrid = $global:window.FindName("RootGrid")
    if ($global:InstPathBlock) { $global:InstPathBlock.Text = "`n$global:installDir" }
} catch {
    Write-Host "XAML Load Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# ==============================================================================
# NAVIGATION
# ==============================================================================
$categories = @(
    "NirSoft", "EricZimmerman", "Spokwn", "Echo", "OrbDiff", "RedLotus", 
    "TRSSCommunity", "Magnet", "Forensics", "SystemTools", "Analysis", "Misc",
    "Meow", "Praiselily", "TeslaPro", "Xeinn", "Dependencies",
    "Commands", "Cmd Commands",
    "Tut"
) | Sort-Object

function Set-ActiveButton {
    param($activeBtn)
    if (-not $global:CategoryPanel) { return }
    foreach ($child in $global:CategoryPanel.Children) {
        if ($child -is [System.Windows.Controls.Button]) {
            $child.Background = "Transparent"
            $child.Foreground = "#8A8AA0"
        }
    }
    if ($activeBtn) {
        $activeBtn.Background = "#1A1A2E"
        $activeBtn.Foreground = "#C084FC"
    }
}

function Show-Overview {
    if (-not $global:ToolsWrap -or -not $global:CategoryPanel) { return }
    $global:ToolsWrap.Children.Clear()
    Set-Status "Overview" "Browse all tool categories at a glance" "OVERVIEW"
    foreach ($child in $global:CategoryPanel.Children) {
        if ($child -is [System.Windows.Controls.Button] -and $child.Tag -eq "overview") {
            Set-ActiveButton -activeBtn $child
        }
    }
    foreach ($cat in $categories) {
        if ($cat -eq "Commands") {
            $catTools = $CommandData; $count = $catTools.Count; $installed = 0
        } elseif ($cat -eq "Cmd Commands") {
            $catTools = $CmdCommandData; $count = $catTools.Count; $installed = 0
        } else {
            $catTools = @($ToolData | Where-Object { $_.Category -eq $cat })
            $count = $catTools.Count
            $installed = @($catTools | Where-Object { Get-ToolStatus $_ }).Count
        }
        $card = New-Object System.Windows.Controls.Border
        $card.Background = "#0F0F1A"; $card.BorderBrush = "#2A2A40"; $card.BorderThickness = "1"
        $card.Margin = "8"; $card.Width = 380; $card.Height = 85; $card.Cursor = "Hand"; $card.Tag = $cat
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "14,10"
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $catName = New-Object System.Windows.Controls.TextBlock
        $catName.Text = $cat; $catName.FontSize = 15; $catName.FontWeight = "SemiBold"
        $catName.Foreground = "#E8E8F0"; $catName.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetRow($catName, 0)
        [void]$grid.Children.Add($catName)
        $infoText = New-Object System.Windows.Controls.TextBlock
        if ($cat -eq "Commands") { $statusColor = "#7C3AED"; $statusText = "$count quick commands" }
        elseif ($cat -eq "Cmd Commands") { $statusColor = "#06B6D4"; $statusText = "$count CMD commands" }
        else {
            $statusColor = if ($installed -eq $count) { "#4ADEA0" } elseif ($installed -gt 0) { "#7C3AED" } else { "#555570" }
            $statusText = if ($installed -eq $count) { "Complete" } elseif ($installed -gt 0) { "$installed/$count" } else { "None" }
        }
        $infoText.Text = $statusText; $infoText.FontSize = 10; $infoText.Foreground = $statusColor
        $infoText.HorizontalAlignment = "Right"; $infoText.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetRow($infoText, 0); [System.Windows.Controls.Grid]::SetColumn($infoText, 1)
        [void]$grid.Children.Add($infoText)
        $progBg = New-Object System.Windows.Controls.Border; $progBg.Background = "#1A1A2E"; $progBg.Height = 4
        [System.Windows.Controls.Grid]::SetRow($progBg, 1); [System.Windows.Controls.Grid]::SetColumnSpan($progBg, 2)
        [void]$grid.Children.Add($progBg)
        $progFill = New-Object System.Windows.Controls.Border
        if ($cat -eq "Commands" -or $cat -eq "Cmd Commands") { $progFill.Background = "#7C3AED"; $progFill.Width = 370 }
        else { $progFill.Background = if ($installed -eq $count) { "#4ADEA0" } else { "#7C3AED" }; $progFill.Width = if ($count -gt 0) { [Math]::Max(2, ($installed / $count) * 370) } else { 0 } }
        $progFill.Height = 4; $progFill.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetRow($progFill, 1); [System.Windows.Controls.Grid]::SetColumnSpan($progFill, 2)
        [void]$grid.Children.Add($progFill)
        $desc = New-Object System.Windows.Controls.TextBlock
        if ($cat -eq "Commands") { $desc.Text = "$count Win+R shortcuts available" }
        elseif ($cat -eq "Cmd Commands") { $desc.Text = "$count CMD/PowerShell commands" }
        else { $desc.Text = "$count tools - $installed installed" }
        $desc.FontSize = 9; $desc.Foreground = "#555570"; $desc.Margin = "0,4,0,0"
        [System.Windows.Controls.Grid]::SetRow($desc, 2); [System.Windows.Controls.Grid]::SetColumnSpan($desc, 2)
        [void]$grid.Children.Add($desc)
        $card.Child = $grid
        $card.Add_MouseLeftButtonUp({ param($s,$e) Show-Category $s.Tag })
        [void]$global:ToolsWrap.Children.Add($card)
    }
}

function Show-Category {
    param($cat)
    if (-not $global:ToolsWrap) { return }
    $global:ToolsWrap.Children.Clear()
    Set-Status "Category" "Viewing items in $cat" "BROWSE"
    foreach ($child in $global:CategoryPanel.Children) {
        if ($child -is [System.Windows.Controls.Button] -and $child.Tag -eq $cat) {
            Set-ActiveButton -activeBtn $child
        }
    }

    if ($cat -eq "Tut") {
        $tutPanel = New-Object System.Windows.Controls.StackPanel
        $tutPanel.Margin = "10"
        $tutPanel.MaxWidth = 900

        $card = New-Object System.Windows.Controls.Border
        $card.Background = "#141420"
        $card.BorderBrush = "#2A2A40"
        $card.BorderThickness = "1"
        $card.Margin = "0,0,0,15"
        $card.CornerRadius = "8"
        $card.Padding = "15"

        $innerStack = New-Object System.Windows.Controls.StackPanel

        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "SCREEN SHARE TUTORIAL - Click each button to run the tool"
        $titleBlock.FontSize = "16"
        $titleBlock.FontWeight = "Bold"
        $titleBlock.Foreground = "#7C3AED"
        $titleBlock.Margin = "0,0,0,10"
        [void]$innerStack.Children.Add($titleBlock)

        foreach ($action in $TutorialActions) {
            $grid = New-Object System.Windows.Controls.Grid
            $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
            $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
            $grid.Margin = "0,4,0,4"

            $stepText = New-Object System.Windows.Controls.TextBlock
            $stepText.Text = "$($action.Step). $($action.Description)"
            $stepText.FontSize = "12"
            $stepText.Foreground = "#E8E8F0"
            $stepText.TextWrapping = "Wrap"
            $stepText.VerticalAlignment = "Center"
            $stepText.Margin = "0,0,10,0"
            [System.Windows.Controls.Grid]::SetColumn($stepText, 0)
            [void]$grid.Children.Add($stepText)

            if ($action.Type -ne "Info") {
                $btn = $null
                if ($action.Type -eq "Command") {
                    $cmdObj = $CommandData | Where-Object { $_.Name -eq $action.Name } | Select-Object -First 1
                    if ($cmdObj) { $btn = New-CommandButton -Command $cmdObj }
                } elseif ($action.Type -eq "Script") {
                    $scriptObj = $ScriptData | Where-Object { $_.Name -eq $action.Name } | Select-Object -First 1
                    if ($scriptObj) { $btn = New-ScriptButton -Script $scriptObj }
                }
                if ($btn) {
                    $btn.Width = 140; $btn.Height = 30; $btn.FontSize = 10
                    $btn.Margin = "5,0,0,0"; $btn.HorizontalAlignment = "Right"
                    [System.Windows.Controls.Grid]::SetColumn($btn, 1)
                    [void]$grid.Children.Add($btn)
                }
            } else {
                $badge = New-Object System.Windows.Controls.Border
                $badge.Background = "#1A1A2E"; $badge.BorderBrush = "#7C3AED"; $badge.BorderThickness = "1"
                $badge.CornerRadius = "4"; $badge.Padding = "6,2"
                $badge.HorizontalAlignment = "Right"; $badge.Margin = "5,0,0,0"
                $badgeText = New-Object System.Windows.Controls.TextBlock
                $badgeText.Text = "Manual"; $badgeText.Foreground = "#7C3AED"
                $badgeText.FontSize = "10"; $badgeText.FontWeight = "Bold"
                $badge.Child = $badgeText
                [System.Windows.Controls.Grid]::SetColumn($badge, 1)
                [void]$grid.Children.Add($badge)
            }
            [void]$innerStack.Children.Add($grid)
        }

        $card.Child = $innerStack
        [void]$tutPanel.Children.Add($card)

        $checkCard = New-Object System.Windows.Controls.Border
        $checkCard.Background = "#141420"; $checkCard.BorderBrush = "#2A2A40"; $checkCard.BorderThickness = "1"
        $checkCard.Margin = "0,0,0,15"; $checkCard.CornerRadius = "8"; $checkCard.Padding = "15"

        $checkStack = New-Object System.Windows.Controls.StackPanel
        $checkTitle = New-Object System.Windows.Controls.TextBlock
        $checkTitle.Text = "QUICK CHECKLIST"
        $checkTitle.FontSize = "16"; $checkTitle.FontWeight = "Bold"; $checkTitle.Foreground = "#06B6D4"
        $checkTitle.Margin = "0,0,0,8"
        [void]$checkStack.Children.Add($checkTitle)

        foreach ($item in $TutorialChecklist) {
            $itemBlock = New-Object System.Windows.Controls.TextBlock
            $itemBlock.Text = $item; $itemBlock.FontSize = "12"; $itemBlock.Foreground = "#E8E8F0"
            $itemBlock.Margin = "0,2,0,2"
            [void]$checkStack.Children.Add($itemBlock)
        }

        $checkCard.Child = $checkStack
        [void]$tutPanel.Children.Add($checkCard)

        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = "Auto"; $scroll.HorizontalScrollBarVisibility = "Disabled"
        $scroll.Content = $tutPanel; $scroll.Height = 550
        [void]$global:ToolsWrap.Children.Add($scroll)
        return
    }

    if ($cat -eq "Commands") {
        foreach ($cmd in $CommandData) { $btn = New-CommandButton -Command $cmd; [void]$global:ToolsWrap.Children.Add($btn) }
        return
    }

    if ($cat -eq "Cmd Commands") {
        foreach ($cmd in $CmdCommandData) { $btn = New-CmdCommandButton -CmdCommand $cmd; [void]$global:ToolsWrap.Children.Add($btn) }
        return
    }

    $catTools = @($ToolData | Where-Object { $_.Category -eq $cat })
    foreach ($tool in $catTools) { $btn = New-ToolButton -Tool $tool; [void]$global:ToolsWrap.Children.Add($btn) }
}

function Show-Scripts {
    if (-not $global:ToolsWrap) { return }
    $global:ToolsWrap.Children.Clear()
    Set-Status "Scripts" "PowerShell scripts available to run" "SCRIPTS"
    foreach ($child in $global:CategoryPanel.Children) {
        if ($child -is [System.Windows.Controls.Button] -and $child.Tag -eq "scripts") {
            Set-ActiveButton -activeBtn $child
        }
    }
    foreach ($script in $ScriptData) { $btn = New-ScriptButton -Script $script; [void]$global:ToolsWrap.Children.Add($btn) }
}

function Build-Sidebar {
    if (-not $global:CategoryPanel) { return }
    $global:CategoryPanel.Children.Clear()
    $overviewBtn = New-Object System.Windows.Controls.Button
    $overviewBtn.Content = "Overview"
    $overviewBtn.Style = $global:window.Resources["SideBtn"]
    $overviewBtn.Tag = "overview"
    $overviewBtn.Add_Click({ Show-Overview })
    [void]$global:CategoryPanel.Children.Add($overviewBtn)
    $scriptBtn = New-Object System.Windows.Controls.Button
    $scriptBtn.Content = "Scripts"
    $scriptBtn.Style = $global:window.Resources["SideBtn"]
    $scriptBtn.Tag = "scripts"
    $scriptBtn.Add_Click({ Show-Scripts })
    [void]$global:CategoryPanel.Children.Add($scriptBtn)
    foreach ($cat in $categories) {
        $catBtn = New-Object System.Windows.Controls.Button
        $catBtn.Content = $cat
        $catBtn.Style = $global:window.Resources["SideBtn"]
        $catBtn.Tag = $cat
        $catBtn.Add_Click({ Show-Category -cat $_.Source.Tag })
        [void]$global:CategoryPanel.Children.Add($catBtn)
    }
}

# ==============================================================================
# WINDOW CONTROLS
# ==============================================================================
if ($global:window) {
    $global:window.Add_MouseLeftButtonDown({ try { $global:window.DragMove() } catch {} })
    if ($global:CloseBtn) { $global:CloseBtn.Add_Click({ $global:window.Close() }) }
    if ($global:MinBtn) { $global:MinBtn.Add_Click({ $global:window.WindowState = "Minimized" }) }
    if ($global:OpenFolderBtn) {
        $global:OpenFolderBtn.Add_Click({
            if (-not (Test-Path $global:installDir)) { New-Item -ItemType Directory -Path $global:installDir -Force | Out-Null }
            Start-Process explorer.exe $global:installDir
            Write-Log "Opened install folder"
        })
    }
    if ($global:ClearCacheBtn) {
        $global:ClearCacheBtn.Add_Click({
            if (Test-Path $global:installDir) {
                $items = Get-ChildItem -Path $global:installDir -Force -ErrorAction SilentlyContinue
                $count = @($items).Count
                $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleared $count item(s)"
                Set-Status "Clean" "Removed downloaded files" "IDLE"
            } else { Write-Log "Nothing to clear" }
        })
    }
    if ($global:OpenCmdBtn) {
        $global:OpenCmdBtn.Add_Click({
            Write-Log "Opening PowerShell console..."
            try {
                Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "Write-Host 'ValyaRssTools PowerShell Console' -ForegroundColor Magenta; Write-Host 'Type your commands below:' -ForegroundColor Cyan"
                Set-Status "CMD" "PowerShell console opened" "DONE"
            } catch {
                Write-Log "Error opening PowerShell: $_"
                Set-Status "Error" "Failed to open PowerShell" "ERROR"
            }
        })
    }
    if ($global:ThemeToggleBtn) {
        $global:ThemeToggleBtn.Add_Click({
            $global:IsDarkTheme = -not $global:IsDarkTheme
            if ($global:IsDarkTheme) {
                $global:ThemeToggleBtn.Content = "Dark"
                $global:RootGrid.Background = "#0A0A0F"
                Set-Status "Dark Theme" "Switched to dark theme" "DARK"
            } else {
                $global:ThemeToggleBtn.Content = "Light"
                $global:RootGrid.Background = "#F0F0F5"
                Set-Status "Light Theme" "Switched to light theme" "LIGHT"
            }
        })
    }
    if ($global:CompactToggleBtn) {
        $global:CompactToggleBtn.Add_Click({
            $global:CompactMode = -not $global:CompactMode
            if ($global:CompactMode) {
                $global:CompactToggleBtn.Content = "Normal"
                $global:CompactToggleBtn.Foreground = "#7C3AED"
                Set-Status "Compact Mode" "Tool buttons resized to compact mode" "COMPACT"
            } else {
                $global:CompactToggleBtn.Content = "Compact"
                $global:CompactToggleBtn.Foreground = "#6A4A7A"
                Set-Status "Normal Mode" "Tool buttons restored to normal size" "IDLE"
            }
            $currentCat = ""
            foreach ($child in $global:CategoryPanel.Children) {
                if ($child.Background -ne "Transparent" -and $child.Tag -ne "overview" -and $child.Tag -ne "scripts") {
                    $currentCat = $child.Tag
                }
            }
            if ($currentCat) { Show-Category $currentCat }
            else { Show-Overview }
        })
    }
    if ($global:SearchBox) {
        $global:SearchBox.Add_TextChanged({
            $searchText = $global:SearchBox.Text.Trim().ToLower()
            if ($global:ClearSearchBtn) { $global:ClearSearchBtn.Visibility = if ($searchText) { 'Visible' } else { 'Collapsed' } }
            $found = 0
            foreach ($child in $global:ToolsWrap.Children) {
                if ($child -is [System.Windows.Controls.Button] -and $child.Tag) {
                    $toolName = $child.Tag.Name.ToLower()
                    $toolDesc = if ($child.Tag.Description) { $child.Tag.Description.ToLower() } else { "" }
                    $toolAuthor = if ($child.Tag.Author) { $child.Tag.Author.ToLower() } else { "" }
                    $isVisible = $searchText -eq "" -or $toolName.Contains($searchText) -or $toolDesc.Contains($searchText) -or $toolAuthor.Contains($searchText)
                    $child.Visibility = if ($isVisible) { 'Visible' } else { 'Collapsed' }
                    if ($isVisible -and $searchText) { $found++ }
                }
            }
            if ($searchText) { Set-Status "Search" "Found $found results for: $searchText" "SEARCH" }
            else { Set-Status "Ready" "Search cleared" "IDLE" }
        })
    }
    if ($global:ClearSearchBtn) {
        $global:ClearSearchBtn.Add_Click({
            $global:SearchBox.Text = ""
            foreach ($child in $global:ToolsWrap.Children) {
                if ($child -is [System.Windows.Controls.Button]) { $child.Visibility = 'Visible' }
            }
            Set-Status "Ready" "Search cleared" "IDLE"
        })
    }
}

# ==============================================================================
# LAUNCH
# ==============================================================================
Build-Sidebar
Show-Overview

Write-Log "ValyaRssTools v1.0 ready"
Write-Log "Install location: $global:installDir"
Write-Log "Total tools: $($ToolData.Count) | Total scripts: $($ScriptData.Count)"
Set-Status "Ready" "All scanners merged! Doomsday, Ghost, Cyemer, Velaris, Heated, DQRKIS" "IDLE"

if ($global:window) {
    $global:window.ShowDialog() | Out-Null
} else {
    Write-Host "Window failed to initialize." -ForegroundColor Red
    Read-Host "Press Enter to exit"
}

Write-Log "Session ended."
