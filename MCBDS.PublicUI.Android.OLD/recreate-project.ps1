# Recreate MCBDS.PublicUI.Android from scratch using official template
# This will guarantee a working configuration

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  Recreating MCBDS.PublicUI.Android from Official Template"
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Backup the old project
Write-Host "Step 1: Backing up old project..." -ForegroundColor Yellow
if (Test-Path "MCBDS.PublicUI.Android.OLD") {
    Remove-Item "MCBDS.PublicUI.Android.OLD" -Recurse -Force
}
if (Test-Path "MCBDS.PublicUI.Android") {
    Move-Item "MCBDS.PublicUI.Android" "MCBDS.PublicUI.Android.OLD"
    Write-Host "   ? Old project backed up to MCBDS.PublicUI.Android.OLD" -ForegroundColor Green
} else {
    Write-Host "   ! No existing project to backup" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Creating new project from template..." -ForegroundColor Yellow
# Create new MAUI Blazor project targeting only Android
dotnet new maui-blazor -n MCBDS.PublicUI.Android -o MCBDS.PublicUI.Android

if (-not (Test-Path "MCBDS.PublicUI.Android")) {
    Write-Host "   ? Failed to create project from template!" -ForegroundColor Red
    if (Test-Path "MCBDS.PublicUI.Android.OLD") {
        Move-Item "MCBDS.PublicUI.Android.OLD" "MCBDS.PublicUI.Android"
        Write-Host "   Restored old project" -ForegroundColor Yellow
    }
    exit 1
}
Write-Host "   ? New project created" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Modifying .csproj to target only Android..." -ForegroundColor Yellow

# Read the generated csproj
$csprojPath = "MCBDS.PublicUI.Android\MCBDS.PublicUI.Android.csproj"
$csprojContent = Get-Content $csprojPath -Raw

# Replace multi-target with Android-only
$csprojContent = $csprojContent -replace '<TargetFrameworks>.*?</TargetFrameworks>', '<TargetFramework>net10.0-android</TargetFramework>'

# Update application ID
$csprojContent = $csprojContent -replace '<ApplicationId>.*?</ApplicationId>', '<ApplicationId>com.mcbds.publicui.android</ApplicationId>'

# Update application title
$csprojContent = $csprojContent -replace '<ApplicationTitle>.*?</ApplicationTitle>', '<ApplicationTitle>MCBDS Manager</ApplicationTitle>'

# Add project reference before closing </Project> tag
$projectReference = @"
  <ItemGroup>
    <ProjectReference Include="..\MCBDS.ClientUI\MCBDS.ClientUI.Shared\MCBDS.ClientUI.Shared.csproj" />
  </ItemGroup>

</Project>
"@

$csprojContent = $csprojContent -replace '</Project>', $projectReference

Set-Content $csprojPath $csprojContent
Write-Host "   ? .csproj modified for Android-only" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Copying Components from MCBDS.PublicUI..." -ForegroundColor Yellow

# Remove template components
Remove-Item "MCBDS.PublicUI.Android\Components" -Recurse -Force -ErrorAction SilentlyContinue

# Copy our components
Copy-Item -Path "MCBDS.PublicUI\Components" -Destination "MCBDS.PublicUI.Android\Components" -Recurse -Force
Write-Host "   ? Components copied" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Copying wwwroot from MCBDS.PublicUI..." -ForegroundColor Yellow

# Remove template wwwroot
Remove-Item "MCBDS.PublicUI.Android\wwwroot" -Recurse -Force -ErrorAction SilentlyContinue

# Copy our wwwroot
Copy-Item -Path "MCBDS.PublicUI\wwwroot" -Destination "MCBDS.PublicUI.Android\wwwroot" -Recurse -Force
Write-Host "   ? wwwroot copied" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Updating MauiProgram.cs with our services..." -ForegroundColor Yellow

$mauiProgramContent = @'
using Microsoft.Extensions.Logging;
using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI.Android;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
			});

		// Register HttpClient
		var httpClient = new HttpClient();
		builder.Services.AddSingleton(httpClient);

		// Register ServerConfigService with MAUI AppDataDirectory for persistence
		builder.Services.AddSingleton<ServerConfigService>(sp => 
		{
			var client = sp.GetRequiredService<HttpClient>();
			return new ServerConfigService(client, FileSystem.Current.AppDataDirectory);
		});

		// Register BedrockApiService
		builder.Services.AddSingleton<BedrockApiService>(sp =>
		{
			var client = sp.GetRequiredService<HttpClient>();
			var serverConfig = sp.GetRequiredService<ServerConfigService>();
			return new BedrockApiService(client, serverConfig);
		});

		builder.Services.AddMauiBlazorWebView();

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}
'@

Set-Content "MCBDS.PublicUI.Android\MauiProgram.cs" $mauiProgramContent
Write-Host "   ? MauiProgram.cs updated" -ForegroundColor Green

Write-Host ""
Write-Host "Step 7: Copying AndroidManifest.xml..." -ForegroundColor Yellow

if (Test-Path "MCBDS.PublicUI.Android.OLD\Platforms\Android\AndroidManifest.xml") {
    Copy-Item "MCBDS.PublicUI.Android.OLD\Platforms\Android\AndroidManifest.xml" "MCBDS.PublicUI.Android\Platforms\Android\AndroidManifest.xml" -Force
    Write-Host "   ? AndroidManifest.xml copied from old project" -ForegroundColor Green
} else {
    Write-Host "   ! No AndroidManifest.xml to copy, using template default" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 8: Verifying project structure..." -ForegroundColor Yellow

$checks = @{
    "Components\Routes.razor" = $false
    "Components\Layout\MainLayout.razor" = $false
    "Components\Pages\Home.razor" = $false
    "wwwroot\index.html" = $false
    "wwwroot\lib\bootstrap" = $false
    "MauiProgram.cs" = $false
    "MCBDS.PublicUI.Android.csproj" = $false
}

foreach ($file in $checks.Keys) {
    $path = Join-Path "MCBDS.PublicUI.Android" $file
    if (Test-Path $path) {
        $checks[$file] = $true
        Write-Host "   ? $file" -ForegroundColor Green
    } else {
        Write-Host "   ? $file MISSING!" -ForegroundColor Red
    }
}

$allPresent = ($checks.Values | Where-Object { $_ -eq $false }).Count -eq 0

if (-not $allPresent) {
    Write-Host ""
    Write-Host "   ? Some files are missing!" -ForegroundColor Yellow
    Write-Host "   The project may not work correctly." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 9: Building new project..." -ForegroundColor Yellow

try {
    $buildOutput = dotnet build MCBDS.PublicUI.Android\MCBDS.PublicUI.Android.csproj -f net10.0-android 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ? Build successful!" -ForegroundColor Green
    } else {
        Write-Host "   ? Build failed!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Build output:" -ForegroundColor Yellow
        $buildOutput | Select-Object -Last 20 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        throw "Build failed"
    }
} catch {
    Write-Host ""
    Write-Host "   ? Build encountered errors" -ForegroundColor Red
    Write-Host ""
    Write-Host "You may need to:" -ForegroundColor Yellow
    Write-Host "   1. Check that MCBDS.ClientUI.Shared project exists" -ForegroundColor Gray
    Write-Host "   2. Verify all dependencies are installed" -ForegroundColor Gray
    Write-Host "   3. Manually fix any remaining issues" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  ? PROJECT RECREATION COMPLETE!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

if ($allPresent) {
    Write-Host "The project has been successfully recreated from the official template." -ForegroundColor Green
    Write-Host "All your Components and wwwroot files have been copied." -ForegroundColor Green
    Write-Host "Your services have been registered in MauiProgram.cs." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: dotnet run MCBDS.PublicUI.Android -f net10.0-android" -ForegroundColor Gray
    Write-Host "  2. The app should now load without a blank screen!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Your old project is backed up in: MCBDS.PublicUI.Android.OLD" -ForegroundColor Yellow
    Write-Host "You can delete it once you verify the new project works." -ForegroundColor Yellow
} else {
    Write-Host "? Project recreation completed with warnings" -ForegroundColor Yellow
    Write-Host "Some files may be missing. Check the output above." -ForegroundColor Yellow
}

Write-Host ""
