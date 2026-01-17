using MCBDS.ClientUI.Shared.Services;

namespace MCBDS.PublicUI.Services;

public class MauiFormFactorService : IFormFactor
{
    public string GetFormFactor()
    {
        if (DeviceInfo.Idiom == DeviceIdiom.Phone)
            return "Mobile";
        if (DeviceInfo.Idiom == DeviceIdiom.Tablet)
            return "Tablet";
        if (DeviceInfo.Idiom == DeviceIdiom.Desktop)
            return "Desktop";
        if (DeviceInfo.Idiom == DeviceIdiom.TV)
            return "TV";
        if (DeviceInfo.Idiom == DeviceIdiom.Watch)
            return "Watch";
        return "Unknown";
    }

    public string GetPlatform()
    {
        return DeviceInfo.Platform.ToString();
    }
    
    public bool IsAndroid()
    {
        return DeviceInfo.Platform == DevicePlatform.Android;
    }
    
    public bool IsMobile()
    {
        return DeviceInfo.Idiom == DeviceIdiom.Phone;
    }
}
