param(
    [string]$OutputPath = "WanGP-Manager.exe"
)

Write-Host "=== ✰✞Hł₮₥₳₦✞✰ - WanGP Manager EXE Builder ===" -ForegroundColor Cyan
Write-Host "Building EXE with NoOutput and RequireAdmin parameters..." -ForegroundColor Yellow

# Check if PS2EXE is installed
if (!(Get-Module -ListAvailable -Name PS2EXE)) {
    Write-Host "Installing PS2EXE module..." -ForegroundColor Yellow
    try {
        Install-Module -Name PS2EXE -Force -Scope CurrentUser
        Write-Host "PS2EXE installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install PS2EXE. Please run as Administrator." -ForegroundColor Red
        exit 1
    }
}

Import-Module PS2EXE -Force

# Main PowerShell script content for EXE
$MainScriptContent = @'
# ================= ✰✞Hł₮₥₳₦✞✰ - WanGP Manager EXE =================
# Version 8.0 - Fixed No Messageboxes

# Load Windows Forms - SILENCED
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void][System.Windows.Forms.Application]::EnableVisualStyles()

try {
    # Get current directory
    $RepoPath = Get-Location
    $Script:HasConda = $false
    $Script:HasPython = $false
    $Script:HasGit = $false
    $Script:CondaActivate = $null
    $Script:CondaEnv = $null

    # Function to check if command exists
    function Test-CommandExists($command) {
        try {
            Get-Command $command -ErrorAction Stop | Out-Null
            return $true
        } catch {
            return $false
        }
    }

    # Enhanced Conda discovery
    function Find-Conda {
        $possiblePaths = @(
            "$env:USERPROFILE\miniconda3", "$env:USERPROFILE\anaconda3",
            "$env:USERPROFILE\AppData\Local\miniconda3", "$env:USERPROFILE\AppData\Local\anaconda3",
            "$env:ProgramData\miniconda3", "$env:ProgramData\anaconda3",
            "C:\Miniconda3", "C:\Anaconda3", "D:\Miniconda3", "D:\Anaconda3"
        )
        
        foreach ($path in $possiblePaths) {
            $activate = Join-Path $path "Scripts\activate.bat"
            if (Test-Path $activate) {
                return $activate
            }
        }
        
        if (Test-CommandExists "conda") {
            try {
                $condaPath = (Get-Command conda).Path
                $condaDir = Split-Path (Split-Path $condaPath) -Parent
                $activate = Join-Path $condaDir "Scripts\activate.bat"
                if (Test-Path $activate) {
                    return $activate
                }
            } catch { }
        }
        
        return $null
    }

    # Find Conda environment
    function Find-CondaEnv {
        if (!$Script:HasConda) { return $null }
        
        $envs = @("wan2gp", "wangp", "hunyuan", "skyreels", "base")
        
        foreach ($env in $envs) {
            try {
                $testCmd = "call `"$Script:CondaActivate`" && conda activate $env 2>&1 && echo SUCCESS"
                $result = cmd /c $testCmd 2>$null
                if ($result -contains "SUCCESS") {
                    return $env
                }
            } catch { }
        }
        
        return $null
    }

    # SILENT INITIALIZATION
    $Script:CondaActivate = Find-Conda
    $Script:HasConda = ($Script:CondaActivate -ne $null)
    
    if ($Script:HasConda) {
        $Script:CondaEnv = Find-CondaEnv
        $Script:HasPython = ($Script:CondaEnv -ne $null)
    }

    $Script:HasGit = Test-CommandExists "git"

    # Check WanGP repository files
    $Script:IsWanGPRepo = $true
    $requiredFiles = @("wgp.py", "requirements.txt")
    foreach ($file in $requiredFiles) {
        if (!(Test-Path (Join-Path $RepoPath $file))) {
            $Script:IsWanGPRepo = $false
            break
        }
    }

    # Get version info
    function Get-VersionInfo {
        try {
            if ($Script:HasConda -and $Script:HasPython -and $Script:HasGit) {
                $commitHash = & cmd /c "call `"$Script:CondaActivate`" && conda activate $Script:CondaEnv && cd /d `"$RepoPath`" && git rev-parse --short HEAD" 2>$null
                $branch = & cmd /c "call `"$Script:CondaActivate`" && conda activate $Script:CondaEnv && cd /d `"$RepoPath`" && git branch --show-current" 2>$null
                return "v8.0 | $($branch.Trim()) | $($commitHash.Trim())"
            }
        } catch { }
        return "v8.0 | Fixed EXE"
    }

    $VersionInfo = Get-VersionInfo
    $RunArgs = "--attention sage2 --fp16"

    # Command runner
    function Run-CondaCmd([string]$Cmd) {
        if (!$Script:HasConda -or !$Script:HasPython) {
            return "INFO: Conda/Python not available. Install Miniconda/Anaconda to enable WanGP features."
        }
        
        try {
            $fullCmd = "call `"$Script:CondaActivate`" && conda activate $Script:CondaEnv && cd /d `"$RepoPath`" && $Cmd"
            $output = cmd /c $fullCmd 2>&1
            return $output -join "`r`n"
        } catch { 
            return "Command ERROR: $($_.Exception.Message)"
        }
    }

    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "✰✞Hł₮₥₳₦✞✰ - WanGP Manager ($VersionInfo)"
    $form.StartPosition = "CenterScreen"
    $form.MinimumSize = New-Object System.Drawing.Size(1000, 600)
    $form.BackColor = [System.Drawing.Color]::WhiteSmoke

    # Main layout - SILENCED ASSIGNMENTS
    $root = New-Object System.Windows.Forms.TableLayoutPanel
    $root.Dock = 'Fill'
    $null = ($root.ColumnCount = 1)
    $null = ($root.RowCount = 2)
    $root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
    $root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
    [void]$form.Controls.Add($root)

    # Info label
    $infoText = "✓ READY | Location: $(Split-Path $RepoPath -Leaf)"
    if ($Script:HasConda) { $infoText += " | Conda: $Script:CondaEnv" }
    if ($Script:HasGit) { $infoText += " | Git: Ready" }
    
    $info = New-Object System.Windows.Forms.Label
    $info.Text = $infoText
    $info.Padding = New-Object System.Windows.Forms.Padding(10,8,10,8)
    $info.AutoSize = $true
    $info.BackColor = [System.Drawing.Color]::LightGreen
    [void]$root.Controls.Add($info, 0, 0)

    # Center panel - SILENCED ASSIGNMENTS
    $center = New-Object System.Windows.Forms.TableLayoutPanel
    $center.Dock = 'Fill'
    $null = ($center.ColumnCount = 1)
    $null = ($center.RowCount = 2)
    $center.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
    $center.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
    [void]$root.Controls.Add($center, 0, 1)

    # Log textbox
    $log = New-Object System.Windows.Forms.TextBox
    $log.Multiline = $true
    $log.ScrollBars = 'Both'
    $log.WordWrap = $false
    $log.ReadOnly = $true
    $log.Font = New-Object System.Drawing.Font("Consolas", 9)
    $log.Dock = 'Fill'
    [void]$center.Controls.Add($log, 0, 0)

    function Append-Log($text){ 
        $timestamp = Get-Date -Format "HH:mm:ss"
        $log.AppendText("[$timestamp] $text`r`n") 
        $log.ScrollToCaret()
    }

    function Show-Status { 
        Append-Log "=== SYSTEM STATUS ==="
        if ($Script:HasGit) {
            Append-Log (Run-CondaCmd "git rev-parse --short HEAD && git branch --show-current && git status -s") 
        } else {
            Append-Log "Git not available - install Git for version control features"
        }
    }

    # Button panel
    $btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $btnPanel.Dock = 'Fill'
    $btnPanel.WrapContents = $true
    $btnPanel.AutoSize = $true
    $btnPanel.FlowDirection = 'LeftToRight'
    $btnPanel.Padding = New-Object System.Windows.Forms.Padding(6)
    $btnPanel.Margin = New-Object System.Windows.Forms.Padding(0)
    [void]$center.Controls.Add($btnPanel, 0, 1)

    # Helper for buttons - SILENCED CLICK HANDLER
    function New-FlatButton([string]$text, [scriptblock]$onClick) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $text
        $b.AutoSize = $true
        $b.Margin = New-Object System.Windows.Forms.Padding(6)
        $b.Padding = New-Object System.Windows.Forms.Padding(12, 6, 12, 6)
        $b.FlatStyle = 'System'
        $b.Add_Click($onClick) | Out-Null
        return $b
    }

    # Controls
    $AttentionOptions = @("default","sdpa","sage2","sage","flash")

    $attentionLabel = New-Object System.Windows.Forms.Label
    $attentionLabel.Text = "Attention:"
    $attentionLabel.AutoSize = $true
    $attentionLabel.Margin = New-Object System.Windows.Forms.Padding(6,10,0,0)

    $attentionBox = New-Object System.Windows.Forms.ComboBox
    $attentionBox.DropDownStyle = 'DropDownList'
    [void]$attentionBox.Items.AddRange($AttentionOptions)
    $attentionBox.SelectedItem = "sage2"
    $attentionBox.Width = 120
    $attentionBox.Margin = New-Object System.Windows.Forms.Padding(6)

    $fp16 = New-Object System.Windows.Forms.CheckBox
    $fp16.Text = "Force FP16"
    $fp16.AutoSize = $true
    $fp16.Checked = $true
    $fp16.Margin = New-Object System.Windows.Forms.Padding(12,12,0,0)

    $extraLabel = New-Object System.Windows.Forms.Label
    $extraLabel.Text = "Extra args:"
    $extraLabel.AutoSize = $true
    $extraLabel.Margin = New-Object System.Windows.Forms.Padding(18,10,0,0)

    $extraArgs = New-Object System.Windows.Forms.TextBox
    $extraArgs.Width = 480
    $extraArgs.Text = $RunArgs
    $extraArgs.Margin = New-Object System.Windows.Forms.Padding(6)

    # SHARE/SERVER
    $share = New-Object System.Windows.Forms.CheckBox
    $share.Text = "Public share"
    $share.AutoSize = $true
    $share.Margin = New-Object System.Windows.Forms.Padding(12,12,0,0)

    $listenAll = New-Object System.Windows.Forms.CheckBox
    $listenAll.Text = "Listen 0.0.0.0"
    $listenAll.AutoSize = $true
    $listenAll.Margin = New-Object System.Windows.Forms.Padding(12,12,0,0)

    $portLabel = New-Object System.Windows.Forms.Label
    $portLabel.Text = "Port:"
    $portLabel.AutoSize = $true
    $portLabel.Margin = New-Object System.Windows.Forms.Padding(18,10,0,0)

    $portBox = New-Object System.Windows.Forms.TextBox
    $portBox.Width = 70
    $portBox.Text = "7860"
    $portBox.Margin = New-Object System.Windows.Forms.Padding(6)

    # Add controls - ALL SILENCED
    [void]$btnPanel.Controls.Add($attentionLabel)
    [void]$btnPanel.Controls.Add($attentionBox)
    [void]$btnPanel.Controls.Add($fp16)
    [void]$btnPanel.Controls.Add($extraLabel)
    [void]$btnPanel.Controls.Add($extraArgs)
    [void]$btnPanel.Controls.Add($share)
    [void]$btnPanel.Controls.Add($listenAll)
    [void]$btnPanel.Controls.Add($portLabel)
    [void]$btnPanel.Controls.Add($portBox)

    # Build arguments and env variables
    function Build-Args-And-Env([string]$mode = "general") {
        $argsList = @()
        $envSet = @{}

        $sel = [string]$attentionBox.SelectedItem
        if ($sel -and $sel -ne "default") { $argsList += "--attention $sel" }

        if ($fp16.Checked) { $argsList += "--fp16" }
        if ($extraArgs.Text) { $argsList += $extraArgs.Text }

        # SHARE/SERVER
        $port = 0
        if ([int]::TryParse($portBox.Text, [ref]$port) -and $port -gt 0) {
            $argsList += "--server-port $port"
            $envSet["GRADIO_SERVER_PORT"] = "$port"
        }
        if ($listenAll.Checked) {
            $argsList += "--server-name 0.0.0.0"
            $envSet["GRADIO_SERVER_NAME"] = "0.0.0.0"
        }
        if ($share.Checked) {
            $argsList += "--share"
            $envSet["GRADIO_SHARE"] = "1"
        }

        return @{ args = ($argsList -join " "); env = $envSet }
    }

    # Start process
    function Start-WanGP([string]$mode = "general") {
        try {
            if (!$Script:HasConda -or !$Script:HasPython) {
                Append-Log "ERROR: Cannot start WanGP - Conda/Python not available"
                Append-Log "Please install Miniconda/Anaconda and create wan2gp environment"
                return
            }

            $built = Build-Args-And-Env -mode $mode

            foreach ($k in $built.env.Keys) { 
                Set-Item -Path "Env:$k" -Value $built.env[$k] | Out-Null 
            }

            $py = "python wgp.py"
            if ($built.args -and $built.args.Trim()) { 
                $py = "$py $($built.args)" 
            }
            $cmd = "call `"$Script:CondaActivate`" && conda activate $Script:CondaEnv && cd /d `"$RepoPath`" && $py"

            Start-Process -FilePath "cmd.exe" -ArgumentList "/k $cmd"
            Append-Log ("Start: mode=$mode args=" + $built.args)
        } catch {
            Append-Log "Startup ERROR: $($_.Exception.Message)"
        }
    }

    # Buttons - ALL SILENCED
    [void]$btnPanel.Controls.Add((New-FlatButton "Update (pull + pip)" {
        Append-Log "== UPDATE =="
        Append-Log (Run-CondaCmd "git pull")
        Append-Log (Run-CondaCmd "pip install -r requirements.txt")
        Show-Status
    }))

    [void]$btnPanel.Controls.Add((New-FlatButton "Rollback to PREVIOUS" {
        $res = [System.Windows.Forms.MessageBox]::Show("Rollback to HEAD~1 (reset --hard)? A backup tag will be created.", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
            $tag = "backup-" + (Get-Date -Format "yyyyMMdd-HHmmss")
            Append-Log (Run-CondaCmd "git tag -f $tag HEAD")
            Append-Log "Backup tag: $tag"
            Append-Log (Run-CondaCmd "git reset --hard HEAD~1")
            Show-Status
        }
    }))

    [void]$btnPanel.Controls.Add((New-FlatButton "Pick commit (list)" {
        $logList = Run-CondaCmd "git log --oneline -n 30"
        $items = $logList -split "`r?`n" | Where-Object { $_ -match "^\w{7,}\s" } |
            ForEach-Object { 
                $hash = ($_ -split " ")[0]
                [PSCustomObject]@{ Commit = $hash; Message = ($_ -replace "^\w+\s", "") } 
            }
        if ($items.Count -gt 0) {
            $sel = $items | Out-GridView -Title "Select commit to checkout (RESET --HARD)" -PassThru
            if ($sel) {
                $res = [System.Windows.Forms.MessageBox]::Show("Reset to $($sel.Commit)? A backup tag will be created.", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
                    $tag = "backup-" + (Get-Date -Format "yyyyMMdd-HHmmss")
                    Append-Log (Run-CondaCmd "git tag -f $tag HEAD")
                    Append-Log "Backup tag: $tag"
                    Append-Log (Run-CondaCmd "git reset --hard $($sel.Commit)")
                    Show-Status
                }
            }
        } else { 
            Append-Log "Unable to read git log." 
        }
    }))

    [void]$btnPanel.Controls.Add((New-FlatButton "Restore to latest main" {
        $res = [System.Windows.Forms.MessageBox]::Show("Restore to origin/main (reset --hard)?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($res -eq [System.Windows.Forms.DialogResult]::OK) {
            Append-Log (Run-CondaCmd "git fetch --all")
            Append-Log (Run-CondaCmd "git checkout main")
            Append-Log (Run-CondaCmd "git reset --hard origin/main")
            Show-Status
        }
    }))

    # Startups - ONLY KEEP THE MAIN START BUTTON
    [void]$btnPanel.Controls.Add((New-FlatButton "Start WanGP" { Start-WanGP "general" }))

    # Open in browser
    [void]$btnPanel.Controls.Add((New-FlatButton "Open in browser" {
        try { 
            $p = 7860
            [void][int]::TryParse($portBox.Text, [ref]$p)
            Start-Process "http://localhost:$p" 
        } catch { 
            Append-Log "Open browser ERROR: $($_.Exception.Message)" 
        }
    }))

    # Discord button
    [void]$btnPanel.Controls.Add((New-FlatButton "Join Discord" {
        try { 
            Start-Process "https://discord.com/channels/1361676211817939125"
            Append-Log "Opening Discord channel..."
        } catch { 
            Append-Log "Open Discord ERROR: $($_.Exception.Message)" 
        }
    }))

    [void]$btnPanel.Controls.Add((New-FlatButton "Status" { Show-Status }))
    [void]$btnPanel.Controls.Add((New-FlatButton "Close" { $form.Close() }))

    # Initialize
    Append-Log "=== ✰✞Hł₮₥₳₦✞✰ - WANGP MANAGER ==="
    Append-Log "Version: $VersionInfo"
    Append-Log "Location: $RepoPath"
    if ($Script:HasConda) { Append-Log "Conda: Ready - $Script:CondaEnv" }
    if ($Script:HasGit) { Append-Log "Git: Ready" }
    Append-Log "Status: Clean startup completed"
    Append-Log "Support: Join our Discord channel (click 'Join Discord' button)"
    
    if ($Script:HasConda -and $Script:HasPython -and $Script:HasGit) {
        Show-Status
    }

} catch {
    $errorMsg = "CRITICAL ERROR:`n`n$($_.Exception.Message)`n`nSupport: Join our Discord channel (click 'Join Discord' button)"
    [System.Windows.Forms.MessageBox]::Show($errorMsg, "Critical Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}

# Show form - SILENCED
[void]$form.ShowDialog()
'@

Write-Host "Building EXE file: $OutputPath" -ForegroundColor Cyan

try {
    # Create a temporary file
    $TempScript = Join-Path $env:TEMP "WanGP_$([System.Guid]::NewGuid().ToString().Substring(0,8)).ps1"
    $MainScriptContent | Out-File -FilePath $TempScript -Encoding UTF8

    # ✅ OVO JE KLJUČNI DIO - Build the EXE with FIXED PARAMETERS
    Invoke-PS2EXE -InputFile $TempScript -OutputFile $OutputPath -NoConsole -NoOutput -RequireAdmin
    
    if (Test-Path $OutputPath) {
        Write-Host "✅ EXE successfully created: $OutputPath" -ForegroundColor Green
        Write-Host "File size: $([math]::Round((Get-Item $OutputPath).Length / 1MB, 2)) MB" -ForegroundColor Green
        Write-Host "`n🎯 MODIFICATIONS MADE:" -ForegroundColor Yellow
        Write-Host "- Removed: SkyReels (SAFE) button" -ForegroundColor White
        Write-Host "- Removed: SkyReels (FAST) button" -ForegroundColor White
        Write-Host "- Removed: SkyReels (SDPA-FAST) button" -ForegroundColor White
        Write-Host "- Added: Join Discord button with channel ID 1361676211817939125" -ForegroundColor White
        Write-Host "`n✅ EXE should start WITHOUT any 0,1 messageboxes!" -ForegroundColor Green
    } else {
        Write-Host "❌ EXE creation failed!" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Build error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying alternative parameters..." -ForegroundColor Yellow
    
    # Fallback if parameters don't exist
    try {
        Invoke-PS2EXE -InputFile $TempScript -OutputFile $OutputPath -NoConsole
        Write-Host "✅ EXE created with fallback parameters" -ForegroundColor Green
    } catch {
        Write-Host "❌ Fallback also failed" -ForegroundColor Red
    }
} finally {
    # Clean up
    if (Test-Path $TempScript) {
        Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nBuild process completed!" -ForegroundColor Cyan