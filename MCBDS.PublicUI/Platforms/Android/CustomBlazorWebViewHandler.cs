using Android.Views;
using Microsoft.AspNetCore.Components.WebView.Maui;
using Microsoft.Maui.Handlers;
using AWebView = Android.Webkit.WebView;

namespace MCBDS.PublicUI.Platforms.Android;

public class CustomBlazorWebViewHandler : BlazorWebViewHandler
{
    protected override AWebView CreatePlatformView()
    {
        var webView = base.CreatePlatformView();
        
        // Enable viewport-fit=cover for safe area insets
        if (webView.Settings != null)
        {
            webView.Settings.LoadWithOverviewMode = true;
            webView.Settings.UseWideViewPort = true;
        }
        
        return webView;
    }
}
