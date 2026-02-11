# merge-appsettings.ps1
# Merges user's existing appsettings.json with new installer defaults
# Preserves user customizations while adding new settings

param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir,
    
    [Parameter(Mandatory=$true)]
    [string]$BedrockExePath,
    
    [Parameter(Mandatory=$true)]
    [string]$LogFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$BackupsPath,
    
    [Parameter(Mandatory=$true)]
    [int]$ServicePort,
    
    [Parameter(Mandatory=$true)]
    [int]$BackupFrequency,
    
    [Parameter(Mandatory=$true)]
    [int]$MaxBackups
)

$ErrorActionPreference = "Stop"

$appSettingsPath = Join-Path $InstallDir "appsettings.json"
$backupPath = Join-Path $InstallDir "appsettings.backup.json"

Write-Host "Starting configuration merge..." -ForegroundColor Cyan

# Convert paths to forward slashes for JSON
function ConvertTo-JsonPath {
    param([string]$Path)
    return $Path -replace '\\', '/'
}

# New default configuration from installer
$newConfig = @{
    Logging = @{
        LogLevel = @{
            Default = "Information"
            "Microsoft.AspNetCore" = "Warning"
        }
    }
    AllowedHosts = "*"
    Urls = "http://0.0.0.0:$ServicePort"
    Runner = @{
        ExePath = ConvertTo-JsonPath $BedrockExePath
        LogFilePath = ConvertTo-JsonPath $LogFilePath
    }
    Backup = @{
        FrequencyMinutes = $BackupFrequency
        BackupDirectory = ConvertTo-JsonPath $BackupsPath
        MaxBackupsToKeep = $MaxBackups
    }
    XboxLive = @{
        ApiKey = ""
        ApiBaseUrl = "https://xbl.io/api/v2"
        EnableCaching = $true
        CacheExpirationMinutes = 1440
    }
}

# Check if existing config exists
if (Test-Path $appSettingsPath) {
    Write-Host "Found existing appsettings.json - preserving user settings" -ForegroundColor Yellow
    
    # Backup existing config
    Copy-Item $appSettingsPath $backupPath -Force
    Write-Host "Created backup: appsettings.backup.json" -ForegroundColor Green
    
    try {
        # Read existing config
        $existingJson = Get-Content $appSettingsPath -Raw
        $existingConfig = $existingJson | ConvertFrom-Json
        
        # Merge configurations (existing takes precedence)
        # Preserve user's Urls (port)
        if ($existingConfig.Urls) {
            $newConfig.Urls = $existingConfig.Urls
            Write-Host "  ? Preserved custom port: $($existingConfig.Urls)" -ForegroundColor Green
        }
        
        # Preserve user's Runner paths if they exist and differ
        if ($existingConfig.Runner) {
            if ($existingConfig.Runner.ExePath -and $existingConfig.Runner.ExePath -ne $BedrockExePath) {
                $newConfig.Runner.ExePath = ConvertTo-JsonPath $existingConfig.Runner.ExePath
                Write-Host "  ? Preserved custom Bedrock path: $($existingConfig.Runner.ExePath)" -ForegroundColor Green
            }
            if ($existingConfig.Runner.LogFilePath -and $existingConfig.Runner.LogFilePath -ne $LogFilePath) {
                $newConfig.Runner.LogFilePath = ConvertTo-JsonPath $existingConfig.Runner.LogFilePath
                Write-Host "  ? Preserved custom log path: $($existingConfig.Runner.LogFilePath)" -ForegroundColor Green
            }
        }
        
        # Preserve user's Backup settings if customized
        if ($existingConfig.Backup) {
            if ($existingConfig.Backup.FrequencyMinutes) {
                $newConfig.Backup.FrequencyMinutes = $existingConfig.Backup.FrequencyMinutes
                Write-Host "  ? Preserved backup frequency: $($existingConfig.Backup.FrequencyMinutes) minutes" -ForegroundColor Green
            }
            if ($existingConfig.Backup.BackupDirectory -and $existingConfig.Backup.BackupDirectory -ne $BackupsPath) {
                $newConfig.Backup.BackupDirectory = ConvertTo-JsonPath $existingConfig.Backup.BackupDirectory
                Write-Host "  ? Preserved custom backup path: $($existingConfig.Backup.BackupDirectory)" -ForegroundColor Green
            }
            if ($existingConfig.Backup.MaxBackupsToKeep) {
                $newConfig.Backup.MaxBackupsToKeep = $existingConfig.Backup.MaxBackupsToKeep
                Write-Host "  ? Preserved max backups: $($existingConfig.Backup.MaxBackupsToKeep)" -ForegroundColor Green
            }
        }
        
        # Preserve Xbox Live API key if exists
        if ($existingConfig.XboxLive -and $existingConfig.XboxLive.ApiKey) {
            $newConfig.XboxLive.ApiKey = $existingConfig.XboxLive.ApiKey
            Write-Host "  ? Preserved Xbox Live API key" -ForegroundColor Green
            
            # Preserve other Xbox Live settings if customized
            if ($existingConfig.XboxLive.ApiBaseUrl) {
                $newConfig.XboxLive.ApiBaseUrl = $existingConfig.XboxLive.ApiBaseUrl
            }
            if ($null -ne $existingConfig.XboxLive.EnableCaching) {
                $newConfig.XboxLive.EnableCaching = $existingConfig.XboxLive.EnableCaching
            }
            if ($existingConfig.XboxLive.CacheExpirationMinutes) {
                $newConfig.XboxLive.CacheExpirationMinutes = $existingConfig.XboxLive.CacheExpirationMinutes
            }
        }
        
        # Preserve any other custom sections not defined in new config
        $existingConfig.PSObject.Properties | Where-Object {
            $_.Name -notin @('Logging', 'AllowedHosts', 'Urls', 'Runner', 'Backup', 'XboxLive')
        } | ForEach-Object {
            $newConfig[$_.Name] = $_.Value
            Write-Host "  ? Preserved custom section: $($_.Name)" -ForegroundColor Green
        }
        
        Write-Host "Configuration merge successful!" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not parse existing config, using new defaults" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Your old config is saved as: appsettings.backup.json" -ForegroundColor Yellow
    }
}
else {
    Write-Host "No existing config found - creating new appsettings.json" -ForegroundColor Cyan
}

# Write merged configuration
try {
    $json = $newConfig | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $appSettingsPath -Encoding UTF8 -Force
    Write-Host "? Wrote appsettings.json successfully" -ForegroundColor Green
    
    # Also create appsettings.user.json for backward compatibility
    $userSettingsPath = Join-Path $InstallDir "appsettings.user.json"
    $json | Out-File -FilePath $userSettingsPath -Encoding UTF8 -Force
    Write-Host "? Wrote appsettings.user.json successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to write configuration files!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`nConfiguration complete!" -ForegroundColor Green
exit 0
