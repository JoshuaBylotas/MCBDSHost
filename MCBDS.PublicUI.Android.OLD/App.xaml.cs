namespace MCBDS.PublicUI.Android;

public partial class App : Application
{
	public App()
	{
		try
		{
			System.Diagnostics.Debug.WriteLine("App constructor: starting InitializeComponent");
			InitializeComponent();
			System.Diagnostics.Debug.WriteLine("App constructor: InitializeComponent completed successfully");
		}
		catch (Exception ex)
		{
			System.Diagnostics.Debug.WriteLine($"App constructor: InitializeComponent FAILED");
			System.Diagnostics.Debug.WriteLine($"Exception: {ex}");
			System.Diagnostics.Debug.WriteLine($"StackTrace: {ex.StackTrace}");
			throw;
		}
	}

	protected override Window CreateWindow(IActivationState? activationState)
	{
		try
		{
			System.Diagnostics.Debug.WriteLine("CreateWindow: creating MainPage");
			var mainPage = new MainPage();
			System.Diagnostics.Debug.WriteLine("CreateWindow: MainPage created");
			
			var window = new Window(mainPage) { Title = "MCBDS Manager" };
			System.Diagnostics.Debug.WriteLine("CreateWindow: Window created successfully");
			return window;
		}
		catch (Exception ex)
		{
			System.Diagnostics.Debug.WriteLine($"CreateWindow: FAILED");
			System.Diagnostics.Debug.WriteLine($"Exception: {ex}");
			System.Diagnostics.Debug.WriteLine($"StackTrace: {ex.StackTrace}");
			throw;
		}
	}
}
