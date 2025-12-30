using Android.App;
using Android.Content.PM;

namespace MCBDS.PublicUI.Android
{
    [Activity(
        Theme = "@style/Maui.SplashTheme",
        MainLauncher = true,
        ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density,
        LaunchMode = LaunchMode.SingleTop
    )]
    public class MainActivity : MauiAppCompatActivity
    {
    }
}
