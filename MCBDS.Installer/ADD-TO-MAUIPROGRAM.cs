// ============================================================
// ADD THIS TO MauiProgram.cs AFTER LINE 104
// (After BackupSettingsService registration)
// ============================================================

// Register CommandHistoryService with MAUI AppDataDirectory
builder.Services.AddSingleton<CommandHistoryService>(sp => 
{
	try
	{
		var appDataDir = FileSystem.Current.AppDataDirectory;
		CrashLogger.LogInfo($"Creating CommandHistoryService with directory: {appDataDir}");
		return new CommandHistoryService(appDataDir);
	}
	catch (Exception ex)
	{
		CrashLogger.LogError("Failed to create CommandHistoryService", ex);
		throw;
	}
});

// ============================================================
// LOCATION: Insert between lines 104-105
// BEFORE: // Register platform service
// AFTER: BackupSettingsService registration closing });
// ============================================================
