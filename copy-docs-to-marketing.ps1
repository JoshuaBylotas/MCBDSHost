# Script to copy all markdown documentation files to the Marketing wwwroot/docs folder

$sourceRoot = ".."
$targetDocsFolder = "MCBDS.Marketing\wwwroot\docs"

# Create the docs folder if it doesn't exist
if (-not (Test-Path $targetDocsFolder)) {
    New-Item -Path $targetDocsFolder -ItemType Directory -Force | Out-Null
    Write-Host "Created docs folder: $targetDocsFolder" -ForegroundColor Green
}

# Create subdirectory for deployment-packages
$deploymentPackagesTarget = Join-Path $targetDocsFolder "deployment-packages"
if (-not (Test-Path $deploymentPackagesTarget)) {
    New-Item -Path $deploymentPackagesTarget -ItemType Directory -Force | Out-Null
}

# Copy root level markdown files
$rootMdFiles = @(
    "ASPIRE_MAUI_SETUP.md",
    "BACKUP_FIX_SAVE_QUERY_WAIT.md",
    "BACKUP_SERVICE_SUMMARY.md",
    "BACKUP_SETTINGS_FEATURE.md",
    "BACKUP_UI_INTEGRATION.md",
    "BUILD_FIX_BACKUP_SETTINGS.md",
    "COMMAND_INTELLISENSE_IMPLEMENTATION.md",
    "COMMAND_INTELLISENSE.md",
    "COMMAND-SENDING-ERROR-FIX.md",
    "DOCKER_DEPLOYMENT.md",
    "EXTERNAL_BEDROCK_SERVER_ARCHITECTURE.md",
    "FILE_PATH_PARSING_FIX.md",
    "GAMERULE-AUTOCOMPLETE-IMPLEMENTATION.md",
    "HOT_RELOAD_BACKUP_SETTINGS.md",
    "MCBDS_MARKETING_DEPLOYMENT.md",
    "PUBLICUI_CHANGES.md",
    "QUICK_START.md",
    "RASPBERRY_PI_DEPLOYMENT.md",
    "README.md",
    "SERVER_PROPERTIES_FEATURE.md",
    "SETTINGS_FINAL_FIX.md",
    "SETTINGS_PERSISTENCE_DEBUG.md",
    "SETTINGS_REVERT_FIX.md",
    "SSH_DEPLOYMENT_QUICKSTART.md",
    "WINDOWS_SERVER_DEPLOYMENT.md",
    "WORLD_PATH_FIX.md"
)

Write-Host "`nCopying root level markdown files..." -ForegroundColor Cyan
foreach ($file in $rootMdFiles) {
    $sourcePath = Join-Path $sourceRoot $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $targetDocsFolder -Force
        Write-Host "  ? Copied $file" -ForegroundColor Green
    } else {
        Write-Host "  ? Not found: $file" -ForegroundColor Yellow
    }
}

# Copy deployment-packages markdown files
$deploymentMdFiles = @(
    "COMPLETE-SUBMISSION-PACKAGE.md",
    "CONTACT-SUPPORT-FEATURE.md",
    "DASHBOARD-IMAGE-SETUP.md",
    "DEPLOYMENT-GUIDE.md",
    "DOWNLOADS-IMPLEMENTATION.md",
    "DOWNLOADS-QUICK-FIX.md",
    "DOWNLOADS-REMOVED-GITHUB.md",
    "DOWNLOADS-SETUP.md",
    "GOFUNDME-DONATION-INTEGRATION.md",
    "GOOGLE-ANALYTICS-SETUP.md",
    "GOOGLE-ANALYTICS-VERIFICATION-FIX.md",
    "GOOGLE-ANALYTICS-VERIFICATION-QUICK-FIX.md",
    "IIS-TROUBLESHOOTING.md",
    "MINECRAFT-THEME-GUIDE.md",
    "PACKAGE-SUMMARY.md",
    "QUICK-REFERENCE-SUBMISSION.md",
    "README.md",
    "SEARCH-ENGINE-SUBMISSION-GUIDE.md",
    "SEO-SETUP-GUIDE.md",
    "SITEMAP-404-FIX.md",
    "SITEMAP-IMPLEMENTATION-SUMMARY.md",
    "WEB-CONFIG-FIX.md",
    "BACKUP_QUICK_START.md",
    "BACKUP_SERVICE_DOCUMENTATION.md",
    "PORT_CONFIGURATION.md"
)

Write-Host "`nCopying deployment-packages markdown files..." -ForegroundColor Cyan
$deploymentSource = Join-Path $sourceRoot "deployment-packages"
foreach ($file in $deploymentMdFiles) {
    $sourcePath = Join-Path $deploymentSource $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $deploymentPackagesTarget -Force
        Write-Host "  ? Copied deployment-packages/$file" -ForegroundColor Green
    } else {
        Write-Host "  ? Not found: deployment-packages/$file" -ForegroundColor Yellow
    }
}

# Copy MCBDS.Marketing specific files
$marketingSource = Join-Path $sourceRoot "MCBDS.Marketing"
$marketingFile = "DOMAIN-UPDATE-SUMMARY.md"
$marketingTarget = Join-Path $targetDocsFolder "MCBDS.Marketing"

if (-not (Test-Path $marketingTarget)) {
    New-Item -Path $marketingTarget -ItemType Directory -Force | Out-Null
}

$marketingFilePath = Join-Path $marketingSource $marketingFile
if (Test-Path $marketingFilePath) {
    Copy-Item -Path $marketingFilePath -Destination $marketingTarget -Force
    Write-Host "`n? Copied MCBDS.Marketing/$marketingFile" -ForegroundColor Green
}

Write-Host "`n? Documentation files copied successfully!" -ForegroundColor Green
Write-Host "Total files copied to: $targetDocsFolder" -ForegroundColor Cyan

# Count files
$totalFiles = (Get-ChildItem -Path $targetDocsFolder -Recurse -Filter "*.md" | Measure-Object).Count
Write-Host "Total markdown files: $totalFiles" -ForegroundColor Cyan
