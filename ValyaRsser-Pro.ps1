# ╔════════════════════════════════════════════════════════════════════════════╗
# ║              VALYAR RSS TOOL PRO - MERGED WITH CHEESY SS TOOL             ║
# ║                         Modern Dark Theme GUI                              ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# Requires -RunAsAdministrator

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.GC]::Collect()

# ──────────────────────────────────────────────────────────────────────────────
# GLOBAL CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────

$global:scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$global:installDir = "$env:USERPROFILE\Downloads\ValyaRssTool"
$global:dataDir = Join-Path $global:installDir "data"
$global:logPath = Join-Path $env:TEMP "valyarss.log"
$global:feedsFile = Join-Path $global:dataDir "feeds.json"
$global:settingsFile = Join-Path $global:dataDir "settings.json"

# Theme & UI Configuration
$global:DarkTheme = @{
    Background = "#1E1E1E"
    Foreground = "#FFFFFF"
    CardBg = "#2D2D2D"
    Accent = "#00D4FF"
    AccentHover = "#00B8D4"
    Success = "#00FF41"
    Error = "#FF006E"
    Warning = "#FFB700"
    Muted = "#808080"
    Border = "#404040"
}

# ──────────────────────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────────

function Initialize-Directories {
    if (-not (Test-Path $global:installDir)) {
        New-Item -ItemType Directory -Path $global:installDir -Force | Out-Null
    }
    if (-not (Test-Path $global:dataDir)) {
        New-Item -ItemType Directory -Path $global:dataDir -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:logPath -Value $logEntry -Force
    
    if ($global:LogTextBox -and $global:LogTextBox.Dispatcher) {
        $global:LogTextBox.Dispatcher.Invoke([Action]{
            $global:LogTextBox.AppendText("$logEntry`r`n")
            $global:LogTextBox.ScrollToEnd()
        })
    }
}

function Load-Settings {
    if (Test-Path $global:settingsFile) {
        try {
            $global:Settings = Get-Content -Path $global:settingsFile | ConvertFrom-Json
        } catch {
            Write-Log "Failed to load settings: $_" "ERROR"
            $global:Settings = @{
                UpdateInterval = 15
                MaxFeeds = 50
                Theme = "Dark"
                AutoUpdate = $true
            }
        }
    } else {
        $global:Settings = @{
            UpdateInterval = 15
            MaxFeeds = 50
            Theme = "Dark"
            AutoUpdate = $true
        }
        Save-Settings
    }
}

function Save-Settings {
    try {
        $global:Settings | ConvertTo-Json | Set-Content -Path $global:settingsFile -Force
        Write-Log "Settings saved successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to save settings: $_" "ERROR"
    }
}

function Load-Feeds {
    if (Test-Path $global:feedsFile) {
        try {
            $global:Feeds = Get-Content -Path $global:feedsFile | ConvertFrom-Json
        } catch {
            Write-Log "Failed to load feeds: $_" "ERROR"
            $global:Feeds = @()
        }
    } else {
        $global:Feeds = @()
    }
}

function Save-Feeds {
    try {
        $global:Feeds | ConvertTo-Json | Set-Content -Path $global:feedsFile -Force
        Write-Log "Feeds saved successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to save feeds: $_" "ERROR"
    }
}

function Add-Feed {
    param([string]$URL, [string]$Name)
    
    if ([string]::IsNullOrWhiteSpace($URL) -or [string]::IsNullOrWhiteSpace($Name)) {
        Write-Log "Feed URL or Name is empty" "ERROR"
        return $false
    }
    
    try {
        $feed = @{
            ID = [guid]::NewGuid().ToString()
            Name = $Name
            URL = $URL
            Added = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            LastUpdate = $null
            Articles = @()
        }
        $global:Feeds += $feed
        Save-Feeds
        Write-Log "Feed added: $Name" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to add feed: $_" "ERROR"
        return $false
    }
}

function Remove-Feed {
    param([string]$FeedID)
    
    $global:Feeds = $global:Feeds | Where-Object { $_.ID -ne $FeedID }
    Save-Feeds
    Write-Log "Feed removed: $FeedID" "SUCCESS"
}

function Fetch-RSS {
    param([string]$URL)
    
    try {
        $web = New-Object System.Net.WebClient
        $web.Encoding = [System.Text.Encoding]::UTF8
        $xml = [xml]$web.DownloadString($URL)
        
        $articles = @()
        foreach ($item in $xml.rss.channel.item) {
            $articles += @{
                Title = $item.title
                Link = $item.link
                Description = $item.description
                PubDate = $item.pubDate
            }
        }
        return $articles
    } catch {
        Write-Log "Failed to fetch RSS from $URL : $_" "ERROR"
        return @()
    }
}

function Update-AllFeeds {
    Write-Log "Starting feed update..." "INFO"
    
    foreach ($feed in $global:Feeds) {
        $articles = Fetch-RSS -URL $feed.URL
        $feed.Articles = $articles
        $feed.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Save-Feeds
    Write-Log "All feeds updated successfully" "SUCCESS"
}

# ──────────────────────────────────────────────────────────────────────────────
# UI FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────────

function Create-DarkButton {
    param(
        [string]$Content,
        [scriptblock]$OnClick,
        [int]$Width = 120,
        [int]$Height = 35
    )
    
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $Content
    $button.Width = $Width
    $button.Height = $Height
    $button.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $button.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $button.BorderThickness = [System.Windows.Thickness]::Parse("1")
    $button.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $button.FontSize = 12
    $button.FontFamily = "Segoe UI"
    $button.Cursor = "Hand"
    
    $button.add_Click($OnClick)
    
    $button.add_MouseEnter({
        $this.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
        $this.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    })
    
    $button.add_MouseLeave({
        $this.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
        $this.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    })
    
    return $button
}

function Create-DarkTextBox {
    param(
        [string]$Placeholder = "",
        [int]$Height = 35,
        [int]$Width = 250
    )
    
    $textBox = New-Object System.Windows.Controls.TextBox
    $textBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $textBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $textBox.BorderThickness = [System.Windows.Thickness]::Parse("1")
    $textBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $textBox.Height = $Height
    $textBox.Width = $Width
    $textBox.Padding = [System.Windows.Thickness]::Parse("8")
    $textBox.FontSize = 12
    $textBox.FontFamily = "Segoe UI"
    
    if ($Placeholder) {
        $textBox.add_GotFocus({
            if ($this.Text -eq $Placeholder) {
                $this.Text = ""
                $this.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
            }
        })
        
        $textBox.add_LostFocus({
            if ([string]::IsNullOrWhiteSpace($this.Text)) {
                $this.Text = $Placeholder
                $this.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Muted)
            }
        })
        
        $textBox.Text = $Placeholder
        $textBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Muted)
    }
    
    return $textBox
}

function Show-MainWindow {
    # Create main window
    $mainWindow = New-Object System.Windows.Window
    $mainWindow.Title = "🔗 ValyaRsser Pro - RSS Aggregator"
    $mainWindow.Width = 1200
    $mainWindow.Height = 700
    $mainWindow.WindowStartupLocation = "CenterScreen"
    $mainWindow.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $mainWindow.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $mainWindow.FontFamily = "Segoe UI"
    $mainWindow.Icon = $null
    
    # Create main grid
    $mainGrid = New-Object System.Windows.Controls.Grid
    $mainGrid.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    
    # Define rows
    $row0 = New-Object System.Windows.Controls.RowDefinition
    $row0.Height = 80
    $row1 = New-Object System.Windows.Controls.RowDefinition
    $row1.Height = "*"
    $row2 = New-Object System.Windows.Controls.RowDefinition
    $row2.Height = 150
    
    $mainGrid.RowDefinitions.Add($row0)
    $mainGrid.RowDefinitions.Add($row1)
    $mainGrid.RowDefinitions.Add($row2)
    
    # ──────── HEADER ────────
    $headerPanel = New-Object System.Windows.Controls.StackPanel
    $headerPanel.Orientation = "Vertical"
    $headerPanel.Margin = [System.Windows.Thickness]::Parse("15")
    $headerPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    
    $titleLabel = New-Object System.Windows.Controls.Label
    $titleLabel.Content = "📰 RSS Feed Aggregator Pro"
    $titleLabel.FontSize = 18
    $titleLabel.FontWeight = "Bold"
    $titleLabel.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    
    $headerPanel.Children.Add($titleLabel)
    [System.Windows.Controls.Grid]::SetRow($headerPanel, 0)
    $mainGrid.Children.Add($headerPanel)
    
    # ──────── CONTENT AREA ────────
    $contentTabControl = New-Object System.Windows.Controls.TabControl
    $contentTabControl.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $contentTabControl.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    # Tab 1: Feeds
    $feedsTab = New-Object System.Windows.Controls.TabItem
    $feedsTab.Header = "📚 My Feeds"
    $feedsTab.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $feedsTab.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    $feedsStackPanel = New-Object System.Windows.Controls.StackPanel
    $feedsStackPanel.Orientation = "Vertical"
    $feedsStackPanel.Margin = [System.Windows.Thickness]::Parse("10")
    
    $feedsListBox = New-Object System.Windows.Controls.ListBox
    $feedsListBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $feedsListBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $feedsListBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $feedsListBox.Height = 200
    
    $global:FeedsListBox = $feedsListBox
    
    # Populate feeds list
    foreach ($feed in $global:Feeds) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = "$($feed.Name) - $($feed.URL)"
        $item.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
        $item.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
        $item.Tag = $feed.ID
        $feedsListBox.Items.Add($item)
    }
    
    $feedsStackPanel.Children.Add($feedsListBox)
    $feedsTab.Content = $feedsStackPanel
    $contentTabControl.Items.Add($feedsTab)
    
    # Tab 2: Articles
    $articlesTab = New-Object System.Windows.Controls.TabItem
    $articlesTab.Header = "📄 Articles"
    $articlesTab.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $articlesTab.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    $articlesListBox = New-Object System.Windows.Controls.ListBox
    $articlesListBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $articlesListBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $articlesListBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    
    $global:ArticlesListBox = $articlesListBox
    $articlesTab.Content = $articlesListBox
    $contentTabControl.Items.Add($articlesTab)
    
    # Tab 3: Settings
    $settingsTab = New-Object System.Windows.Controls.TabItem
    $settingsTab.Header = "⚙️ Settings"
    $settingsTab.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $settingsTab.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    $settingsPanel = New-Object System.Windows.Controls.StackPanel
    $settingsPanel.Orientation = "Vertical"
    $settingsPanel.Margin = [System.Windows.Thickness]::Parse("15")
    
    $updateIntervalLabel = New-Object System.Windows.Controls.Label
    $updateIntervalLabel.Content = "Update Interval (minutes):"
    $updateIntervalLabel.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    $updateIntervalSpinner = New-Object System.Windows.Controls.TextBox
    $updateIntervalSpinner.Text = $global:Settings.UpdateInterval.ToString()
    $updateIntervalSpinner.Width = 100
    $updateIntervalSpinner.Height = 30
    $updateIntervalSpinner.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $updateIntervalSpinner.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $updateIntervalSpinner.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    
    $settingsPanel.Children.Add($updateIntervalLabel)
    $settingsPanel.Children.Add($updateIntervalSpinner)
    
    $settingsTab.Content = $settingsPanel
    $contentTabControl.Items.Add($settingsTab)
    
    [System.Windows.Controls.Grid]::SetRow($contentTabControl, 1)
    $mainGrid.Children.Add($contentTabControl)
    
    # ──────── BOTTOM PANEL (Controls + Log) ────────
    $bottomPanel = New-Object System.Windows.Controls.Grid
    $bottomPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    
    $col0 = New-Object System.Windows.Controls.ColumnDefinition
    $col0.Width = "*"
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = 300
    
    $bottomPanel.ColumnDefinitions.Add($col0)
    $bottomPanel.ColumnDefinitions.Add($col1)
    
    # Log area
    $logLabel = New-Object System.Windows.Controls.Label
    $logLabel.Content = "📋 Activity Log:"
    $logLabel.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    $logLabel.FontWeight = "Bold"
    
    $logTextBox = New-Object System.Windows.Controls.TextBox
    $logTextBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $logTextBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Success)
    $logTextBox.IsReadOnly = $true
    $logTextBox.VerticalScrollBarVisibility = "Auto"
    $logTextBox.TextWrapping = "Wrap"
    $logTextBox.Height = 100
    $logTextBox.Margin = [System.Windows.Thickness]::Parse("5")
    
    $global:LogTextBox = $logTextBox
    
    $logStackPanel = New-Object System.Windows.Controls.StackPanel
    $logStackPanel.Orientation = "Vertical"
    $logStackPanel.Children.Add($logLabel)
    $logStackPanel.Children.Add($logTextBox)
    
    [System.Windows.Controls.Grid]::SetColumn($logStackPanel, 0)
    $bottomPanel.Children.Add($logStackPanel)
    
    # Button area
    $buttonStackPanel = New-Object System.Windows.Controls.StackPanel
    $buttonStackPanel.Orientation = "Vertical"
    $buttonStackPanel.Margin = [System.Windows.Thickness]::Parse("10")
    $buttonStackPanel.VerticalAlignment = "Center"
    
    $addFeedButton = Create-DarkButton -Content "➕ Add Feed" -Width 120 -Height 35 -OnClick {
        Show-AddFeedWindow
    }
    
    $updateButton = Create-DarkButton -Content "🔄 Update All" -Width 120 -Height 35 -OnClick {
        Update-AllFeeds
        Refresh-FeedsList
    }
    
    $removeFeedButton = Create-DarkButton -Content "❌ Remove" -Width 120 -Height 35 -OnClick {
        if ($global:FeedsListBox.SelectedItem) {
            $feedID = $global:FeedsListBox.SelectedItem.Tag
            Remove-Feed -FeedID $feedID
            Refresh-FeedsList
        }
    }
    
    $buttonStackPanel.Children.Add($addFeedButton)
    $buttonStackPanel.Children.Add($updateButton)
    $buttonStackPanel.Children.Add($removeFeedButton)
    
    [System.Windows.Controls.Grid]::SetColumn($buttonStackPanel, 1)
    $bottomPanel.Children.Add($buttonStackPanel)
    
    [System.Windows.Controls.Grid]::SetRow($bottomPanel, 2)
    $mainGrid.Children.Add($bottomPanel)
    
    $mainWindow.Content = $mainGrid
    
    Write-Log "Main window loaded successfully" "SUCCESS"
    $mainWindow.ShowDialog() | Out-Null
}

function Show-AddFeedWindow {
    $addWindow = New-Object System.Windows.Window
    $addWindow.Title = "➕ Add New Feed"
    $addWindow.Width = 500
    $addWindow.Height = 250
    $addWindow.WindowStartupLocation = "CenterOwner"
    $addWindow.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $addWindow.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::Parse("15")
    
    # Row definitions
    for ($i = 0; $i -lt 6; $i++) {
        $row = New-Object System.Windows.Controls.RowDefinition
        $row.Height = "Auto"
        $grid.RowDefinitions.Add($row)
    }
    
    # Feed Name
    $nameLabel = New-Object System.Windows.Controls.Label
    $nameLabel.Content = "Feed Name:"
    $nameLabel.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    [System.Windows.Controls.Grid]::SetRow($nameLabel, 0)
    $grid.Children.Add($nameLabel)
    
    $nameBox = Create-DarkTextBox -Placeholder "Enter feed name" -Width 400
    [System.Windows.Controls.Grid]::SetRow($nameBox, 1)
    $grid.Children.Add($nameBox)
    
    # Feed URL
    $urlLabel = New-Object System.Windows.Controls.Label
    $urlLabel.Content = "Feed URL:"
    $urlLabel.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    [System.Windows.Controls.Grid]::SetRow($urlLabel, 2)
    $grid.Children.Add($urlLabel)
    
    $urlBox = Create-DarkTextBox -Placeholder "Enter RSS feed URL" -Width 400
    [System.Windows.Controls.Grid]::SetRow($urlBox, 3)
    $grid.Children.Add($urlBox)
    
    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Right"
    $buttonPanel.Margin = [System.Windows.Thickness]::Parse("0,20,0,0")
    
    $addButton = Create-DarkButton -Content "✅ Add" -Width 100 -OnClick {
        $name = $nameBox.Text
        $url = $urlBox.Text
        
        if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($url)) {
            [System.Windows.MessageBox]::Show("Please fill in all fields", "Error", "OK", "Error")
            return
        }
        
        if (Add-Feed -URL $url -Name $name) {
            [System.Windows.MessageBox]::Show("Feed added successfully!", "Success", "OK", "Information")
            Refresh-FeedsList
            $addWindow.Close()
        } else {
            [System.Windows.MessageBox]::Show("Failed to add feed", "Error", "OK", "Error")
        }
    }
    
    $cancelButton = Create-DarkButton -Content "❌ Cancel" -Width 100 -OnClick {
        $addWindow.Close()
    }
    
    $buttonPanel.Children.Add($addButton)
    $buttonPanel.Children.Add($cancelButton)
    
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 5)
    $grid.Children.Add($buttonPanel)
    
    $addWindow.Content = $grid
    $addWindow.ShowDialog() | Out-Null
}

function Refresh-FeedsList {
    Load-Feeds
    $global:FeedsListBox.Items.Clear()
    
    foreach ($feed in $global:Feeds) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = "$($feed.Name) - $($feed.URL)"
        $item.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
        $item.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
        $item.Tag = $feed.ID
        $global:FeedsListBox.Items.Add($item)
    }
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ──────────────────────────────────────────────────────────────────────────────

function Main {
    Initialize-Directories
    Load-Settings
    Load-Feeds
    
    Write-Log "ValyaRsser Pro started" "SUCCESS"
    Write-Log "Config Directory: $global:installDir" "INFO"
    
    Show-MainWindow
}

# Run main function
Main
