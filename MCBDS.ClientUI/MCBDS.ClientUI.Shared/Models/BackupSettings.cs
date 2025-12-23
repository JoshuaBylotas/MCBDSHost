namespace MCBDS.ClientUI.Shared.Models;

public class BackupSettings
{
    public int FrequencyMinutes { get; set; } = 30;
    public string OutputDirectory { get; set; } = string.Empty;
}
