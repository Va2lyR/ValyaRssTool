Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing, System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.GC]::Collect()

if ($MyInvocation.MyCommand.Path) {
    $global:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $global:scriptDir = $PSScriptRoot
    if (-not $global:scriptDir) { $global:scriptDir = (Get-Location).Path }
}

$global:installDir = "$env:USERPROFILE\Downloads\ValyaRssTool"
$global:logPath = Join-Path $env:TEMP "valyarss_tool.log"
$global:window = $null
$global:bgTimer = $null
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
# SCANNER FUNCTIONS (Doomsday, Ghost, Cyemer, Velaris, Heated, HackedClients, DQRKIS, JournalTrace)
# ==============================================================================
function Run-DoomsdayFinder {
    Write-Log "Starting Doomsday Finder v3..."
    Set-Status "Running" "Doomsday Finder v3 - Scanning..." "BUSY"
    try {
        $scriptContent = @'
#Requires -Version 5.1

function Show-Banner {
    $duck1 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡏⠉⢻⣷⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣾⣿⣿⣶⣶⣶⣦⣤⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⠏⠉⠉⠉⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⠿⠟⠀⠀⠀⠀⠀⠀⠀⠀
"@

    $duck2 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣤⣤⣶⣾⣷⣄⠀⠀⠀⠀⠀
⠀⠀⣶⣤⣤⣤⣤⣤⣤⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⠛⢻⣿⣿⣿⡆⠀⠀⠀⠀
⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⢀⣿⣿⣿⣿⡇⠀⠀⠀⠀
⠀⠀⠈⢿⣿⣿⣏⡈⠛⠿⠿⣿⣿⣿⠿⠿⠟⠋⣁⣴⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀
⠀⠀⠀⠀⠙⠿⣿⣿⣶⣦⣤⣤⣤⣤⣤⣴⣶⣿⣿⣿⣿⣿⣿⡿⠏⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠻⠿⠿⠿⢿⡿⠿⠿⠿⠟⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀
"@

    $duck3 = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡄⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣧⣾⣶⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"@

    Write-Host $duck1 -ForegroundColor Yellow
    Write-Host $duck2 -ForegroundColor White
    Write-Host $duck3 -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "                    Made by " -NoNewline
    Write-Host "TeslaPro " -NoNewline -ForegroundColor White
    Write-Host "@" -NoNewline -ForegroundColor Blue
    Write-Host "teamwsf on discord " -NoNewline -ForegroundColor Yellow
    Write-Host "&" -NoNewline -ForegroundColor Blue
    Write-Host "Goodluck SS'ing! " -ForegroundColor Red
    Write-Host ""
    Write-Host "                    Doomsday Client Scanner v1.2 (USN Journal)" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$script:DebugMode = $false
$script:CheckUSN = $true
$script:RecentDeletions = @{}
$script:USNSearched = $false

function Get-NTFSDrives {
    $ntfsDrives = @()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
    foreach ($drive in $drives) {
        try {
            $driveLetter = $drive.Root.Substring(0, 2)
            $volume = Get-Volume -DriveLetter $driveLetter[0] -ErrorAction SilentlyContinue
            if ($volume -and $volume.FileSystem -eq 'NTFS') {
                $ntfsDrives += $driveLetter[0]
            }
        }
        catch { continue }
    }
    return $ntfsDrives
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NtdllDecompressor {
    [DllImport("ntdll.dll")]
    public static extern uint RtlDecompressBufferEx(
        ushort CompressionFormat,
        byte[] UncompressedBuffer,
        int UncompressedBufferSize,
        byte[] CompressedBuffer,
        int CompressedBufferSize,
        out int FinalUncompressedSize,
        IntPtr WorkSpace
    );
    
    [DllImport("ntdll.dll")]
    public static extern uint RtlGetCompressionWorkSpaceSize(
        ushort CompressionFormat,
        out uint CompressBufferWorkSpaceSize,
        out uint CompressFragmentWorkSpaceSize
    );
    
    public static byte[] Decompress(byte[] compressed) {
        if (compressed.Length < 8) return null;
        if (compressed[0] != 0x4D || compressed[1] != 0x41 || compressed[2] != 0x4D) {
            return null;
        }
        
        int uncompSize = BitConverter.ToInt32(compressed, 4);
        
        uint wsComp, wsFrag;
        if (RtlGetCompressionWorkSpaceSize(4, out wsComp, out wsFrag) != 0) return null;
        
        IntPtr workspace = Marshal.AllocHGlobal((int)wsFrag);
        byte[] result = new byte[uncompSize];
        
        try {
            int finalSize;
            byte[] compData = new byte[compressed.Length - 8];
            Array.Copy(compressed, 8, compData, 0, compData.Length);
            
            uint status = RtlDecompressBufferEx(4, result, uncompSize, 
                compData, compData.Length, out finalSize, workspace);
            
            if (status != 0) return null;
            return result;
        }
        finally {
            Marshal.FreeHGlobal(workspace);
        }
    }
}
"@

function Get-RecentDeletionsFromUSN {
    param(
        [string[]]$DriveLetters,
        [int]$MinutesBack = 30
    )
    if ($script:USNSearched) {
        return $script:RecentDeletions
    }
    $allRecentActivity = @{}
    foreach ($driveLetter in $DriveLetters) {
        try {
            Write-Host "[*] Scanning drive $driveLetter`: for recent file activity (last $MinutesBack minutes)..." -ForegroundColor Cyan
            $cutoffTime = (Get-Date).AddMinutes(-$MinutesBack)
            $usnOutput = & fsutil usn readjournal "$driveLetter`:" 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[!] Unable to read USN Journal on drive $driveLetter`: (may be disabled)" -ForegroundColor Yellow
                continue
            }
            $totalLines = $usnOutput.Count
            if ($totalLines -eq 0) {
                Write-Host "[!] No USN Journal data on drive $driveLetter`:" -ForegroundColor Yellow
                continue
            }
            $recentActivity = @{}
            $activityCount = 0
            $currentFile = ""
            $currentTime = $null
            $currentReason = ""
            $entriesProcessed = 0
            foreach ($line in $usnOutput) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if ($line -match 'File name\s+:\s*(.+)$') {
                    $currentFile = $Matches[1].Trim()
                }
                elseif ($line -match 'Time stamp\s+:\s*(.+)$') {
                    $timeStr = $Matches[1].Trim()
                    try {
                        $currentTime = [DateTime]::Parse($timeStr)
                    } catch {
                        $currentTime = $null
                    }
                }
                elseif ($line -match 'Reason\s+:\s*(.+)$') {
                    $entriesProcessed++
                    $currentReason = $Matches[1].Trim()
                    if ($currentFile -and $currentTime -and $currentTime -gt $cutoffTime) {
                        $fullKey = "$driveLetter`:\$currentFile"
                        if (-not $recentActivity.ContainsKey($fullKey) -or 
                            $recentActivity[$fullKey].Timestamp -lt $currentTime) {
                            $recentActivity[$fullKey] = @{
                                Timestamp = $currentTime
                                Reason = $currentReason
                                Drive = $driveLetter
                            }
                            $activityCount++
                        }
                    }
                    $currentFile = ""
                    $currentTime = $null
                    $currentReason = ""
                }
            }
            Write-Host "[+] Drive $driveLetter`: - Found $activityCount files with recent activity" -ForegroundColor Green
            foreach ($key in $recentActivity.Keys) {
                $allRecentActivity[$key] = $recentActivity[$key]
            }
        }
        catch {
            Write-Host "[!] Error reading USN Journal on drive $driveLetter`: - $_" -ForegroundColor Yellow
            continue
        }
    }
    $script:RecentDeletions = $allRecentActivity
    $script:USNSearched = $true
    Write-Host ""
    Write-Host "[+] Total unique files with recent activity across all drives: $($allRecentActivity.Count)" -ForegroundColor Green
    Write-Host ""
    return $allRecentActivity
}

function Test-RecentlyDeleted {
    param(
        [string]$FilePath
    )
    if ($script:RecentDeletions.ContainsKey($FilePath)) {
        return $script:RecentDeletions[$FilePath]
    }
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    foreach ($key in $script:RecentDeletions.Keys) {
        if ($key -like "*\$fileName") {
            return $script:RecentDeletions[$key]
        }
    }
    return $null
}

function Get-PrefetchVersion {
    param([byte[]]$data)
    if ($data.Length -lt 8) { return 0 }
    $sig = [System.Text.Encoding]::ASCII.GetString($data, 4, 4)
    if ($sig -ne "SCCA") { return 0 }
    $version = [BitConverter]::ToUInt32($data, 0)
    return $version
}

function Get-SystemIndexes {
    param([string]$FilePath)
    try {
        $data = [System.IO.File]::ReadAllBytes($FilePath)
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] File: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Magenta
            Write-Host "  [DEBUG] Raw size: $($data.Length) bytes" -ForegroundColor Magenta
        }
        $isCompressed = ($data[0] -eq 0x4D -and $data[1] -eq 0x41 -and $data[2] -eq 0x4D)
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Compressed: $isCompressed" -ForegroundColor Magenta
        }
        if ($isCompressed) {
            $data = [NtdllDecompressor]::Decompress($data)
            if ($data -eq $null) {
                Write-Warning "Failed to decompress: $FilePath"
                return @()
            }
            if ($script:DebugMode) {
                Write-Host "  [DEBUG] Decompressed size: $($data.Length) bytes" -ForegroundColor Magenta
            }
        }
        if ($data.Length -lt 108) {
            Write-Warning "File too small after decompression: $FilePath"
            return @()
        }
        $version = Get-PrefetchVersion -data $data
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Prefetch version: $version" -ForegroundColor Magenta
        }
        $sig = [System.Text.Encoding]::ASCII.GetString($data, 4, 4)
        if ($sig -ne "SCCA") {
            Write-Warning "Invalid file signature: $FilePath (got: $sig)"
            return @()
        }
        $stringsOffset = 0
        $stringsSize = 0
        switch ($version) {
            17 { $stringsOffset = [BitConverter]::ToUInt32($data, 100); $stringsSize = [BitConverter]::ToUInt32($data, 104) }
            23 { $stringsOffset = [BitConverter]::ToUInt32($data, 100); $stringsSize = [BitConverter]::ToUInt32($data, 104) }
            26 { $stringsOffset = [BitConverter]::ToUInt32($data, 100); $stringsSize = [BitConverter]::ToUInt32($data, 104) }
            30 { $stringsOffset = [BitConverter]::ToUInt32($data, 100); $stringsSize = [BitConverter]::ToUInt32($data, 104) }
            31 { $stringsOffset = [BitConverter]::ToUInt32($data, 100); $stringsSize = [BitConverter]::ToUInt32($data, 104) }
            default {
                Write-Warning "Unknown prefetch version $version for: $FilePath"
                $stringsOffset = [BitConverter]::ToUInt32($data, 100)
                $stringsSize = [BitConverter]::ToUInt32($data, 104)
            }
        }
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Strings offset: $stringsOffset" -ForegroundColor Magenta
            Write-Host "  [DEBUG] Strings size: $stringsSize" -ForegroundColor Magenta
        }
        if ($stringsOffset -eq 0 -or $stringsSize -eq 0) {
            Write-Warning "Invalid string section offsets: $FilePath"
            return @()
        }
        if ($stringsOffset -ge $data.Length -or ($stringsOffset + $stringsSize) -gt $data.Length) {
            Write-Warning "String section out of bounds: $FilePath (offset: $stringsOffset, size: $stringsSize, data: $($data.Length))"
            return @()
        }
        $filenames = @()
        $pos = $stringsOffset
        $endPos = $stringsOffset + $stringsSize
        while ($pos -lt $endPos -and $pos -lt $data.Length - 2) {
            $nullPos = $pos
            while ($nullPos -lt $data.Length - 1) {
                if ($data[$nullPos] -eq 0 -and $data[$nullPos + 1] -eq 0) {
                    break
                }
                $nullPos += 2
            }
            if ($nullPos -gt $pos) {
                $strLen = $nullPos - $pos
                if ($strLen -gt 0 -and $strLen -lt 2048) {
                    try {
                        $filename = [System.Text.Encoding]::Unicode.GetString($data, $pos, $strLen)
                        if ($filename.Length -gt 0) {
                            $filenames += $filename
                        }
                    }
                    catch { }
                }
            }
            $pos = $nullPos + 2
            if ($filenames.Count -gt 1000) { break }
        }
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Extracted $($filenames.Count) filenames" -ForegroundColor Magenta
        }
        return $filenames
    }
    catch {
        Write-Warning "Error parsing $FilePath : $_"
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Exception: $($_.Exception.GetType().Name)" -ForegroundColor Red
            Write-Host "  [DEBUG] Message: $($_.Exception.Message)" -ForegroundColor Red
        }
        return @()
    }
}

function Test-FileInSizeRange {
    param(
        [string]$Path,
        [long]$MinBytes = 200KB,
        [long]$MaxBytes = 15MB
    )
    if (-not (Test-Path $Path -PathType Leaf)) {
        return $false
    }
    try {
        $size = (Get-Item $Path -ErrorAction Stop).Length
        return ($size -ge $MinBytes -and $size -le $MaxBytes)
    }
    catch {
        return $false
    }
}

$script:BytePatterns = @(
    @{
        Name = "Pattern #1"
        Bytes = "6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A160C14005C6588B800"
    },
    @{
        Name = "Pattern #2"
        Bytes = "0C1504851D85160A6161370E160609949E0029033EA7000A2C1D03548403011D1008A1FFF6033EA7000A2B1D03548403011D07A1FFF710FEAC150599001A2A16"
    },
    @{
        Name = "Pattern #3"
        Bytes = "5910071088544C2A2BB8004D3B033DA7000A2B1C03548402011C1008A1FFF61A9E000C1A110800A2000503AC04AC00000000000A0005004E000101FA000001D3"
    }
)

$script:ClassPatterns = @(
    "net/java/f",
    "net/java/g",
    "net/java/h",
    "net/java/i",
    "net/java/k",
    "net/java/l",
    "net/java/m",
    "net/java/r",
    "net/java/s",
    "net/java/t",
    "net/java/y"
)

function ConvertHex-ToBytes {
    param([string]$hexString)
    $bytes = New-Object byte[] ($hexString.Length / 2)
    for ($i = 0; $i -lt $hexString.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($hexString.Substring($i, 2), 16)
    }
    return $bytes
}

function Search-BytePattern {
    param(
        [byte[]]$data,
        [byte[]]$pattern
    )
    $patternLength = $pattern.Length
    $dataLength = $data.Length
    for ($i = 0; $i -le ($dataLength - $patternLength); $i++) {
        $match = $true
        for ($j = 0; $j -lt $patternLength; $j++) {
            if ($data[$i + $j] -ne $pattern[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            return $true
        }
    }
    return $false
}

function Search-ClassPattern {
    param(
        [byte[]]$data,
        [string]$className
    )
    $classBytes = [System.Text.Encoding]::ASCII.GetBytes($className)
    return Search-BytePattern -data $data -pattern $classBytes
}

function Test-ZipMagicBytes {
    param([string]$Path)
    try {
        $fileStream = [System.IO.File]::OpenRead($Path)
        $reader = New-Object System.IO.BinaryReader($fileStream)
        if ($fileStream.Length -lt 2) {
            $reader.Close()
            $fileStream.Close()
            return $false
        }
        $byte1 = $reader.ReadByte()
        $byte2 = $reader.ReadByte()
        $reader.Close()
        $fileStream.Close()
        return ($byte1 -eq 0x50 -and $byte2 -eq 0x4B)
    } catch {
        return $false
    }
}

function Find-SingleLetterClasses {
    param([string]$Path)
    $singleLetterClasses = @()
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        foreach ($entry in $jar.Entries) {
            if ($entry.FullName -like "*.class") {
                $className = $entry.FullName
                $parts = $className -split '/'
                $filename = $parts[-1]
                $classNameOnly = $filename -replace '\.class$', ''
                if ($classNameOnly -match '^[a-zA-Z]$') {
                    $fullPath = ($parts[0..($parts.Length-2)] -join '/') + '/' + $classNameOnly
                    $singleLetterClasses += $fullPath
                }
            }
        }
        $jar.Dispose()
    } catch {
    }
    return $singleLetterClasses
}

function Test-DoomsdayClient {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $result = [PSCustomObject]@{
        IsDetected = $false
        Confidence = "NONE"
        BytePatternMatches = @()
        ClassNameMatches = @()
        SingleLetterClasses = @()
        IsRenamedJar = $false
        Error = $null
    }
    if (-not (Test-Path $Path -PathType Leaf)) {
        $result.Error = "File not found"
        return $result
    }
    try {
        $fileExtension = [System.IO.Path]::GetExtension($Path).ToLower()
        $hasPKHeader = Test-ZipMagicBytes -Path $Path
        if ($hasPKHeader -and $fileExtension -ne ".jar") {
            $result.IsRenamedJar = $true
            $result.IsDetected = $true
            $result.Confidence = "HIGH"
        }
        if (-not $hasPKHeader) {
            $result.Error = "File is not a JAR/ZIP file (missing PK header)"
            return $result
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $classFiles = $jar.Entries | Where-Object { $_.FullName -like "*.class" }
        $classCount = $classFiles.Count
        if ($classCount -gt 30) {
            $jar.Dispose()
            $result.Error = "Skipped: Too many classes ($classCount) - likely legitimate library"
            return $result
        }
        if ($classCount -eq 0) {
            $jar.Dispose()
            $result.Error = "No .class files found in JAR"
            return $result
        }
        $allBytes = @()
        foreach ($entry in $classFiles) {
            $stream = $entry.Open()
            $reader = New-Object System.IO.BinaryReader($stream)
            $bytes = $reader.ReadBytes([int]$entry.Length)
            $allBytes += $bytes
            $reader.Close()
            $stream.Close()
        }
        $jar.Dispose()
        foreach ($pattern in $script:BytePatterns) {
            $patternBytes = ConvertHex-ToBytes -hexString $pattern.Bytes
            if (Search-BytePattern -data $allBytes -pattern $patternBytes) {
                $result.BytePatternMatches += $pattern.Name
            }
        }
        foreach ($className in $script:ClassPatterns) {
            if (Search-ClassPattern -data $allBytes -className $className) {
                $result.ClassNameMatches += $className
            }
        }
        $result.SingleLetterClasses = Find-SingleLetterClasses -Path $Path
        $byteMatchCount = $result.BytePatternMatches.Count
        $classMatchCount = $result.ClassNameMatches.Count
        $singleLetterCount = $result.SingleLetterClasses.Count
        if ($byteMatchCount -ge 2) {
            $result.IsDetected = $true
            $result.Confidence = "HIGH"
        }
        elseif ($byteMatchCount -eq 1 -and ($classMatchCount -ge 5 -or $singleLetterCount -ge 5)) {
            $result.IsDetected = $true
            $result.Confidence = "MEDIUM"
        }
        elseif ($byteMatchCount -eq 1) {
            $result.IsDetected = $true
            $result.Confidence = "LOW"
        }
        elseif ($singleLetterCount -ge 8 -and $classMatchCount -ge 3) {
            $result.IsDetected = $true
            $result.Confidence = "MEDIUM"
        }
        elseif ($singleLetterCount -ge 5 -or $classMatchCount -ge 5) {
            $result.IsDetected = $true
            $result.Confidence = "LOW"
        }
        if ($result.IsRenamedJar -and $result.Confidence -eq "NONE") {
            $result.Confidence = "MEDIUM"
        }
    } catch {
        $result.Error = $_.Exception.Message
    }
    return $result
}

function Start-DoomsdayScan {
    param(
        [switch]$Debug
    )
    $script:DebugMode = $Debug
    Show-Banner
    if (-not (Test-Administrator)) {
        Write-Host ""
        Write-Host "ERROR: " -ForegroundColor Red -NoNewline
        Write-Host "Administrator privileges required!"
        Write-Host ""
        Write-Host "Please launch CMD or PowerShell as admin!" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "[*] Windows Version: $($osVersion.Major).$($osVersion.Minor) Build $($osVersion.Build)" -ForegroundColor Cyan
    if ($osVersion.Major -eq 10) {
        if ($osVersion.Build -ge 22000) {
            Write-Host "[*] Detected: Windows 11" -ForegroundColor Green
        } else {
            Write-Host "[*] Detected: Windows 10" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "[*] Extracting file indexes..." -ForegroundColor Cyan
    Write-Host ""
    $systemPath = "C:\Windows\" + "Pre" + "fetch"
    if (-not (Test-Path $systemPath)) {
        Write-Host "[!] Prefetch directory not found: $systemPath" -ForegroundColor Red
        return
    }
    $javaFiles = Get-ChildItem -Path $systemPath -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue
    if ($javaFiles.Count -eq 0) {
        Write-Host "[!] No JAVA prefetch files found in $systemPath" -ForegroundColor Yellow
        Write-Host "[*] This could mean:" -ForegroundColor Yellow
        Write-Host "    - Java has never been run on this system" -ForegroundColor Gray
        Write-Host "    - Prefetch files have been cleared" -ForegroundColor Gray
        Write-Host "    - Prefetch is disabled" -ForegroundColor Gray
        return
    }
    Write-Host "[+] Found $($javaFiles.Count) JAVA prefetch file(s)" -ForegroundColor Green
    Write-Host ""
    $allJarPaths = @()
    $fileMetadata = @{}
    $processedFiles = 0
    $successfulParsing = 0
    foreach ($sysFile in $javaFiles) {
        $processedFiles++
        Write-Progress -Activity "Extracting Indexes" `
                      -Status "Processing file $processedFiles of $($javaFiles.Count)" `
                      -PercentComplete (($processedFiles / $javaFiles.Count) * 100)
        if ($script:DebugMode) {
            Write-Host ""
            Write-Host "[DEBUG] ======================================" -ForegroundColor Magenta
        }
        $indexes = Get-SystemIndexes -FilePath $sysFile.FullName
        if ($indexes.Count -eq 0) {
            if ($script:DebugMode) {
                Write-Host "  [DEBUG] No indexes extracted from $($sysFile.Name)" -ForegroundColor Yellow
            }
            continue
        }
        $successfulParsing++
        if ($script:DebugMode) {
            Write-Host "  [DEBUG] Successfully extracted $($indexes.Count) paths" -ForegroundColor Green
        }
        $indexNum = 0
        foreach ($index in $indexes) {
            $indexNum++
            if ($index -match '\\VOLUME\{[^\}]+\}\\(.*)$') {
                $relativePath = $Matches[1]
                $assumedPath = "C:\$relativePath"
                $allJarPaths += $assumedPath
                if (-not $fileMetadata.ContainsKey($assumedPath)) {
                    $fileMetadata[$assumedPath] = @{
                        SourceFile = $sysFile.Name
                        IndexNumber = $indexNum
                        OriginalPath = $index
                    }
                }
            }
            else {
                $allJarPaths += $index
                if (-not $fileMetadata.ContainsKey($index)) {
                    $fileMetadata[$index] = @{
                        SourceFile = $sysFile.Name
                        IndexNumber = $indexNum
                        OriginalPath = $index
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Extracting Indexes" -Completed
    Write-Host ""
    Write-Host "[+] Prefetch files successfully parsed: $successfulParsing / $processedFiles" -ForegroundColor Green
    Write-Host "[+] Total file paths extracted: $($allJarPaths.Count)" -ForegroundColor Green
    if ($allJarPaths.Count -eq 0) {
        Write-Host ""
        Write-Host "[!] No file paths could be extracted from prefetch files" -ForegroundColor Yellow
        Write-Host "[*] Possible issues:" -ForegroundColor Yellow
        Write-Host "    - Prefetch parsing failed (incompatible format)" -ForegroundColor Gray
        Write-Host "    - No Java applications with file references" -ForegroundColor Gray
        Write-Host ""
        Write-Host "[*] Try running with -Debug flag for more information:" -ForegroundColor Cyan
        Write-Host "    .\doomsday-scanner-usn.ps1 -Debug" -ForegroundColor White
        return
    }
    $uniquePaths = $allJarPaths | Select-Object -Unique
    Write-Host "[+] Unique files to scan: $($uniquePaths.Count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "[*] Checking file existence across all drives..." -ForegroundColor Cyan
    Write-Host ""
    $existingPaths = @{}
    $trulyMissingPaths = @()
    $checkCount = 0
    $outsideRangeCount = 0
    $resolvedToDifferentDrive = 0
    $allDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object { $_.Root.Substring(0, 1) }
    foreach ($path in $uniquePaths) {
        $checkCount++
        $foundPath = $null
        if (Test-Path $path -PathType Leaf) {
            $foundPath = $path
        }
        else {
            if ($path -match '^[A-Z]:\\(.*)$') {
                $relativePath = $Matches[1]
                foreach ($drive in $allDrives) {
                    $testPath = "$drive`:\$relativePath"
                    if (Test-Path $testPath -PathType Leaf) {
                        $foundPath = $testPath
                        $resolvedToDifferentDrive++
                        if ($script:DebugMode) {
                            Write-Host "  [DEBUG] Found on different drive: $testPath (assumed $path)" -ForegroundColor Cyan
                        }
                        break
                    }
                }
            }
        }
        if ($foundPath) {
            $fileSize = (Get-Item $foundPath -ErrorAction SilentlyContinue).Length
            if ($fileSize -ge 200KB -and $fileSize -le 15MB) {
                $existingPaths[$path] = $foundPath
            } else {
                $outsideRangeCount++
                if ($script:DebugMode) {
                    $sizeMB = [math]::Round($fileSize / 1MB, 2)
                    Write-Host "  [DEBUG] Skipped (size: $sizeMB MB): $foundPath" -ForegroundColor Gray
                }
            }
        }
        else {
            $trulyMissingPaths += $path
        }
    }
    $missingCount = $trulyMissingPaths.Count
    Write-Host ""
    Write-Host "[+] Total paths checked: $checkCount" -ForegroundColor Cyan
    Write-Host "[+] Files found and in size range (200KB-15MB): $($existingPaths.Count)" -ForegroundColor Green
    if ($resolvedToDifferentDrive -gt 0) {
        Write-Host "[+] Files resolved to different drives: $resolvedToDifferentDrive" -ForegroundColor Cyan
    }
    Write-Host "[!] Files outside size range: $outsideRangeCount" -ForegroundColor Gray
    Write-Host "[!] Files truly missing (not on any drive): $missingCount" -ForegroundColor Yellow
    Write-Host ""
    if ($missingCount -gt 0) {
        Write-Host "[*] Truly missing files (deleted from all drives):" -ForegroundColor Cyan
        Write-Host ""
        $displayedCount = 0
        foreach ($missingPath in $trulyMissingPaths) {
            if ($missingPath -match '\\TEMP\\|\\TMP\\|HSPERFDATA|\.TMP$|JNA\d+\.DLL') {
                continue
            }
            if ($missingPath -notmatch '\.(JAR|EXE|DLL)$') {
                continue
            }
            $displayedCount++
            Write-Host "  [DELETED] " -ForegroundColor Yellow -NoNewline
            Write-Host $missingPath -ForegroundColor White
            Write-Host "      Source: " -NoNewline
            Write-Host "$($fileMetadata[$missingPath].SourceFile)" -ForegroundColor Cyan
        }
        if ($displayedCount -eq 0) {
            Write-Host "  No suspicious deletions found (only temp files deleted)" -ForegroundColor Green
        }
        Write-Host ""
    }
    if ($existingPaths.Count -eq 0) {
        Write-Host "[!] No files exist to scan" -ForegroundColor Yellow
        Write-Host "[*] All extracted paths point to files that either:" -ForegroundColor Yellow
        Write-Host "    - No longer exist (deleted)" -ForegroundColor Gray
        Write-Host "    - Are outside the 200KB-15MB size range" -ForegroundColor Gray
        return
    }
    Write-Host "[*] Scanning files for Doomsday Client..." -ForegroundColor Cyan
    Write-Host ""
    $detections = @()
    $scanned = 0
    $skipped = 0
    foreach ($assumedPath in $existingPaths.Keys) {
        $actualPath = $existingPaths[$assumedPath]
        $scanned++
        $filename = [System.IO.Path]::GetFileName($actualPath)
        Write-Progress -Activity "Scanning for Doomsday Client" `
                      -Status "[$scanned/$($existingPaths.Count)]" `
                      -PercentComplete (($scanned / $existingPaths.Count) * 100)
        Write-Host "`r[$scanned/$($existingPaths.Count)]" -NoNewline -ForegroundColor Cyan
        try {
            $result = Test-DoomsdayClient -Path $actualPath
            if ($result.Error -and $result.Error -like "Skipped:*") {
                $skipped++
            }
            if ($result.IsDetected) {
                Write-Host "`r                              `r" -NoNewline
                $detections += [PSCustomObject]@{
                    Path = $actualPath
                    SourceFile = $fileMetadata[$assumedPath].SourceFile
                    IndexNumber = $fileMetadata[$assumedPath].IndexNumber
                    Confidence = $result.Confidence
                    IsRenamedJar = $result.IsRenamedJar
                    BytePatterns = $result.BytePatternMatches.Count
                    ClassMatches = $result.ClassNameMatches.Count
                    SingleLetterClasses = $result.SingleLetterClasses.Count
                }
                Write-Host "[!] DETECTION: " -ForegroundColor Red -NoNewline
                Write-Host $actualPath
                Write-Host "    Confidence: " -NoNewline
                switch ($result.Confidence) {
                    "HIGH"   { Write-Host "HIGH" -ForegroundColor Red }
                    "MEDIUM" { Write-Host "MEDIUM" -ForegroundColor Yellow }
                    "LOW"    { Write-Host "LOW" -ForegroundColor Gray }
                }
                if ($result.IsRenamedJar) {
                    Write-Host "    Renamed JAR detected!" -ForegroundColor Red
                }
                if ($result.BytePatternMatches.Count -gt 0) {
                    Write-Host "    Byte patterns: $($result.BytePatternMatches.Count)" -ForegroundColor Red
                }
                Write-Host ""
            }
        }
        catch {
            Write-Host "`r                              `r" -NoNewline
            Write-Host "Error scanning $filename : $_" -ForegroundColor Red
        }
    }
    Write-Host "`r                              `r" -NoNewline
    Write-Progress -Activity "Scanning for Doomsday Client" -Completed
    Write-Host ""
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SCAN COMPLETE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total indexes extracted: $($allJarPaths.Count)"
    Write-Host "Files in size range: $($uniquePaths.Count)"
    Write-Host "Files exist: $($existingPaths.Count)"
    Write-Host "Files scanned: $scanned"
    Write-Host "Files skipped (>30 classes): $skipped" -ForegroundColor Gray
    Write-Host "Doomsday Client detections: " -NoNewline
    if ($detections.Count -gt 0) {
        Write-Host $detections.Count -ForegroundColor Red
        Write-Host ""
        Write-Host "Detections by confidence:" -ForegroundColor Yellow
        $high = ($detections | Where-Object { $_.Confidence -eq "HIGH" }).Count
        $medium = ($detections | Where-Object { $_.Confidence -eq "MEDIUM" }).Count
        $low = ($detections | Where-Object { $_.Confidence -eq "LOW" }).Count
        if ($high -gt 0) { Write-Host "  HIGH: $high" -ForegroundColor Red }
        if ($medium -gt 0) { Write-Host "  MEDIUM: $medium" -ForegroundColor Yellow }
        if ($low -gt 0) { Write-Host "  LOW: $low" -ForegroundColor Gray }
        Write-Host ""
        Write-Host "DOOMSDAY CLIENT DETECTED ON THIS SYSTEM!" -ForegroundColor Red
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "DETECTION DETAILS" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        $detectionNum = 1
        foreach ($detection in $detections) {
            Write-Host "[$detectionNum] " -NoNewline -ForegroundColor Red
            Write-Host $detection.Path -ForegroundColor White
            Write-Host "    Source File: " -NoNewline
            Write-Host $detection.SourceFile -ForegroundColor Cyan
            Write-Host "    Index Number: " -NoNewline
            Write-Host "#$($detection.IndexNumber)" -ForegroundColor Cyan
            Write-Host "    Confidence: " -NoNewline
            switch ($detection.Confidence) {
                "HIGH"   { Write-Host "HIGH" -ForegroundColor Red }
                "MEDIUM" { Write-Host "MEDIUM" -ForegroundColor Yellow }
                "LOW"    { Write-Host "LOW" -ForegroundColor Gray }
            }
            if ($detection.IsRenamedJar) {
                Write-Host "    Renamed JAR: " -NoNewline
                Write-Host "YES" -ForegroundColor Red
            }
            if ($detection.BytePatterns -gt 0) {
                Write-Host "    Byte Patterns: " -NoNewline
                Write-Host $detection.BytePatterns -ForegroundColor Red
            }
            if ($detection.ClassMatches -gt 0) {
                Write-Host "    Class Matches: " -NoNewline
                Write-Host $detection.ClassMatches -ForegroundColor Yellow
            }
            if ($detection.SingleLetterClasses -gt 0) {
                Write-Host "    Single-Letter Classes: " -NoNewline
                Write-Host $detection.SingleLetterClasses -ForegroundColor Yellow
            }
            Write-Host ""
            $detectionNum++
        }
    } else {
        Write-Host "0" -ForegroundColor Green
        Write-Host ""
        Write-Host "No Doomsday Client detected!" -ForegroundColor Green
    }
    Write-Host ""
    if ($script:DebugMode) {
        Write-Host "[DEBUG MODE] Scan completed with debugging enabled" -ForegroundColor Magenta
    }
}

Start-DoomsdayScan
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
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$currentFont = (Get-ItemProperty "HKCU:\Console" -ErrorAction SilentlyContinue).FaceName
if ($currentFont -notmatch "NSimSun|Gothic|Noto") {
    Write-Host "  [!] Tip: Set your terminal font to 'NSimSun' to display all elements correctly." -ForegroundColor DarkYellow
    Write-Host
}

$Banner = @"
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                              ║
║   ████████╗███████╗███████╗██╗      █████╗ ██████╗ ██████╗  ██████╗         ║
║   ╚══██╔══╝██╔════╝██╔════╝██║     ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗        ║
║      ██║   █████╗  ███████╗██║     ███████║██████╔╝██████╔╝██║   ██║        ║
║      ██║   ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔══██╗██║   ██║        ║
║      ██║   ███████╗███████║███████╗██║  ██║██║     ██║  ██║╚██████╔╝        ║
║      ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝         ║
║                                                                                              ║
║                     G H O S T   C L I E N T   S C A N                       ║
║                                                                                              ║
╚════════════════════════════════════════════════════════════════════════════════╝
"@

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host ("║  " + $Title.PadRight(64) + "║") -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Good {
    param([string]$Text)
    Write-Host "  [+] $Text" -ForegroundColor Green
}

function Write-Bad {
    param([string]$Text)
    Write-Host "  [!] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [•] $Text" -ForegroundColor Gray
}

function Write-Row {
    param([string]$char, [int]$count, [System.ConsoleColor]$color)
    Write-Host ($char * $count) -ForegroundColor $color
}

Write-Host $Banner -ForegroundColor Cyan
Write-Host ""
Write-Section "TESLAPRO ADVANCED SCANNER"
Write-Host "  ⚡ Powered by " -ForegroundColor Gray -NoNewline
Write-Host "TeslaPro " -ForegroundColor Cyan -NoNewline
Write-Host "|| " -ForegroundColor DarkGray -NoNewline
Write-Host "Discord: " -ForegroundColor Gray -NoNewline
Write-Host "teamwsf " -ForegroundColor White -NoNewline
Write-Host "|| " -ForegroundColor DarkGray -NoNewline
Write-Host "Credits to: " -ForegroundColor DarkGray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor DarkGray
Write-Host ""
Write-Row "─" 85 DarkGray
Write-Host

Write-Host "  [>] Enter the path to the mods folder: " -NoNewline -ForegroundColor White
Write-Host "(Press Enter for default)" -ForegroundColor DarkGray
$modsPath = Read-Host "  "
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "  [+] Starting with default location: " -NoNewline -ForegroundColor Gray
    Write-Host $modsPath -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "  [X] ERROR: Invalid Path!" -ForegroundColor Red
    Write-Host "  [-] The specified directory does not exist or is inaccessible." -ForegroundColor Yellow
    Write-Host
    exit 1
}

Write-Row "═" 85 DarkCyan
Write-Host "  [►] SCAN MODE ACTIVATED ON: $modsPath" -ForegroundColor Green
Write-Row "═" 85 DarkCyan
Write-Host

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "  ┌── { Minecraft Runtime Status }" -ForegroundColor Cyan
        Write-Host "  ├── Process: $($mcProcess.Name) (PID $($mcProcess.Id))" -ForegroundColor Gray
        Write-Host "  ├── Started on: $startTime" -ForegroundColor Gray
        Write-Host "  └── Uptime:     $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "JumpReset", "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "Virgin", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill",  "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean", "Argon",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy", "DubbelKeybinds", "DoubleKeybinds",
    "Grim", "grim", "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion", "dev.gambleclient", "obfuscatedAuth",
    "xyz.greaj"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "AutoHitCrystal",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "anchortweaks", "AirAnchor",
    "AutoTotem", "autototem", "InventoryTotem", "HoverTotem",
    "AutoPot", "autopot", "AutoArmor", "autoarmor", "ShieldDisabler", "ShieldBreaker",
    "AutoDoubleHand", "AutoClicker", "AutoMace", "MaceSwap", "SpearSwap",
    "Donut", "JumpReset", "axespam", "axe spam", "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot", "Silent Rotations", "SilentRotations",
    "FakeInv", "FakeLag", "pingspoof", "ping spoof", "fakePunch", "Fake Punch",
    "webmacro", "AntiWeb", "AutoWeb", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "PackSpoof", "Antiknockback",
    "AuthBypass", "obfuscatedAuth", "BaseFinder", "invsee", "ItemExploit", "FreezePlayer"
)

$clientFrameworks = @{
    "meteor-client" = "Meteor Client Core"
    "meteorclient" = "Meteor Client Core"
    "meteordevelopment" = "Meteor Client API"
    "vape.gg" = "Vape Client Injectable"
    "vapeclient" = "Vape Client Framework"
    "novaclient" = "Nova Client Leaks"
    "liquidbounce" = "LiquidBounce Utility Mod"
    "fdp-client" = "FDP Bypass Client"
    "aristois" = "Aristois Hack Menu"
    "impactclient" = "Impact Utility Engine"
    "futureClient" = "Future Client Framework"
    "rusherhack" = "Rusherhack Utility Pack"
    "DubbelKeybinds" = "DubbelKeybinds Found"
    "doublekeybinds" = "DubbelKeybinds Found"
}

$patternRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

function Get-FileSHA1 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA1).Hash
}

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                         { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord CDN" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub Releases" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        else {
            if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
            return $url
        }
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
    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
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
                    foreach ($s in $cheatStringSet) {
                        if ($ascii.Contains($s)) {
                            [void]$foundStrings.Add($s)
                            if ($clientFrameworks.ContainsKey($s)) { [void]$detectedClients.Add($clientFrameworks[$s]) }
                        }
                    }
                } catch { }
            }
        }
        $archive.Dispose()
    } catch { }
    return @{ Patterns = $foundPatterns; Strings = $foundStrings; ClientFrames = $detectedClients }
}

$files = Get-ChildItem -Path $modsPath -Filter *.jar -File -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Host "  [i] No target items discovered." -ForegroundColor Yellow
    exit 0
}

$flaggedMods = [System.Collections.Generic.List[object]]::new()
$cleanMods   = [System.Collections.Generic.List[object]]::new()
$totalFiles  = $files.Count
$currentIndex = 0

Write-Host "  [>] Commencing sequence pipeline on $totalFiles elements..." -ForegroundColor Cyan
Write-Host

foreach ($file in $files) {
    $currentIndex++
    $percent = [math]::Round(($currentIndex / $totalFiles) * 100)
    Write-Progress -Activity "TeslaPro Ghost Scan" -Status "Running: $($file.Name)" -PercentComplete $percent

    $sha1 = Get-FileSHA1 -Path $file.FullName
    $source = Get-DownloadSource -Path $file.FullName

    $modrinth = Query-Modrinth -Hash $sha1
    if ($modrinth.Name) {
        $cleanMods.Add(@{ Name = $file.Name; Details = "Verified Modrinth Archive: $($modrinth.Name)" })
        continue
    }

    $scan = Invoke-ModScan -FilePath $file.FullName

    if ($scan.Patterns.Count -gt 0 -or $scan.Strings.Count -gt 0) {
        $clientTag = "Custom Modified / Independent Hack"
        if ($scan.ClientFrames.Count -gt 0) { $clientTag = ($scan.ClientFrames | ForEach-Object {$_}) -join ", " }

        $flaggedMods.Add(@{
            File       = $file.Name
            Source     = $source
            Client     = $clientTag
            Indicators = @($scan.Patterns + $scan.Strings)
        })
    } else {
        $cleanMods.Add(@{ Name = $file.Name; Details = "No anomalies identified inside target binaries." })
    }
}

Clear-Host
Write-Host $Banner -ForegroundColor Cyan
Write-Host "`n"

Write-Row "═" 90 Cyan
Write-Host "                 TESLAPRO GHOSTCLIENTFUCKER - DETAILED SCAN REPORT                  " -ForegroundColor White
Write-Row "═" 90 Cyan
Write-Host ""
Write-Host "  [+] TARGET DIRECTORY : " -NoNewline -ForegroundColor Gray; Write-Host "$modsPath" -ForegroundColor White
Write-Host "  [+] TOTAL SCANNED    : " -NoNewline -ForegroundColor Gray; Write-Host "$totalFiles JAR files examined" -ForegroundColor White
Write-Host "  [+] INFRA STATUS     : " -NoNewline -ForegroundColor Gray
if ($flaggedMods.Count -gt 0) {
    Write-Host "COMPROMISED - CHEAT MODIFICATIONS OR GHOST CLIENTS DETECTED" -ForegroundColor Red
} else {
    Write-Host "CLEAN - ALL FILES VALIDATED AGAINST TRUSTED STANDARDS" -ForegroundColor Green
}
Write-Host ""

Write-Row "─" 90 DarkGray
Write-Host " 🛑 FLAGGED SOFTWARE & INJECTED CLIENT ASSEMBLIES ($($flaggedMods.Count) Files Flagged)" -ForegroundColor Red
Write-Row "─" 90 DarkGray
Write-Host ""

if ($flaggedMods.Count -eq 0) {
    Write-Host "  📋 No malicious modules or cheat client payloads found in the target directory." -ForegroundColor Green
    Write-Host ""
} else {
    foreach ($mod in $flaggedMods) {
        Write-Host "  [💥] DETECTED MOD : " -NoNewline -ForegroundColor White
        Write-Host "$($mod.File)" -ForegroundColor Red

        Write-Host "       ├── Client Base/Framework : " -NoNewline -ForegroundColor Gray
        Write-Host "$($mod.Client)" -ForegroundColor Yellow

        Write-Host "       ├── Network Source Stream : " -NoNewline -ForegroundColor Gray
        Write-Host "$($mod.Source)" -ForegroundColor DarkYellow

        Write-Host "       └── Signature Triggers    : " -NoNewline -ForegroundColor Gray
        $indList = ($mod.Indicators | ForEach-Object { "'$_'" }) -join ", "
        Write-Host "[$indList]" -ForegroundColor DarkCyan
        Write-Host ""
    }
}

Write-Row "─" 90 DarkGray
Write-Host " ✅ SAFE & INDEPENDENT VERIFIED MODS ($($cleanMods.Count) Files Cleared)" -ForegroundColor Green
Write-Row "─" 90 DarkGray
Write-Host ""

if ($cleanMods.Count -eq 0) {
    Write-Host "  [!] Zero modules returned verified status benchmarks or repository matches." -ForegroundColor Yellow
    Write-Host ""
} else {
    foreach ($c in $cleanMods) {
        Write-Host "  [✓] PASSED: " -NoNewline -ForegroundColor Green
        Write-Host "$($c.Name) " -NoNewline -ForegroundColor White
        Write-Host "➔ $($c.Details)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Row "═" 90 Cyan
Write-Host "  📊 FINAL ANALYSIS METRICS MATRIX:" -ForegroundColor White
Write-Host "  ────────────────────────────────"
Write-Host "  • Total Examined Elements   : " -NoNewline -ForegroundColor Gray; Write-Host "$totalFiles" -ForegroundColor White
Write-Host "  • Rogue/Flagged Items Found : " -NoNewline -ForegroundColor Gray; Write-Host "$($flaggedMods.Count)" -ForegroundColor Red
Write-Host "  • Clean/Verified Packages   : " -NoNewline -ForegroundColor Gray; Write-Host "$($cleanMods.Count)" -ForegroundColor Green
Write-Host ""
Write-Row "═" 90 Cyan
Write-Host ""
Write-Host "  ✨ System Analysis Complete. Thanks for using TeslaPro's Ghost client fucker!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👤 Creator   : " -ForegroundColor White -NoNewline
Write-Host "TeslaPro" -ForegroundColor Cyan
Write-Host "  📱 Discord   : " -ForegroundColor White -NoNewline
Write-Host "teamwsf" -ForegroundColor White
Write-Host "  📝 Credits to: " -ForegroundColor DarkGray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  [i] Forensic scan run terminated. Press any key to safely dispose this window..." -ForegroundColor Gray
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

$script:DebugMode = $false
$script:RecentDeletions = @{}
$script:USNSearched = $false

$script:CyemerNeedles = @(
    "com/slither/cyemer",
    "com.slither.cyemer",
    "CyemerClient",
    "com/slither/cyemer/Cyemer.class",
    "com/slither/cyemer/CyemerClient.class",
    "cyemer.client.mixins.json",
    "assets/dynamic_fps/textures/cyemer.png",
    "assets/dynamic_fps/font/cyemer.json",
    "dynamic_fps",
    "AimAssist",
    "TriggerBot",
    "AutoCrystal",
    "AutoAnchor",
    "AutoShieldBreak",
    "BowAimbot",
    "ESP",
    "Effectesp",
    "Fakelag",
    "Blink",
    "WTap",
    "Fly",
    "FastPlace",
    "AutoTotem",
    "SelfDestruct",
    "AuthenticationScreen",
    "ConfigHubManager",
    "RemoteConfig",
    "CustomCapeUploadScreen",
    "TotemPopManager",
    "ReachHudElement",
    "TargetHudElement",
    "sqlite-jdbc",
    "esp_surface.fsh",
    "esp_surface.vsh",
    "com/slither/cyemer/module/implementation/combat/",
    "com/slither/cyemer/module/implementation/movement/",
    "com/slither/cyemer/module/implementation/render/",
    "com/slither/cyemer/mixin/",
    "com/slither/cyemer/gui/new_ui/",
    "com/slither/cyemer/config/hub/"
)

$script:StrongNeedles = @(
    "com/slither/cyemer",
    "CyemerClient",
    "cyemer.client.mixins.json",
    "assets/dynamic_fps/textures/cyemer.png",
    "AuthenticationScreen",
    "RemoteConfig"
)

$script:SelfDestructKeywords = @(
    "cyemer", "client", "ghost", "inject", "loader", "launch", "minecraft",
    "mc", "cheat", "hack", "clicker", "autoclick", "bypass", "destruct",
    "selfdestruct", "crystal", "aim", "trigger", "esp"
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NtdllDecompressor {
    [DllImport("ntdll.dll")]
    public static extern uint RtlDecompressBufferEx(
        ushort CompressionFormat,
        byte[] UncompressedBuffer,
        int UncompressedBufferSize,
        byte[] CompressedBuffer,
        int CompressedBufferSize,
        out int FinalUncompressedSize,
        IntPtr WorkSpace
    );

    [DllImport("ntdll.dll")]
    public static extern uint RtlGetCompressionWorkSpaceSize(
        ushort CompressionFormat,
        out uint CompressBufferWorkSpaceSize,
        out uint CompressFragmentWorkSpaceSize
    );

    public static byte[] Decompress(byte[] compressed) {
        if (compressed.Length < 8) return null;
        if (compressed[0] != 0x4D || compressed[1] != 0x41 || compressed[2] != 0x4D) {
            return null;
        }
        int uncompSize = BitConverter.ToInt32(compressed, 4);
        uint wsComp, wsFrag;
        if (RtlGetCompressionWorkSpaceSize(4, out wsComp, out wsFrag) != 0) return null;
        IntPtr workspace = Marshal.AllocHGlobal((int)wsFrag);
        byte[] result = new byte[uncompSize];
        try {
            int finalSize;
            byte[] compData = new byte[compressed.Length - 8];
            Array.Copy(compressed, 8, compData, 0, compData.Length);
            uint status = RtlDecompressBufferEx(4, result, uncompSize,
                compData, compData.Length, out finalSize, workspace);
            if (status != 0) return null;
            return result;
        }
        finally {
            Marshal.FreeHGlobal(workspace);
        }
    }
}
"@

function Show-Banner {
    Clear-Host
    $banner = @"
 ██████╗██╗   ██╗███████╗███╗   ███╗███████╗██████╗ 
██╔════╝╚██╗ ██╔╝██╔════╝████╗ ████║██╔════╝██╔══██╗
██║      ╚████╔╝ █████╗  ██╔████╔██║█████╗  ██████╔╝
██║       ╚██╔╝  ██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══██╗
╚██████╗   ██║   ███████╗██║ ╚═╝ ██║███████╗██║  ██║
 ╚═════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝
"@
    Write-Host $banner -ForegroundColor Red
    Write-Host ""
    Write-Host "                         CYEMER FORENSIC SCANNER" -ForegroundColor White
    Write-Host "                    Prefetch + JAR + USN Investigation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("=" * 88) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Separator { Write-Host ("=" * 88) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 88) -ForegroundColor DarkGray }

function Write-Stat {
    param(
        [string]$Label,
        [string]$Value,
        [ConsoleColor]$ValueColor = [ConsoleColor]::White
    )
    $Label = $Label.PadRight(24)
    Write-Host "  $Label : " -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $ValueColor
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ZipMagicBytes {
    param([string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $br = New-Object System.IO.BinaryReader($fs)
        if ($fs.Length -lt 2) { $br.Close(); $fs.Close(); return $false }
        $b1 = $br.ReadByte()
        $b2 = $br.ReadByte()
        $br.Close()
        $fs.Close()
        return ($b1 -eq 0x50 -and $b2 -eq 0x4B)
    } catch {
        return $false
    }
}

function Get-NTFSDrives {
    $ntfsDrives = @()
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
    foreach ($drive in $drives) {
        try {
            $letter = $drive.Root.Substring(0, 1)
            $vol = Get-Volume -DriveLetter $letter
            if ($vol -and $vol.FileSystem -eq 'NTFS') {
                $ntfsDrives += $letter
            }
        } catch {}
    }
    return $ntfsDrives
}

function Search-BytePattern {
    param(
        [byte[]]$Data,
        [byte[]]$Pattern
    )
    $pLen = $Pattern.Length
    $dLen = $Data.Length
    for ($i = 0; $i -le ($dLen - $pLen); $i++) {
        $match = $true
        for ($j = 0; $j -lt $pLen; $j++) {
            if ($Data[$i + $j] -ne $Pattern[$j]) {
                $match = $false
                break
            }
        }
        if ($match) { return $true }
    }
    return $false
}

function Find-SingleLetterClasses {
    param([string]$Path)
    $hits = @()
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        foreach ($entry in $jar.Entries) {
            if ($entry.FullName -like "*.class") {
                $parts = $entry.FullName -split '/'
                $file = $parts[-1] -replace '\.class$',''
                if ($file -match '^[a-zA-Z]$') {
                    $hits += $entry.FullName
                }
            }
        }
        $jar.Dispose()
    } catch {}
    return $hits
}

function Get-PrefetchVersion {
    param([byte[]]$Data)
    if ($Data.Length -lt 8) { return 0 }
    $sig = [System.Text.Encoding]::ASCII.GetString($Data, 4, 4)
    if ($sig -ne "SCCA") { return 0 }
    return [BitConverter]::ToUInt32($Data, 0)
}

function Get-SystemIndexes {
    param([string]$FilePath)
    try {
        $data = [System.IO.File]::ReadAllBytes($FilePath)
        $isCompressed = ($data[0] -eq 0x4D -and $data[1] -eq 0x41 -and $data[2] -eq 0x4D)
        if ($isCompressed) {
            $data = [NtdllDecompressor]::Decompress($data)
            if ($null -eq $data) { return @() }
        }
        if ($data.Length -lt 108) { return @() }
        $sig = [System.Text.Encoding]::ASCII.GetString($data, 4, 4)
        if ($sig -ne "SCCA") { return @() }
        $version = Get-PrefetchVersion -Data $data
        $stringsOffset = [BitConverter]::ToUInt32($data, 100)
        $stringsSize   = [BitConverter]::ToUInt32($data, 104)
        if ($stringsOffset -eq 0 -or $stringsSize -eq 0) { return @() }
        if ($stringsOffset -ge $data.Length -or ($stringsOffset + $stringsSize) -gt $data.Length) { return @() }
        $filenames = @()
        $pos = $stringsOffset
        $endPos = $stringsOffset + $stringsSize
        while ($pos -lt $endPos -and $pos -lt ($data.Length - 2)) {
            $nullPos = $pos
            while ($nullPos -lt ($data.Length - 1)) {
                if ($data[$nullPos] -eq 0 -and $data[$nullPos + 1] -eq 0) { break }
                $nullPos += 2
            }
            if ($nullPos -gt $pos) {
                $strLen = $nullPos - $pos
                if ($strLen -gt 0 -and $strLen -lt 4096) {
                    try {
                        $filename = [System.Text.Encoding]::Unicode.GetString($data, $pos, $strLen)
                        if ($filename.Length -gt 0) { $filenames += $filename }
                    } catch {}
                }
            }
            $pos = $nullPos + 2
            if ($filenames.Count -gt 3000) { break }
        }
        return $filenames
    } catch {
        return @()
    }
}

function Get-RecentDeletionsFromUSN {
    param(
        [string[]]$DriveLetters,
        [int]$MinutesBack = 90
    )
    if ($script:USNSearched) { return $script:RecentDeletions }
    $allRecent = @{}
    $cutoff = (Get-Date).AddMinutes(-$MinutesBack)
    foreach ($drive in $DriveLetters) {
        try {
            $usnOutput = & fsutil usn readjournal "$drive`:" 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $usnOutput) { continue }
            $currentFile = ""
            $currentTime = $null
            $currentReason = ""
            foreach ($line in $usnOutput) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if ($line -match 'File name\s+:\s*(.+)$') {
                    $currentFile = $Matches[1].Trim()
                }
                elseif ($line -match 'Time stamp\s+:\s*(.+)$') {
                    try { $currentTime = [DateTime]::Parse($Matches[1].Trim()) } catch { $currentTime = $null }
                }
                elseif ($line -match 'Reason\s+:\s*(.+)$') {
                    $currentReason = $Matches[1].Trim()
                    if ($currentFile -and $currentTime -and $currentTime -gt $cutoff) {
                        $fullKey = "$drive`:\$currentFile"
                        if (-not $allRecent.ContainsKey($fullKey) -or $allRecent[$fullKey].Timestamp -lt $currentTime) {
                            $allRecent[$fullKey] = @{
                                Timestamp = $currentTime
                                Reason    = $currentReason
                                Drive     = $drive
                            }
                        }
                    }
                    $currentFile = ""
                    $currentTime = $null
                    $currentReason = ""
                }
            }
        } catch {}
    }
    $script:RecentDeletions = $allRecent
    $script:USNSearched = $true
    return $allRecent
}

function Test-RecentlyDeleted {
    param([string]$FilePath)
    if ($script:RecentDeletions.ContainsKey($FilePath)) {
        return $script:RecentDeletions[$FilePath]
    }
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    foreach ($key in $script:RecentDeletions.Keys) {
        if ($key -like "*\$fileName") {
            return $script:RecentDeletions[$key]
        }
    }
    return $null
}

function Test-CyemerClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    $result = [PSCustomObject]@{
        IsDetected          = $false
        Confidence          = "NONE"
        MatchCount          = 0
        StrongMatchCount    = 0
        Matches             = @()
        SingleLetterClasses = @()
        IsRenamedJar        = $false
        Error               = $null
    }
    if (-not (Test-Path $Path -PathType Leaf)) {
        $result.Error = "File not found"
        return $result
    }
    try {
        $ext = [System.IO.Path]::GetExtension($Path).ToLower()
        $hasPK = Test-ZipMagicBytes -Path $Path
        if ($hasPK -and $ext -ne ".jar") {
            $result.IsRenamedJar = $true
        }
        if (-not $hasPK) {
            $result.Error = "Not a ZIP/JAR"
            return $result
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        [System.Collections.Generic.List[byte]]$allBytesList = New-Object 'System.Collections.Generic.List[byte]'
        foreach ($entry in $jar.Entries) {
            $entryNameBytes = [System.Text.Encoding]::ASCII.GetBytes($entry.FullName)
            [void]$allBytesList.AddRange($entryNameBytes)
            if ($entry.FullName -like "*.class" -or
                $entry.FullName -like "*.json"  -or
                $entry.FullName -like "*.png"   -or
                $entry.FullName -like "*.fsh"   -or
                $entry.FullName -like "*.vsh"   -or
                $entry.FullName -like "META-INF/MANIFEST.MF" -or
                $entry.FullName -like "fabric.mod.json") {
                try {
                    $stream = $entry.Open()
                    $reader = New-Object System.IO.BinaryReader($stream)
                    $bytes = $reader.ReadBytes([int]$entry.Length)
                    [void]$allBytesList.AddRange($bytes)
                    $reader.Close()
                    $stream.Close()
                } catch {}
            }
        }
        $jar.Dispose()
        $allBytes = $allBytesList.ToArray()
        foreach ($needle in $script:CyemerNeedles) {
            $needleBytes = [System.Text.Encoding]::ASCII.GetBytes($needle)
            if (Search-BytePattern -Data $allBytes -Pattern $needleBytes) {
                $result.Matches += $needle
            }
        }
        foreach ($needle in $script:StrongNeedles) {
            $needleBytes = [System.Text.Encoding]::ASCII.GetBytes($needle)
            if (Search-BytePattern -Data $allBytes -Pattern $needleBytes) {
                $result.StrongMatchCount++
            }
        }
        $result.SingleLetterClasses = Find-SingleLetterClasses -Path $Path
        $result.MatchCount = $result.Matches.Count
        if ($result.StrongMatchCount -ge 3) {
            $result.IsDetected = $true
            $result.Confidence = "HIGH"
        }
        elseif ($result.StrongMatchCount -ge 2 -and $result.MatchCount -ge 6) {
            $result.IsDetected = $true
            $result.Confidence = "HIGH"
        }
        elseif ($result.MatchCount -ge 10) {
            $result.IsDetected = $true
            $result.Confidence = "HIGH"
        }
        elseif ($result.MatchCount -ge 6) {
            $result.IsDetected = $true
            $result.Confidence = "MEDIUM"
        }
        elseif ($result.MatchCount -ge 3) {
            $result.IsDetected = $true
            $result.Confidence = "LOW"
        }
        if ($result.IsRenamedJar -and $result.IsDetected -and $result.Confidence -eq "LOW") {
            $result.Confidence = "MEDIUM"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    return $result
}

function Test-SelfDestructSuspicion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$SourceFile = "",
        $RecentDeletion = $null
    )
    $result = [PSCustomObject]@{
        IsSuspicious = $false
        Confidence   = "NONE"
        Score        = 0
        Reasons      = @()
        FileName     = [System.IO.Path]::GetFileName($Path)
        Extension    = [System.IO.Path]::GetExtension($Path).ToLower()
        Path         = $Path
    }
    $lowerPath = $Path.ToLower()
    $lowerName = $result.FileName.ToLower()
    if ($result.Extension -in @(".jar", ".exe", ".dll", ".bin", ".dat")) {
        $result.Score += 2
        $result.Reasons += "Java-referenced executable/container extension"
    }
    if ($result.Extension -ne ".jar" -and (Test-ZipMagicBytes -Path $Path)) {
        $result.Score += 4
        $result.Reasons += "Renamed JAR-style payload"
    }
    $keywordHits = @($script:SelfDestructKeywords | Where-Object { $lowerName -like "*$_*" })
    if ($keywordHits.Count -gt 0) {
        $result.Score += [Math]::Min(4, $keywordHits.Count + 1)
        $result.Reasons += "Suspicious filename keywords: $($keywordHits -join ', ')"
    }
    if ($lowerPath -match '\\downloads\\|\\desktop\\|\\documents\\|\\appdata\\roaming\\|\\appdata\\local\\|\\temp\\|\\tmp\\|\\minecraft\\|\\mods\\|\\versions\\|\\libraries\\') {
        $result.Score += 2
        $result.Reasons += "Stored in user/mod/temp-related path"
    }
    if ($SourceFile -match '^JAVA.*\.pf$') {
        $result.Score += 2
        $result.Reasons += "Referenced by Java prefetch"
    }
    if ($RecentDeletion) {
        $result.Score += 3
        $result.Reasons += "Recently removed or modified according to USN Journal"
        if ($RecentDeletion.Reason -match 'FILE_DELETE|CLOSE|RENAME|DATA_TRUNCATION') {
            $result.Score += 2
            $result.Reasons += "USN reason suggests delete/rename/truncation"
        }
    }
    if ($lowerPath -match '\\minecraft\\|\\mods\\|\\versions\\|\\libraries\\') {
        $result.Score += 3
        $result.Reasons += "Missing Java artifact from suspicious Minecraft-related path"
    }
    if ($lowerName -match '^(cyemer|loader|client|ghost|inject|launch|mod|hack|cheat)[a-z0-9_\-]*\.(jar|exe|dll|bin|dat)$') {
        $result.Score += 2
        $result.Reasons += "Payload-style filename"
    }
    if ($result.Score -ge 10) {
        $result.IsSuspicious = $true
        $result.Confidence = "HIGH"
    }
    elseif ($result.Score -ge 7) {
        $result.IsSuspicious = $true
        $result.Confidence = "MEDIUM"
    }
    elseif ($result.Score -ge 4) {
        $result.IsSuspicious = $true
        $result.Confidence = "LOW"
    }
    return $result
}

function Show-Summary {
    param(
        [hashtable]$Stats,
        [array]$Detections,
        [array]$DeletedFiles,
        [array]$SelfDestructFindings
    )
    Show-Banner
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Separator
    $high = ($Detections | Where-Object { $_.Confidence -eq "HIGH" }).Count
    $medium = ($Detections | Where-Object { $_.Confidence -eq "MEDIUM" }).Count
    $low = ($Detections | Where-Object { $_.Confidence -eq "LOW" }).Count
    if ($Detections.Count -gt 0) {
        Write-Stat "Scan Status" "DETECTIONS FOUND" Red
    } else {
        Write-Stat "Scan Status" "CLEAN" Green
    }
    Write-Stat "Windows Version" $Stats.WindowsVersion White
    Write-Stat "Java Prefetch Files" "$($Stats.JavaPrefetchCount)" White
    Write-Stat "Parsed Prefetch Files" "$($Stats.SuccessfulParsing) / $($Stats.ProcessedFiles)" White
    Write-Stat "Extracted Paths" "$($Stats.TotalIndexes)" White
    Write-Stat "Unique Paths" "$($Stats.UniquePaths)" White
    Write-Stat "Existing Files" "$($Stats.ExistingFiles)" White
    Write-Stat "Files Scanned" "$($Stats.FilesScanned)" White
    Write-Stat "Files Skipped" "$($Stats.FilesSkipped)" White
    Write-Stat "Missing Files" "$($Stats.MissingFiles)" $(if ($Stats.MissingFiles -gt 0) { "Yellow" } else { "Green" })
    Write-Stat "Detections" "$($Detections.Count)" $(if ($Detections.Count -gt 0) { "Red" } else { "Green" })
    Write-Stat "Self-Destruct Hits" "$($SelfDestructFindings.Count)" $(if ($SelfDestructFindings.Count -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    Write-SubSeparator
    Write-Host "  CONFIDENCE BREAKDOWN" -ForegroundColor White
    Write-SubSeparator
    Write-Host ""
    Write-Stat "HIGH" "$high" $(if ($high -gt 0) { "Red" } else { "Green" })
    Write-Stat "MEDIUM" "$medium" $(if ($medium -gt 0) { "Yellow" } else { "Green" })
    Write-Stat "LOW" "$low" $(if ($low -gt 0) { "Gray" } else { "Green" })
    Write-Host ""
}

function Show-Detections {
    param([array]$Detections)
    Show-Banner
    Write-Host "  DETECTIONS" -ForegroundColor Cyan
    Write-Separator
    if ($Detections.Count -eq 0) {
        Write-Host "  Geen Cyemer-detecties gevonden." -ForegroundColor Green
        return
    }
    $i = 1
    foreach ($d in $Detections) {
        Write-Host "  [$i] $($d.Path)" -ForegroundColor White
        Write-Host ""
        Write-Stat "Source File" $d.SourceFile Cyan
        Write-Stat "Index Number" "#$($d.IndexNumber)" White
        Write-Stat "Confidence" $d.Confidence $(switch ($d.Confidence) { "HIGH" {"Red"} "MEDIUM" {"Yellow"} "LOW" {"Gray"} default {"White"} })
        Write-Stat "Renamed JAR" $(if ($d.IsRenamedJar) { "YES" } else { "NO" }) $(if ($d.IsRenamedJar) { "Red" } else { "Green" })
        Write-Stat "Match Count" "$($d.MatchCount)" White
        Write-Stat "Strong Matches" "$($d.StrongMatchCount)" White
        Write-Host "  Matches:" -ForegroundColor White
        foreach ($m in $d.Matches) {
            Write-Host "    - $m" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-SubSeparator
        $i++
    }
}

function Show-DeletedFiles {
    param([array]$DeletedFiles)
    Show-Banner
    Write-Host "  DELETED / MISSING FILES" -ForegroundColor Cyan
    Write-Separator
    if ($DeletedFiles.Count -eq 0) {
        Write-Host "  Geen verdachte deleted/missing files gevonden." -ForegroundColor Green
        return
    }
    $i = 1
    foreach ($f in $DeletedFiles) {
        Write-Host "  [$i] $($f.Path)" -ForegroundColor White
        Write-Host ""
        Write-Stat "Source Prefetch" $f.SourceFile Cyan
        Write-Stat "Last Activity" $(if ($f.DeletionTime) { $f.DeletionTime } else { "Unknown" }) White
        Write-Stat "USN Reason" $(if ($f.Reason) { $f.Reason } else { "Unavailable" }) White
        Write-Stat "Self-Destruct" $(if ($f.Suspicious) { $f.SuspicionConfidence } else { "NO" }) $(if ($f.Suspicious) { if ($f.SuspicionConfidence -eq "HIGH") {"Red"} elseif ($f.SuspicionConfidence -eq "MEDIUM") {"Yellow"} else {"Gray"} } else { "Green" })
        Write-Stat "Suspicion Score" "$($f.SuspicionScore)" White
        Write-Host ""
        Write-SubSeparator
        $i++
    }
}

function Show-SelfDestruct {
    param([array]$Findings)
    Show-Banner
    Write-Host "  SELF-DESTRUCT ANALYSIS" -ForegroundColor Cyan
    Write-Separator
    if ($Findings.Count -eq 0) {
        Write-Host "  Geen duidelijke self-destruct indicators gevonden." -ForegroundColor Green
        return
    }
    $i = 1
    foreach ($item in $Findings) {
        Write-Host "  [$i] $($item.Path)" -ForegroundColor White
        Write-Host ""
        Write-Stat "Source Prefetch" $item.SourceFile Cyan
        Write-Stat "Confidence" $item.Confidence $(switch ($item.Confidence) { "HIGH" {"Red"} "MEDIUM" {"Yellow"} "LOW" {"Gray"} default {"White"} })
        Write-Stat "Suspicion Score" "$($item.Score)" White
        Write-Stat "Last Activity" $(if ($item.DeletionTime) { $item.DeletionTime } else { "Unknown" }) White
        Write-Stat "USN Reason" $(if ($item.Reason) { $item.Reason } else { "Unavailable" }) White
        Write-Host "  Indicators:" -ForegroundColor White
        foreach ($r in $item.Reasons) {
            Write-Host "    - $r" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-SubSeparator
        $i++
    }
}

function Read-Choice {
    Write-Host ""
    Write-Host "  [1] Summary    [2] Detections    [3] Deleted Files    [4] Self-Destruct    [Q] Exit" -ForegroundColor Cyan
    Write-Separator
    Write-Host ""
    Write-Host "  Select option: " -NoNewline -ForegroundColor White
    return (Read-Host).Trim().ToUpper()
}

function Show-Dashboard {
    param(
        [hashtable]$Stats,
        [array]$Detections,
        [array]$DeletedFiles,
        [array]$SelfDestructFindings
    )
    $tab = "1"
    while ($true) {
        switch ($tab) {
            "1" { Show-Summary -Stats $Stats -Detections $Detections -DeletedFiles $DeletedFiles -SelfDestructFindings $SelfDestructFindings }
            "2" { Show-Detections -Detections $Detections }
            "3" { Show-DeletedFiles -DeletedFiles $DeletedFiles }
            "4" { Show-SelfDestruct -Findings $SelfDestructFindings }
            default { Show-Summary -Stats $Stats -Detections $Detections -DeletedFiles $DeletedFiles -SelfDestructFindings $SelfDestructFindings }
        }
        $choice = Read-Choice
        switch ($choice) {
            "1" { $tab = "1" }
            "2" { $tab = "2" }
            "3" { $tab = "3" }
            "4" { $tab = "4" }
            "Q" { break }
        }
    }
}

function Start-CyemerScan {
    param([switch]$Debug)
    $script:DebugMode = $Debug
    Show-Banner
    if (-not (Test-Administrator)) {
        Write-Host "  ERROR: Administrator privileges required." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Start PowerShell as Administrator." -ForegroundColor Yellow
        return
    }
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "[*] Windows Version: $($osVersion.Major).$($osVersion.Minor) Build $($osVersion.Build)" -ForegroundColor Cyan
    Write-Host ""
    $prefetchPath = "C:\Windows\Prefetch"
    if (-not (Test-Path $prefetchPath)) {
        Write-Host "[!] Prefetch directory not found." -ForegroundColor Red
        return
    }
    $javaFiles = Get-ChildItem -Path $prefetchPath -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue
    if ($javaFiles.Count -eq 0) {
        Write-Host "[!] No JAVA prefetch files found." -ForegroundColor Yellow
        return
    }
    Write-Host "[+] Found $($javaFiles.Count) JAVA prefetch file(s)" -ForegroundColor Green
    Write-Host ""
    $allPaths = @()
    $fileMetadata = @{}
    $processedFiles = 0
    $successfulParsing = 0
    foreach ($pf in $javaFiles) {
        $processedFiles++
        Write-Progress -Activity "Extracting Indexes" -Status "Processing $processedFiles / $($javaFiles.Count)" -PercentComplete (($processedFiles / $javaFiles.Count) * 100)
        $indexes = Get-SystemIndexes -FilePath $pf.FullName
        if ($indexes.Count -eq 0) { continue }
        $successfulParsing++
        $indexNum = 0
        foreach ($index in $indexes) {
            $indexNum++
            if ($index -match '\\VOLUME\{[^\}]+\}\\(.*)$') {
                $resolved = "C:\$($Matches[1])"
                $allPaths += $resolved
                if (-not $fileMetadata.ContainsKey($resolved)) {
                    $fileMetadata[$resolved] = @{
                        SourceFile  = $pf.Name
                        IndexNumber = $indexNum
                        OriginalPath = $index
                    }
                }
            } else {
                $allPaths += $index
                if (-not $fileMetadata.ContainsKey($index)) {
                    $fileMetadata[$index] = @{
                        SourceFile  = $pf.Name
                        IndexNumber = $indexNum
                        OriginalPath = $index
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Extracting Indexes" -Completed
    $uniquePaths = $allPaths | Select-Object -Unique
    Write-Host "[+] Parsed prefetch files: $successfulParsing / $processedFiles" -ForegroundColor Green
    Write-Host "[+] Total extracted paths: $($allPaths.Count)" -ForegroundColor Green
    Write-Host "[+] Unique paths: $($uniquePaths.Count)" -ForegroundColor Green
    Write-Host ""
    $existingPaths = @{}
    $missingPaths = @()
    $outsideRangeCount = 0
    $resolvedToDifferentDrive = 0
    $allDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object { $_.Root.Substring(0,1) }
    foreach ($path in $uniquePaths) {
        $foundPath = $null
        if (Test-Path $path -PathType Leaf) {
            $foundPath = $path
        } elseif ($path -match '^[A-Z]:\\(.*)$') {
            $relative = $Matches[1]
            foreach ($drive in $allDrives) {
                $candidate = "$drive`:\$relative"
                if (Test-Path $candidate -PathType Leaf) {
                    $foundPath = $candidate
                    $resolvedToDifferentDrive++
                    break
                }
            }
        }
        if ($foundPath) {
            try {
                $size = (Get-Item $foundPath).Length
                if ($size -ge 50KB -and $size -le 50MB) {
                    $existingPaths[$path] = $foundPath
                } else {
                    $outsideRangeCount++
                }
            } catch {
                $missingPaths += $path
            }
        } else {
            $missingPaths += $path
        }
    }
    Write-Host "[+] Existing files in scan range: $($existingPaths.Count)" -ForegroundColor Green
    if ($resolvedToDifferentDrive -gt 0) {
        Write-Host "[+] Resolved on different drives: $resolvedToDifferentDrive" -ForegroundColor Cyan
    }
    Write-Host "[!] Files outside range: $outsideRangeCount" -ForegroundColor Gray
    Write-Host "[!] Missing paths: $($missingPaths.Count)" -ForegroundColor Yellow
    Write-Host ""
    $deletedFilesForUi = @()
    $selfDestructFindings = @()
    if ($missingPaths.Count -gt 0) {
        $ntfsDrives = Get-NTFSDrives
        if ($ntfsDrives.Count -gt 0) {
            Get-RecentDeletionsFromUSN -DriveLetters $ntfsDrives -MinutesBack 90 | Out-Null
        }
        foreach ($missingPath in $missingPaths) {
            if ($missingPath -match '\\TEMP\\|\\TMP\\|HSPERFDATA|\.TMP$|JNA\d+\.DLL') { continue }
            if ($missingPath -notmatch '\.(JAR|EXE|DLL|BIN|DAT)$') { continue }
            $recentDeletion = Test-RecentlyDeleted -FilePath $missingPath
            $deletionTime = $null
            $reason = $null
            if ($recentDeletion) {
                $deletionTime = $recentDeletion.Timestamp
                $reason = $recentDeletion.Reason
            }
            $sourcePf = ""
            if ($fileMetadata.ContainsKey($missingPath)) {
                $sourcePf = $fileMetadata[$missingPath].SourceFile
            }
            $sd = Test-SelfDestructSuspicion -Path $missingPath -SourceFile $sourcePf -RecentDeletion $recentDeletion
            $deletedFilesForUi += [PSCustomObject]@{
                Path                = $missingPath
                SourceFile          = $sourcePf
                DeletionTime        = if ($deletionTime) { $deletionTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                Reason              = $reason
                Suspicious          = $sd.IsSuspicious
                SuspicionConfidence = $sd.Confidence
                SuspicionScore      = $sd.Score
                SuspicionReasons    = ($sd.Reasons -join " | ")
            }
            if ($sd.IsSuspicious) {
                $selfDestructFindings += [PSCustomObject]@{
                    Path         = $missingPath
                    SourceFile   = $sourcePf
                    Confidence   = $sd.Confidence
                    Score        = $sd.Score
                    DeletionTime = if ($deletionTime) { $deletionTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                    Reason       = $reason
                    Reasons      = $sd.Reasons
                }
            }
        }
    }
    Write-Host "[*] Scanning existing files for Cyemer..." -ForegroundColor Cyan
    Write-Host ""
    $detections = @()
    $scanned = 0
    $skipped = 0
    foreach ($assumedPath in $existingPaths.Keys) {
        $actualPath = $existingPaths[$assumedPath]
        $scanned++
        Write-Progress -Activity "Scanning for Cyemer" -Status "[$scanned/$($existingPaths.Count)]" -PercentComplete (($scanned / $existingPaths.Count) * 100)
        $result = Test-CyemerClient -Path $actualPath
        if ($result.Error) {
            $skipped++
            continue
        }
        if ($result.IsDetected) {
            $detections += [PSCustomObject]@{
                Path                = $actualPath
                SourceFile          = $fileMetadata[$assumedPath].SourceFile
                IndexNumber         = $fileMetadata[$assumedPath].IndexNumber
                Confidence          = $result.Confidence
                IsRenamedJar        = $result.IsRenamedJar
                MatchCount          = $result.MatchCount
                StrongMatchCount    = $result.StrongMatchCount
                Matches             = $result.Matches
            }
            Write-Host "[!] DETECTION: $actualPath" -ForegroundColor Red
            Write-Host "    Confidence: $($result.Confidence)" -ForegroundColor Yellow
            Write-Host "    Matches: $($result.MatchCount) | Strong: $($result.StrongMatchCount)" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
    Write-Progress -Activity "Scanning for Cyemer" -Completed
    $stats = @{
        WindowsVersion    = "$($osVersion.Major).$($osVersion.Minor) Build $($osVersion.Build)"
        JavaPrefetchCount = $javaFiles.Count
        SuccessfulParsing = $successfulParsing
        ProcessedFiles    = $processedFiles
        TotalIndexes      = $allPaths.Count
        UniquePaths       = $uniquePaths.Count
        ExistingFiles     = $existingPaths.Count
        FilesScanned      = $scanned
        FilesSkipped      = $skipped
        MissingFiles      = $missingPaths.Count
    }
    Show-Dashboard -Stats $stats -Detections $detections -DeletedFiles $deletedFilesForUi -SelfDestructFindings $selfDestructFindings
}

Start-CyemerScan
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

$script:DebugMode        = $false
$script:RecentDeletions  = @{}
$script:USNSearched      = $false
$script:ScanVersion      = "3.0"

$script:VelarisNeedles = @(
    "velaris","Velaris","VELARIS","com/velaris","com.velaris","VelarisClient",
    "velaris-client","velaris_client","VelarisMod","velarismod",
    ".velaris-cache",".velaris_cache","velaris-cache","config/velaris",
    "velaris/config","velaris-config","velaris_config","velaris.json",
    "velaris.cfg","velaris.toml","velaris.yml","velaris.properties",
    "velaris.mixins.json","velaris-mixins.json","fabric.mod.json",
    "META-INF/mods.toml","META-INF/MANIFEST.MF","AutoClicker","AutoClick",
    "Clicker","Reach","Velocity","Timer","Scaffold","KillAura","KillAuraModule",
    "AntiKB","AntiKnockback","AntiKnockBack","Criticals","WTap","STap",
    "BlockHit","AutoRod","AutoSoup","AutoPot","FastBow","AimAssist","AimBot",
    "TriggerBot","AutoArmor","ChestStealer","InventoryManager","NoSlow",
    "NoSlowDown","Sprint","AutoSprint","Speed","SpeedModule","Fly","Flight",
    "LongJump","HighJump","Step","NoFall","Jesus","Spider","Phase","Clip",
    "Teleport","Blink","Freecam","XRay","Xray","FullBright","Fullbright",
    "ESP","EntityESP","PlayerESP","MobESP","ChestESP","ItemESP","StorageESP",
    "Tracers","Nametags","NameTags","Chams","Wallhack","NoRender","Waypoints",
    "Hud","HUD","ArrayList","TabGUI","ClickGUI","ClickGui","GuiModule",
    "velaris_chams","velaris_esp","velaris_outline","velaris_glow",
    "velaris_shader","velaris_render","velaris-auth","velaris-api",
    "velaris-license","velaris-hwid","velaris-login","velaris-token",
    "velaris-session","VelarisModule","VelarisCommand","VelarisEvent",
    "VelarisListener","VelarisManager","VelarisConfig","VelarisGui",
    "VelarisRender","VelarisCombat","VelarisMovement","VelarisPlayer",
    "VelarisWorld","VelarisMisc","VelarisUtil","VelarisUtils",
    "velaris/module","velaris/command","velaris/event","velaris/listener",
    "velaris/manager","velaris/config","velaris/gui","velaris/render",
    "velaris/combat","velaris/movement","velaris/player","velaris/world",
    "velaris/misc","velaris/util","velaris/mixin","velaris/mixins",
    "MixinVelaris","VelarisMixin","velaris/api","velaris/network","velaris/packet",
    "velaris/protocol","velaris-version","velaris-updater","velaris-update",
    "DiscordRPC","discord_rpc","velaris/discord"
)

$script:VelarisStrongNeedles = @(
    "velaris","VelarisClient","com/velaris","com.velaris",
    ".velaris-cache",".velaris_cache","config/velaris","velaris/config",
    "velaris.mixins.json","velaris-auth","velaris-license","velaris-hwid",
    "velaris-login","VelarisModule","VelarisCommand","velaris_chams","velaris_esp"
)

$script:AutoMaceNeedles = @(
    "AutoMace","automace","auto_mace","AutoCrystal","autocrystal","auto_crystal",
    "CrystalAura","crystalaura","crystal_aura","AutoTotem","autototem","auto_totem",
    "TotemPop","totempop","SurroundBreaker","surroundbreaker","HoleFill","holefill",
    "AutoPlace","autoplace","CrystalPlace","crystalplace","Anchor","AnchorAura",
    "BedAura","bedaura","bed_aura","Surround","SurroundModule","AutoSurround",
    "BreakSurround","PistonPush","KnockbackModule","CrystalESP","AnchorESP",
    "BedESP","MaceAura","maceaura","mace_aura","AutoBow","autoboww",
    "BowAimbot","AutoCrossbow","autocrossbow","Trident","TridentAura",
    "WindBurst","wind_burst","Breeze","BreezeAura","mace","Mace",
    "net/optifine","OptiFine","optifine","Sodium","sodium","Iris","iris"
)

$script:GenericCheatNeedles = @(
    "meteor","MeteorClient","meteor-client","com/meteorclient",
    "impact","ImpactClient","com/impactclient",
    "wurst","WurstClient","com/wurstclient",
    "aristois","AristoisClient",
    "liquidbounce","LiquidBounce","com/liquidbounce",
    "rusherhack","RusherHack","com/rusherhack",
    "novoline","NovoLine","com/novoline",
    "rise","RiseClient","com/riseclient",
    "pyro","PyroClient","com/pyroclient",
    "sigma","SigmaClient","com/sigmaclient",
    "skillclient","SkillClient","com/skillclient",
    "future","FutureClient","com/future",
    "inertia","InertiaClient","com/inertia",
    "ghostware","GhostWare","ghost_ware",
    "vape","VapeClient","com/vape","vapelite",
    "dragonfly","DragonflyClient",
    "wolfi","WolfiClient",
    "ares","AresClient","com/ares",
    "xodus","XodusClient",
    "cosmo","CosmoClient",
    "datura","DaturaClient",
    "module/Module","ModuleManager","CommandManager",
    "hack/module","hack/command","hack/event",
    "client/module","client/command","client/event",
    "mixin/Mixin","mixins/Mixin","net/minecraft/client/Minecraft",
    "com/google/inject","org/springframework","net/bytebuddy",
    "javassist","asm/ClassWriter","objectweb/asm"
)

$script:VelarisSelfDestructKeywords = @(
    "velaris","client","ghost","inject","loader","launch","minecraft",
    "mc","cheat","hack","clicker","autoclick","bypass","destruct",
    "selfdestruct","self-destruct","crystal","aim","trigger","esp",
    "killaura","reach","velocity","timer","scaffold","fly","speed",
    "xray","chams","wallhack","autoclicker","antikb","antiknockback",
    "fullbright","nametags","tracers","phase","clip","blink",
    "freecam","step","nofall","jesus","spider","longjump","highjump",
    "autosprint","noslow","noslowdown","criticals","wtap","stap",
    "blockhit","autorod","autosoup","autopot","fastbow","aimassist",
    "aimbot","triggerbot","autoarmor","cheststealer","inventorymanager",
    "waypoints","clickgui","arraylist","tabgui","hud","automace",
    "autocrystal","crystalaura","autototem","surround","maceaura",
    "meteor","wurst","liquidbounce","rusherhack","sigma","future",
    "vape","inertia","ghostware","dragonfly"
)

$script:KnownLegitModIds = @(
    "fabric","fabricloader","fabric-api","fabric_loader",
    "forge","neoforge","quilt","quiltloader",
    "sodium","lithium","phosphor","starlight","ferritecore",
    "iris","continuity","indium","reeses-sodium-options",
    "malilib","minihud","tweakeroo","itemscroller","litematica",
    "optifabric","modmenu","cloth-config","architectury",
    "jei","rei","emi","roughly-enough-items",
    "journeymap","xaeros-minimap","voxelmap",
    "create","botania","ae2","thermal","immersive-engineering",
    "tinkers-construct","nature-aura","mystical-agriculture",
    "waystones","ftb-chunks","ftb-teams","ftb-quests",
    "patchouli","baubles","curios","trinkets",
    "appleskin","jade","hwyla","waila",
    "mouse-tweaks","inventory-sorter","sorted",
    "carpet","servux","syncmatica",
    "entityculling","c2me","noisium","exordium",
    "minecraft","java","javax","com/google","org/apache",
    "net/java","com/mojang","org/lwjgl","com/sun",
    "paulscode","io/netty","com/ibm","org/objectweb"
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class NtdllDecompressor {
    [DllImport("ntdll.dll")]
    public static extern uint RtlDecompressBufferEx(ushort CompressionFormat,byte[] UncompressedBuffer,int UncompressedBufferSize,byte[] CompressedBuffer,int CompressedBufferSize,out int FinalUncompressedSize,IntPtr WorkSpace);
    [DllImport("ntdll.dll")]
    public static extern uint RtlGetCompressionWorkSpaceSize(ushort CompressionFormat,out uint CompressBufferWorkSpaceSize,out uint CompressFragmentWorkSpaceSize);
    public static byte[] Decompress(byte[] compressed) {
        if (compressed.Length < 8) return null;
        if (compressed[0]!=0x4D||compressed[1]!=0x41||compressed[2]!=0x4D) return null;
        int uncompSize=BitConverter.ToInt32(compressed,4);
        uint wsComp,wsFrag;
        if (RtlGetCompressionWorkSpaceSize(4,out wsComp,out wsFrag)!=0) return null;
        IntPtr workspace=Marshal.AllocHGlobal((int)wsFrag);
        byte[] result=new byte[uncompSize];
        try {
            int finalSize;
            byte[] compData=new byte[compressed.Length-8];
            Array.Copy(compressed,8,compData,0,compData.Length);
            uint status=RtlDecompressBufferEx(4,result,uncompSize,compData,compData.Length,out finalSize,workspace);
            if (status!=0) return null;
            return result;
        } finally { Marshal.FreeHGlobal(workspace); }
    }
}
"@

function Show-Banner {
    Clear-Host
    $banner = @"
  ██╗   ██╗███████╗██╗      █████╗ ██████╗ ██╗███████╗
  ██║   ██║██╔════╝██║     ██╔══██╗██╔══██╗██║██╔════╝
  ██║   ██║█████╗  ██║     ███████║██████╔╝██║███████╗
  ╚██╗ ██╔╝██╔══╝  ██║     ██╔══██║██╔══██╗██║╚════██║
   ╚████╔╝ ███████╗███████╗██║  ██║██║  ██║██║███████║
    ╚═══╝  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝
"@
    Write-Host $banner -ForegroundColor Magenta
    Write-Host "        VELARIS FORENSIC SCANNER v$($script:ScanVersion) — FULL SYSTEM EDITION" -ForegroundColor White
    Write-Host "   Prefetch + JAR + Modpack + AutoMace + Unknown-Mod Deep Investigation" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "                    Created by: _iaec" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Separator    { Write-Host ("=" * 80) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 80) -ForegroundColor DarkGray }

function Write-Stat {
    param([string]$Label,[string]$Value,[ConsoleColor]$ValueColor=[ConsoleColor]::White)
    Write-Host "  $($Label.PadRight(30)) : " -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $ValueColor
}
function Write-Status  { param([string]$Message,[ConsoleColor]$Color=[ConsoleColor]::White) Write-Host "  [*] $Message" -ForegroundColor $Color }
function Write-Success { param([string]$Message) Write-Host "  [+] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "  [X] $Message" -ForegroundColor Red }
function Write-Detection {
    param([string]$Message,[string]$Confidence="HIGH")
    $color = switch ($Confidence) { "HIGH"{"Red"} "MEDIUM"{"Yellow"} "LOW"{"Gray"} default{"White"} }
    Write-Host "  [!] DETECTION [$Confidence]: $Message" -ForegroundColor $color
}

function Format-FileSize {
    param([long]$Size)
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size/1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size/1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size/1KB) }
    return "$Size B"
}

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ZipMagicBytes {
    param([string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $br = New-Object System.IO.BinaryReader($fs)
        if ($fs.Length -lt 2) { $br.Close(); $fs.Close(); return $false }
        $b1 = $br.ReadByte(); $b2 = $br.ReadByte()
        $br.Close(); $fs.Close()
        return ($b1 -eq 0x50 -and $b2 -eq 0x4B)
    } catch { return $false }
}

function Get-NTFSDrives {
    $out = @()
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' })) {
        try {
            $letter = $drive.Root.Substring(0,1)
            $vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
            if ($vol -and $vol.FileSystem -eq 'NTFS') { $out += $letter }
        } catch {}
    }
    return $out
}

function Search-BytePattern {
    param([byte[]]$Data,[byte[]]$Pattern)
    $pLen = $Pattern.Length; $dLen = $Data.Length
    for ($i = 0; $i -le ($dLen - $pLen); $i++) {
        $match = $true
        for ($j = 0; $j -lt $pLen; $j++) { if ($Data[$i+$j] -ne $Pattern[$j]) { $match=$false; break } }
        if ($match) { return $true }
    }
    return $false
}

function Get-SystemIndexes {
    param([string]$FilePath)
    try {
        $data = [System.IO.File]::ReadAllBytes($FilePath)
        if ($data[0] -eq 0x4D -and $data[1] -eq 0x41 -and $data[2] -eq 0x4D) {
            $data = [NtdllDecompressor]::Decompress($data)
            if ($null -eq $data) { return @() }
        }
        if ($data.Length -lt 108) { return @() }
        if ([System.Text.Encoding]::ASCII.GetString($data,4,4) -ne "SCCA") { return @() }
        $strOff  = [BitConverter]::ToUInt32($data,100)
        $strSize = [BitConverter]::ToUInt32($data,104)
        if ($strOff -eq 0 -or $strSize -eq 0) { return @() }
        if ($strOff -ge $data.Length -or ($strOff+$strSize) -gt $data.Length) { return @() }
        $filenames = @(); $pos = $strOff; $endPos = $strOff + $strSize
        while ($pos -lt $endPos -and $pos -lt ($data.Length-2)) {
            $nullPos = $pos
            while ($nullPos -lt ($data.Length-1)) {
                if ($data[$nullPos] -eq 0 -and $data[$nullPos+1] -eq 0) { break }
                $nullPos += 2
            }
            if ($nullPos -gt $pos) {
                $strLen = $nullPos - $pos
                if ($strLen -gt 0 -and $strLen -lt 4096) {
                    try {
                        $fn = [System.Text.Encoding]::Unicode.GetString($data,$pos,$strLen)
                        if ($fn.Length -gt 0) { $filenames += $fn }
                    } catch {}
                }
            }
            $pos = $nullPos + 2
            if ($filenames.Count -gt 3000) { break }
        }
        return $filenames
    } catch { return @() }
}

function Get-RecentDeletionsFromUSN {
    param([string[]]$DriveLetters,[int]$MinutesBack=120)
    if ($script:USNSearched) { return $script:RecentDeletions }
    $all = @{}; $cutoff = (Get-Date).AddMinutes(-$MinutesBack)
    foreach ($drive in $DriveLetters) {
        try {
            $usnOutput = & fsutil usn readjournal "$drive`:" 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $usnOutput) { continue }
            $cf=""; $ct=$null; $cr=""
            foreach ($line in $usnOutput) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                if      ($line -match 'File name\s+:\s*(.+)$')  { $cf=$Matches[1].Trim() }
                elseif  ($line -match 'Time stamp\s+:\s*(.+)$') { try { $ct=[DateTime]::Parse($Matches[1].Trim()) } catch { $ct=$null } }
                elseif  ($line -match 'Reason\s+:\s*(.+)$')     {
                    $cr=$Matches[1].Trim()
                    if ($cf -and $ct -and $ct -gt $cutoff) {
                        $fk="$drive`:\$cf"
                        if (-not $all.ContainsKey($fk) -or $all[$fk].Timestamp -lt $ct) {
                            $all[$fk]=@{Timestamp=$ct;Reason=$cr;Drive=$drive}
                        }
                    }
                    $cf=""; $ct=$null; $cr=""
                }
            }
        } catch {}
    }
    $script:RecentDeletions=$all; $script:USNSearched=$true; return $all
}

function Test-RecentlyDeleted {
    param([string]$FilePath)
    if ($script:RecentDeletions.ContainsKey($FilePath)) { return $script:RecentDeletions[$FilePath] }
    $fn = [System.IO.Path]::GetFileName($FilePath)
    foreach ($k in $script:RecentDeletions.Keys) { if ($k -like "*\$fn") { return $script:RecentDeletions[$k] } }
    return $null
}

function Read-FabricModJson {
    param([System.IO.Compression.ZipArchive]$Jar)
    $entry = $Jar.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
    if (-not $entry) { return $null }
    try {
        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $json   = $reader.ReadToEnd()
        $reader.Close(); $stream.Close()
        $result = @{ id=""; name=""; description=""; authors=@(); contact=@{}; version="" }
        if ($json -match '"id"\s*:\s*"([^"]+)"')          { $result.id          = $Matches[1] }
        if ($json -match '"name"\s*:\s*"([^"]+)"')         { $result.name        = $Matches[1] }
        if ($json -match '"description"\s*:\s*"([^"]+)"')  { $result.description = $Matches[1] }
        if ($json -match '"version"\s*:\s*"([^"]+)"')      { $result.version     = $Matches[1] }
        if ($json -match '"homepage"\s*:\s*"([^"]+)"')     { $result.contact['homepage'] = $Matches[1] }
        if ($json -match '"sources"\s*:\s*"([^"]+)"')      { $result.contact['sources']  = $Matches[1] }
        return $result
    } catch { return $null }
}

function Read-ForgeModsToml {
    param([System.IO.Compression.ZipArchive]$Jar)
    $entry = $Jar.Entries | Where-Object { $_.FullName -eq "META-INF/mods.toml" } | Select-Object -First 1
    if (-not $entry) { return $null }
    try {
        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $toml   = $reader.ReadToEnd()
        $reader.Close(); $stream.Close()
        $result = @{ modId=""; displayName=""; description=""; logoFile="" }
        if ($toml -match 'modId\s*=\s*"([^"]+)"')      { $result.modId       = $Matches[1] }
        if ($toml -match 'displayName\s*=\s*"([^"]+)"') { $result.displayName = $Matches[1] }
        if ($toml -match '(?i)description\s*=\s*"""([\s\S]*?)"""') { $result.description = $Matches[1].Trim() }
        if ($toml -match 'logoFile\s*=\s*"([^"]+)"')   { $result.logoFile    = $Matches[1] }
        return $result
    } catch { return $null }
}

function Test-UnknownMod {
    param(
        [string]$JarPath,
        [System.IO.Compression.ZipArchive]$Jar,
        $FabricMeta,
        $ForgeMeta
    )
    $result = [PSCustomObject]@{
        IsUnknown      = $false
        Confidence     = "NONE"
        Score          = 0
        Reasons        = @()
        ModId          = ""
        ModName        = ""
        ModVersion     = ""
        HasModJson     = ($null -ne $FabricMeta -or $null -ne $ForgeMeta)
        EntryCount     = $Jar.Entries.Count
        ObfuscatedCode = $false
        SuspiciousImports = @()
    }
    $lowerPath = $JarPath.ToLower()
    $jarName   = [System.IO.Path]::GetFileNameWithoutExtension($JarPath).ToLower()
    if ($FabricMeta) {
        $result.ModId      = $FabricMeta.id
        $result.ModName    = $FabricMeta.name
        $result.ModVersion = $FabricMeta.version
    } elseif ($ForgeMeta) {
        $result.ModId   = $ForgeMeta.modId
        $result.ModName = $ForgeMeta.displayName
    }
    $modIdLower = $result.ModId.ToLower()
    if (-not $result.HasModJson) {
        $result.Score += 3
        $result.Reasons += "No fabric.mod.json / mods.toml found (anonymous JAR)"
    }
    if ($result.ModId -ne "") {
        $isKnown = $false
        foreach ($known in $script:KnownLegitModIds) {
            if ($modIdLower -like "*$known*" -or $known -like "*$modIdLower*") { $isKnown=$true; break }
        }
        if (-not $isKnown) {
            $result.Score += 2
            $result.Reasons += "Mod ID '$($result.ModId)' not in known-legit database"
        }
    }
    if ($FabricMeta) {
        $hasLink = ($FabricMeta.contact['homepage'] -ne "" -or $FabricMeta.contact['sources'] -ne "")
        if (-not $hasLink) { $result.Score += 1; $result.Reasons += "No homepage or sources link in fabric.mod.json" }
    }
    $classNames  = @()
    $allTextData = New-Object 'System.Collections.Generic.List[byte]'
    foreach ($entry in $Jar.Entries) {
        if ($entry.FullName -like "*.class") { $classNames += $entry.FullName }
        if ($entry.FullName -like "*.class" -or $entry.FullName -like "*.json" -or
            $entry.FullName -like "META-INF/MANIFEST.MF" -or $entry.FullName -like "*.toml") {
            try {
                $s = $entry.Open()
                $r = New-Object System.IO.BinaryReader($s)
                $b = $r.ReadBytes([int][Math]::Min($entry.Length, 65536))
                [void]$allTextData.AddRange($b)
                $r.Close(); $s.Close()
            } catch {}
        }
    }
    $shortNames = @($classNames | Where-Object {
        $parts = $_.Split('/')
        $simple = [System.IO.Path]::GetFileNameWithoutExtension($parts[-1])
        $simple.Length -le 2 -and $simple -match '^[a-zA-Z]+$'
    })
    if ($classNames.Count -gt 0) {
        $ratio = $shortNames.Count / $classNames.Count
        if ($ratio -gt 0.4 -and $classNames.Count -gt 20) {
            $result.ObfuscatedCode = $true
            $result.Score += 4
            $result.Reasons += "High obfuscation ratio: $([math]::Round($ratio*100))% short class names ($($shortNames.Count)/$($classNames.Count))"
        }
    }
    $suspImports = @()
    $allBytes = $allTextData.ToArray()
    $suspPatterns = @(
        @("hwid","HWID / hardware fingerprint"),
        @("license","License check code"),
        @("crack","Anti-crack / crack bypass"),
        @("bypass","Bypass / evasion logic"),
        @("inject","Code injection pattern"),
        @("obfuscate","Obfuscation reference"),
        @("webhook","Discord webhook (data exfil?)"),
        @("discord.com/api","Discord API call"),
        @("pastebin","Pastebin URL"),
        @("Runtime.exec","Shell execution via Runtime"),
        @("ProcessBuilder","ProcessBuilder (shell exec)"),
        @("URLClassLoader","Dynamic classloading"),
        @("Instrumentation","Java agent instrumentation"),
        @("AgentMain","Java agent main method"),
        @("premain","Java agent premain"),
        @("ClassFileTransformer","Bytecode transformer"),
        @("Unsafe","sun.misc.Unsafe usage"),
        @("sun/misc/Unsafe","sun.misc.Unsafe field access")
    )
    foreach ($sp in $suspPatterns) {
        $pat = [System.Text.Encoding]::ASCII.GetBytes($sp[0])
        if (Search-BytePattern -Data $allBytes -Pattern $pat) {
            $suspImports += $sp[1]
        }
    }
    if ($suspImports.Count -gt 0) {
        $result.Score += [Math]::Min(5, $suspImports.Count)
        $result.SuspiciousImports = $suspImports
        $result.Reasons += "Suspicious bytecode patterns: $($suspImports.Count) hits"
    }
    $cheatHits = 0
    foreach ($needle in $script:GenericCheatNeedles) {
        $pat = [System.Text.Encoding]::ASCII.GetBytes($needle)
        if (Search-BytePattern -Data $allBytes -Pattern $pat) { $cheatHits++ }
    }
    if ($cheatHits -ge 3) {
        $result.Score += [Math]::Min(6, $cheatHits)
        $result.Reasons += "Generic cheat client signatures: $cheatHits matches"
    }
    $autoMaceHits = 0
    foreach ($needle in $script:AutoMaceNeedles) {
        $pat = [System.Text.Encoding]::ASCII.GetBytes($needle)
        if (Search-BytePattern -Data $allBytes -Pattern $pat) { $autoMaceHits++ }
    }
    if ($autoMaceHits -ge 2) {
        $result.Score += [Math]::Min(5, $autoMaceHits)
        $result.Reasons += "AutoMace / crystal-PvP hack signatures: $autoMaceHits matches"
    }
    $jarSize = (Get-Item $JarPath -ErrorAction SilentlyContinue).Length
    if ($jarSize -lt 20KB -and $classNames.Count -gt 0 -and $result.ObfuscatedCode) {
        $result.Score += 2
        $result.Reasons += "Tiny obfuscated JAR ($(Format-FileSize $jarSize)) — common loader pattern"
    }
    if ($result.Score -ge 10)     { $result.IsUnknown=$true; $result.Confidence="HIGH" }
    elseif ($result.Score -ge 6)  { $result.IsUnknown=$true; $result.Confidence="MEDIUM" }
    elseif ($result.Score -ge 3)  { $result.IsUnknown=$true; $result.Confidence="LOW" }
    return $result
}

function Test-JarFull {
    param([string]$Path)
    $result = [PSCustomObject]@{
        Path             = $Path
        FileSize         = 0
        IsVelaris        = $false
        VelarisConfidence= "NONE"
        VelarisMatches   = @()
        VelarisStrong    = 0
        VelarisFiles     = @()
        ConfigPaths      = @()
        IsAutoMace       = $false
        AutoMaceMatches  = @()
        AutoMaceCount    = 0
        IsGenericCheat   = $false
        GenericMatches   = @()
        GenericCount     = 0
        UnknownMod       = $null
        IsRenamedJar     = $false
        Error            = $null
        ScanTimeMs       = 0
        FabricMeta       = $null
        ForgeMeta        = $null
    }
    if (-not (Test-Path $Path -PathType Leaf)) { $result.Error="File not found"; return $result }
    $result.FileSize = (Get-Item $Path).Length
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $ext   = [System.IO.Path]::GetExtension($Path).ToLower()
        $hasPK = Test-ZipMagicBytes -Path $Path
        if ($hasPK -and $ext -ne ".jar") { $result.IsRenamedJar=$true }
        if (-not $hasPK) { $result.Error="Not a valid ZIP/JAR"; return $result }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $jar = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $result.FabricMeta = Read-FabricModJson  -Jar $jar
        $result.ForgeMeta  = Read-ForgeModsToml  -Jar $jar
        $allBytesList = New-Object 'System.Collections.Generic.List[byte]'
        foreach ($entry in $jar.Entries) {
            $en = $entry.FullName.ToLower()
            if ($en -match "velaris")                    { $result.VelarisFiles += $entry.FullName }
            if ($en -match "config/velaris|\.velaris-cache|\.velaris_cache|velaris\.json|velaris\.cfg|velaris\.toml|velaris\.yml|velaris\.properties") {
                $result.ConfigPaths += $entry.FullName
            }
            [void]$allBytesList.AddRange([System.Text.Encoding]::ASCII.GetBytes($entry.FullName))
            if ($entry.FullName -like "*.class" -or $entry.FullName -like "*.json" -or
                $entry.FullName -like "*.png"   -or $entry.FullName -like "*.fsh"  -or
                $entry.FullName -like "*.vsh"   -or $entry.FullName -like "*.glsl" -or
                $entry.FullName -like "META-INF/MANIFEST.MF" -or
                $entry.FullName -like "fabric.mod.json" -or
                $entry.FullName -like "*.cfg"   -or $entry.FullName -like "*.toml") {
                try {
                    $s=$entry.Open(); $r=New-Object System.IO.BinaryReader($s)
                    $b=$r.ReadBytes([int]$entry.Length)
                    [void]$allBytesList.AddRange($b)
                    $r.Close(); $s.Close()
                } catch {}
            }
        }
        $allBytes = $allBytesList.ToArray()
        foreach ($n in $script:VelarisNeedles) {
            $pat=[System.Text.Encoding]::ASCII.GetBytes($n)
            if (Search-BytePattern -Data $allBytes -Pattern $pat) { $result.VelarisMatches += $n }
        }
        foreach ($n in $script:VelarisStrongNeedles) {
            $pat=[System.Text.Encoding]::ASCII.GetBytes($n)
            if (Search-BytePattern -Data $allBytes -Pattern $pat) { $result.VelarisStrong++ }
        }
        $mc = $result.VelarisMatches.Count
        if     ($result.VelarisStrong -ge 3)                            { $result.IsVelaris=$true; $result.VelarisConfidence="HIGH" }
        elseif ($result.VelarisStrong -ge 2 -and $mc -ge 6)             { $result.IsVelaris=$true; $result.VelarisConfidence="HIGH" }
        elseif ($mc -ge 12)                                              { $result.IsVelaris=$true; $result.VelarisConfidence="HIGH" }
        elseif ($mc -ge 8)                                               { $result.IsVelaris=$true; $result.VelarisConfidence="MEDIUM" }
        elseif ($mc -ge 4)                                               { $result.IsVelaris=$true; $result.VelarisConfidence="LOW" }
        if ($result.VelarisFiles.Count -gt 0 -and $result.VelarisConfidence -eq "LOW")  { $result.VelarisConfidence="MEDIUM" }
        if ($result.VelarisFiles.Count -ge 5 -and $result.VelarisConfidence -ne "HIGH") { $result.VelarisConfidence="HIGH" }
        if ($result.ConfigPaths.Count -gt 0  -and $result.VelarisConfidence -eq "LOW")  { $result.VelarisConfidence="MEDIUM" }
        if ($result.IsRenamedJar -and $result.IsVelaris -and $result.VelarisConfidence -eq "LOW") { $result.VelarisConfidence="MEDIUM" }
        foreach ($n in $script:AutoMaceNeedles) {
            $pat=[System.Text.Encoding]::ASCII.GetBytes($n)
            if (Search-BytePattern -Data $allBytes -Pattern $pat) { $result.AutoMaceMatches += $n }
        }
        $result.AutoMaceCount = $result.AutoMaceMatches.Count
        if ($result.AutoMaceCount -ge 2) { $result.IsAutoMace=$true }
        foreach ($n in $script:GenericCheatNeedles) {
            $pat=[System.Text.Encoding]::ASCII.GetBytes($n)
            if (Search-BytePattern -Data $allBytes -Pattern $pat) { $result.GenericMatches += $n }
        }
        $result.GenericCount = $result.GenericMatches.Count
        if ($result.GenericCount -ge 3) { $result.IsGenericCheat=$true }
        $result.UnknownMod = Test-UnknownMod -JarPath $Path -Jar $jar -FabricMeta $result.FabricMeta -ForgeMeta $result.ForgeMeta
        $jar.Dispose()
    } catch { $result.Error = $_.Exception.Message }
    $sw.Stop()
    $result.ScanTimeMs = $sw.ElapsedMilliseconds
    return $result
}

function Get-AllJarsOnSystem {
    param([long]$MinBytes=10KB,[long]$MaxBytes=200MB)
    $found = [System.Collections.Generic.List[string]]::new()
    $priorityPaths = @(
        "$env:APPDATA\.minecraft",
        "$env:APPDATA\ModrinthApp",
        "$env:APPDATA\PrismLauncher",
        "$env:APPDATA\MultiMC",
        "$env:APPDATA\ATLauncher",
        "$env:APPDATA\CurseForge",
        "$env:APPDATA\GDLauncher",
        "$env:LOCALAPPDATA\Packages",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents",
        "$env:TEMP",
        [System.IO.Path]::GetTempPath()
    )
    Write-Status "Phase 1/2: Scanning priority Minecraft/launcher paths..." Cyan
    foreach ($p in $priorityPaths) {
        if (-not (Test-Path $p)) { continue }
        try {
            Get-ChildItem -Path $p -Recurse -Include "*.jar","*.zip","*.bin","*.dat" -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge $MinBytes -and $_.Length -le $MaxBytes } |
            ForEach-Object { $found.Add($_.FullName) }
        } catch {}
    }
    Write-Status "Phase 2/2: Scanning all drives for remaining JAR files..." Cyan
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
    foreach ($drive in $drives) {
        $skipPaths = @($priorityPaths | Where-Object { $_ -match "^$([regex]::Escape($drive.Root))" })
        try {
            Get-ChildItem -Path $drive.Root -Recurse -Include "*.jar" -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Length -ge $MinBytes -and $_.Length -le $MaxBytes -and
                $_.FullName -notmatch '\\Windows\\|\\System32\\|\\SysWOW64\\|\\WinSxS\\' -and
                ($skipPaths.Count -eq 0 -or -not ($skipPaths | Where-Object { $_.FullName -like "$_*" }))
            } |
            ForEach-Object {
                if (-not $found.Contains($_.FullName)) { $found.Add($_.FullName) }
            }
        } catch {}
    }
    $unique = $found | Select-Object -Unique
    Write-Success "Total JAR/archive files found: $($unique.Count)"
    return $unique
}

function Test-SelfDestructSuspicion {
    param([string]$Path,[string]$SourceFile="",$RecentDeletion=$null)
    $result = [PSCustomObject]@{
        IsSuspicious=$false; Confidence="NONE"; Score=0; Reasons=@()
        FileName=[System.IO.Path]::GetFileName($Path)
        Extension=[System.IO.Path]::GetExtension($Path).ToLower()
        Path=$Path
    }
    $lowerName = $result.FileName.ToLower(); $lowerPath = $Path.ToLower()
    if ($result.Extension -in @(".jar",".exe",".dll",".bin",".dat")) { $result.Score+=2; $result.Reasons+="Executable/container extension" }
    if ($result.Extension -ne ".jar" -and (Test-ZipMagicBytes -Path $Path))   { $result.Score+=4; $result.Reasons+="Renamed JAR payload (possible obfuscation)" }
    $kwHits = @($script:VelarisSelfDestructKeywords | Where-Object { $lowerName -like "*$_*" })
    if ($kwHits.Count -gt 0) { $result.Score+=[Math]::Min(4,$kwHits.Count+1); $result.Reasons+="Suspicious filename keywords: $($kwHits -join ', ')" }
    if ($lowerPath -match '\\downloads\\|\\desktop\\|\\documents\\|\\appdata\\roaming\\|\\appdata\\local\\|\\temp\\|\\tmp\\|\\minecraft\\|\\mods\\|\\versions\\|\\libraries\\') { $result.Score+=2; $result.Reasons+="Stored in user/mod/temp-related path" }
    if ($SourceFile -match '^JAVA.*\.pf$')                                     { $result.Score+=2; $result.Reasons+="Referenced by Java prefetch (was executed)" }
    if ($RecentDeletion)                                                        {
        $result.Score+=3; $result.Reasons+="Recently removed/modified (USN Journal)"
        if ($RecentDeletion.Reason -match 'FILE_DELETE|CLOSE|RENAME|DATA_TRUNCATION') { $result.Score+=2; $result.Reasons+="USN reason: delete/rename/truncation" }
    }
    if ($lowerPath -match '\\minecraft\\|\\mods\\|\\versions\\|\\libraries\\') { $result.Score+=3; $result.Reasons+="Missing Java artifact from Minecraft path" }
    if ($lowerName -match '^(velaris|loader|client|ghost|inject|launch|mod|hack|cheat)[a-z0-9_-]*\.(jar|exe|dll|bin|dat)$') { $result.Score+=2; $result.Reasons+="Payload-style filename pattern" }
    if     ($result.Score -ge 10) { $result.IsSuspicious=$true; $result.Confidence="HIGH" }
    elseif ($result.Score -ge 7)  { $result.IsSuspicious=$true; $result.Confidence="MEDIUM" }
    elseif ($result.Score -ge 4)  { $result.IsSuspicious=$true; $result.Confidence="LOW" }
    return $result
}

function Get-ModpackPath {
    Write-Host ""
    Write-Status "Enter your Modpack profile path (press Enter to skip)" Cyan
    Write-Host "      Example: C:\Users\YourName\AppData\Roaming\ModrinthApp\profiles\MyModpack" -ForegroundColor DarkGray
    Write-Host "  Path: " -NoNewline -ForegroundColor White
    $path = Read-Host
    if ([string]::IsNullOrWhiteSpace($path)) { Write-Warning "No path entered. Skipping modpack scan."; return $null }
    if (-not (Test-Path $path)) { Write-Warning "Path does not exist: $path"; return $null }
    return $path
}

function Scan-ModpackFolder {
    param([string]$ModpackPath)
    $findings = @()
    if ([string]::IsNullOrWhiteSpace($ModpackPath) -or -not (Test-Path $ModpackPath)) { return $findings }
    Write-Status "Scanning modpack folder: $ModpackPath" Cyan
    foreach ($cn in @(".velaris-cache",".velaris_cache")) {
        $cp = Join-Path $ModpackPath $cn
        if (Test-Path $cp) {
            $findings += [PSCustomObject]@{Type="FOLDER";Path=$cp;Confidence="HIGH";Description="Velaris cache folder";Details="Cache: $cn";Category="VELARIS"}
            Write-Detection "$cn folder found!" "HIGH"
        }
    }
    $vc = Join-Path $ModpackPath "config\velaris"
    if (Test-Path $vc) {
        $findings += [PSCustomObject]@{Type="FOLDER";Path=$vc;Confidence="HIGH";Description="Velaris config folder";Details="config/velaris";Category="VELARIS"}
        Write-Detection "config/velaris folder found!" "HIGH"
    }
    foreach ($cf in @("config\velaris.json","config\velaris.cfg","config\velaris.toml","config\velaris.yml","velaris.json","velaris.cfg","velaris.toml")) {
        $cfp = Join-Path $ModpackPath $cf
        if (Test-Path $cfp) {
            $findings += [PSCustomObject]@{Type="FILE";Path=$cfp;Confidence="HIGH";Description="Velaris config file";Details="File: $cf";Category="VELARIS"}
            Write-Detection "Config file: $cf" "HIGH"
        }
    }
    $modsFolder = Join-Path $ModpackPath "mods"
    if (Test-Path $modsFolder) {
        $jarFiles = Get-ChildItem -Path $modsFolder -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
        Write-Status "Scanning $($jarFiles.Count) mod JAR(s) in modpack..." Cyan
        $idx=0
        foreach ($jar in $jarFiles) {
            $idx++
            Write-Progress -Activity "Scanning Modpack Mods" -Status "[$idx/$($jarFiles.Count)] $($jar.Name)" -PercentComplete (($idx/$jarFiles.Count)*100)
            if ($jar.Name.ToLower() -match "velaris") {
                $findings += [PSCustomObject]@{Type="JAR_FILENAME";Path=$jar.FullName;Confidence="HIGH";Description="Velaris-named JAR";Details="Filename: $($jar.Name)";Category="VELARIS"}
                Write-Detection "Velaris filename: $($jar.Name)" "HIGH"; continue
            }
            $r = Test-JarFull -Path $jar.FullName
            if ($r.IsVelaris) {
                $findings += [PSCustomObject]@{Type="JAR_VELARIS";Path=$jar.FullName;Confidence=$r.VelarisConfidence;Description="Velaris inside mod JAR"
                    Details="Matches:$($r.VelarisMatches.Count) Strong:$($r.VelarisStrong)";MatchCount=$r.VelarisMatches.Count
                    StrongMatchCount=$r.VelarisStrong;VelarisFiles=$r.VelarisFiles;ConfigPaths=$r.ConfigPaths
                    IsRenamedJar=$r.IsRenamedJar;FileSize=$r.FileSize;ScanTimeMs=$r.ScanTimeMs;Category="VELARIS"}
                Write-Detection "$($jar.Name) [VELARIS]" $r.VelarisConfidence
            }
            if ($r.IsAutoMace) {
                $findings += [PSCustomObject]@{Type="JAR_AUTOMACE";Path=$jar.FullName;Confidence="HIGH";Description="AutoMace/Crystal hack detected"
                    Details="Matches: $($r.AutoMaceCount)";MatchCount=$r.AutoMaceCount;AutoMaceMatches=$r.AutoMaceMatches
                    FileSize=$r.FileSize;Category="AUTOMACE"}
                Write-Detection "$($jar.Name) [AUTOMACE/CRYSTAL]" "HIGH"
            }
            if ($r.IsGenericCheat) {
                $findings += [PSCustomObject]@{Type="JAR_GENERIC";Path=$jar.FullName;Confidence="MEDIUM";Description="Generic cheat client signatures"
                    Details="Matches: $($r.GenericCount)";MatchCount=$r.GenericCount;GenericMatches=$r.GenericMatches
                    FileSize=$r.FileSize;Category="GENERIC_CHEAT"}
                Write-Detection "$($jar.Name) [GENERIC CHEAT]" "MEDIUM"
            }
            if ($r.UnknownMod -and $r.UnknownMod.IsUnknown) {
                $findings += [PSCustomObject]@{Type="UNKNOWN_MOD";Path=$jar.FullName;Confidence=$r.UnknownMod.Confidence
                    Description="Unknown / suspicious mod";Details="Score:$($r.UnknownMod.Score) | $($r.UnknownMod.Reasons -join '; ')"
                    ModId=$r.UnknownMod.ModId;ModName=$r.UnknownMod.ModName;Reasons=$r.UnknownMod.Reasons
                    SuspiciousImports=$r.UnknownMod.SuspiciousImports;ObfuscatedCode=$r.UnknownMod.ObfuscatedCode
                    FileSize=$r.FileSize;Category="UNKNOWN_MOD"}
                Write-Detection "$($jar.Name) [UNKNOWN MOD]" $r.UnknownMod.Confidence
            }
        }
        Write-Progress -Activity "Scanning Modpack Mods" -Completed
    }
    $logFolder = Join-Path $ModpackPath "logs"
    if (Test-Path $logFolder) {
        foreach ($log in (Get-ChildItem -Path $logFolder -Filter "*.log" -ErrorAction SilentlyContinue | Select-Object -First 5)) {
            try {
                $content = Get-Content $log.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match "velaris|Velaris|VELARIS|automace|AutoMace") {
                    $findings += [PSCustomObject]@{Type="LOG_REFERENCE";Path=$log.FullName;Confidence="MEDIUM";Description="Cheat mentioned in log";Details="Log: $($log.Name)";Category="LOG"}
                    Write-Detection "Log reference: $($log.Name)" "MEDIUM"
                }
            } catch {}
        }
    }
    Write-Success "Modpack scan complete — $($findings.Count) finding(s)."
    return $findings
}

function Show-AllDetections {
    param([array]$AllDetections)
    Show-Banner
    Write-Host "  ALL DETECTIONS — FULL SYSTEM SCAN" -ForegroundColor Cyan; Write-Separator
    if ($AllDetections.Count -eq 0) { Write-Success "No detections found on this system."; return }
    $byCategory = $AllDetections | Group-Object Category
    foreach ($grp in $byCategory) {
        $catColor = switch ($grp.Name) {
            "VELARIS"      {"Red"}
            "AUTOMACE"     {"Red"}
            "GENERIC_CHEAT"{"Yellow"}
            "UNKNOWN_MOD"  {"Yellow"}
            "PREFETCH"     {"Magenta"}
            "SELF_DESTRUCT"{"DarkYellow"}
            default        {"White"}
        }
        Write-Host ""; Write-Host "  ═══ $($grp.Name) ($($grp.Count) finding(s)) ═══" -ForegroundColor $catColor
        $i=1
        foreach ($d in $grp.Group) {
            Write-Host ""; Write-Host "  [$i] $($d.Path)" -ForegroundColor White
            Write-Stat "Confidence"  $d.Confidence $(switch($d.Confidence){"HIGH"{"Red"}"MEDIUM"{"Yellow"}"LOW"{"Gray"}default{"White"}})
            Write-Stat "Description" $d.Description White
            if ($d.Details)     { Write-Stat "Details" $d.Details DarkGray }
            if ($d.ModId -and $d.ModId -ne "") {
                Write-Stat "Mod ID"   $d.ModId White
                Write-Stat "Mod Name" $d.ModName White
            }
            if ($d.ObfuscatedCode) { Write-Stat "Obfuscated" "YES — high obfuscation ratio" Red }
            if ($d.SuspiciousImports -and $d.SuspiciousImports.Count -gt 0) {
                Write-Host "  Suspicious patterns:" -ForegroundColor Yellow
                foreach ($si in $d.SuspiciousImports) { Write-Host "    - $si" -ForegroundColor DarkGray }
            }
            if ($d.Reasons -and $d.Reasons.Count -gt 0) {
                Write-Host "  Indicators:" -ForegroundColor White
                foreach ($r in $d.Reasons) { Write-Host "    - $r" -ForegroundColor DarkGray }
            }
            if ($d.AutoMaceMatches -and $d.AutoMaceMatches.Count -gt 0) {
                Write-Host "  AutoMace/Combat signatures:" -ForegroundColor Red
                foreach ($m in ($d.AutoMaceMatches | Select-Object -First 15)) { Write-Host "    - $m" -ForegroundColor DarkGray }
            }
            if ($d.FileSize) { Write-Stat "File Size" (Format-FileSize $d.FileSize) White }
            Write-Host ""; Write-SubSeparator; $i++
        }
    }
}

function Show-Summary {
    param([hashtable]$Stats,[array]$AllDetections)
    Show-Banner
    Write-Host "  SCAN SUMMARY" -ForegroundColor Cyan; Write-Separator
    $velCount  = @($AllDetections | Where-Object { $_.Category -eq "VELARIS" }).Count
    $amCount   = @($AllDetections | Where-Object { $_.Category -eq "AUTOMACE" }).Count
    $gcCount   = @($AllDetections | Where-Object { $_.Category -eq "GENERIC_CHEAT" }).Count
    $umCount   = @($AllDetections | Where-Object { $_.Category -eq "UNKNOWN_MOD" }).Count
    $sdCount   = @($AllDetections | Where-Object { $_.Category -eq "SELF_DESTRUCT" }).Count
    $highCount = @($AllDetections | Where-Object { $_.Confidence -eq "HIGH" }).Count
    if ($AllDetections.Count -gt 0) { Write-Stat "Overall Status" "⚠ DETECTIONS FOUND" Red }
    else                            { Write-Stat "Overall Status" "✔ CLEAN — No cheats detected" Green }
    Write-Host ""
    Write-SubSeparator; Write-Host "  SYSTEM" -ForegroundColor White; Write-SubSeparator
    Write-Stat "Windows Build"    $Stats.WindowsVersion White
    Write-Stat "Scan Duration"    "$($Stats.ScanDuration)s" White
    Write-Stat "Total JARs Found" $Stats.TotalJarsFound White
    Write-Stat "Total JARs Scanned" $Stats.JarsScanned White
    Write-Host ""
    Write-SubSeparator; Write-Host "  PREFETCH" -ForegroundColor White; Write-SubSeparator
    Write-Stat "Java PF Files"     $Stats.JavaPFCount White
    Write-Stat "Parsed"            "$($Stats.PFParsed) / $($Stats.PFTotal)" White
    Write-Stat "Missing Files"     $Stats.MissingFiles $(if($Stats.MissingFiles -gt 0){"Yellow"}else{"Green"})
    Write-Host ""
    Write-SubSeparator; Write-Host "  DETECTIONS" -ForegroundColor White; Write-SubSeparator
    Write-Stat "VELARIS"           "$velCount" $(if($velCount -gt 0){"Red"}else{"Green"})
    Write-Stat "AUTOMACE/CRYSTAL"  "$amCount"  $(if($amCount  -gt 0){"Red"}else{"Green"})
    Write-Stat "GENERIC CHEAT"     "$gcCount"  $(if($gcCount  -gt 0){"Yellow"}else{"Green"})
    Write-Stat "UNKNOWN MODS"      "$umCount"  $(if($umCount  -gt 0){"Yellow"}else{"Green"})
    Write-Stat "SELF-DESTRUCT"     "$sdCount"  $(if($sdCount  -gt 0){"Red"}else{"Green"})
    Write-Stat "HIGH Confidence"   "$highCount" $(if($highCount -gt 0){"Red"}else{"Green"})
    Write-Host ""
}

function Read-Choice {
    Write-Host "  [1] Summary  [2] All Detections  [Q] Exit" -ForegroundColor Cyan
    Write-Separator; Write-Host "  Select option: " -NoNewline -ForegroundColor White
    return (Read-Host).Trim().ToUpper()
}

function Show-Dashboard {
    param([hashtable]$Stats,[array]$AllDetections)
    $tab = "1"
    while ($true) {
        switch ($tab) {
            "1" { Show-Summary       -Stats $Stats -AllDetections $AllDetections }
            "2" { Show-AllDetections -AllDetections $AllDetections }
            default { Show-Summary   -Stats $Stats -AllDetections $AllDetections }
        }
        $choice = Read-Choice
        switch ($choice) {
            "1" { $tab="1" } "2" { $tab="2" }
            "Q" { return }
        }
        if ($choice -eq "Q") { break }
    }
}

function Start-VelarisScan {
    param([switch]$Debug,[switch]$SkipFullSystemScan,[switch]$SkipModpack)
    $script:DebugMode = $Debug
    $scanStart = Get-Date
    Show-Banner
    if (-not (Test-Administrator)) {
        Write-Err "Administrator privileges required."
        Write-Warning "Right-click PowerShell → Run as Administrator"
        return
    }
    $osVer = [System.Environment]::OSVersion.Version
    Write-Status "OS: $($osVer.Major).$($osVer.Minor) Build $($osVer.Build)" Cyan
    Write-Host ""
    $allDetections = [System.Collections.Generic.List[object]]::new()
    $modpackFindings = @()
    if (-not $SkipModpack) {
        $modpackPath = Get-ModpackPath
        if ($modpackPath) {
            $modpackFindings = Scan-ModpackFolder -ModpackPath $modpackPath
            foreach ($f in $modpackFindings) { [void]$allDetections.Add($f) }
        }
    }
    $prefetchPath = "C:\Windows\Prefetch"
    $javaFiles = @()
    $pfParsed=0; $pfTotal=0; $missingCount=0
    $fileMetadata = @{}; $prefetchPaths = @()
    if (Test-Path $prefetchPath) {
        $javaFiles = @(Get-ChildItem -Path $prefetchPath -Filter "JAVA*.EXE-*.pf" -ErrorAction SilentlyContinue)
        $pfTotal   = $javaFiles.Count
        Write-Success "Found $pfTotal JAVA prefetch file(s)"; Write-Host ""
        foreach ($pf in $javaFiles) {
            Write-SubSeparator
            Write-Host "  PREFETCH: $($pf.Name)" -ForegroundColor Cyan
            Write-SubSeparator
            Write-Stat "Full Path"     $pf.FullName                                        White
            Write-Stat "File Size"     (Format-FileSize $pf.Length)                        White
            Write-Stat "Created"       $pf.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")    Yellow
            Write-Stat "Last Modified" $pf.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")   Yellow
            Write-Stat "Last Accessed" $pf.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss")  Cyan
            if ($pf.Name -match '^(.+?)-([0-9A-F]{8})\.pf$') {
                Write-Stat "Executable"  $Matches[1]  White
                Write-Stat "PF Hash"     $Matches[2]  DarkGray
            }
            try {
                $pfBytes = [System.IO.File]::ReadAllBytes($pf.FullName)
                if ($pfBytes.Length -ge 3 -and $pfBytes[0] -eq 0x4D -and $pfBytes[1] -eq 0x41 -and $pfBytes[2] -eq 0x4D) {
                    $pfBytes = [NtdllDecompressor]::Decompress($pfBytes)
                }
                if ($pfBytes -and $pfBytes.Length -ge 200) {
                    $ver = [BitConverter]::ToUInt32($pfBytes, 0)
                    Write-Stat "PF Version" "v$ver $(switch($ver){17{'(WinXP)'}23{'(Vista/7)'}26{'(Win8)'}30{'(Win10/11)'}default{'(Unknown)'}})" White
                    $runCountOff = switch ($ver) { 17{0x90} 23{0x98} 26{0xD0} 30{0xD0} default{0} }
                    $lastRunOff  = switch ($ver) { 17{0x78} 23{0x80} 26{0xC0} 30{0xC0} default{0} }
                    if ($runCountOff -gt 0 -and ($runCountOff+4) -le $pfBytes.Length) {
                        $rc = [BitConverter]::ToUInt32($pfBytes, $runCountOff)
                        Write-Stat "Run Count" "$rc time(s)" $(if($rc -ge 10){"Red"}elseif($rc -ge 3){"Yellow"}else{"Green"})
                    }
                    if ($lastRunOff -gt 0 -and ($lastRunOff+8) -le $pfBytes.Length) {
                        try {
                            $ft = [BitConverter]::ToInt64($pfBytes, $lastRunOff)
                            if ($ft -gt 0) {
                                $lr  = [DateTime]::FromFileTimeUtc($ft).ToLocalTime()
                                $ago = (Get-Date) - $lr
                                $agoStr = if ($ago.TotalMinutes -lt 60) { "$([int]$ago.TotalMinutes) min ago" }
                                          elseif ($ago.TotalHours -lt 24) { "$([int]$ago.TotalHours) hr ago" }
                                          else { "$([int]$ago.TotalDays) days ago" }
                                Write-Stat "Last Executed" "$($lr.ToString('yyyy-MM-dd HH:mm:ss'))  ($agoStr)" `
                                    $(if($ago.TotalHours -lt 2){"Red"}elseif($ago.TotalHours -lt 24){"Yellow"}else{"White"})
                            }
                        } catch {}
                    }
                    if ($ver -eq 30 -and $pfBytes.Length -ge 0x100) {
                        $tsSlots = @()
                        for ($ti=0; $ti -lt 8; $ti++) {
                            $off = 0xC0 + ($ti*8)
                            if (($off+8) -gt $pfBytes.Length) { break }
                            try {
                                $ft2 = [BitConverter]::ToInt64($pfBytes, $off)
                                if ($ft2 -gt 0) { $tsSlots += [DateTime]::FromFileTimeUtc($ft2).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") }
                            } catch {}
                        }
                        if ($tsSlots.Count -gt 1) {
                            Write-Host "  Run History:" -ForegroundColor White
                            foreach ($ts in $tsSlots) { Write-Host "    - $ts" -ForegroundColor DarkGray }
                        }
                    }
                }
            } catch {}
            Write-Host ""
        }
        Write-SubSeparator; Write-Host ""
        $processed = 0
        foreach ($pf in $javaFiles) {
            $processed++
            Write-Progress -Activity "Parsing Prefetch" -Status "$processed/$pfTotal — $($pf.Name)" -PercentComplete (($processed/$pfTotal)*100)
            $indexes = Get-SystemIndexes -FilePath $pf.FullName
            if ($indexes.Count -eq 0) { continue }
            $pfParsed++
            $idxNum=0
            foreach ($idx in $indexes) {
                $idxNum++
                $resolved = if ($idx -match '\\VOLUME\{[^}]+\}\\(.*)$') { "C:\$($Matches[1])" } else { $idx }
                $prefetchPaths += $resolved
                if (-not $fileMetadata.ContainsKey($resolved)) {
                    $fileMetadata[$resolved]=@{SourceFile=$pf.Name;IndexNumber=$idxNum;OriginalPath=$idx}
                }
            }
        }
        Write-Progress -Activity "Parsing Prefetch" -Completed
        $uniquePF = $prefetchPaths | Select-Object -Unique
        $ntfsDrives = Get-NTFSDrives
        if ($ntfsDrives.Count -gt 0) { Get-RecentDeletionsFromUSN -DriveLetters $ntfsDrives -MinutesBack 120 | Out-Null }
        foreach ($p in $uniquePF) {
            if (Test-Path $p -PathType Leaf) { continue }
            if ($p -match '\\TEMP\\|\\TMP\\|HSPERFDATA|\.TMP$|JNA\d+\.DLL') { continue }
            if ($p -notmatch '\.(JAR|EXE|DLL|BIN|DAT)$') { continue }
            $missingCount++
            $del  = Test-RecentlyDeleted -FilePath $p
            $src  = if ($fileMetadata.ContainsKey($p)) { $fileMetadata[$p].SourceFile } else { "" }
            $sd   = Test-SelfDestructSuspicion -Path $p -SourceFile $src -RecentDeletion $del
            if ($sd.IsSuspicious) {
                [void]$allDetections.Add([PSCustomObject]@{
                    Category="SELF_DESTRUCT"; Type="MISSING_FILE"; Path=$p
                    Confidence=$sd.Confidence; Description="Self-destruct pattern — file deleted after execution"
                    Details="Score: $($sd.Score)/20"; Reasons=$sd.Reasons
                    DeletionTime=if($del){$del.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")}else{$null}
                    Reason=if($del){$del.Reason}else{$null}
                    SourceFile=$src
                })
                Write-Detection "Self-destruct: $p" $sd.Confidence
            }
        }
    } else {
        Write-Warning "Prefetch directory not found (may be disabled)."
    }
    $totalJarsFound=0; $jarsScanned=0; $jarsSkipped=0
    if (-not $SkipFullSystemScan) {
        Write-Host ""
        Write-Status "Starting full-system JAR discovery and scan..." Cyan
        Write-Warning "This may take several minutes on large drives."
        Write-Host ""
        $allJars = @(Get-AllJarsOnSystem)
        $totalJarsFound = $allJars.Count
        $idx=0
        foreach ($jarPath in $allJars) {
            $idx++
            $shortName = Split-Path $jarPath -Leaf
            Write-Progress -Activity "Full-System JAR Scan" -Status "[$idx/$totalJarsFound] $shortName" -PercentComplete (($idx/$totalJarsFound)*100)
            $r = Test-JarFull -Path $jarPath
            $jarsScanned++
            if ($r.Error) { $jarsSkipped++; continue }
            $loc = $jarPath
            if ($r.IsVelaris) {
                [void]$allDetections.Add([PSCustomObject]@{
                    Category="VELARIS"; Type="JAR_CONTENT"; Path=$loc; Confidence=$r.VelarisConfidence
                    Description="Velaris cheat client detected"; Details="Matches:$($r.VelarisMatches.Count) Strong:$($r.VelarisStrong)"
                    VelarisFiles=$r.VelarisFiles; ConfigPaths=$r.ConfigPaths; IsRenamedJar=$r.IsRenamedJar
                    FileSize=$r.FileSize; MatchCount=$r.VelarisMatches.Count; StrongMatchCount=$r.VelarisStrong
                    Matches=$r.VelarisMatches
                })
                Write-Detection "$shortName [VELARIS]" $r.VelarisConfidence
            }
            if ($r.IsAutoMace) {
                [void]$allDetections.Add([PSCustomObject]@{
                    Category="AUTOMACE"; Type="JAR_CONTENT"; Path=$loc; Confidence="HIGH"
                    Description="AutoMace / Crystal PvP hack detected"
                    Details="$($r.AutoMaceCount) combat-hack signatures"
                    AutoMaceMatches=$r.AutoMaceMatches; MatchCount=$r.AutoMaceCount; FileSize=$r.FileSize
                })
                Write-Detection "$shortName [AUTOMACE/CRYSTAL]" "HIGH"
            }
            if ($r.IsGenericCheat) {
                [void]$allDetections.Add([PSCustomObject]@{
                    Category="GENERIC_CHEAT"; Type="JAR_CONTENT"; Path=$loc; Confidence="MEDIUM"
                    Description="Generic cheat client signatures ($($r.GenericCount) matches)"
                    GenericMatches=$r.GenericMatches; MatchCount=$r.GenericCount; FileSize=$r.FileSize
                    Details="Matches: $($r.GenericCount)"
                })
                Write-Detection "$shortName [GENERIC CHEAT]" "MEDIUM"
            }
            if ($r.UnknownMod -and $r.UnknownMod.IsUnknown) {
                [void]$allDetections.Add([PSCustomObject]@{
                    Category="UNKNOWN_MOD"; Type="JAR_CONTENT"; Path=$loc; Confidence=$r.UnknownMod.Confidence
                    Description="Unknown / suspicious mod"
                    Details="Score:$($r.UnknownMod.Score) ModId:$($r.UnknownMod.ModId)"
                    ModId=$r.UnknownMod.ModId; ModName=$r.UnknownMod.ModName
                    Reasons=$r.UnknownMod.Reasons; SuspiciousImports=$r.UnknownMod.SuspiciousImports
                    ObfuscatedCode=$r.UnknownMod.ObfuscatedCode; FileSize=$r.FileSize
                })
                Write-Detection "$shortName [UNKNOWN MOD]" $r.UnknownMod.Confidence
            }
        }
        Write-Progress -Activity "Full-System JAR Scan" -Completed
        Write-Success "Full-system JAR scan complete — $jarsScanned scanned, $jarsSkipped skipped."
    }
    $scanEnd = Get-Date
    $stats = @{
        WindowsVersion = "$($osVer.Major).$($osVer.Minor) Build $($osVer.Build)"
        ScanDuration   = [math]::Round(($scanEnd-$scanStart).TotalSeconds,2)
        JavaPFCount    = $javaFiles.Count
        PFParsed       = $pfParsed
        PFTotal        = $pfTotal
        TotalJarsFound = $totalJarsFound
        JarsScanned    = $jarsScanned
        MissingFiles   = $missingCount
    }
    $detArr = @($allDetections)
    Write-Host ""
    Write-Success "Scan complete in $($stats.ScanDuration) seconds!"
    Write-Success "Total detections: $($detArr.Count)"
    Write-Host ""; Write-Host "  Press any key to open results dashboard..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Dashboard -Stats $stats -AllDetections $detArr
}

Start-VelarisScan
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
param(
    [string]$ModPath,
    [switch]$SkipDeepScan,
    [switch]$ExportJson
)

Clear-Host

$HeatedBanner = @"

  ██╗  ██╗███████╗ █████╗ ████████╗███████╗██████╗
  ██║  ██║██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
  ███████║█████╗  ███████║   ██║   █████╗  ██║  ██║
  ██╔══██║██╔══╝  ██╔══██║   ██║   ██╔══╝  ██║  ██║
  ██║  ██║███████╗██║  ██║   ██║   ███████╗██████╔╝
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═════╝

   █████╗ ███╗   ██╗ █████╗ ██╗   ██╗   ██╗███████╗███████╗██████╗
  ██╔══██╗████╗  ██║██╔══██╗██║   ╚██╗ ██╔╝╚══███╔╝██╔════╝██╔══██╗
  ███████║██╔██╗ ██║███████║██║    ╚████╔╝   ███╔╝ █████╗  ██████╔╝
  ██╔══██║██║╚██╗██║██╔══██║██║     ╚██╔╝   ███╔╝  ██╔══╝  ██╔══██╗
  ██║  ██║██║ ╚████║██║  ██║███████╗ ██║    ███████╗███████╗██║  ██║
  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝ ╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝

"@

Write-Host $HeatedBanner -ForegroundColor Red
Write-Host ""
Write-Host "                Made with " -NoNewline -ForegroundColor Gray
Write-Host "♥ " -NoNewline -ForegroundColor Red
Write-Host "by " -NoNewline -ForegroundColor Gray
Write-Host "Heated" -ForegroundColor Red
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkRed
Write-Host ""

Write-Host " Enter path to mods folder:" -ForegroundColor Cyan
Write-Host " (Press Enter to use default Minecraft mods folder)" -ForegroundColor DarkGray
$inputPath = Read-Host " PATH"

if ([string]::IsNullOrWhiteSpace($inputPath)) {
    $inputPath = "$env:APPDATA\.minecraft\mods"
    Write-Host " Continuing with: $inputPath" -ForegroundColor White
}

if (-not (Test-Path $inputPath -PathType Container)) {
    Write-Host " Invalid Path! Directory does not exist." -ForegroundColor Red
    Write-Host " Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkRed
Write-Host ""

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host " MINECRAFT UPTIME" -ForegroundColor DarkCyan
        Write-Host "    $($mcProcess.Name) PID $($mcProcess.Id) started at $startTime" -ForegroundColor Gray
        Write-Host "    Running for: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch {}
}

function Get-ZoneIdentifier {
    param ([string]$filePath)
    $ads = Get-Content -Raw -Stream Zone.Identifier $filePath -ErrorAction SilentlyContinue
    if ($ads -match "HostUrl=(.+)") {
        return $matches[1]
    }
    return $null
}

function Get-FileDates {
    param([string]$FilePath)
    $file = Get-Item $FilePath -ErrorAction SilentlyContinue
    if ($file) {
        return @{
            Created = $file.CreationTime
            Modified = $file.LastWriteTime
            Accessed = $file.LastAccessTime
        }
    }
    return @{
        Created = "Unknown"
        Modified = "Unknown"
        Accessed = "Unknown"
    }
}

function Get-SourceDescription {
    param([string]$ZoneUrl)
    if (-not $ZoneUrl) { return "Unknown" }
    if ($ZoneUrl -match "discord") { return "Discord" }
    if ($ZoneUrl -match "modrinth") { return "Modrinth" }
    if ($ZoneUrl -match "curseforge") { return "CurseForge" }
    if ($ZoneUrl -match "github") { return "GitHub" }
    if ($ZoneUrl -match "mediafire") { return "MediaFire" }
    if ($ZoneUrl -match "dropbox") { return "Dropbox" }
    if ($ZoneUrl -match "drive.google") { return "Google Drive" }
    if ($ZoneUrl -match "mega") { return "MEGA" }
    if ($ZoneUrl -match "vape") { return "Vape Client" }
    if ($ZoneUrl -match "intent.store") { return "Intent Store" }
    if ($ZoneUrl -match "rise.today") { return "Rise Client" }
    if ($ZoneUrl -match "doomsday") { return "Doomsday Client" }
    if ($ZoneUrl -match "https?://([^/]+)") {
        return $matches[1]
    }
    return "Unknown"
}

function Get-SHA1 {
    param ([string]$filePath)
    return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}

function Test-Modrinth {
    param ([string]$hash)
    try {
        $response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$hash" -Method Get -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
        if ($response.project_id) {
            $project = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($response.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
            return @{ Name = $project.title; Slug = $project.slug }
        }
    } catch {}
    return $null
}

function Test-Megabase {
    param ([string]$hash)
    try {
        $response = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$hash" -Method Get -UseBasicParsing -ErrorAction Stop -TimeoutSec 5
        if (-not $response.error) {
            return @{ Name = $response.data.name; Slug = $response.data.slug }
        }
    } catch {}
    return $null
}

function Invoke-DeepScan {
    param([string]$FilePath)
    $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
    $tempDir = Join-Path $env:TEMP "heated_deepscan_$(Get-Random)"
    $cheatPatterns = @(
        "KillAura", "ClickAura", "TriggerBot", "MultiAura", "ForceField", "AimAssist", "AimBot", "SilentAim",
        "CrystalAura", "AutoCrystal", "AutoHitCrystal", "AnchorAura", "AutoAnchor", "DoubleAnchor", "SafeAnchor",
        "BowAimbot", "AutoCrit", "Criticals", "ReachHack", "LongReach", "HitboxExpand", "AntiKB", "NoKnockback",
        "Velocity", "GrimDisabler", "AutoTotem", "HoverTotem", "InventoryTotem", "OffhandTotem", "ShieldBreaker",
        "WTap", "JumpReset", "AxeSpam", "MaceSwap", "FlyHack", "PacketFly", "SpeedHack", "NoFall",
        "Scaffold", "ScaffoldWalk", "ElytraFly", "ElytraSwap", "PlayerESP", "XRay", "Freecam", "FullBright",
        "Disabler", "TimerHack", "FakeLag", "PingSpoof", "SelfDestruct", "ChestStealer", "AutoArmor", "AutoPot",
        "vape.gg", "vape v4", "vapeclient", "intent.store", "rise.today", "riseclient.com", "meteorclient",
        "wurstclient", "liquidbounce", "doomsdayclient", "DoomsdayClient", "aristois", "impactclient"
    )
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($FilePath, $tempDir)
        $files = Get-ChildItem -Path $tempDir -Recurse -Include *.class, *.json, *.properties, *.txt, *.cfg -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    foreach ($pattern in $cheatPatterns) {
                        if ($content -match "\b$([regex]::Escape($pattern))\b") {
                            $foundPatterns.Add($pattern) | Out-Null
                        }
                    }
                }
            } catch {}
        }
        $nestedJars = Get-ChildItem -Path "$tempDir\META-INF\jars" -Filter *.jar -ErrorAction SilentlyContinue
        foreach ($nested in $nestedJars) {
            $nestedResult = Invoke-DeepScan -FilePath $nested.FullName
            foreach ($pattern in $nestedResult) {
                $foundPatterns.Add($pattern) | Out-Null
            }
        }
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    return $foundPatterns
}

$jarFiles = Get-ChildItem -Path $inputPath -Filter *.jar -File

if ($jarFiles.Count -eq 0) {
    Write-Host " No mods found in: $inputPath" -ForegroundColor Red
    Write-Host " Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host " Found $($jarFiles.Count) mod(s) to analyze" -ForegroundColor Green
Write-Host ""

$spinner = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷")

Write-Host " PASS 1: Verifying mods against databases..." -ForegroundColor Cyan
Write-Host ("─" * 76) -ForegroundColor DarkGray

$verifiedMods = @()
$unknownMods = @()
$counter = 0

foreach ($file in $jarFiles) {
    $counter++
    $spin = $spinner[$counter % $spinner.Length]
    Write-Host "`r [$spin] Verifying: $counter / $($jarFiles.Count) - $($file.Name)" -NoNewline -ForegroundColor Yellow
    $hash = Get-SHA1 -filePath $file.FullName
    $fileDates = Get-FileDates -FilePath $file.FullName
    $modrinthData = Test-Modrinth -hash $hash
    if ($modrinthData) {
        $verifiedMods += [PSCustomObject]@{
            FileName = $file.Name
            ModName = $modrinthData.Name
            Hash = $hash
            RawSource = Get-ZoneIdentifier -filePath $file.FullName
            SourceDesc = Get-SourceDescription -ZoneUrl (Get-ZoneIdentifier -filePath $file.FullName)
            FilePath = $file.FullName
            FileSize = [math]::Round($file.Length / 1KB, 2)
            CreatedDate = $fileDates.Created
            ModifiedDate = $fileDates.Modified
        }
        continue
    }
    $megabaseData = Test-Megabase -hash $hash
    if ($megabaseData) {
        $verifiedMods += [PSCustomObject]@{
            FileName = $file.Name
            ModName = $megabaseData.Name
            Hash = $hash
            RawSource = Get-ZoneIdentifier -filePath $file.FullName
            SourceDesc = Get-SourceDescription -ZoneUrl (Get-ZoneIdentifier -filePath $file.FullName)
            FilePath = $file.FullName
            FileSize = [math]::Round($file.Length / 1KB, 2)
            CreatedDate = $fileDates.Created
            ModifiedDate = $fileDates.Modified
        }
        continue
    }
    $unknownMods += [PSCustomObject]@{
        FileName = $file.Name
        FilePath = $file.FullName
        Hash = $hash
        RawSource = Get-ZoneIdentifier -filePath $file.FullName
        SourceDesc = Get-SourceDescription -ZoneUrl (Get-ZoneIdentifier -filePath $file.FullName)
        FileSize = [math]::Round($file.Length / 1KB, 2)
        CreatedDate = $fileDates.Created
        ModifiedDate = $fileDates.Modified
    }
}

Write-Host "`r" + " " * 100 + "`r" -NoNewline

Write-Host ""
Write-Host " PASS 2: Deep scanning unknown mods..." -ForegroundColor Cyan
Write-Host ("─" * 76) -ForegroundColor DarkGray

$cheatMods = @()
$cleanUnknownMods = @()
$counter = 0
$totalUnknown = $unknownMods.Count

if ($SkipDeepScan) {
    $cleanUnknownMods = $unknownMods
    Write-Host " Deep scan skipped by user" -ForegroundColor Yellow
} elseif ($totalUnknown -eq 0) {
    Write-Host " No unknown mods to deep scan!" -ForegroundColor Green
} else {
    foreach ($mod in $unknownMods) {
        $counter++
        $spin = $spinner[$counter % $spinner.Length]
        Write-Host "`r [$spin] Deep scanning: $counter / $totalUnknown - $($mod.FileName)" -NoNewline -ForegroundColor Yellow
        $deepResult = Invoke-DeepScan -FilePath $mod.FilePath
        if ($deepResult.Count -gt 0) {
            $cheatMods += [PSCustomObject]@{
                FileName = $mod.FileName
                FilePath = $mod.FilePath
                Hash = $mod.Hash
                RawSource = $mod.RawSource
                SourceDesc = $mod.SourceDesc
                FileSize = $mod.FileSize
                CreatedDate = $mod.CreatedDate
                ModifiedDate = $mod.ModifiedDate
                PatternsFound = $deepResult
                PatternCount = $deepResult.Count
            }
        } else {
            $cleanUnknownMods += $mod
        }
    }
}

Write-Host "`r" + " " * 100 + "`r" -NoNewline

Clear-Host
Write-Host $HeatedBanner -ForegroundColor Red
Write-Host ""
Write-Host "                Made with " -NoNewline -ForegroundColor Gray
Write-Host "♥ " -NoNewline -ForegroundColor Red
Write-Host "by " -NoNewline -ForegroundColor Gray
Write-Host "Heated" -ForegroundColor Red
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkRed
Write-Host ""

Write-Host " VERIFIED MODS ($($verifiedMods.Count))" -ForegroundColor Green
Write-Host ("─" * 76) -ForegroundColor DarkGray
if ($verifiedMods.Count -gt 0) {
    foreach ($mod in $verifiedMods) {
        Write-Host "  $($mod.ModName)" -ForegroundColor White
        Write-Host "     File: $($mod.FileName)" -ForegroundColor Gray
        Write-Host "     Size: $($mod.FileSize) KB" -ForegroundColor DarkGray
        Write-Host "     Downloaded: $($mod.CreatedDate)" -ForegroundColor DarkGray
        Write-Host "     Location: $($mod.FilePath)" -ForegroundColor DarkGray
        if ($mod.SourceDesc -and $mod.SourceDesc -ne "Unknown") {
            Write-Host "     Source: $($mod.SourceDesc)" -ForegroundColor Cyan
        }
        Write-Host ""
    }
} else {
    Write-Host "  No verified mods found." -ForegroundColor Gray
    Write-Host ""
}

Write-Host " UNKNOWN MODS (No cheats detected) ($($cleanUnknownMods.Count))" -ForegroundColor Yellow
Write-Host ("─" * 76) -ForegroundColor DarkGray
if ($cleanUnknownMods.Count -gt 0) {
    foreach ($mod in $cleanUnknownMods) {
        Write-Host "  $($mod.FileName)" -ForegroundColor Yellow
        Write-Host "     Size: $($mod.FileSize) KB" -ForegroundColor DarkGray
        Write-Host "     Downloaded: $($mod.CreatedDate)" -ForegroundColor DarkGray
        Write-Host "     Location: $($mod.FilePath)" -ForegroundColor DarkGray
        if ($mod.SourceDesc -and $mod.SourceDesc -ne "Unknown") {
            Write-Host "     Source: $($mod.SourceDesc)" -ForegroundColor Cyan
        }
        Write-Host ""
    }
} else {
    Write-Host "  No unknown clean mods." -ForegroundColor Gray
    Write-Host ""
}

Write-Host " CHEAT MODS DETECTED ($($cheatMods.Count))" -ForegroundColor Red
Write-Host ("━" * 76) -ForegroundColor Red
if ($cheatMods.Count -gt 0) {
    foreach ($mod in $cheatMods) {
        Write-Host ""
        Write-Host "  ┌─────────────────────────────────────────────────────────" -ForegroundColor DarkRed
        Write-Host "  │ $($mod.FileName)" -ForegroundColor Red
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  LOCATION:" -ForegroundColor Yellow
        Write-Host "  │     $($mod.FilePath)" -ForegroundColor Gray
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  DOWNLOADED:" -ForegroundColor Yellow
        Write-Host "  │     $($mod.CreatedDate)" -ForegroundColor Gray
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  SIZE: $($mod.FileSize) KB" -ForegroundColor Gray
        Write-Host "  │  SHA1: $($mod.Hash)" -ForegroundColor Gray
        Write-Host "  │" -ForegroundColor DarkRed
        if ($mod.SourceDesc -and $mod.SourceDesc -ne "Unknown") {
            Write-Host "  │  DOWNLOAD SOURCE:" -ForegroundColor Yellow
            Write-Host "  │     $($mod.SourceDesc)" -ForegroundColor Cyan
            Write-Host "  │" -ForegroundColor DarkRed
        }
        Write-Host "  │  DETECTED PATTERNS ($($mod.PatternCount)):" -ForegroundColor Red
        foreach ($pattern in ($mod.PatternsFound | Select-Object -First 15)) {
            Write-Host "  │     • $pattern" -ForegroundColor DarkRed
        }
        if ($mod.PatternCount -gt 15) {
            Write-Host "  │     ... and $($mod.PatternCount - 15) more" -ForegroundColor DarkGray
        }
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  └─────────────────────────────────────────────────────────" -ForegroundColor DarkRed
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "  No cheat mods detected! System is clean." -ForegroundColor Green
    Write-Host ""
}

Write-Host ("━" * 76) -ForegroundColor DarkRed
Write-Host ""
Write-Host " SUMMARY" -ForegroundColor Cyan
Write-Host ("─" * 76) -ForegroundColor DarkGray
Write-Host "     Verified (Safe): $($verifiedMods.Count)" -ForegroundColor Green
Write-Host "     Unknown (Clean): $($cleanUnknownMods.Count)" -ForegroundColor Yellow
Write-Host "     Cheat Mods: $($cheatMods.Count)" -ForegroundColor Red
Write-Host "     Total Scanned: $($jarFiles.Count)" -ForegroundColor White
Write-Host ""

if ($ExportJson) {
    $exportData = @{
        ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ModPath = $inputPath
        TotalMods = $jarFiles.Count
        VerifiedMods = $verifiedMods | Select-Object FileName, ModName, Hash, SourceDesc, CreatedDate
        UnknownMods = $cleanUnknownMods | Select-Object FileName, Hash, SourceDesc, CreatedDate
        CheatMods = $cheatMods | Select-Object FileName, FilePath, Hash, SourceDesc, CreatedDate, PatternCount
    }
    $jsonPath = "$env:USERPROFILE\Desktop\heated_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath
    Write-Host " Results exported to: $jsonPath" -ForegroundColor Green
    Write-Host ""
}

Write-Host " Press any key to exit..." -ForegroundColor DarkGray
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
$scanPaths = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:TEMP",
    "$env:APPDATA\.minecraft\mods"
)

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
    $modulesDetected = @()
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
        $entries = $zip.Entries | ForEach-Object { $_.FullName }
        $zip.Dispose()
        foreach ($client in $hackedClients.Keys) {
            $score = 0
            $modules = @()
            foreach ($pattern in $hackedClients[$client]) {
                foreach ($entry in $entries) {
                    if ($entry -match [regex]::Escape($pattern)) {
                        $score += 10
                        $modules += $pattern
                    }
                }
            }
            $scoreTable[$client] = [PSCustomObject]@{
                Score = $score
                Modules = ($modules | Sort-Object -Unique) -join ", "
            }
        }
        $bestClient = $scoreTable.GetEnumerator() | Sort-Object -Property Value.Score -Descending | Select-Object -First 1
        if ($bestClient.Value.Score -ge 50) {
            Write-Host "🔴 File: $jarPath" -ForegroundColor Red
            Write-Host "Detected Client: $($bestClient.Key)"
            Write-Host "Score: $($bestClient.Value.Score)"
            Write-Host "Modules: $($bestClient.Value.Modules)"
        } else {
            Write-Host "🟢 File: $jarPath"
            Write-Host "Verified Mod / Unknown"
        }
        Write-Host "-----------------------------------"
    } catch {
        Write-Host "❌ Error reading $jarPath"
    }
}

foreach ($path in $scanPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Filter *.jar | ForEach-Object {
            Analyze-Jar $_.FullName
        }
    }
}
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
        $errorMsg = $_.Exception.Message
        Write-Log "Error in DQRKISDetector: $errorMsg"
        Write-Log "Stack trace: $($_.ScriptStackTrace)"
        Set-Status "Error" "DQRKISDetector failed: $errorMsg" "ERROR"
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
        $errorMsg = $_.Exception.Message
        Write-Log "Error in JournalTrace: $errorMsg"
        Set-Status "Error" "JournalTrace failed: $errorMsg" "ERROR"
    }
}

# ==============================================================================
# TOOL DATABASE - COMPLETE MERGED
# ==============================================================================
$ToolData = @(
    [PSCustomObject]@{ Name="WinPrefetchView_x64.zip";      Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/winprefetchview-x64.zip"; Description="View prefetch files" },
    [PSCustomObject]@{ Name="LastActivityView.zip";          Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/lastactivityview.zip"; Description="List recent user activity" },
    [PSCustomObject]@{ Name="UsbDriveLog.zip";              Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/usbdrivelog.zip"; Description="Show USB drive history" },
    [PSCustomObject]@{ Name="WinDefLogView.zip";            Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/windeflogview.zip"; Description="Windows Defender log viewer" },
    [PSCustomObject]@{ Name="ShellBagsView.zip";            Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/shellbagsview.zip"; Description="Shell bags / folder history" },
    [PSCustomObject]@{ Name="UninstallView_x64.zip";        Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/uninstallview-x64.zip"; Description="List installed programs" },
    [PSCustomObject]@{ Name="LoadedDllsView_x64.zip";       Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/loadeddllsview-x64.zip"; Description="Loaded DLL list" },
    [PSCustomObject]@{ Name="JumpListsView.zip";            Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/jumplistsview.zip"; Description="Jump list history" },
    [PSCustomObject]@{ Name="Clipboardic.zip";              Category="NirSoft";      Type="zip"; Author="NirSoft"; URL="https://www.nirsoft.net/utils/clipboardic.zip"; Description="Clipboard history viewer" },
    
    [PSCustomObject]@{ Name="TimelineExplorer.zip";          Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip"; Description="Timeline analysis" },
    [PSCustomObject]@{ Name="SrumECmd.zip";                 Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/SrumECmd.zip"; Description="SRUM database parser" },
    [PSCustomObject]@{ Name="AmcacheParser.zip";            Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/AmcacheParser.zip"; Description="Amcache analysis tool" },
    [PSCustomObject]@{ Name="WxTCmd.zip";                   Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net6/WxTCmd.zip"; Description="Windows Timeline database" },
    [PSCustomObject]@{ Name="RegistryExplorer.zip";         Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip"; Description="Registry explorer" },
    [PSCustomObject]@{ Name="MFTECmd.zip";                  Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/MFTECmd.zip"; Description="MFT filesystem parser" },
    [PSCustomObject]@{ Name="JLECmd.zip";                   Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/JLECmd.zip"; Description="JumpList CSV parser" },
    [PSCustomObject]@{ Name="JumpListExplorer.zip";         Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip"; Description="JumpList GUI parser" },
    [PSCustomObject]@{ Name="PECmd.zip";                    Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/PECmd.zip"; Description="Prefetch parser" },
    [PSCustomObject]@{ Name="RecentFileCacheParser.zip";    Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip"; Description="Recent file cache parser" },
    [PSCustomObject]@{ Name="ShellBagsExplorer.zip";        Category="EricZimmerman"; Type="zip"; Author="Eric Zimmerman"; URL="https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip"; Description="Shell bags explorer" },
    
    [PSCustomObject]@{ Name="BAMParser.exe";                Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe"; Description="BAM record parser" },
    [PSCustomObject]@{ Name="PrefetchParser.exe";           Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/prefetch-parser/releases/download/v1.5.5/PrefetchParser.exe"; Description="Prefetch parser" },
    [PSCustomObject]@{ Name="ProcessParser.exe";            Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/process-parser/releases/download/v0.5.5/ProcessParser.exe"; Description="Process information parser" },
    [PSCustomObject]@{ Name="PcaSvcExecuted.exe";           Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/pcasvc-executed/releases/download/v0.8.7/PcaSvcExecuted.exe"; Description="PCA service execution record" },
    [PSCustomObject]@{ Name="JournalTraceNormal.exe";       Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTraceNormal.exe"; Description="USN Journal trace" },
    [PSCustomObject]@{ Name="PathsParser.exe";              Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe"; Description="File path history" },
    [PSCustomObject]@{ Name="KernelLiveDumpTool.exe";       Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe"; Description="Kernel live dump tool" },
    [PSCustomObject]@{ Name="espouken.exe";                 Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/Tool/releases/download/v1.1.2/espouken.exe"; Description="Espouken analysis tool" },
    [PSCustomObject]@{ Name="BamDeletedKeys.exe";           Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/BamDeletedKeys/releases/download/v1.0/BamDeletedKeys.exe"; Description="Deleted BAM records" },
    [PSCustomObject]@{ Name="ActivitiesCache.exe";          Category="Spokwn";       Type="exe"; Author="spokwn"; URL="https://github.com/spokwn/ActivitiesCache-execution/releases/latest"; Description="Activities cache execution" },
    
    [PSCustomObject]@{ Name="Echo-Journal.exe";             Category="Echo";         Type="exe"; Author="Echo"; URL="https://github.com/Echo-Anticheat/Echo-Journal/raw/main/echo-journal.exe"; Description="Journal analysis tool" },
    [PSCustomObject]@{ Name="UserAssist.exe";               Category="Echo";         Type="exe"; Author="Echo"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-userassist.exe"; Description="UserAssist registry viewer" },
    [PSCustomObject]@{ Name="UsbTool.exe";                  Category="Echo";         Type="exe"; Author="Echo"; URL="https://github.com/korkusuzadX/TR-SS-AutoDownloader/raw/main/echo%20tools/echo-usb.exe"; Description="USB record analysis" },
    
    [PSCustomObject]@{ Name="pv++.exe";                     Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.6/pv++.exe"; Description="Detailed Prefetch analyzer" },
    [PSCustomObject]@{ Name="AmcacheParser.exe";            Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/AmcacheParser/releases/download/v1.0/AmcacheParser.exe"; Description="Detailed Amcache analyzer" },
    [PSCustomObject]@{ Name="JARParser.exe";                Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/JARParser/releases/download/v1.2/JARParser.exe"; Description="JAR scanner" },
    [PSCustomObject]@{ Name="fileless.exe";                 Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/Fileless/releases/download/v1.3/fileless.exe"; Description="Fileless malware detector" },
    [PSCustomObject]@{ Name="BAMReveal.exe";                Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/BAMReveal/releases/download/v1.3/BAMReveal.exe"; Description="BAM records viewer" },
    [PSCustomObject]@{ Name="OrbDiff-DPSAnalyzer.exe";      Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/DPS-Analyzer/releases/download/v1.1/dpsanalyzer.exe"; Description="DPS analysis tool" },
    [PSCustomObject]@{ Name="OrbDiff-UserAssistView.exe";   Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/UserAssistView/releases/latest"; Description="UserAssist viewer" },
    [PSCustomObject]@{ Name="OrbDiff-JournalParser.exe";    Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/JournalParser/releases/latest"; Description="Journal parser" },
    [PSCustomObject]@{ Name="OrbDiff-InjGen.exe";           Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/InjGen/releases/latest"; Description="Injection detection" },
    [PSCustomObject]@{ Name="OrbDiff-USBDetector.exe";      Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/USBDetector/releases/latest"; Description="USB detection" },
    [PSCustomObject]@{ Name="OrbDiff-PFTrace.exe";          Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/PFTrace/releases/latest"; Description="Prefetch trace" },
    [PSCustomObject]@{ Name="OrbDiff-CheckDeletedUSN.exe";  Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/CheckDeletedUSN/releases/latest"; Description="Deleted USN check" },
    [PSCustomObject]@{ Name="OrbDiff-StringsParser.exe";    Category="OrbDiff";      Type="exe"; Author="Orbdiff"; URL="https://github.com/Orbdiff/StringsParser/releases/latest"; Description="Strings parser" },
    
    [PSCustomObject]@{ Name="RedLotusModAnalyzer.exe";      Category="RedLotus";     Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/download/RL/RedLotusModAnalyzer.exe"; Description="Mod analysis tool" },
    [PSCustomObject]@{ Name="RedLotusAltChecker.exe";       Category="RedLotus";     Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotusAltChecker/releases/download/RL/RedLotusAltChecker.exe"; Description="Alt account checker" },
    [PSCustomObject]@{ Name="RedLotusTaskSentinel.exe";     Category="RedLotus";     Type="exe"; Author="ItzIceHere"; URL="https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/download/RL/RedLotusTaskSentinel.exe"; Description="Task monitor sentinel" },
    
    [PSCustomObject]@{ Name="PathDuzenleyicisiV2.exe";      Category="TRSSCommunity"; Type="exe"; Author="TRSSCommunity"; URL="https://github.com/trSScommunity/PathDuzenleyiciV2/raw/refs/heads/main/PathDuzenleyicisiV2.exe"; Description="Path organizer v2" },
    [PSCustomObject]@{ Name="MzHunter.exe";                 Category="TRSSCommunity"; Type="exe"; Author="TRSSCommunity"; URL="https://github.com/trSScommunity/MZHunter/raw/refs/heads/main/MzHunter.exe"; Description="MZ header scanner" },
    [PSCustomObject]@{ Name="MandarinTool.jar";             Category="TRSSCommunity"; Type="jar"; Author="TRSSCommunity"; URL="https://github.com/Mehmetyll/Mandarin-Tool/releases/download/Mandarin-Tool/MandarinTool.jar"; Description="Multi SS tool / JAR decompiler" },
    
    [PSCustomObject]@{ Name="MagnetEncryptedDiskDetector.exe"; Category="Magnet";    Type="exe"; Author="Magnet"; URL="https://go.magnetforensics.com/e/52162/MagnetEncryptedDiskDetector/kpt9bg/1663239667/h/LtXFtTL-Soawv5C1oL3BIEghi7e1Lx93yesZLR--Ok0"; Description="Encrypted disk detector" },
    [PSCustomObject]@{ Name="MRCv120.exe";                  Category="Magnet";       Type="exe"; Author="Magnet"; URL="https://go.magnetforensics.com/e/52162/mail-utm-campaign-UTMC-0000044/llr4bg/1663358653/h/4kZ9Y4i2yPRqBzuQMrywA_v5bfkpG3rG8gEiSWrYU70"; Description="RAM dump tool" },
    
    [PSCustomObject]@{ Name="FTK_Imager_4.7.1.exe";         Category="Forensics";    Type="exe"; Author="AccessData"; URL="https://archive.org/download/access-data-ftk-imager-4.7.1/AccessData_FTK_Imager_4.7.1.exe"; Description="Disk imaging tool" },
    [PSCustomObject]@{ Name="hayabusa-3.6.0-win-aarch64.zip"; Category="Forensics";  Type="zip"; Author="Yamato-Security"; URL="https://github.com/Yamato-Security/hayabusa/releases/download/v3.6.0/hayabusa-3.6.0-win-aarch64.zip"; Description="Windows event log analyzer" },
    [PSCustomObject]@{ Name="Velocidace.exe";               Category="Forensics";    Type="exe"; Author="Velocidex"; URL="https://github.com/Velocidex/velociraptor/releases/download/v0.75/velociraptor-v0.75.1-windows-amd64.exe"; Description="Digital forensics platform" },
    
    [PSCustomObject]@{ Name="SystemInformer_Canary_Setup.exe"; Category="SystemTools"; Type="exe"; Author="winsiderss"; URL="https://github.com/winsiderss/si-builds/releases/download/3.2.25275.112/systeminformer-build-canary-setup.exe"; Description="Advanced system monitor" },
    [PSCustomObject]@{ Name="Everything-Setup.exe";         Category="SystemTools";  Type="exe"; Author="voidtools"; URL="https://www.voidtools.com/Everything-1.4.1.1032.x64-Setup.exe"; Description="Instant file search engine" },
    [PSCustomObject]@{ Name="ProcessHacker-Setup.exe";      Category="SystemTools";  Type="exe"; Author="winsiderss"; URL="https://sourceforge.net/projects/processhacker/files/latest/download"; Description="Process hacker" },
    
    [PSCustomObject]@{ Name="InjGen.exe";                   Category="Analysis";     Type="exe"; Author="NotRequiem"; URL="https://github.com/NotRequiem/InjGen/releases/download/v2.0/InjGen.exe"; Description="Injection detection tool" },
    [PSCustomObject]@{ Name="Luyten.exe";                   Category="Analysis";     Type="exe"; Author="deathmarine"; URL="https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe"; Description="Java decompiler" },
    [PSCustomObject]@{ Name="dpsanalyzer.exe";              Category="Analysis";     Type="exe"; Author="nay-cat"; URL="https://github.com/nay-cat/dpsanalyzer/releases/download/1.3/dpsanalyzer.exe"; Description="DPS analyzer" },
    [PSCustomObject]@{ Name="DIE_engine_portable.zip";      Category="Analysis";     Type="zip"; Author="horsicq"; URL="https://github.com/horsicq/DIE-engine/releases/download/3.09/die_win64_portable_3.09_x64.zip"; Description="Detect-It-Easy PE analyzer" },
    
    [PSCustomObject]@{ Name="Jarabel.Light.exe";            Category="Misc";         Type="exe"; Author="nay-cat"; URL="https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe"; Description="JAR analysis tool" },
    [PSCustomObject]@{ Name="Unicode.exe";                  Category="Misc";         Type="exe"; Author="RRancio"; URL="https://github.com/RRancio/Exec/raw/main/Files/Unicode.exe"; Description="Unicode character analyzer" },
    [PSCustomObject]@{ Name="CachedProgramsList.exe";       Category="Misc";         Type="exe"; Author="ponei"; URL="https://github.com/ponei/CachedProgramsList/releases/download/1.1/CachedProgramsList.exe"; Description="Cache program list" },
    [PSCustomObject]@{ Name="TimeChangeDetect.exe";         Category="Misc";         Type="exe"; Author="santiagolin"; URL="https://github.com/santiagolin/TimeChangeDetect/releases/download/1.0/TimeChangeDetect.exe"; Description="System time change detector" },
    [PSCustomObject]@{ Name="HardlinkFinder.exe";           Category="Misc";         Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/HardlinkFinder/releases/download/Tools/hardlink.exe"; Description="Hardlink detection" },
    
    [PSCustomObject]@{ Name="MeowNovowareFucker.exe";       Category="Meow";         Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowNovowareFucker/raw/refs/heads/main/MeowNovowareFucker.exe"; Description="Novoware client detector" },
    [PSCustomObject]@{ Name="MeowDoomsdayFucker.exe";       Category="Meow";         Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowDoomsdayFucker/raw/refs/heads/main/MeowDoomsdayFucker.exe"; Description="Doomsday client detector" },
    [PSCustomObject]@{ Name="MeowResolver.exe";             Category="Meow";         Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowResolver/releases/latest"; Description="Meow resolver" },
    [PSCustomObject]@{ Name="MeowImportsChecker.exe";       Category="Meow";         Type="exe"; Author="MeowTonynoh"; URL="https://github.com/MeowTonynoh/MeowImportsChecker/releases/latest"; Description="Imports checker" },
    
    [PSCustomObject]@{ Name="PSHunter.exe";                 Category="Praiselily";   Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/PSHunter/releases/latest"; Description="PS hunter tool" },
    [PSCustomObject]@{ Name="AltDetector.exe";              Category="Praiselily";   Type="exe"; Author="praiselily"; URL="https://github.com/praiselily/AltDetector/releases/latest"; Description="Alt account detector" },
    
    [PSCustomObject]@{ Name="TeslaPro-MacroFinder.exe";     Category="TeslaPro";     Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/TeslaProMacroFinder/releases/latest"; Description="Macro finder tool" },
    [PSCustomObject]@{ Name="TeslaPro-DoomsdayDetector.exe"; Category="TeslaPro";    Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/DoomsdayDetector/releases/latest"; Description="Doomsday detector" },
    [PSCustomObject]@{ Name="TeslaPro-VPNFinder.exe";       Category="TeslaPro";     Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/VPNChecker/releases/latest"; Description="VPN finder" },
    [PSCustomObject]@{ Name="TeslaPro-GhostClientFucker.exe"; Category="TeslaPro";   Type="exe"; Author="TeslaPro"; URL="https://github.com/TeslaPros/GhostClientFucker/releases/latest"; Description="Ghost client detector" },
    
    [PSCustomObject]@{ Name="Xeinn-SSTools.exe";            Category="Xeinn";        Type="exe"; Author="Xeinn"; URL="https://github.com/Xeinn-Software/Xeinn-SS-Tools-Downloader/releases/latest"; Description="Xeinn SS tools" },
    
    [PSCustomObject]@{ Name="NET-9.0-SDK.exe";              Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/9.0"; Description=".NET 9.0 SDK" },
    [PSCustomObject]@{ Name="NET-10.0-Runtime.exe";         Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://dotnet.microsoft.com/en-us/download/dotnet/10.0"; Description=".NET 10.0 Runtime" },
    [PSCustomObject]@{ Name="VC_Redist.exe";                Category="Dependencies"; Type="exe"; Author="Microsoft"; URL="https://aka.ms/vs/17/release/vc_redist.x64.exe"; Description="Visual C++ Redistributable" }
)

# ==============================================================================
# SCRIPT DATA - COMPLETE MERGED SCRIPTS
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
    [PSCustomObject]@{ Name="read-journal"; Author="wazz1"; URL="https://raw.githubusercontent.com/waaz1/read-journal/refs/heads/main/read-journal.ps1"; Description="read-journal" },
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
# TUTORIAL DATA - INTERACTIVE STEPS (USB removed)
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
    "☑️ Recent Files",
    "☑️ System Cleanup",
    "☑️ Prefetch",
    "☑️ Meow Mod Analyzer",
    "☑️ Habibi Mod Analyzer",
    "☑️ Ghost Client Scanner",
    "☑️ Doomsday Finder v3",
    "☑️ Velaris Scanner",
    "☑️ Cyemer Scanner",
    "☑️ DQRKIS Detector",
    "☑️ Hacked Clients Detector",
    "☑️ Heated Mod Analyzer",
    "☑️ Prestige Finder",
    "☑️ Injector Detector",
    "☑️ Journal Trace",
    "☑️ Review Log"
)

# ==============================================================================
# COMMANDS DATA - Win+R Shortcuts
# ==============================================================================
$CommandData = @(
    [PSCustomObject]@{ Name="Recent Files"; Command="shell:recent"; Description="Open recent files folder"; Icon="📁" },
    [PSCustomObject]@{ Name="Startup Folder"; Command="shell:startup"; Description="Open startup programs folder"; Icon="🚀" },
    [PSCustomObject]@{ Name="Send To"; Command="shell:sendto"; Description="Open Send To folder"; Icon="📤" },
    [PSCustomObject]@{ Name="Start Menu"; Command="shell:start menu"; Description="Open Start Menu folder"; Icon="🏁" },
    [PSCustomObject]@{ Name="Common Startup"; Command="shell:common startup"; Description="Open all users startup"; Icon="🚀" },
    [PSCustomObject]@{ Name="AppData (Roaming)"; Command="%APPDATA%"; Description="Open roaming app data"; Icon="📂" },
    [PSCustomObject]@{ Name="Local AppData"; Command="%LOCALAPPDATA%"; Description="Open local app data"; Icon="📂" },
    [PSCustomObject]@{ Name="Program Files"; Command="%ProgramFiles%"; Description="Open Program Files"; Icon="💻" },
    [PSCustomObject]@{ Name="Program Files (x86)"; Command="%ProgramFiles(x86)%"; Description="Open Program Files (x86)"; Icon="💻" },
    [PSCustomObject]@{ Name="Windows Folder"; Command="%windir%"; Description="Open Windows system folder"; Icon="🪟" },
    [PSCustomObject]@{ Name="System32"; Command="%windir%\System32"; Description="Open System32 folder"; Icon="⚙️" },
    [PSCustomObject]@{ Name="Temp Folder"; Command="%TEMP%"; Description="Open temporary files folder"; Icon="🗑️" },
    [PSCustomObject]@{ Name="Downloads"; Command="%USERPROFILE%\Downloads"; Description="Open Downloads folder"; Icon="⬇️" },
    [PSCustomObject]@{ Name="Desktop"; Command="%USERPROFILE%\Desktop"; Description="Open Desktop folder"; Icon="🖥️" },
    [PSCustomObject]@{ Name="Documents"; Command="%USERPROFILE%\Documents"; Description="Open Documents folder"; Icon="📄" },
    [PSCustomObject]@{ Name="Pictures"; Command="%USERPROFILE%\Pictures"; Description="Open Pictures folder"; Icon="🖼️" },
    [PSCustomObject]@{ Name="Music"; Command="%USERPROFILE%\Music"; Description="Open Music folder"; Icon="🎵" },
    [PSCustomObject]@{ Name="Videos"; Command="%USERPROFILE%\Videos"; Description="Open Videos folder"; Icon="🎬" },
    [PSCustomObject]@{ Name="Prefetch Folder"; Command="C:\Windows\Prefetch"; Description="Open Windows prefetch folder"; Icon="⚡" },
    [PSCustomObject]@{ Name="Network Connections"; Command="ncpa.cpl"; Description="Open network connections"; Icon="🌐" },
    [PSCustomObject]@{ Name="Device Manager"; Command="devmgmt.msc"; Description="Open Device Manager"; Icon="🔧" },
    [PSCustomObject]@{ Name="Disk Management"; Command="diskmgmt.msc"; Description="Open Disk Management"; Icon="💾" },
    [PSCustomObject]@{ Name="Event Viewer"; Command="eventvwr.msc"; Description="Open Event Viewer"; Icon="📊" },
    [PSCustomObject]@{ Name="Services"; Command="services.msc"; Description="Open Services manager"; Icon="⚙️" },
    [PSCustomObject]@{ Name="Registry Editor"; Command="regedit"; Description="Open Registry Editor"; Icon="📝" },
    [PSCustomObject]@{ Name="Task Manager"; Command="taskmgr"; Description="Open Task Manager"; Icon="📊" },
    [PSCustomObject]@{ Name="Control Panel"; Command="control"; Description="Open Control Panel"; Icon="🎛️" },
    [PSCustomObject]@{ Name="System Properties"; Command="sysdm.cpl"; Description="Open System Properties"; Icon="🖥️" },
    [PSCustomObject]@{ Name="Power Options"; Command="powercfg.cpl"; Description="Open Power Options"; Icon="🔋" }
)

# ==============================================================================
# CMD COMMANDS DATA
# ==============================================================================
$CmdCommandData = @(
    [PSCustomObject]@{ Name="System Info"; Command="systeminfo"; Description="Display system information"; Icon="🖥️" },
    [PSCustomObject]@{ Name="IP Config"; Command="ipconfig /all"; Description="Display network configuration"; Icon="🌐" },
    [PSCustomObject]@{ Name="Ping Test"; Command="ping 8.8.8.8 -t"; Description="Continuous ping test"; Icon="📡" },
    [PSCustomObject]@{ Name="Task List"; Command="tasklist"; Description="List running processes"; Icon="📊" },
    [PSCustomObject]@{ Name="Netstat"; Command="netstat -ano"; Description="Display network connections"; Icon="🔌" },
    [PSCustomObject]@{ Name="DNS Flush"; Command="ipconfig /flushdns"; Description="Flush DNS cache"; Icon="🔄" },
    [PSCustomObject]@{ Name="Route Print"; Command="route print"; Description="Display routing table"; Icon="🗺️" },
    [PSCustomObject]@{ Name="ARP Table"; Command="arp -a"; Description="Display ARP table"; Icon="📋" },
    [PSCustomObject]@{ Name="Disk Check"; Command="chkdsk"; Description="Check disk for errors"; Icon="💾" },
    [PSCustomObject]@{ Name="SFC Scan"; Command="sfc /scannow"; Description="Scan system files"; Icon="🔧" },
    [PSCustomObject]@{ Name="DISM Check"; Command="DISM /Online /Cleanup-Image /CheckHealth"; Description="Check image health"; Icon="🛠️" },
    [PSCustomObject]@{ Name="DISM Restore"; Command="DISM /Online /Cleanup-Image /RestoreHealth"; Description="Restore image health"; Icon="💊" },
    [PSCustomObject]@{ Name="Driver List"; Command="driverquery"; Description="List installed drivers"; Icon="⚙️" },
    [PSCustomObject]@{ Name="Boot Config"; Command="bcdedit"; Description="Edit boot configuration"; Icon="🚀" },
    [PSCustomObject]@{ Name="Battery Report"; Command="powercfg /batteryreport"; Description="Generate battery report"; Icon="🔋" },
    [PSCustomObject]@{ Name="WMIC OS"; Command="wmic os get name,version,lastbootuptime"; Description="OS information"; Icon="🪟" },
    [PSCustomObject]@{ Name="WMIC CPU"; Command="wmic cpu get name,numberofcores"; Description="CPU information"; Icon="💻" },
    [PSCustomObject]@{ Name="WMIC Memory"; Command="wmic memorychip get capacity,speed"; Description="Memory information"; Icon="🧠" },
    [PSCustomObject]@{ Name="WMIC Disk"; Command="wmic diskdrive get model,size"; Description="Disk information"; Icon="💾" },
    [PSCustomObject]@{ Name="WMIC BIOS"; Command="wmic bios get manufacturer,version"; Description="BIOS information"; Icon="🔌" },
    [PSCustomObject]@{ Name="WMIC Services"; Command="wmic service get name,state,startmode"; Description="List services"; Icon="⚙️" },
    [PSCustomObject]@{ Name="WMIC Processes"; Command="wmic process get name,processid"; Description="List processes"; Icon="📊" },
    [PSCustomObject]@{ Name="Who Am I"; Command="whoami"; Description="Display current user"; Icon="👤" },
    [PSCustomObject]@{ Name="Hostname"; Command="hostname"; Description="Display computer name"; Icon="🏷️" },
    [PSCustomObject]@{ Name="Uptime"; Command="systeminfo | find ""System Boot Time"""; Description="Show system uptime"; Icon="⏳" },
    [PSCustomObject]@{ Name="Running Services"; Command="net start"; Description="List running services"; Icon="⚙️" },
    [PSCustomObject]@{ Name="Open Ports"; Command="netstat -an | find ""LISTENING"""; Description="List listening ports"; Icon="🔌" },
    [PSCustomObject]@{ Name="DNS Lookup"; Command="nslookup google.com"; Description="DNS lookup test"; Icon="🔍" },
    [PSCustomObject]@{ Name="Trace Route"; Command="tracert google.com"; Description="Trace route to Google"; Icon="🗺️" },
    [PSCustomObject]@{ Name="Local Groups"; Command="net localgroup"; Description="List local groups"; Icon="👥" },
    [PSCustomObject]@{ Name="Administrators"; Command="net localgroup administrators"; Description="List administrators"; Icon="🔑" }
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
    $btn.Margin = "6"
    $btn.Cursor = "Hand"
    $btn.Background = "#151515"
    $btn.BorderBrush = "#262626"
    $btn.BorderThickness = "1"
    $btn.Tag = $Tool
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1
    $scaleTransform.ScaleY = 1
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
    $nameBlock.Foreground = "#F5F5F5"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $author = if ($Tool.Author -and $Tool.Author -ne "") { $Tool.Author } else { "Unknown" }
    $authorBorder = New-Object System.Windows.Controls.Border
    $authorBorder.Background = "#1E1E1E"
    $authorBorder.Padding = "6,2"
    $authorBorder.HorizontalAlignment = "Center"
    $authorBorder.Margin = "0,3,0,0"
    $authorBorder.CornerRadius = "6"
    [System.Windows.Controls.Grid]::SetRow($authorBorder, 1)
    $authorBlock = New-Object System.Windows.Controls.TextBlock
    $authorBlock.Text = "✦ by $author ✦"
    $authorBlock.FontSize = 8
    $authorBlock.FontWeight = "Bold"
    $authorBlock.Foreground = "#8B5CF6"
    $authorBlock.HorizontalAlignment = "Center"
    $authorBlock.VerticalAlignment = "Center"
    $authorBorder.Child = $authorBlock
    [void]$grid.Children.Add($authorBorder)
    $tagBorder = New-Object System.Windows.Controls.Border
    $tagBorder.Background = "#0D0D0D"
    $tagBorder.Padding = "6,1"
    $tagBorder.HorizontalAlignment = "Right"
    $tagBorder.Margin = "0,3,0,0"
    $tagBorder.CornerRadius = "4"
    [System.Windows.Controls.Grid]::SetRow($tagBorder, 2)
    $tagText = New-Object System.Windows.Controls.TextBlock
    $tagText.Text = if ($Tool.Type -eq "launcher") { "LAUNCHER" } else { $Tool.Type.ToUpper() }
    $tagText.FontSize = 7
    $tagText.FontWeight = "Bold"
    $tagText.Foreground = "#EC4899"
    $tagBorder.Child = $tagText
    [void]$grid.Children.Add($tagBorder)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1.05
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1.05
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source
        $toolData = $clickedBtn.Tag
        if (-not $toolData) { return }
        $clickedBtn.IsEnabled = $false
        $clickedBtn.Background = "#1E1E1E"
        $cleanName = $toolData.Name
        $author = if ($toolData.Author -and $toolData.Author -ne "") { $toolData.Author } else { "Unknown" }
        Write-Log "Launching: $cleanName (by $author)"
        $kp = Join-Path $global:installDir $toolData.Category
        $dest = Join-Path $kp $toolData.Name
        if (-not (Test-Path $kp)) { New-Item -ItemType Directory $kp -Force | Out-Null }
        if (Get-ToolStatus $toolData) {
            Write-Log "Already installed: $cleanName"
            Set-Status "Ready" "$cleanName is already installed." "INSTALLED"
            Start-Process explorer.exe $kp
            $clickedBtn.Background = "#151515"
            $clickedBtn.IsEnabled = $true
            return
        }
        Set-Status "Downloading" "Fetching $cleanName by $author..." "BUSY"
        Write-Log "Downloading: $cleanName"
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "ValyaRssTool/1.0")
            $wc.DownloadFile($toolData.URL, $dest)
            $wc.Dispose()
            Write-Log "Download complete"
            if ($toolData.Type -eq "zip") {
                $exD = Join-Path $kp ($toolData.Name -replace "\.zip$","")
                Write-Log "Extracting..."
                if (Expand-ZipSafe $dest $exD) {
                    Remove-Item $dest -Force -EA SilentlyContinue
                    Write-Log "Extraction complete"
                } else {
                    Write-Log "Extraction failed"
                }
            }
            Write-Log "Ready: $cleanName"
            Set-Status "Ready" "$cleanName by $author installed." "DONE"
            Start-Process explorer.exe $kp
        } catch {
            Write-Log "Error: $_"
            Set-Status "Error" "Failed to download $cleanName" "ERROR"
            if(Test-Path $dest){Remove-Item $dest -Force -EA SilentlyContinue}
        }
        $clickedBtn.Background = "#151515"
        $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-ScriptButton {
    param($Script)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "6"
    $btn.Cursor = "Hand"
    $btn.Background = "#151515"
    $btn.BorderBrush = "#262626"
    $btn.BorderThickness = "1"
    $btn.Tag = $Script
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1
    $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = if ($Script.URL -eq "LOCAL") { "🔧 $($Script.Name)" } else { $Script.Name }
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#F5F5F5"
    $nameBlock.FontSize = if ($global:CompactMode) { 10 } else { 11 }
    $nameBlock.TextWrapping = "Wrap"
    $nameBlock.TextAlignment = "Center"
    $nameBlock.VerticalAlignment = "Center"
    $nameBlock.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($nameBlock, 0)
    [void]$grid.Children.Add($nameBlock)
    $authorBorder = New-Object System.Windows.Controls.Border
    $authorBorder.Background = "#1E1E1E"
    $authorBorder.Padding = "6,2"
    $authorBorder.HorizontalAlignment = "Center"
    $authorBorder.Margin = "0,3,0,0"
    $authorBorder.CornerRadius = "6"
    [System.Windows.Controls.Grid]::SetRow($authorBorder, 1)
    $authorBlock = New-Object System.Windows.Controls.TextBlock
    $authorBlock.Text = "✦ by $($Script.Author) ✦"
    $authorBlock.FontSize = 8
    $authorBlock.FontWeight = "Bold"
    $authorBlock.Foreground = if ($Script.URL -eq "LOCAL") { "#EF4444" } else { "#EC4899" }
    $authorBlock.HorizontalAlignment = "Center"
    $authorBlock.VerticalAlignment = "Center"
    $authorBorder.Child = $authorBlock
    [void]$grid.Children.Add($authorBorder)
    $tagBorder = New-Object System.Windows.Controls.Border
    $tagBorder.Background = "#0D0D0D"
    $tagBorder.Padding = "6,1"
    $tagBorder.HorizontalAlignment = "Right"
    $tagBorder.Margin = "0,3,0,0"
    $tagBorder.CornerRadius = "4"
    [System.Windows.Controls.Grid]::SetRow($tagBorder, 2)
    $tagText = New-Object System.Windows.Controls.TextBlock
    $tagText.Text = if ($Script.URL -eq "LOCAL") { "LOCAL" } else { "PS1" }
    $tagText.FontSize = 7
    $tagText.FontWeight = "Bold"
    $tagText.Foreground = if ($Script.URL -eq "LOCAL") { "#EF4444" } else { "#EC4899" }
    $tagBorder.Child = $tagText
    [void]$grid.Children.Add($tagBorder)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1.05
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1.05
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source
        $scriptData = $clickedBtn.Tag
        if (-not $scriptData) { return }
        $clickedBtn.IsEnabled = $false
        $clickedBtn.Background = "#1E1E1E"
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
                    default {
                        Write-Log "Unknown local script: $($scriptData.Name)"
                        Set-Status "Error" "Unknown local script" "ERROR"
                    }
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
        $clickedBtn.Background = "#151515"
        $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-CommandButton {
    param($Command)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "6"
    $btn.Cursor = "Hand"
    $btn.Background = "#151515"
    $btn.BorderBrush = "#262626"
    $btn.BorderThickness = "1"
    $btn.Tag = $Command
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1
    $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = "$($Command.Icon) $($Command.Name)"
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#F5F5F5"
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
    $pathBlock.Foreground = "#8B5CF6"
    $pathBlock.HorizontalAlignment = "Center"
    $pathBlock.VerticalAlignment = "Center"
    $pathBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($pathBlock, 1)
    [void]$grid.Children.Add($pathBlock)
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = $Command.Description
    $descBlock.FontSize = 8
    $descBlock.Foreground = "#525252"
    $descBlock.HorizontalAlignment = "Center"
    $descBlock.VerticalAlignment = "Center"
    $descBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($descBlock, 2)
    [void]$grid.Children.Add($descBlock)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1.05
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1.05
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source
        $cmdData = $clickedBtn.Tag
        if (-not $cmdData) { return }
        $clickedBtn.IsEnabled = $false
        $clickedBtn.Background = "#1E1E1E"
        Write-Log "Opening: $($cmdData.Command) ($($cmdData.Name))"
        Set-Status "Running" "Opening $($cmdData.Name)..." "BUSY"
        try {
            $command = $cmdData.Command
            if ($command -match '^shell:') {
                Start-Process "explorer.exe" -ArgumentList $command
                Write-Log "Opened shell command: $command"
            }
            elseif ($command -match '^%.*%$') {
                $expandedPath = [Environment]::ExpandEnvironmentVariables($command)
                if (Test-Path $expandedPath) {
                    Start-Process "explorer.exe" -ArgumentList $expandedPath
                    Write-Log "Opened: $expandedPath"
                } else {
                    Write-Log "Path not found: $expandedPath"
                    Set-Status "Error" "Path not found: $expandedPath" "ERROR"
                }
            }
            elseif ($command -match '%') {
                $expandedPath = [Environment]::ExpandEnvironmentVariables($command)
                if (Test-Path $expandedPath) {
                    Start-Process "explorer.exe" -ArgumentList $expandedPath
                    Write-Log "Opened: $expandedPath"
                } else {
                    Write-Log "Path not found: $expandedPath"
                    Set-Status "Error" "Path not found: $expandedPath" "ERROR"
                }
            }
            elseif ($command -match '\.(msc|cpl)$') {
                Start-Process $command
                Write-Log "Opened MMC/CPL: $command"
            }
            elseif ($command -match '^(regedit|taskmgr|control|cmd|powershell)') {
                Start-Process $command
                Write-Log "Opened system tool: $command"
            }
            else {
                $expandedPath = [Environment]::ExpandEnvironmentVariables($command)
                if (Test-Path $expandedPath -PathType Container) {
                    Start-Process "explorer.exe" -ArgumentList $expandedPath
                    Write-Log "Opened folder: $expandedPath"
                } elseif (Test-Path $expandedPath -PathType Leaf) {
                    Start-Process "explorer.exe" -ArgumentList "/select,$expandedPath"
                    Write-Log "Selected file: $expandedPath"
                } else {
                    Start-Process "explorer.exe" -ArgumentList $command
                    Write-Log "Attempted to open: $command"
                }
            }
            Write-Log "Opened: $($cmdData.Name)"
            Set-Status "Ready" "$($cmdData.Name) opened." "DONE"
        } catch {
            Write-Log "Error opening: $_"
            Set-Status "Error" "Failed to open $($cmdData.Name)" "ERROR"
        }
        $clickedBtn.Background = "#151515"
        $clickedBtn.IsEnabled = $true
    })
    return $btn
}

function New-CmdCommandButton {
    param($CmdCommand)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Style = $global:window.Resources["ToolBtn"]
    $btn.Width = if ($global:CompactMode) { 160 } else { 205 }
    $btn.Height = if ($global:CompactMode) { 80 } else { 100 }
    $btn.Margin = "6"
    $btn.Cursor = "Hand"
    $btn.Background = "#151515"
    $btn.BorderBrush = "#262626"
    $btn.BorderThickness = "1"
    $btn.Tag = $CmdCommand
    $scaleTransform = New-Object System.Windows.Media.ScaleTransform
    $scaleTransform.ScaleX = 1
    $scaleTransform.ScaleY = 1
    $btn.RenderTransform = $scaleTransform
    $btn.RenderTransformOrigin = "0.5,0.5"
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.Margin = "6"
    $nameBlock = New-Object System.Windows.Controls.TextBlock
    $nameBlock.Text = "$($CmdCommand.Icon) $($CmdCommand.Name)"
    $nameBlock.FontWeight = "SemiBold"
    $nameBlock.Foreground = "#F5F5F5"
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
    $cmdBlock.Foreground = "#EC4899"
    $cmdBlock.HorizontalAlignment = "Center"
    $cmdBlock.VerticalAlignment = "Center"
    $cmdBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($cmdBlock, 1)
    [void]$grid.Children.Add($cmdBlock)
    $descBlock = New-Object System.Windows.Controls.TextBlock
    $descBlock.Text = $CmdCommand.Description
    $descBlock.FontSize = 8
    $descBlock.Foreground = "#525252"
    $descBlock.HorizontalAlignment = "Center"
    $descBlock.VerticalAlignment = "Center"
    $descBlock.Margin = "0,2,0,0"
    [System.Windows.Controls.Grid]::SetRow($descBlock, 2)
    [void]$grid.Children.Add($descBlock)
    $btn.Content = $grid
    $btn.Add_MouseEnter({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1.05
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1.05
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_MouseLeave({
        $b = $_.Source
        $scale = $b.RenderTransform
        $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animX.To = 1
        $animX.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $animX)
        $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animY.To = 1
        $animY.Duration = [TimeSpan]::FromMilliseconds(150)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $animY)
    })
    $btn.Add_Click({
        $clickedBtn = $_.Source
        $cmdData = $clickedBtn.Tag
        if (-not $cmdData) { return }
        $clickedBtn.IsEnabled = $false
        $clickedBtn.Background = "#1E1E1E"
        Write-Log "Running CMD: $($cmdData.Command)"
        Set-Status "Running" "Executing: $($cmdData.Name)..." "BUSY"
        try {
            $cmdArgs = "/k echo [*] Running: $($cmdData.Name) & echo [*] Command: $($cmdData.Command) & echo. & $($cmdData.Command)"
            Start-Process "cmd.exe" -ArgumentList $cmdArgs
            Write-Log "CMD opened: $($cmdData.Name)"
            Set-Status "Ready" "$($cmdData.Name) executed" "DONE"
        } catch {
            Write-Log "Error running command: $_"
            Set-Status "Error" "Failed to run command" "ERROR"
        }
        $clickedBtn.Background = "#151515"
        $clickedBtn.IsEnabled = $true
    })
    return $btn
}

# ==============================================================================
# XAML - COMPLETE UI
# ==============================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ValyaRssTool" Width="1440" Height="900"
        MinWidth="1280" MinHeight="760"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Opacity="1">

    <Window.Resources>
        <SolidColorBrush x:Key="BgDark" Color="#000000"/>
        <SolidColorBrush x:Key="BgPanel" Color="#0D0D0D"/>
        <SolidColorBrush x:Key="BgCard" Color="#151515"/>
        <SolidColorBrush x:Key="BgHover" Color="#1E1E1E"/>
        <SolidColorBrush x:Key="BorderColor" Color="#262626"/>
        <SolidColorBrush x:Key="AccentPurple" Color="#8B5CF6"/>
        <SolidColorBrush x:Key="AccentPink" Color="#EC4899"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#F5F5F5"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#A3A3A3"/>
        <SolidColorBrush x:Key="TextMuted" Color="#525252"/>
        <LinearGradientBrush x:Key="AccentGrad" StartPoint="0,0" EndPoint="1,0">
            <GradientStop Offset="0" Color="#8B5CF6"/>
            <GradientStop Offset="1" Color="#EC4899"/>
        </LinearGradientBrush>
        <DropShadowEffect x:Key="Shadow" BlurRadius="30" ShadowDepth="0" Opacity="0.5" Color="#000000"/>

        <Style x:Key="SideBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#A3A3A3"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Margin" Value="4,2"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderThickness="0" 
                                Margin="2,0"
                                CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" Margin="16,0"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1E1E1E"/>
                                <Setter Property="Foreground" Value="#A78BFA"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TitleBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#737373"/>
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#262626"/>
                                <Setter Property="Foreground" Value="#EC4899"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ToolBtn" TargetType="Button">
            <Setter Property="Background" Value="#151515"/>
            <Setter Property="Foreground" Value="#F5F5F5"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Width" Value="205"/>
            <Setter Property="Height" Value="100"/>
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#262626"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1E1E1E"/>
                                <Setter Property="BorderBrush" Value="#8B5CF6"/>
                                <Setter Property="BorderThickness" Value="2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid x:Name="RootGrid" Background="Transparent">
        <Border Background="#000000" CornerRadius="16" BorderBrush="#262626" BorderThickness="1" Margin="12">
            <Border.Effect><DropShadowEffect BlurRadius="50" ShadowDepth="0" Opacity="0.6" Color="#000000"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="60"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="0,0,0,1" CornerRadius="16,16,0,0">
                    <Grid Margin="20,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border Width="40" Height="40" Background="{StaticResource AccentGrad}" Margin="0,0,12,0" CornerRadius="10">
                                <TextBlock Text="VR" FontSize="15" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel>
                                <TextBlock Text="VALYA RSS TOOL" FontSize="17" FontWeight="Bold" Foreground="#F5F5F5"/>
                                <TextBlock Text="PROFESSIONAL TOOLSET" FontSize="8" Foreground="#8B5CF6"/>
                            </StackPanel>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                            <Border Background="#151515" BorderBrush="#262626" BorderThickness="1" Padding="10,3,14,3" Margin="0,0,12,0" CornerRadius="8">
                                <StackPanel Orientation="Horizontal">
                                    <Ellipse Width="7" Height="7" Fill="#22C55E" Margin="0,0,7,0"/>
                                    <TextBlock Text="CONNECTED" Foreground="#22C55E" FontSize="9" FontWeight="Bold"/>
                                </StackPanel>
                            </Border>
                            <Button x:Name="ThemeToggleBtn" Content="🌙" Style="{StaticResource TitleBtn}" Margin="0,0,3,0" ToolTip="Toggle Theme"/>
                            <Button x:Name="CompactToggleBtn" Content="▦" Style="{StaticResource TitleBtn}" Margin="0,0,3,0" ToolTip="Toggle Compact Mode"/>
                            <Button x:Name="OpenFolderBtn" Content="📂" Style="{StaticResource TitleBtn}" Margin="0,0,3,0"/>
                            <Button x:Name="ClearCacheBtn" Content="🗑️" Style="{StaticResource TitleBtn}" Margin="0,0,3,0"/>
                            <Button x:Name="OpenCmdBtn" Content="⌨" Style="{StaticResource TitleBtn}" Margin="0,0,3,0"/>
                            <Button x:Name="MinBtn" Content="─" Style="{StaticResource TitleBtn}" Margin="0,0,0,0"/>
                            <Button x:Name="CloseBtn" Content="✕" Style="{StaticResource TitleBtn}" Foreground="#EF4444" Margin="6,0,0,0"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="210"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Grid.Column="0" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="0,0,1,0">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                            <StackPanel Margin="10,14">
                                <TextBlock Text="CATEGORIES" FontSize="10" FontWeight="Bold" Foreground="#A78BFA" Margin="14,0,0,10"/>
                                <StackPanel x:Name="CategoryPanel"/>
                                <Separator Background="#262626" Margin="10,14,10,14"/>
                                <TextBlock Text="INSTALL PATH" FontSize="8" FontWeight="Bold" Foreground="#525252" Margin="14,0,0,6"/>
                                <TextBlock x:Name="InstPathBlock" Text="" FontSize="8" Foreground="#A3A3A3" TextWrapping="Wrap" Margin="14,0,0,0"/>
                                <Border Height="2" Width="40" Background="{StaticResource AccentGrad}" Margin="14,14,0,0" HorizontalAlignment="Left" CornerRadius="1"/>
                            </StackPanel>
                        </ScrollViewer>
                    </Border>

                    <Grid Grid.Column="1" Margin="16,14,16,16">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="10"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="10"/>
                            <RowDefinition Height="140"/>
                        </Grid.RowDefinitions>

                        <Border Grid.Row="0" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="1" Padding="16,10" CornerRadius="12">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock x:Name="StatusTitle" Text="Ready" FontSize="17" FontWeight="SemiBold" Foreground="#F5F5F5"/>
                                    <TextBlock x:Name="StatusSub" Text="Select a tool or script from the sidebar." FontSize="11" Foreground="#A3A3A3"/>
                                </StackPanel>
                                <Border Grid.Column="1" Background="#151515" BorderBrush="#262626" BorderThickness="1" Padding="12,4" VerticalAlignment="Center" CornerRadius="8">
                                    <TextBlock x:Name="StatusBadge" Text="IDLE" FontSize="10" FontWeight="Bold" Foreground="#8B5CF6"/>
                                </Border>
                            </Grid>
                        </Border>

                        <Border Grid.Row="1" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="1" Padding="12,8" CornerRadius="12">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="SearchBox" Background="#151515" Foreground="#F5F5F5" BorderBrush="#262626" BorderThickness="1" FontSize="12" Padding="10,7" CornerRadius="8"/>
                                <Button Grid.Column="1" Content="✕" Background="Transparent" Foreground="#525252" BorderThickness="0" Width="32" Height="32" Cursor="Hand" x:Name="ClearSearchBtn" Visibility="Collapsed"/>
                            </Grid>
                        </Border>

                        <Border Grid.Row="3" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="1" Padding="8" CornerRadius="12">
                            <ScrollViewer x:Name="CenterScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                <WrapPanel x:Name="ToolsWrap" Margin="4"/>
                            </ScrollViewer>
                        </Border>

                        <Border Grid.Row="5" Background="#0D0D0D" BorderBrush="#262626" BorderThickness="1" Padding="12,8" CornerRadius="12">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Text="ACTIVITY LOG" FontSize="9" FontWeight="Bold" Foreground="#A78BFA" FontFamily="Consolas" Margin="0,0,0,4"/>
                                <TextBox x:Name="LogBox" Grid.Row="1" Background="Transparent" Foreground="#EC4899" BorderThickness="0" FontFamily="Consolas" FontSize="10" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
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
            $child.Foreground = "#A3A3A3"
        }
    }
    if ($activeBtn) {
        $activeBtn.Background = "#1E1E1E"
        $activeBtn.Foreground = "#A78BFA"
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
        $card.Background = "#0D0D0D"; $card.BorderBrush = "#262626"; $card.BorderThickness = "1"
        $card.Margin = "8"; $card.Width = 380; $card.Height = 85; $card.Cursor = "Hand"; $card.Tag = $cat
        $card.CornerRadius = "12"
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "14,10"
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $catName = New-Object System.Windows.Controls.TextBlock
        $catName.Text = $cat; $catName.FontSize = 15; $catName.FontWeight = "SemiBold"
        $catName.Foreground = "#F5F5F5"; $catName.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetRow($catName, 0)
        [void]$grid.Children.Add($catName)
        $infoText = New-Object System.Windows.Controls.TextBlock
        if ($cat -eq "Commands") { $statusColor = "#8B5CF6"; $statusText = "⚡ $count quick commands" }
        elseif ($cat -eq "Cmd Commands") { $statusColor = "#EC4899"; $statusText = "⌨️ $count CMD commands" }
        else {
            $statusColor = if ($installed -eq $count) { "#22C55E" } elseif ($installed -gt 0) { "#8B5CF6" } else { "#525252" }
            $statusText = if ($installed -eq $count) { "✓ Complete" } elseif ($installed -gt 0) { "⟳ $installed/$count" } else { "✗ None" }
        }
        $infoText.Text = $statusText; $infoText.FontSize = 10; $infoText.Foreground = $statusColor
        $infoText.HorizontalAlignment = "Right"; $infoText.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetRow($infoText, 0); [System.Windows.Controls.Grid]::SetColumn($infoText, 1)
        [void]$grid.Children.Add($infoText)
        $progBg = New-Object System.Windows.Controls.Border; $progBg.Background = "#1E1E1E"; $progBg.Height = 4
        [System.Windows.Controls.Grid]::SetRow($progBg, 1); [System.Windows.Controls.Grid]::SetColumnSpan($progBg, 2)
        [void]$grid.Children.Add($progBg)
        $progFill = New-Object System.Windows.Controls.Border
        if ($cat -eq "Commands" -or $cat -eq "Cmd Commands") { $progFill.Background = "#8B5CF6"; $progFill.Width = 370 }
        else { $progFill.Background = if ($installed -eq $count) { "#22C55E" } else { "#8B5CF6" }; $progFill.Width = if ($count -gt 0) { [Math]::Max(2, ($installed / $count) * 370) } else { 0 } }
        $progFill.Height = 4; $progFill.HorizontalAlignment = "Left"
        [System.Windows.Controls.Grid]::SetRow($progFill, 1); [System.Windows.Controls.Grid]::SetColumnSpan($progFill, 2)
        [void]$grid.Children.Add($progFill)
        $desc = New-Object System.Windows.Controls.TextBlock
        if ($cat -eq "Commands") { $desc.Text = "$count Win+R shortcuts available" }
        elseif ($cat -eq "Cmd Commands") { $desc.Text = "$count CMD/PowerShell commands" }
        else { $desc.Text = "$count tools • $installed installed" }
        $desc.FontSize = 9; $desc.Foreground = "#525252"; $desc.Margin = "0,4,0,0"
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
        $card.Background = "#151515"
        $card.BorderBrush = "#262626"
        $card.BorderThickness = "1"
        $card.Margin = "0,0,0,15"
        $card.CornerRadius = "12"
        $card.Padding = "15"
        
        $innerStack = New-Object System.Windows.Controls.StackPanel
        
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "🔍 SCREEN SHARE TUTORIAL – Click each button to run the tool"
        $titleBlock.FontSize = "16"
        $titleBlock.FontWeight = "Bold"
        $titleBlock.Foreground = "#8B5CF6"
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
            $stepText.Foreground = "#F5F5F5"
            $stepText.TextWrapping = "Wrap"
            $stepText.VerticalAlignment = "Center"
            $stepText.Margin = "0,0,10,0"
            [System.Windows.Controls.Grid]::SetColumn($stepText, 0)
            [void]$grid.Children.Add($stepText)
            
            if ($action.Type -ne "Info") {
                $btn = $null
                if ($action.Type -eq "Command") {
                    $cmdObj = $CommandData | Where-Object { $_.Name -eq $action.Name } | Select-Object -First 1
                    if ($cmdObj) {
                        $btn = New-CommandButton -Command $cmdObj
                    }
                } elseif ($action.Type -eq "Script") {
                    $scriptObj = $ScriptData | Where-Object { $_.Name -eq $action.Name } | Select-Object -First 1
                    if ($scriptObj) {
                        $btn = New-ScriptButton -Script $scriptObj
                    }
                }
                if ($btn) {
                    $btn.Width = 140
                    $btn.Height = 30
                    $btn.FontSize = 10
                    $btn.Margin = "5,0,0,0"
                    $btn.HorizontalAlignment = "Right"
                    [System.Windows.Controls.Grid]::SetColumn($btn, 1)
                    [void]$grid.Children.Add($btn)
                }
            } else {
                $badge = New-Object System.Windows.Controls.Border
                $badge.Background = "#1E1E1E"
                $badge.BorderBrush = "#8B5CF6"
                $badge.BorderThickness = "1"
                $badge.CornerRadius = "8"
                $badge.Padding = "6,2"
                $badge.HorizontalAlignment = "Right"
                $badge.Margin = "5,0,0,0"
                $badgeText = New-Object System.Windows.Controls.TextBlock
                $badgeText.Text = "📋 Manual"
                $badgeText.Foreground = "#8B5CF6"
                $badgeText.FontSize = "10"
                $badgeText.FontWeight = "Bold"
                $badge.Child = $badgeText
                [System.Windows.Controls.Grid]::SetColumn($badge, 1)
                [void]$grid.Children.Add($badge)
            }
            [void]$innerStack.Children.Add($grid)
        }
        
        $card.Child = $innerStack
        [void]$tutPanel.Children.Add($card)
        
        $checkCard = New-Object System.Windows.Controls.Border
        $checkCard.Background = "#151515"
        $checkCard.BorderBrush = "#262626"
        $checkCard.BorderThickness = "1"
        $checkCard.Margin = "0,0,0,15"
        $checkCard.CornerRadius = "12"
        $checkCard.Padding = "15"
        
        $checkStack = New-Object System.Windows.Controls.StackPanel
        $checkTitle = New-Object System.Windows.Controls.TextBlock
        $checkTitle.Text = "⚡ QUICK CHECKLIST"
        $checkTitle.FontSize = "16"
        $checkTitle.FontWeight = "Bold"
        $checkTitle.Foreground = "#EC4899"
        $checkTitle.Margin = "0,0,0,8"
        [void]$checkStack.Children.Add($checkTitle)
        
        foreach ($item in $TutorialChecklist) {
            $itemBlock = New-Object System.Windows.Controls.TextBlock
            $itemBlock.Text = $item
            $itemBlock.FontSize = "12"
            $itemBlock.Foreground = "#F5F5F5"
            $itemBlock.Margin = "0,2,0,2"
            [void]$checkStack.Children.Add($itemBlock)
        }
        
        $checkCard.Child = $checkStack
        [void]$tutPanel.Children.Add($checkCard)
        
        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = "Auto"
        $scroll.HorizontalScrollBarVisibility = "Disabled"
        $scroll.Content = $tutPanel
        $scroll.Height = 550
        [void]$global:ToolsWrap.Children.Add($scroll)
        return
    }
    
    if ($cat -eq "Commands") {
        foreach ($cmd in $CommandData) {
            $btn = New-CommandButton -Command $cmd
            [void]$global:ToolsWrap.Children.Add($btn)
        }
        return
    }
    
    if ($cat -eq "Cmd Commands") {
        foreach ($cmd in $CmdCommandData) {
            $btn = New-CmdCommandButton -CmdCommand $cmd
            [void]$global:ToolsWrap.Children.Add($btn)
        }
        return
    }
    
    $catTools = @($ToolData | Where-Object { $_.Category -eq $cat })
    foreach ($tool in $catTools) {
        $btn = New-ToolButton -Tool $tool
        [void]$global:ToolsWrap.Children.Add($btn)
    }
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
    foreach ($script in $ScriptData) {
        $btn = New-ScriptButton -Script $script
        [void]$global:ToolsWrap.Children.Add($btn)
    }
}

function Build-Sidebar {
    if (-not $global:CategoryPanel) { return }
    $global:CategoryPanel.Children.Clear()
    $overviewBtn = New-Object System.Windows.Controls.Button
    $overviewBtn.Content = "⭐ Overview"
    $overviewBtn.Style = $global:window.Resources["SideBtn"]
    $overviewBtn.Tag = "overview"
    $overviewBtn.Add_Click({ Show-Overview })
    [void]$global:CategoryPanel.Children.Add($overviewBtn)
    $scriptBtn = New-Object System.Windows.Controls.Button
    $scriptBtn.Content = "📜 Scripts"
    $scriptBtn.Style = $global:window.Resources["SideBtn"]
    $scriptBtn.Tag = "scripts"
    $scriptBtn.Add_Click({ Show-Scripts })
    [void]$global:CategoryPanel.Children.Add($scriptBtn)
    foreach ($cat in $categories) {
        $catBtn = New-Object System.Windows.Controls.Button
        $catBtn.Content = "📁 $cat"
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
                Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "Write-Host 'ValyaRssTool PowerShell Console' -ForegroundColor Magenta; Write-Host 'Type your commands below:' -ForegroundColor Cyan"
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
                $global:ThemeToggleBtn.Content = "🌙"
                $global:RootGrid.Background = "Transparent"
                Set-Status "Dark Theme" "Switched to dark theme" "DARK"
            } else {
                $global:ThemeToggleBtn.Content = "☀️"
                $global:RootGrid.Background = "#F0F0F5"
                Set-Status "Light Theme" "Switched to light theme" "LIGHT"
            }
        })
    }
    if ($global:CompactToggleBtn) {
        $global:CompactToggleBtn.Add_Click({
            $global:CompactMode = -not $global:CompactMode
            if ($global:CompactMode) {
                $global:CompactToggleBtn.Content = "▣"
                $global:CompactToggleBtn.Foreground = "#8B5CF6"
                Set-Status "Compact Mode" "Tool buttons resized to compact mode" "COMPACT"
            } else {
                $global:CompactToggleBtn.Content = "▦"
                $global:CompactToggleBtn.Foreground = "#737373"
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

Write-Log "ValyaRssTool v1.0 ready - ALL SCANNERS MERGED"
Write-Log "Install location: $global:installDir"
Write-Log "Total tools: $($ToolData.Count) | Total scripts: $($ScriptData.Count)"
Write-Log "FIXES: All scanners now work locally (no 404 errors), hover fixed, Tutorial added, USB removed"
Set-Status "Ready" "✦ All scanners merged! Doomsday, Ghost, Cyemer, Velaris, Heated, DQRKIS" "IDLE"

if ($global:window) {
    $global:window.ShowDialog() | Out-Null
} else {
    Write-Host "Window failed to initialize." -ForegroundColor Red
    Read-Host "Press Enter to exit"
}

Write-Log "Session ended."
