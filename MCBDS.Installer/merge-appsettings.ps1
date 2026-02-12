# merge-appsettings.ps1
# Merges user's existing appsettings.json with new installer defaults
# Preserves user customizations while adding new settings

param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupConfig,
    
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

Write-Host "========== Merge-appsettings.ps1 Starting ==========" -ForegroundColor Cyan
Write-Host "Parameters:" -ForegroundColor Cyan
Write-Host "  InstallDir: $InstallDir" -ForegroundColor Cyan
Write-Host "  BackupConfig: $BackupConfig" -ForegroundColor Cyan
Write-Host "  BedrockExePath: $BedrockExePath" -ForegroundColor Cyan
Write-Host "  LogFilePath: $LogFilePath" -ForegroundColor Cyan
Write-Host "  BackupsPath: $BackupsPath" -ForegroundColor Cyan
Write-Host "  ServicePort: $ServicePort" -ForegroundColor Cyan
Write-Host "  BackupFrequency: $BackupFrequency" -ForegroundColor Cyan
Write-Host "  MaxBackups: $MaxBackups" -ForegroundColor Cyan

$appSettingsPath = Join-Path $InstallDir "appsettings.json"

# Use backup file if provided, otherwise look for existing file
if ($BackupConfig -and (Test-Path $BackupConfig)) {
    $existingConfigPath = $BackupConfig
    Write-Host "Using backed up configuration from: $BackupConfig" -ForegroundColor Cyan
} elseif (Test-Path $appSettingsPath) {
    $existingConfigPath = $appSettingsPath
    Write-Host "Using existing configuration from: $appSettingsPath" -ForegroundColor Cyan
} else {
    Write-Host "No existing configuration found - creating new" -ForegroundColor Yellow
    $existingConfigPath = $null
}

Write-Host "Starting configuration merge..." -ForegroundColor Cyan

# Convert Windows paths to JSON-safe paths (forward slashes)
function ConvertTo-JsonPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Host "  Warning: Empty path provided to ConvertTo-JsonPath" -ForegroundColor Yellow
        return ""
    }
    # Convert backslashes to forward slashes
    $jsonPath = $Path -replace '\\', '/'
    # Verify the result doesn't have any remaining backslashes
    return $jsonPath
}

# Convert JSON paths (with forward slashes) back to Windows paths
function ConvertFrom-JsonPath {
    param([string]$JsonPath)
    # Forward slashes in JSON become backslashes for Windows
    return $JsonPath -replace '/', '\'
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
if ($existingConfigPath -and (Test-Path $existingConfigPath)) {
    Write-Host "Found existing configuration - preserving user settings" -ForegroundColor Yellow
    
    try {
        # Read existing config
        Write-Host "Reading existing config from: $existingConfigPath" -ForegroundColor Cyan
        $existingJson = Get-Content $existingConfigPath -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($existingJson)) {
            Write-Host "ERROR: Existing config file is empty!" -ForegroundColor Red
            throw "Existing configuration file is empty"
        }
        
        Write-Host "Parsing JSON..." -ForegroundColor Cyan
        $existingConfig = $existingJson | ConvertFrom-Json -ErrorAction Stop
        
        # Merge configurations (existing takes precedence)
        # Preserve user's Urls (port)
        if ($existingConfig.Urls) {
            $newConfig.Urls = $existingConfig.Urls
            Write-Host "  ? Preserved custom port: $($existingConfig.Urls)" -ForegroundColor Green
        } else {
            Write-Host "  Note: Existing configuration has no custom port setting" -ForegroundColor Yellow
        }
        
        # Preserve user's Runner paths if they exist and differ
        if ($existingConfig.Runner) {
            if ($existingConfig.Runner.ExePath -and $existingConfig.Runner.ExePath -ne $BedrockExePath) {
                # Ensure path is in JSON format (forward slashes)
                $jsonPath = $existingConfig.Runner.ExePath
                if ($jsonPath -like '*\*') {
                    Write-Host "  Converting path from Windows format: $jsonPath" -ForegroundColor Yellow
                    $jsonPath = ConvertTo-JsonPath $jsonPath
                }
                $newConfig.Runner.ExePath = $jsonPath
                Write-Host "  ? Preserved custom Bedrock path: $jsonPath" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom Bedrock path setting" -ForegroundColor Yellow
            }
            if ($existingConfig.Runner.LogFilePath -and $existingConfig.Runner.LogFilePath -ne $LogFilePath) {
                # Ensure path is in JSON format (forward slashes)
                $jsonPath = $existingConfig.Runner.LogFilePath
                if ($jsonPath -like '*\*') {
                    Write-Host "  Converting path from Windows format: $jsonPath" -ForegroundColor Yellow
                    $jsonPath = ConvertTo-JsonPath $jsonPath
                }
                $newConfig.Runner.LogFilePath = $jsonPath
                Write-Host "  ? Preserved custom log path: $jsonPath" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom log path setting" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Note: Existing configuration has no Runner settings" -ForegroundColor Yellow
        }
        
        # Preserve user's Backup settings if customized
        if ($existingConfig.Backup) {
            if ($existingConfig.Backup.FrequencyMinutes) {
                $newConfig.Backup.FrequencyMinutes = $existingConfig.Backup.FrequencyMinutes
                Write-Host "  ? Preserved backup frequency: $($existingConfig.Backup.FrequencyMinutes) minutes" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom backup frequency setting" -ForegroundColor Yellow
            }
            if ($existingConfig.Backup.BackupDirectory -and $existingConfig.Backup.BackupDirectory -ne $BackupsPath) {
                # Ensure path is in JSON format (forward slashes)
                $jsonPath = $existingConfig.Backup.BackupDirectory
                if ($jsonPath -like '*\*') {
                    Write-Host "  Converting path from Windows format: $jsonPath" -ForegroundColor Yellow
                    $jsonPath = ConvertTo-JsonPath $jsonPath
                }
                $newConfig.Backup.BackupDirectory = $jsonPath
                Write-Host "  ? Preserved custom backup path: $jsonPath" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom backup path setting" -ForegroundColor Yellow
            }
            if ($existingConfig.Backup.MaxBackupsToKeep) {
                $newConfig.Backup.MaxBackupsToKeep = $existingConfig.Backup.MaxBackupsToKeep
                Write-Host "  ? Preserved max backups: $($existingConfig.Backup.MaxBackupsToKeep)" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom max backups setting" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Note: Existing configuration has no Backup settings" -ForegroundColor Yellow
        }
        
        # Preserve Xbox Live API key if exists
        if ($existingConfig.XboxLive -and $existingConfig.XboxLive.ApiKey) {
            $newConfig.XboxLive.ApiKey = $existingConfig.XboxLive.ApiKey
            Write-Host "  ? Preserved Xbox Live API key" -ForegroundColor Green
            
            # Preserve other Xbox Live settings if customized
            if ($existingConfig.XboxLive.ApiBaseUrl) {
                $newConfig.XboxLive.ApiBaseUrl = $existingConfig.XboxLive.ApiBaseUrl
                Write-Host "  ? Preserved Xbox Live API Base URL" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom Xbox Live API Base URL setting" -ForegroundColor Yellow
            }
            if ($null -ne $existingConfig.XboxLive.EnableCaching) {
                $newConfig.XboxLive.EnableCaching = $existingConfig.XboxLive.EnableCaching
                Write-Host "  ? Preserved Xbox Live caching setting" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom Xbox Live caching setting" -ForegroundColor Yellow
            }
            if ($existingConfig.XboxLive.CacheExpirationMinutes) {
                $newConfig.XboxLive.CacheExpirationMinutes = $existingConfig.XboxLive.CacheExpirationMinutes
                Write-Host "  ? Preserved Xbox Live cache expiration setting" -ForegroundColor Green
            } else {
                Write-Host "  Note: Existing configuration has no custom Xbox Live cache expiration setting" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Note: Existing configuration has no Xbox Live API key" -ForegroundColor Yellow
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
        Write-Host "WARNING: Could not parse/merge existing config, using new defaults only" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
        
        # Try to show the problematic content if it's the existing config
        if ($existingConfigPath -and (Test-Path $existingConfigPath)) {
            Write-Host "First 500 chars of existing config:" -ForegroundColor Yellow
            $firstChars = Get-Content $existingConfigPath -Raw | Select-Object -First 500
            Write-Host $firstChars -ForegroundColor Gray
        }
        
        Write-Host "Your old config is saved as: appsettings.backup.json" -ForegroundColor Yellow
        # Continue with new config only
    }
}
else {
    Write-Host "No existing config found - creating new appsettings.json" -ForegroundColor Cyan
}

# Write merged configuration
Write-Host "Writing configuration files..." -ForegroundColor Cyan
try {
    Write-Host "Converting configuration to JSON..." -ForegroundColor Cyan
    $json = $newConfig | ConvertTo-Json -Depth 10
    
    if ([string]::IsNullOrWhiteSpace($json)) {
        throw "ConvertTo-Json returned empty string!"
    }
    
    Write-Host "JSON generated, length: $($json.Length) characters" -ForegroundColor Cyan
    
    # Validate JSON before writing
    Write-Host "Validating JSON syntax..." -ForegroundColor Cyan
    $null = $json | ConvertFrom-Json -ErrorAction Stop
    Write-Host "? JSON is valid" -ForegroundColor Green
    
    # Write to file
    Write-Host "Writing appsettings.json to: $appSettingsPath" -ForegroundColor Cyan
    $json | Out-File -FilePath $appSettingsPath -Encoding UTF8 -Force -ErrorAction Stop
    
    # Verify file was written
    if (-not (Test-Path $appSettingsPath)) {
        throw "File was not created at $appSettingsPath"
    }
    Write-Host "? Wrote appsettings.json successfully" -ForegroundColor Green
    
    # Validate file was written correctly
    Write-Host "Validating written file..." -ForegroundColor Cyan
    $fileSize = (Get-Item $appSettingsPath).Length
    Write-Host "File size: $fileSize bytes" -ForegroundColor Cyan
    $testRead = Get-Content $appSettingsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    Write-Host "? Verified appsettings.json is readable and valid JSON" -ForegroundColor Green
    
    # Also create appsettings.user.json for backward compatibility
    Write-Host "Creating appsettings.user.json..." -ForegroundColor Cyan
    $userSettingsPath = Join-Path $InstallDir "appsettings.user.json"
    $json | Out-File -FilePath $userSettingsPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "? Wrote appsettings.user.json successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to write or validate configuration files!" -ForegroundColor Red
    Write-Host "Exception: $($_.Exception.GetType().Name)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Show the JSON that failed if it exists
    if ($json) {
        Write-Host "JSON content (first 1000 chars):" -ForegroundColor Yellow
        Write-Host $json.Substring(0, [Math]::Min(1000, $json.Length)) -ForegroundColor Gray
    }
    
    # Try to write error to file for diagnostics
    $errorLog = Join-Path $InstallDir "merge-error.log"
    @"
Merge Script Error
==================
Time: $(Get-Date)
Exception: $($_.Exception.GetType().Name)
Message: $($_.Exception.Message)
Stack: $($_.ScriptStackTrace)
JSON Length: $($json.Length)
"@ | Out-File -FilePath $errorLog -Encoding UTF8 -Force
    
    Write-Host "Error details saved to: $errorLog" -ForegroundColor Yellow
    exit 1
}

Write-Host "========== Merge-appsettings.ps1 Complete ==========" -ForegroundColor Green
exit 0

