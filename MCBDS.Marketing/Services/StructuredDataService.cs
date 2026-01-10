namespace MCBDS.Marketing.Services;

/// <summary>
/// Service for generating structured data (JSON-LD) for SEO optimization
/// </summary>
public class StructuredDataService
{
    private readonly string _baseUrl = "https://www.mc-bds.com";

    /// <summary>
    /// Generates Organization structured data for the website
    /// </summary>
    public string GetOrganizationData()
    {
        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "Organization",
            "name": "MCBDS Manager",
            "url": "{{_baseUrl}}",
            "logo": "{{_baseUrl}}/images/logo.png",
            "description": "Professional web-based management for Minecraft Bedrock Dedicated Server",
            "sameAs": [
                "https://github.com/JoshuaBylotas/MCBDSHost"
            ],
            "contactPoint": {
                "@type": "ContactPoint",
                "contactType": "Customer Support",
                "email": "support@mc-bds.com",
                "url": "{{_baseUrl}}/contact"
            }
        }
        """;
    }

    /// <summary>
    /// Generates SoftwareApplication structured data
    /// </summary>
    public string GetSoftwareApplicationData()
    {
        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "MCBDS Manager",
            "applicationCategory": "GameApplication",
            "operatingSystem": "Windows, Linux, Docker",
            "offers": {
                "@type": "Offer",
                "price": "0",
                "priceCurrency": "USD"
            },
            "description": "Professional web-based management tool for Minecraft Bedrock Dedicated Server with real-time monitoring, automated backups, and smart command console.",
            "url": "{{_baseUrl}}",
            "screenshot": "{{_baseUrl}}/images/dashboard-preview.png",
            "softwareVersion": "1.0",
            "datePublished": "2025-01-01",
            "author": {
                "@type": "Organization",
                "name": "MCBDS Manager"
            },
            "downloadUrl": "{{_baseUrl}}/get-started",
            "featureList": [
                "Real-time server monitoring",
                "Smart command console with IntelliSense",
                "Automated backup system",
                "Server properties editor",
                "Player tracking and management",
                "Docker integration",
                "Multi-platform support"
            ],
            "requirements": "Docker or .NET 10 Runtime"
        }
        """;
    }

    /// <summary>
    /// Generates WebPage structured data for documentation pages
    /// </summary>
    public string GetWebPageData(string name, string description, string url)
    {
        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "WebPage",
            "name": "{{name}}",
            "description": "{{description}}",
            "url": "{{url}}",
            "publisher": {
                "@type": "Organization",
                "name": "MCBDS Manager",
                "url": "{{_baseUrl}}"
            }
        }
        """;
    }

    /// <summary>
    /// Generates HowTo structured data for setup guides
    /// </summary>
    public string GetHowToData(string name, string description, List<string> steps)
    {
        var stepsJson = string.Join(",\n", steps.Select((step, index) => 
            $$"""
                    {
                        "@type": "HowToStep",
                        "position": {{index + 1}},
                        "name": "Step {{index + 1}}",
                        "text": "{{step}}"
                    }
            """));

        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "HowTo",
            "name": "{{name}}",
            "description": "{{description}}",
            "step": [
        {{stepsJson}}
            ]
        }
        """;
    }

    /// <summary>
    /// Generates FAQPage structured data
    /// </summary>
    public string GetFAQPageData(Dictionary<string, string> faqs)
    {
        var faqItems = string.Join(",\n", faqs.Select(faq => 
            $$"""
                    {
                        "@type": "Question",
                        "name": "{{faq.Key}}",
                        "acceptedAnswer": {
                            "@type": "Answer",
                            "text": "{{faq.Value}}"
                        }
                    }
            """));

        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": [
        {{faqItems}}
            ]
        }
        """;
    }

    /// <summary>
    /// Generates BreadcrumbList structured data
    /// </summary>
    public string GetBreadcrumbData(List<(string Name, string Url)> breadcrumbs)
    {
        var items = string.Join(",\n", breadcrumbs.Select((crumb, index) => 
            $$"""
                    {
                        "@type": "ListItem",
                        "position": {{index + 1}},
                        "name": "{{crumb.Name}}",
                        "item": "{{crumb.Url}}"
                    }
            """));

        return $$"""
        {
            "@context": "https://schema.org",
            "@type": "BreadcrumbList",
            "itemListElement": [
        {{items}}
            ]
        }
        """;
    }
}
