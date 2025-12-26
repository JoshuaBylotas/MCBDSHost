namespace MCBDS.API.Models;

public class BackupConfiguration
{
    public int FrequencyMinutes { get; set; } = 30;
    public string BackupDirectory { get; set; } = string.Empty;
    public int MaxBackupsToKeep { get; set; } = 10;
    public string? WorldPath { get; set; }
}
