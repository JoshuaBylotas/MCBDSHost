using MCBDS.PublicUI.Services;

namespace MCBDS.PublicUI;

public partial class App : Application
{
	public App()
	{
		try
		{
			CrashLogger.LogInfo("App constructor started");
			InitializeComponent();
			CrashLogger.LogInfo("App InitializeComponent completed");
		}
		catch (Exception ex)
		{
			CrashLogger.LogFatal("App constructor failed", ex);
			System.Diagnostics.Debug.WriteLine($"FATAL ERROR in App constructor: {ex}");
			throw;
		}
	}

	protected override Window CreateWindow(IActivationState? activationState)
	{
		try
		{
			CrashLogger.LogInfo("CreateWindow called");
			var window = new Window(new MainPage()) { Title = "MCBDS Manager" };
			CrashLogger.LogInfo("Window created successfully");
			return window;
		}
		catch (Exception ex)
		{
			CrashLogger.LogFatal("CreateWindow failed", ex);
			System.Diagnostics.Debug.WriteLine($"FATAL ERROR in CreateWindow: {ex}");
			throw;
		}
	}

	protected override void OnStart()
	{
		base.OnStart();
		CrashLogger.LogInfo("App.OnStart called - application is starting");
	}

	protected override void OnResume()
	{
		base.OnResume();
		CrashLogger.LogInfo("App.OnResume called - application is resuming from background");
	}

	protected override void OnSleep()
	{
		base.OnSleep();
		CrashLogger.LogInfo("App.OnSleep called - application is going to background");
	}
}
