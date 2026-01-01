using System.Reflection;
using System.Text.RegularExpressions;

namespace MCBDS.Marketing.Services;

public class DocumentationService
{
    public class DocumentationItem
    {
        public string Title { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string Route { get; set; } = string.Empty;
    }

    private readonly IWebHostEnvironment _environment;
    private List<DocumentationItem>? _cachedDocs;

    public DocumentationService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public async Task<List<DocumentationItem>> GetAllDocumentsAsync()
    {
        if (_cachedDocs != null)
            return _cachedDocs;

        var docs = new List<DocumentationItem>
        {
            // Root Level Documentation
            new() { Title = "Quick Start Guide", FileName = "QUICK_START.md", Category = "Getting Started", Route = "quick-start" },
            new() { Title = "README", FileName = "README.md", Category = "Getting Started", Route = "readme" },
            
            // Setup & Configuration
            new() { Title = "Aspire MAUI Setup", FileName = "ASPIRE_MAUI_SETUP.md", Category = "Setup & Configuration", Route = "aspire-maui-setup" },
            new() { Title = "External Bedrock Server Architecture", FileName = "EXTERNAL_BEDROCK_SERVER_ARCHITECTURE.md", Category = "Setup & Configuration", Route = "external-bedrock-architecture" },
            new() { Title = "Port Configuration", FileName = "deployment-packages/PORT_CONFIGURATION.md", Category = "Setup & Configuration", Route = "port-configuration" },
            
            // Deployment Guides
            new() { Title = "Docker Deployment", FileName = "DOCKER_DEPLOYMENT.md", Category = "Deployment", Route = "docker-deployment" },
            new() { Title = "Windows Server Deployment", FileName = "WINDOWS_SERVER_DEPLOYMENT.md", Category = "Deployment", Route = "windows-deployment" },
            new() { Title = "Raspberry Pi Deployment", FileName = "RASPBERRY_PI_DEPLOYMENT.md", Category = "Deployment", Route = "raspberry-pi-deployment" },
            new() { Title = "SSH Deployment Quickstart", FileName = "SSH_DEPLOYMENT_QUICKSTART.md", Category = "Deployment", Route = "ssh-deployment" },
            new() { Title = "IIS Troubleshooting", FileName = "deployment-packages/IIS-TROUBLESHOOTING.md", Category = "Deployment", Route = "iis-troubleshooting" },
            new() { Title = "Complete Deployment Package", FileName = "deployment-packages/COMPLETE-SUBMISSION-PACKAGE.md", Category = "Deployment", Route = "complete-deployment" },
            
            // Features & Functionality
            new() { Title = "Backup Service Summary", FileName = "BACKUP_SERVICE_SUMMARY.md", Category = "Features", Route = "backup-service" },
            new() { Title = "Backup Settings Feature", FileName = "BACKUP_SETTINGS_FEATURE.md", Category = "Features", Route = "backup-settings" },
            new() { Title = "Backup Service Documentation", FileName = "deployment-packages/BACKUP_SERVICE_DOCUMENTATION.md", Category = "Features", Route = "backup-documentation" },
            new() { Title = "Backup Quick Start", FileName = "deployment-packages/BACKUP_QUICK_START.md", Category = "Features", Route = "backup-quickstart" },
            new() { Title = "Server Properties Feature", FileName = "SERVER_PROPERTIES_FEATURE.md", Category = "Features", Route = "server-properties" },
            new() { Title = "Command Intellisense", FileName = "COMMAND_INTELLISENSE.md", Category = "Features", Route = "command-intellisense" },
            new() { Title = "Command Intellisense Implementation", FileName = "COMMAND_INTELLISENSE_IMPLEMENTATION.md", Category = "Features", Route = "command-intellisense-impl" },
            new() { Title = "Game Rule Autocomplete", FileName = "GAMERULE-AUTOCOMPLETE-IMPLEMENTATION.md", Category = "Features", Route = "gamerule-autocomplete" },
            new() { Title = "Contact & Support Feature", FileName = "deployment-packages/CONTACT-SUPPORT-FEATURE.md", Category = "Features", Route = "contact-support" },
            
            // Marketing & Website
            new() { Title = "Marketing Deployment", FileName = "MCBDS_MARKETING_DEPLOYMENT.md", Category = "Marketing Website", Route = "marketing-deployment" },
            new() { Title = "Domain Update Summary", FileName = "DOMAIN-UPDATE-SUMMARY.md", Category = "Marketing Website", Route = "domain-update" },
            new() { Title = "SEO Setup Guide", FileName = "deployment-packages/SEO-SETUP-GUIDE.md", Category = "Marketing Website", Route = "seo-setup" },
            new() { Title = "Google Analytics Setup", FileName = "deployment-packages/GOOGLE-ANALYTICS-SETUP.md", Category = "Marketing Website", Route = "google-analytics" },
            new() { Title = "Google Analytics Verification", FileName = "deployment-packages/GOOGLE-ANALYTICS-VERIFICATION-FIX.md", Category = "Marketing Website", Route = "analytics-verification" },
            new() { Title = "Search Engine Submission", FileName = "deployment-packages/SEARCH-ENGINE-SUBMISSION-GUIDE.md", Category = "Marketing Website", Route = "search-engine-submission" },
            new() { Title = "Sitemap Implementation", FileName = "deployment-packages/SITEMAP-IMPLEMENTATION-SUMMARY.md", Category = "Marketing Website", Route = "sitemap-implementation" },
            new() { Title = "Sitemap 404 Fix", FileName = "deployment-packages/SITEMAP-404-FIX.md", Category = "Marketing Website", Route = "sitemap-404-fix" },
            new() { Title = "Downloads Setup", FileName = "deployment-packages/DOWNLOADS-SETUP.md", Category = "Marketing Website", Route = "downloads-setup" },
            new() { Title = "Downloads Implementation", FileName = "deployment-packages/DOWNLOADS-IMPLEMENTATION.md", Category = "Marketing Website", Route = "downloads-implementation" },
            new() { Title = "Minecraft Theme Guide", FileName = "deployment-packages/MINECRAFT-THEME-GUIDE.md", Category = "Marketing Website", Route = "minecraft-theme" },
            new() { Title = "Dashboard Image Setup", FileName = "deployment-packages/DASHBOARD-IMAGE-SETUP.md", Category = "Marketing Website", Route = "dashboard-image" },
            new() { Title = "GoFundMe Integration", FileName = "deployment-packages/GOFUNDME-DONATION-INTEGRATION.md", Category = "Marketing Website", Route = "gofundme-integration" },
            
            // Troubleshooting & Fixes
            new() { Title = "Backup Fix - Save Query Wait", FileName = "BACKUP_FIX_SAVE_QUERY_WAIT.md", Category = "Troubleshooting", Route = "backup-fix-save-query" },
            new() { Title = "Build Fix - Backup Settings", FileName = "BUILD_FIX_BACKUP_SETTINGS.md", Category = "Troubleshooting", Route = "build-fix-backup" },
            new() { Title = "Command Sending Error Fix", FileName = "COMMAND-SENDING-ERROR-FIX.md", Category = "Troubleshooting", Route = "command-sending-fix" },
            new() { Title = "File Path Parsing Fix", FileName = "FILE_PATH_PARSING_FIX.md", Category = "Troubleshooting", Route = "file-path-fix" },
            new() { Title = "Hot Reload Backup Settings", FileName = "HOT_RELOAD_BACKUP_SETTINGS.md", Category = "Troubleshooting", Route = "hot-reload-backup" },
            new() { Title = "Settings Final Fix", FileName = "SETTINGS_FINAL_FIX.md", Category = "Troubleshooting", Route = "settings-final-fix" },
            new() { Title = "Settings Persistence Debug", FileName = "SETTINGS_PERSISTENCE_DEBUG.md", Category = "Troubleshooting", Route = "settings-persistence-debug" },
            new() { Title = "Settings Revert Fix", FileName = "SETTINGS_REVERT_FIX.md", Category = "Troubleshooting", Route = "settings-revert-fix" },
            new() { Title = "World Path Fix", FileName = "WORLD_PATH_FIX.md", Category = "Troubleshooting", Route = "world-path-fix" },
            new() { Title = "Web Config Fix", FileName = "deployment-packages/WEB-CONFIG-FIX.md", Category = "Troubleshooting", Route = "web-config-fix" },
            new() { Title = "Downloads Removed GitHub", FileName = "deployment-packages/DOWNLOADS-REMOVED-GITHUB.md", Category = "Troubleshooting", Route = "downloads-removed" },
            new() { Title = "Downloads Quick Fix", FileName = "deployment-packages/DOWNLOADS-QUICK-FIX.md", Category = "Troubleshooting", Route = "downloads-quick-fix" },
            
            // PublicUI Documentation
            new() { Title = "PublicUI Changes", FileName = "PUBLICUI_CHANGES.md", Category = "Client Applications", Route = "publicui-changes" },
            new() { Title = "Backup UI Integration", FileName = "BACKUP_UI_INTEGRATION.md", Category = "Client Applications", Route = "backup-ui-integration" },
            
            // Quick References
            new() { Title = "Package Summary", FileName = "deployment-packages/PACKAGE-SUMMARY.md", Category = "Reference", Route = "package-summary" },
            new() { Title = "Quick Reference - Submission", FileName = "deployment-packages/QUICK-REFERENCE-SUBMISSION.md", Category = "Reference", Route = "quick-reference-submission" },
            new() { Title = "Deployment Guide", FileName = "deployment-packages/DEPLOYMENT-GUIDE.md", Category = "Reference", Route = "deployment-guide" },
        };

        _cachedDocs = docs;
        return docs;
    }

    public async Task<DocumentationItem?> GetDocumentAsync(string route)
    {
        var docs = await GetAllDocumentsAsync();
        var doc = docs.FirstOrDefault(d => d.Route == route);
        
        if (doc != null && string.IsNullOrEmpty(doc.Content))
        {
            try
            {
                var filePath = Path.Combine(_environment.WebRootPath, "docs", doc.FileName);
                if (File.Exists(filePath))
                {
                    doc.Content = await File.ReadAllTextAsync(filePath);
                }
                else
                {
                    doc.Content = $"# Document Not Found\n\nThe file `{doc.FileName}` could not be found at `{filePath}`.";
                }
            }
            catch (Exception ex)
            {
                doc.Content = $"# Error Loading Document\n\n{ex.Message}";
            }
        }
        
        return doc;
    }

    public async Task<Dictionary<string, List<DocumentationItem>>> GetDocumentsByCategoryAsync()
    {
        var docs = await GetAllDocumentsAsync();
        return docs.GroupBy(d => d.Category)
                   .ToDictionary(g => g.Key, g => g.ToList());
    }

    public string ExtractTitle(string markdown)
    {
        var match = Regex.Match(markdown, @"^#\s+(.+)$", RegexOptions.Multiline);
        return match.Success ? match.Groups[1].Value : "Documentation";
    }
}
