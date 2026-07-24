# ╔════════════════════════════════════════════════════════════════════════════╗
# ║              VALYAR RSS TOOL PRO - MERGED WITH CHEESY SS TOOL             ║
# ║                         Modern Dark Theme GUI                              ║
# ║                    https://github.com/Va2lyR/ValyaRssTool                 ║
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

$global:Fonts = @{
    Title = "Segoe UI"
    Normal = "Segoe UI"
    Mono = "Consolas"
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
    Add-Content -Path $global:logPath -Value $logEntry -ErrorAction SilentlyContinue
    
    if ($global:LogTextBox -and $global:LogTextBox.Dispatcher) {
        $global:LogTextBox.Dispatcher.Invoke([Action]{
            $global:LogTextBox.AppendText("$logEntry`r`n")
            $global:LogTextBox.ScrollToEnd()
        }, $null)
    }
}

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Type = "Info"
    )
    
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, 
        @{Info=0; Warning=1; Error=2}[$Type]) | Out-Null
}

function Update-StatusBar {
    param([string]$Status, [string]$Color = "#00FF41")
    if ($global:StatusLabel -and $global:StatusLabel.Dispatcher) {
        $global:StatusLabel.Dispatcher.Invoke([Action]{
            $global:StatusLabel.Content = $Status
            $global:StatusLabel.Foreground = [System.Windows.Media.Brush]::Parse($Color)
        }, $null)
    }
}

# ──────────────────────────────────────────────────────────────────────────────
# RSS FEED MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

function Get-RssFeeds {
    if (Test-Path $global:feedsFile) {
        $feeds = Get-Content $global:feedsFile -Raw | ConvertFrom-Json
        return $feeds
    }
    return @()
}

function Save-RssFeeds {
    param([array]$Feeds)
    $Feeds | ConvertTo-Json | Set-Content -Path $global:feedsFile
}

function Add-RssFeed {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Category = "General"
    )
    
    $feeds = Get-RssFeeds
    $newFeed = @{
        Id = [guid]::NewGuid().ToString()
        Name = $Name
        Url = $Url
        Category = $Category
        Added = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        LastUpdate = $null
        ItemCount = 0
    }
    
    $feeds += $newFeed
    Save-RssFeeds $feeds
    Write-Log "Feed added: $Name ($Url)" "SUCCESS"
    return $newFeed
}

function Remove-RssFeed {
    param([string]$FeedId)
    $feeds = Get-RssFeeds
    $feeds = $feeds | Where-Object { $_.Id -ne $FeedId }
    Save-RssFeeds $feeds
    Write-Log "Feed removed: $FeedId" "SUCCESS"
}

function Update-RssFeed {
    param([string]$Url)
    
    try {
        Update-StatusBar "جاري التحديث..." "#FFB700"
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10
        $xmlContent = [xml]$response.Content
        
        $items = $xmlContent.rss.channel.item | Select-Object -First 10
        Update-StatusBar "تم التحديث بنجاح!" "#00FF41"
        Write-Log "Feed updated successfully: $Url" "SUCCESS"
        
        return $items
    }
    catch {
        Update-StatusBar "خطأ في التحديث" "#FF006E"
        Write-Log "Error updating feed: $_" "ERROR"
        return $null
    }
}

function Get-AllFeeds {
    $feeds = Get-RssFeeds
    $allItems = @()
    
    foreach ($feed in $feeds) {
        $items = Update-RssFeed $feed.Url
        if ($items) {
            $allItems += $items | Add-Member -NotePropertyName "FeedName" -NotePropertyValue $feed.Name -PassThru
        }
    }
    
    return $allItems | Sort-Object pubDate -Descending
}

# ──────────────────────────────────────────────────────────────────────────────
# UI COMPONENTS & STYLING
# ──────────────────────────────────────────────────────────────────────────────

function New-ModernButton {
    param(
        [string]$Text,
        [int]$Width = 120,
        [int]$Height = 35,
        [scriptblock]$OnClick
    )
    
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $Text
    $button.Width = $Width
    $button.Height = $Height
    $button.FontFamily = $global:Fonts.Normal
    $button.FontSize = 12
    $button.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $button.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    $button.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    $button.BorderThickness = "0"
    $button.Cursor = "Hand"
    $button.Padding = "10,5,10,5"
    $button.CornerRadius = "5"
    
    # Hover Effect
    $button.Add_MouseEnter({
        $this.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.AccentHover)
    })
    
    $button.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    })
    
    if ($OnClick) {
        $button.Add_Click($OnClick)
    }
    
    return $button
}

function New-ModernTextBox {
    param(
        [string]$Placeholder = "",
        [int]$Width = 300,
        [int]$Height = 35,
        [bool]$IsMultiline = $false
    )
    
    $textBox = New-Object System.Windows.Controls.TextBox
    $textBox.Width = $Width
    $textBox.Height = $Height
    $textBox.FontFamily = $global:Fonts.Normal
    $textBox.FontSize = 12
    $textBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $textBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $textBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $textBox.BorderThickness = "1"
    $textBox.Padding = "10"
    $textBox.AcceptsReturn = $IsMultiline
    $textBox.TextWrapping = if ($IsMultiline) { "Wrap" } else { "NoWrap" }
    
    if ($Placeholder) {
        $textBox.Tag = $Placeholder
    }
    
    return $textBox
}

function New-ModernLabel {
    param(
        [string]$Text,
        [int]$FontSize = 12,
        [string]$Color = $null,
        [string]$Weight = "Normal"
    )
    
    $label = New-Object System.Windows.Controls.Label
    $label.Content = $Text
    $label.FontFamily = $global:Fonts.Normal
    $label.FontSize = $FontSize
    $label.Foreground = [System.Windows.Media.Brush]::Parse($Color -or $global:DarkTheme.Foreground)
    $label.FontWeight = $Weight
    
    return $label
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN GUI WINDOW
# ──────────────────────────────────────────────────────────────────────────────

function Create-MainWindow {
    # Main Window
    $window = New-Object System.Windows.Window
    $window.Title = "🔗 ValyaRsser Pro - Advanced RSS Aggregator"
    $window.Width = 1200
    $window.Height = 800
    $window.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $window.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $window.FontFamily = $global:Fonts.Normal
    $window.Icon = $null
    $window.WindowStartupLocation = "CenterScreen"
    $window.ResizeMode = "CanResize"
    
    # Root Grid
    $rootGrid = New-Object System.Windows.Controls.Grid
    $rootGrid.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $window.Content = $rootGrid
    
    # Define Rows & Columns
    $rowDef1 = New-Object System.Windows.Controls.RowDefinition
    $rowDef1.Height = [System.Windows.GridLength]::new(60)
    $rootGrid.RowDefinitions.Add($rowDef1)
    
    $rowDef2 = New-Object System.Windows.Controls.RowDefinition
    $rowDef2.Height = [System.Windows.GridLength]::new(1, "Star")
    $rootGrid.RowDefinitions.Add($rowDef2)
    
    $rowDef3 = New-Object System.Windows.Controls.RowDefinition
    $rowDef3.Height = [System.Windows.GridLength]::new(150)
    $rootGrid.RowDefinitions.Add($rowDef3)
    
    # ─────── HEADER SECTION ───────
    $headerPanel = New-Object System.Windows.Controls.DockPanel
    $headerPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    [System.Windows.Controls.Grid]::SetRow($headerPanel, 0)
    $headerPanel.LastChildFill = $false
    $headerPanel.Margin = "0"
    
    $headerLabel = New-ModernLabel "🔗 ValyaRsser Pro" 18 $global:DarkTheme.Accent "Bold"
    $headerLabel.Margin = "20,15,0,0"
    [System.Windows.Controls.DockPanel]::SetDock($headerLabel, "Left")
    $headerPanel.Children.Add($headerLabel) | Out-Null
    
    # Header Buttons
    $headerButtonsPanel = New-Object System.Windows.Controls.StackPanel
    $headerButtonsPanel.Orientation = "Horizontal"
    $headerButtonsPanel.Margin = "0,12,20,0"
    [System.Windows.Controls.DockPanel]::SetDock($headerButtonsPanel, "Right")
    
    $refreshBtn = New-ModernButton "🔄 تحديث" 100 35 {
        Update-StatusBar "جاري تحديث جميع المصادر..." "#FFB700"
        Get-AllFeeds | Out-Null
    }
    $headerButtonsPanel.Children.Add($refreshBtn) | Out-Null
    
    $settingsBtn = New-ModernButton "⚙️ إعدادات" 100 35 {
        Show-SettingsWindow
    }
    $settingsBtn.Margin = "10,0,0,0"
    $headerButtonsPanel.Children.Add($settingsBtn) | Out-Null
    
    $headerPanel.Children.Add($headerButtonsPanel) | Out-Null
    $rootGrid.Children.Add($headerPanel) | Out-Null
    
    # ─────── CONTENT SECTION ───────
    $contentPanel = New-Object System.Windows.Controls.Grid
    [System.Windows.Controls.Grid]::SetRow($contentPanel, 1)
    $contentPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    
    # Left Panel - Feed List
    $colDef1 = New-Object System.Windows.Controls.ColumnDefinition
    $colDef1.Width = [System.Windows.GridLength]::new(300)
    $contentPanel.ColumnDefinitions.Add($colDef1)
    
    $colDef2 = New-Object System.Windows.Controls.ColumnDefinition
    $colDef2.Width = [System.Windows.GridLength]::new(1, "Star")
    $contentPanel.ColumnDefinitions.Add($colDef2)
    
    # Feed List Panel
    $feedListPanel = New-Object System.Windows.Controls.Border
    $feedListPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $feedListPanel.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $feedListPanel.BorderThickness = "1,0,1,0"
    $feedListPanel.Margin = "0"
    [System.Windows.Controls.Grid]::SetColumn($feedListPanel, 0)
    
    $feedStackPanel = New-Object System.Windows.Controls.StackPanel
    $feedStackPanel.Margin = "10"
    
    $feedListLabel = New-ModernLabel "📰 المصادر" 14 $global:DarkTheme.Accent "Bold"
    $feedStackPanel.Children.Add($feedListLabel) | Out-Null
    
    $global:FeedListBox = New-Object System.Windows.Controls.ListBox
    $global:FeedListBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $global:FeedListBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $global:FeedListBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $global:FeedListBox.BorderThickness = "1"
    $global:FeedListBox.Height = 250
    $global:FeedListBox.Margin = "0,10,0,10"
    $feedStackPanel.Children.Add($global:FeedListBox) | Out-Null
    
    # Add Feed Button
    $addFeedBtn = New-ModernButton "➕ إضافة مصدر" 280 35 {
        Show-AddFeedWindow
    }
    $feedStackPanel.Children.Add($addFeedBtn) | Out-Null
    
    # Remove Feed Button
    $removeFeedBtn = New-ModernButton "🗑️ حذف" 280 35 {
        if ($global:FeedListBox.SelectedItem) {
            Remove-RssFeed $global:FeedListBox.SelectedItem.Id
            Refresh-FeedList
        }
    }
    $removeFeedBtn.Margin = "0,5,0,0"
    $feedStackPanel.Children.Add($removeFeedBtn) | Out-Null
    
    $feedListPanel.Child = $feedStackPanel
    $contentPanel.Children.Add($feedListPanel) | Out-Null
    
    # Right Panel - Feed Content
    $contentViewPanel = New-Object System.Windows.Controls.Border
    $contentViewPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $contentViewPanel.Margin = "10"
    [System.Windows.Controls.Grid]::SetColumn($contentViewPanel, 1)
    
    $global:FeedContentBox = New-Object System.Windows.Controls.TextBox
    $global:FeedContentBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $global:FeedContentBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $global:FeedContentBox.FontFamily = $global:Fonts.Mono
    $global:FeedContentBox.FontSize = 11
    $global:FeedContentBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $global:FeedContentBox.BorderThickness = "1"
    $global:FeedContentBox.TextWrapping = "Wrap"
    $global:FeedContentBox.IsReadOnly = $true
    $global:FeedContentBox.VerticalScrollBarVisibility = "Auto"
    $global:FeedContentBox.Padding = "10"
    
    $contentViewPanel.Child = $global:FeedContentBox
    $contentPanel.Children.Add($contentViewPanel) | Out-Null
    
    $rootGrid.Children.Add($contentPanel) | Out-Null
    
    # ─────── LOG SECTION ───────
    $logPanel = New-Object System.Windows.Controls.Border
    $logPanel.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.CardBg)
    $logPanel.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $logPanel.BorderThickness = "0,1,0,0"
    $logPanel.Margin = "0"
    [System.Windows.Controls.Grid]::SetRow($logPanel, 2)
    
    $logStackPanel = New-Object System.Windows.Controls.StackPanel
    $logStackPanel.Margin = "10"
    
    $logLabel = New-ModernLabel "📋 السجلات" 12 $global:DarkTheme.Accent "Bold"
    $logStackPanel.Children.Add($logLabel) | Out-Null
    
    $global:LogTextBox = New-Object System.Windows.Controls.TextBox
    $global:LogTextBox.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $global:LogTextBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Muted)
    $global:LogTextBox.FontFamily = $global:Fonts.Mono
    $global:LogTextBox.FontSize = 10
    $global:LogTextBox.BorderBrush = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Border)
    $global:LogTextBox.BorderThickness = "1"
    $global:LogTextBox.IsReadOnly = $true
    $global:LogTextBox.TextWrapping = "Wrap"
    $global:LogTextBox.VerticalScrollBarVisibility = "Auto"
    $global:LogTextBox.Height = 110
    $global:LogTextBox.Margin = "0,5,0,0"
    $logStackPanel.Children.Add($global:LogTextBox) | Out-Null
    
    # Status Bar
    $statusPanel = New-Object System.Windows.Controls.DockPanel
    $statusPanel.Margin = "0,5,0,0"
    $statusPanel.LastChildFill = $false
    
    $global:StatusLabel = New-ModernLabel "✓ جاهز" 11 $global:DarkTheme.Success
    [System.Windows.Controls.DockPanel]::SetDock($global:StatusLabel, "Left")
    $statusPanel.Children.Add($global:StatusLabel) | Out-Null
    
    $logStackPanel.Children.Add($statusPanel) | Out-Null
    $logPanel.Child = $logStackPanel
    $rootGrid.Children.Add($logPanel) | Out-Null
    
    $window.Add_Loaded({
        Refresh-FeedList
        Write-Log "تطبيق ValyaRsser Pro تم تحميله" "SUCCESS"
    })
    
    $window.Add_Closing({
        Write-Log "تطبيق ValyaRsser Pro تم إغلاقه" "INFO"
    })
    
    return $window
}

function Refresh-FeedList {
    $global:FeedListBox.Items.Clear()
    $feeds = Get-RssFeeds
    foreach ($feed in $feeds) {
        $global:FeedListBox.Items.Add($feed) | Out-Null
    }
    if ($feeds.Count -gt 0) {
        $global:FeedListBox.SelectedIndex = 0
    }
}

function Show-AddFeedWindow {
    $addWindow = New-Object System.Windows.Window
    $addWindow.Title = "إضافة مصدر RSS جديد"
    $addWindow.Width = 450
    $addWindow.Height = 300
    $addWindow.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $addWindow.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $addWindow.FontFamily = $global:Fonts.Normal
    $addWindow.WindowStartupLocation = "CenterOwner"
    $addWindow.ResizeMode = "NoResize"
    
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "20"
    $addWindow.Content = $grid
    
    $rowDef1 = New-Object System.Windows.Controls.RowDefinition
    $rowDef1.Height = [System.Windows.GridLength]::new("Auto")
    $grid.RowDefinitions.Add($rowDef1)
    
    $rowDef2 = New-Object System.Windows.Controls.RowDefinition
    $rowDef2.Height = [System.Windows.GridLength]::new("Auto")
    $grid.RowDefinitions.Add($rowDef2)
    
    $rowDef3 = New-Object System.Windows.Controls.RowDefinition
    $rowDef3.Height = [System.Windows.GridLength]::new("Auto")
    $grid.RowDefinitions.Add($rowDef3)
    
    $rowDef4 = New-Object System.Windows.Controls.RowDefinition
    $rowDef4.Height = [System.Windows.GridLength]::new("Auto")
    $grid.RowDefinitions.Add($rowDef4)
    
    $rowDef5 = New-Object System.Windows.Controls.RowDefinition
    $rowDef5.Height = [System.Windows.GridLength]::new(1, "Star")
    $grid.RowDefinitions.Add($rowDef5)
    
    # Name Field
    $nameLabel = New-ModernLabel "اسم المصدر:" 12
    [System.Windows.Controls.Grid]::SetRow($nameLabel, 0)
    $grid.Children.Add($nameLabel) | Out-Null
    
    $nameTextBox = New-ModernTextBox -Width 400 -Height 35
    [System.Windows.Controls.Grid]::SetRow($nameTextBox, 0)
    $nameTextBox.Margin = "0,25,0,10"
    $grid.Children.Add($nameTextBox) | Out-Null
    
    # URL Field
    $urlLabel = New-ModernLabel "رابط RSS:" 12
    [System.Windows.Controls.Grid]::SetRow($urlLabel, 1)
    $grid.Children.Add($urlLabel) | Out-Null
    
    $urlTextBox = New-ModernTextBox -Width 400 -Height 35
    [System.Windows.Controls.Grid]::SetRow($urlTextBox, 1)
    $urlTextBox.Margin = "0,25,0,10"
    $grid.Children.Add($urlTextBox) | Out-Null
    
    # Category Field
    $categoryLabel = New-ModernLabel "التصنيف:" 12
    [System.Windows.Controls.Grid]::SetRow($categoryLabel, 2)
    $grid.Children.Add($categoryLabel) | Out-Null
    
    $categoryTextBox = New-ModernTextBox -Width 400 -Height 35
    $categoryTextBox.Text = "عام"
    [System.Windows.Controls.Grid]::SetRow($categoryTextBox, 2)
    $categoryTextBox.Margin = "0,25,0,20"
    $grid.Children.Add($categoryTextBox) | Out-Null
    
    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 3)
    
    $saveBtn = New-ModernButton "💾 حفظ" 120 35 {
        if ($nameTextBox.Text -and $urlTextBox.Text) {
            Add-RssFeed -Name $nameTextBox.Text -Url $urlTextBox.Text -Category $categoryTextBox.Text
            Refresh-FeedList
            $addWindow.Close()
        }
        else {
            Show-Notification "خطأ" "يرجى ملء جميع الحقول" "Error"
        }
    }
    $buttonPanel.Children.Add($saveBtn) | Out-Null
    
    $cancelBtn = New-ModernButton "إلغاء" 120 35 {
        $addWindow.Close()
    }
    $cancelBtn.Margin = "10,0,0,0"
    $buttonPanel.Children.Add($cancelBtn) | Out-Null
    
    $grid.Children.Add($buttonPanel) | Out-Null
    
    $addWindow.ShowDialog() | Out-Null
}

function Show-SettingsWindow {
    $settingsWindow = New-Object System.Windows.Window
    $settingsWindow.Title = "⚙️ الإعدادات"
    $settingsWindow.Width = 500
    $settingsWindow.Height = 400
    $settingsWindow.Background = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Background)
    $settingsWindow.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Foreground)
    $settingsWindow.FontFamily = $global:Fonts.Normal
    $settingsWindow.WindowStartupLocation = "CenterOwner"
    $settingsWindow.ResizeMode = "NoResize"
    
    $grid = New-Object System.Windows.Controls.StackPanel
    $grid.Margin = "20"
    $settingsWindow.Content = $grid
    
    $title = New-ModernLabel "إعدادات التطبيق" 14 $global:DarkTheme.Accent "Bold"
    $grid.Children.Add($title) | Out-Null
    
    # Theme Toggle
    $themePanel = New-Object System.Windows.Controls.StackPanel
    $themePanel.Orientation = "Horizontal"
    $themePanel.Margin = "0,20,0,0"
    
    $themeLabel = New-ModernLabel "الوضع الليلي" 12
    $themePanel.Children.Add($themeLabel) | Out-Null
    
    $themeCheckBox = New-Object System.Windows.Controls.CheckBox
    $themeCheckBox.IsChecked = $true
    $themeCheckBox.Margin = "20,0,0,0"
    $themeCheckBox.Foreground = [System.Windows.Media.Brush]::Parse($global:DarkTheme.Accent)
    $themePanel.Children.Add($themeCheckBox) | Out-Null
    $grid.Children.Add($themePanel) | Out-Null
    
    # Update Interval
    $intervalPanel = New-Object System.Windows.Controls.StackPanel
    $intervalPanel.Margin = "0,20,0,0"
    
    $intervalLabel = New-ModernLabel "فترة التحديث (بالدقائق):" 12
    $intervalPanel.Children.Add($intervalLabel) | Out-Null
    
    $intervalSpinner = New-Object System.Windows.Controls.TextBox
    $intervalSpinner.Text = "30"
    $intervalSpinner.Width = 100
    $intervalSpinner.Height = 35
    $intervalSpinner.Margin = "0,10,0,0"
    $intervalSpinner.Background = [System.Windows.Media.
