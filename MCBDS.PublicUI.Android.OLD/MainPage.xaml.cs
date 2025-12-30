using Microsoft.AspNetCore.Components.WebView;

namespace MCBDS.PublicUI.Android;

public partial class MainPage : ContentPage
{
	public MainPage()
	{
		try
		{
			System.Diagnostics.Debug.WriteLine("MainPage constructor: starting");
			InitializeComponent();
			System.Diagnostics.Debug.WriteLine("MainPage constructor: InitializeComponent completed");
			
			// Add URL changed handler to track navigation
			blazorWebView.UrlLoading += OnUrlLoading;
		}
		catch (Exception ex)
		{
			System.Diagnostics.Debug.WriteLine($"MainPage constructor: FAILED");
			System.Diagnostics.Debug.WriteLine($"Exception: {ex.Message}");
			System.Diagnostics.Debug.WriteLine($"StackTrace: {ex.StackTrace}");
			throw;
		}
	}

	private void OnBlazorWebViewInitializing(object? sender, BlazorWebViewInitializingEventArgs e)
	{
		System.Diagnostics.Debug.WriteLine("? BlazorWebView: Initializing...");
	}

	private void OnBlazorWebViewInitialized(object? sender, BlazorWebViewInitializedEventArgs e)
	{
		System.Diagnostics.Debug.WriteLine("? BlazorWebView: Initialized successfully");
		System.Diagnostics.Debug.WriteLine($"   WebView available: {e.WebView != null}");
	}

	private void OnUrlLoading(object? sender, UrlLoadingEventArgs e)
	{
		System.Diagnostics.Debug.WriteLine($"BlazorWebView: Loading URL: {e.Url}");
		System.Diagnostics.Debug.WriteLine($"   Scheme: {e.Url.Scheme}, Host: {e.Url.Host}");
	}
}
