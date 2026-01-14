# Microsoft Store Launch Crash - Diagnosis and Fix Guide

## Problem Summary

The MCBDS.PublicUI app is **crashing at launch** during Microsoft Store certification testing on:
- Microsoft Surface Laptop 5
- Dell Inspiron 13-5379  
- Windows Build: 26200.7462

## Root Cause Analysis

Based on the code review, here are the most likely causes:

### 1. **File System Access Issues (MOST LIKELY)**

The `ServerConfigService` tries to read/write files at startup:

```csharp
// In ServerConfigService constructor
_settingsFilePath = Path.Combine(directory, "server-config.json");
InitializeDefaultConfig();  // Reads file synchronously on startup
```

**Problem:** Store apps run in a **sandboxed environment** with restricted file system access.

**What Happens:**
1. App tries to access `Directory.GetCurrentDirectory()` or `FileSystem.Current.AppDataDirectory`
2. Permission denied or path doesn't exist in sandbox
3. Unhandled exception ? **CRASH**

### 2. **Missing Exception Handling**

```csharp
private void InitializeDefaultConfig()
{
    try
    {
        if (File.Exists(_settingsFilePath))  // May throw UnauthorizedAccessException
        {
            var json = File.ReadAllText(_settingsFilePath);  // May throw IOException
            _cachedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
        }
        // ...
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error: {ex.Message}");  // Console not available in Store apps!
        // ...
    }
}
```

**Problems:**
- `Console.WriteLine()` doesn't work in packaged apps
- Generic exception catch masks specific issues
- App assumes file operations always succeed

### 3. **HttpClient Configuration**

```csharp
// In MauiProgram.cs
var httpClient = new HttpClient();
builder.Services.AddSingleton(httpClient);
```

**Problem:** HttpClient with no timeout/error handling connecting to `localhost:8080` which doesn't exist in certification environment.

### 4. **Missing Crash Telemetry**

No logging or telemetry to capture what actually fails during certification testing.

---

## How to Reproduce Locally

### Method 1: Test in Windows Sandbox (Most Accurate)

Windows Sandbox simulates the Store certification environment:

```powershell
# Enable Windows Sandbox (requires Windows 10/11 Pro or Enterprise)
Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All

# Build your MSIX package
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true

# Copy the MSIX to a shared folder
$msixPath = "AppPackages\MCBDS.PublicUI_1.0.0.0\MCBDS.PublicUI_1.0.0.0_x64.msix"
Copy-Item $msixPath C:\Users\Public\Desktop\

# Launch Windows Sandbox
WindowsSandbox.exe

# Inside Sandbox:
# 1. Copy MSIX from C:\Users\Public\Desktop
# 2. Double-click to install
# 3. Launch app and observe behavior
# 4. Check Event Viewer for crash logs
```

### Method 2: Install and Test Packaged App

```powershell
# Build MSIX package
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true

# Install the package
$msixPath = "AppPackages\MCBDS.PublicUI_1.0.0.0\MCBDS.PublicUI_1.0.0.0_x64.msix"
Add-AppxPackage -Path $msixPath

# Check installation
Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}

# Launch from Start Menu or:
$packageName = (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
Start-Process "shell:AppsFolder\$packageName!App"

# Monitor for crashes
Get-WinEvent -LogName Application -MaxEvents 20 | Where-Object {$_.Message -like "*MCBDS*" -or $_.ProviderName -like "*ApplicationError*"}
```

### Method 3: Test with WACK (Windows App Certification Kit)

```powershell
# Run full certification tests
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" test `
  -appxpackagepath "AppPackages\MCBDS.PublicUI_1.0.0.0\MCBDS.PublicUI_1.0.0.0_x64.msix" `
  -reportoutputpath "wack-report.xml"

# WACK will test:
# - Launch and suspend
# - File system access
# - Network access
# - Resource usage
# - API compliance
```

### Method 4: Simulate Missing Config Files

```powershell
# Create a test without any config files
$testDir = "C:\Temp\MCBDSTest"
New-Item -ItemType Directory -Path $testDir -Force

# Try to create ServerConfigService with non-existent directory
# This simulates what happens in a fresh Store install
```

---

## The Fix

### Step 1: Add Robust Error Handling and Logging

Create a new crash logging service:

```csharp
// MCBDS.PublicUI/Services/CrashLogger.cs
using System.Diagnostics;

namespace MCBDS.PublicUI.Services;

public static class CrashLogger
{
    private static string? _logFilePath;

    public static void Initialize(string appDataDirectory)
    {
        try
        {
            _logFilePath = Path.Combine(appDataDirectory, "crash-log.txt");
        }
        catch
        {
            // Fallback to temp
            _logFilePath = Path.Combine(Path.GetTempPath(), "mcbds-crash-log.txt");
        }
    }

    public static void Log(string message, Exception? ex = null)
    {
        try
        {
            var logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
            if (ex != null)
            {
                logEntry += $"\nException: {ex.GetType().Name}\nMessage: {ex.Message}\nStackTrace: {ex.StackTrace}";
            }

            Debug.WriteLine(logEntry);

            if (_logFilePath != null)
            {
                File.AppendAllText(_logFilePath, logEntry + "\n\n");
            }
        }
        catch
        {
            // Swallow logging errors - don't crash because logging failed
            Debug.WriteLine($"Failed to write log: {message}");
        }
    }

    public static string? GetLogFilePath() => _logFilePath;
}
```

### Step 2: Fix ServerConfigService

Update the service to handle all file system errors gracefully:

```csharp
// MCBDS.ClientUI.Shared/Services/ServerConfigService.cs - UpdatedinitializeDefaultConfig method

private void InitializeDefaultConfig()
{
    try
    {
        CrashLogger.Log("Initializing ServerConfigService");
        CrashLogger.Log($"Settings file path: {_settingsFilePath}");

        // Try to load config synchronously on startup
        if (File.Exists(_settingsFilePath))
        {
            CrashLogger.Log("Config file exists, attempting to read");
            var json = File.ReadAllText(_settingsFilePath);
            _cachedConfig = JsonSerializer.Deserialize<ServerConfig>(json);
            CrashLogger.Log("Config loaded successfully");
        }
        else
        {
            CrashLogger.Log("Config file does not exist, using defaults");
        }
        
        _cachedConfig ??= GetDefaultConfig();
        
        // Set the HttpClient base address immediately
        if (!string.IsNullOrWhiteSpace(_cachedConfig.CurrentServerUrl))
        {
            SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
            CrashLogger.Log($"HttpClient base address set to: {_cachedConfig.CurrentServerUrl}");
        }
        
        _isInitialized = true;
        CrashLogger.Log("ServerConfigService initialized successfully");
    }
    catch (UnauthorizedAccessException ex)
    {
        CrashLogger.Log("File access denied - using default config", ex);
        _cachedConfig = GetDefaultConfig();
        SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
        _isInitialized = true;
    }
    catch (IOException ex)
    {
        CrashLogger.Log("IO error - using default config", ex);
        _cachedConfig = GetDefaultConfig();
        SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
        _isInitialized = true;
    }
    catch (JsonException ex)
    {
        CrashLogger.Log("JSON parsing error - using default config", ex);
        _cachedConfig = GetDefaultConfig();
        SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
        _isInitialized = true;
    }
    catch (Exception ex)
    {
        CrashLogger.Log("Unexpected error during initialization - using default config", ex);
        _cachedConfig = GetDefaultConfig();
        SetHttpClientBaseAddress(_cachedConfig.CurrentServerUrl);
        _isInitialized = true;
    }
}
```

### Step 3: Add Safety Checks to MauiProgram.cs

```csharp
// MCBDS.PublicUI/MauiProgram.cs

public static MauiApp CreateMauiApp()
{
    try
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
            });

        // Initialize crash logger FIRST
        var appDataDirectory = FileSystem.Current.AppDataDirectory;
        CrashLogger.Initialize(appDataDirectory);
        CrashLogger.Log("MauiProgram.CreateMauiApp started");

        // Create HttpClient with timeout
        var httpClient = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(30)
        };
        builder.Services.AddSingleton(httpClient);
        CrashLogger.Log("HttpClient configured");
        
        // Register ServerConfigService with MAUI AppDataDirectory for persistence
        builder.Services.AddSingleton<ServerConfigService>(sp => 
        {
            try
            {
                var client = sp.GetRequiredService<HttpClient>();
                CrashLogger.Log($"Creating ServerConfigService with directory: {appDataDirectory}");
                return new ServerConfigService(client, appDataDirectory);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("Failed to create ServerConfigService", ex);
                throw;
            }
        });
        
        // Register BedrockApiService with ServerConfigService for dynamic URL resolution
        builder.Services.AddSingleton<BedrockApiService>(sp =>
        {
            try
            {
                var client = sp.GetRequiredService<HttpClient>();
                var serverConfig = sp.GetRequiredService<ServerConfigService>();
                CrashLogger.Log("Creating BedrockApiService");
                return new BedrockApiService(client, serverConfig);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("Failed to create BedrockApiService", ex);
                throw;
            }
        });

        // Register BackupSettingsService with MAUI AppDataDirectory
        builder.Services.AddSingleton<BackupSettingsService>(sp => 
        {
            try
            {
                CrashLogger.Log($"Creating BackupSettingsService with directory: {appDataDirectory}");
                return new BackupSettingsService(appDataDirectory);
            }
            catch (Exception ex)
            {
                CrashLogger.Log("Failed to create BackupSettingsService", ex);
                throw;
            }
        });

        builder.Services.AddMauiBlazorWebView();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.AddDebug();
#endif

        CrashLogger.Log("MauiProgram.CreateMauiApp completed successfully");
        return builder.Build();
    }
    catch (Exception ex)
    {
        CrashLogger.Log("FATAL: MauiProgram.CreateMauiApp failed", ex);
        
        // Show error dialog
        Application.Current?.MainPage?.DisplayAlert(
            "Startup Error",
            $"The app failed to start. Error: {ex.Message}\n\nLog file: {CrashLogger.GetLogFilePath()}",
            "OK");
        
        throw;
    }
}
```

### Step 4: Add Error Boundary in App.xaml.cs

```csharp
// MCBDS.PublicUI/App.xaml.cs

namespace MCBDS.PublicUI;

public partial class App : Application
{
    public App()
    {
        try
        {
            CrashLogger.Log("App constructor started");
            InitializeComponent();
            CrashLogger.Log("App InitializeComponent completed");
        }
        catch (Exception ex)
        {
            CrashLogger.Log("FATAL: App constructor failed", ex);
            throw;
        }
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        try
        {
            CrashLogger.Log("CreateWindow called");
            var window = new Window(new MainPage()) { Title = "MCBDS Manager" };
            CrashLogger.Log("Window created successfully");
            return window;
        }
        catch (Exception ex)
        {
            CrashLogger.Log("FATAL: CreateWindow failed", ex);
            throw;
        }
    }

    protected override void OnStart()
    {
        base.OnStart();
        CrashLogger.Log("App.OnStart called");
    }

    protected override void OnResume()
    {
        base.OnResume();
        CrashLogger.Log("App.OnResume called");
    }

    protected override void OnSleep()
    {
        base.OnSleep();
        CrashLogger.Log("App.OnSleep called");
    }
}
```

### Step 5: Update Package Manifest Capabilities

Ensure `Package.appxmanifest` has proper capabilities:

```xml
<Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <Capability Name="internetClient" />
    <!-- Add if you need broader file access -->
    <rescap:Capability Name="broadFileSystemAccess" />
</Capabilities>
```

### Step 6: Add a Diagnostic Settings Page

Create a settings page that shows the crash log:

```razor
<!-- MCBDS.PublicUI/Components/Pages/Diagnostics.razor -->
@page "/diagnostics"
@using MCBDS.PublicUI.Services

<h3>Diagnostic Information</h3>

<div class="card">
    <div class="card-body">
        <h5>Crash Log</h5>
        <button class="btn btn-primary" @onclick="RefreshLog">Refresh Log</button>
        <button class="btn btn-secondary" @onclick="ClearLog">Clear Log</button>
        
        @if (!string.IsNullOrEmpty(logFilePath))
        {
            <p><strong>Log File:</strong> @logFilePath</p>
        }
        
        <pre style="max-height: 400px; overflow-y: auto; background: #f5f5f5; padding: 10px;">
@logContent
        </pre>
    </div>
</div>

@code {
    private string? logFilePath;
    private string logContent = "Loading...";

    protected override void OnInitialized()
    {
        RefreshLog();
    }

    private void RefreshLog()
    {
        logFilePath = CrashLogger.GetLogFilePath();
        
        try
        {
            if (logFilePath != null && File.Exists(logFilePath))
            {
                logContent = File.ReadAllText(logFilePath);
            }
            else
            {
                logContent = "No log file found.";
            }
        }
        catch (Exception ex)
        {
            logContent = $"Error reading log: {ex.Message}";
        }
    }

    private void ClearLog()
    {
        try
        {
            if (logFilePath != null && File.Exists(logFilePath))
            {
                File.WriteAllText(logFilePath, string.Empty);
                logContent = "Log cleared.";
            }
        }
        catch (Exception ex)
        {
            logContent = $"Error clearing log: {ex.Message}";
        }
    }
}
```

---

## Testing After Fix

### 1. Build and Test Locally

```powershell
# Build Release configuration
dotnet build -f net10.0-windows10.0.19041.0 -c Release

# Create MSIX package
dotnet publish -f net10.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=MSIX `
  -p:GenerateAppxPackageOnBuild=true

# Install package
$msixPath = (Get-ChildItem -Path "AppPackages" -Recurse -Filter "*.msix" | Select-Object -First 1).FullName
Add-AppxPackage -Path $msixPath -ForceApplicationShutdown

# Launch and check diagnostics page
Start-Process "shell:AppsFolder\$(
  (Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}).PackageFamilyName
)!App"
```

### 2. Check Crash Logs

```powershell
# Find app data directory
$package = Get-AppxPackage | Where-Object {$_.Name -like "*MCBDS*"}
$appDataPath = "$env:LOCALAPPDATA\Packages\$($package.PackageFamilyName)\LocalState"

# View crash log
Get-Content "$appDataPath\crash-log.txt"
```

### 3. Test in Windows Sandbox

Follow Method 1 from "How to Reproduce Locally" section.

### 4. Run WACK Tests

```powershell
& "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe" test `
  -appxpackagepath $msixPath `
  -reportoutputpath "wack-report.xml"

# Review report
Start-Process "wack-report.html"
```

---

## Submission Notes for Microsoft

When resubmitting to the Store, include these notes for certification:

```
NOTES FOR CERTIFICATION TESTERS:

App Launch Requirements:
- The app is designed to manage a Minecraft Bedrock Server
- Full functionality requires Docker Desktop (optional for testing UI)
- The app will work without Docker, showing appropriate error messages

First Launch Behavior:
- App creates configuration files in LocalState folder on first run
- Default server URL is set to localhost:8080
- No external dependencies required for UI testing

Testing the App:
1. Launch the app - should open without crashing
2. Navigate to "Overview" page - shows app info
3. Navigate to "Commands" page - shows command interface
4. Navigate to "Diagnostics" page (if available) - shows crash logs
5. The app is fully functional for UI testing

Diagnostic Information:
- Crash logs are saved to: %LOCALAPPDATA%\Packages\[PackageFamily]\LocalState\crash-log.txt
- All file operations have fallback error handling
- The app will NOT crash if config files are missing

Known Limitations:
- Server management features require Docker Desktop (not needed for certification)
- Some features show "connection error" without a running backend (expected behavior)

Test Credentials:
- Not required - app is fully functional without authentication
```

---

## Additional Recommendations

### 1. Add Telemetry (Optional)

Consider adding Application Insights or similar:

```xml
<!-- MCBDS.PublicUI.csproj -->
<ItemGroup>
  <PackageReference Include="Microsoft.ApplicationInsights.WorkerService" Version="2.21.0" />
</ItemGroup>
```

### 2. Add First-Run Experience

Create a welcome screen that explains app requirements:

```razor
@page "/welcome"

<h3>Welcome to MCBDS Manager!</h3>

<div class="alert alert-info">
    <h4>First-Time Setup</h4>
    <p>This app manages Minecraft Bedrock Dedicated Servers.</p>
    <p><strong>Requirements for full functionality:</strong></p>
    <ul>
        <li>Docker Desktop installed</li>
        <li>MCBDS API running (on localhost:8080 or custom URL)</li>
    </ul>
    <p>You can still explore the app without these requirements.</p>
</div>

<button class="btn btn-primary" @onclick="Continue">Continue</button>
```

### 3. Improve HttpClient Configuration

```csharp
var httpClient = new HttpClient(new SocketsHttpHandler
{
    PooledConnectionLifetime = TimeSpan.FromMinutes(2),
    ConnectTimeout = TimeSpan.FromSeconds(5)
})
{
    Timeout = TimeSpan.FromSeconds(30)
};

// Add default headers
httpClient.DefaultRequestHeaders.Add("User-Agent", "MCBDS.PublicUI/1.0");
```

---

## Summary Checklist

Before resubmitting:

- [ ] Add `CrashLogger` service
- [ ] Update `ServerConfigService` with detailed logging and error handling
- [ ] Update `MauiProgram.cs` with try-catch blocks
- [ ] Update `App.xaml.cs` with lifecycle logging
- [ ] Add diagnostics page to view crash logs
- [ ] Test in Windows Sandbox
- [ ] Run WACK tests
- [ ] Install and test MSIX package locally
- [ ] Verify app doesn't crash without config files
- [ ] Verify app doesn't crash without network connectivity
- [ ] Update submission notes for Microsoft
- [ ] Increment version number
- [ ] Rebuild and resubmit

---

## Expected Results

After implementing these fixes:

? **App launches successfully** even without config files  
? **Graceful error handling** for all file system operations  
? **Detailed crash logs** for any remaining issues  
? **Pass WACK tests** without errors  
? **Pass Microsoft Store certification**  

---

## Getting Crash Logs After Submission Fails

If the app still crashes after resubmission:

1. Request detailed crash logs from Microsoft Support
2. Check Partner Center **Health** section for crash reports
3. Enable **Analytics** in Partner Center
4. Contact developer support: http://aka.ms/storesupport

---

## Contact

For questions about this fix:
- GitHub Issues: https://github.com/JoshuaBylotas/MCBDSHost/issues
- Email: support@mc-bds.com
