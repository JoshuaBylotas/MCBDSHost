#Requires -Version 5.0
<#
.SYNOPSIS
    MCBDSHost Search Engine Submission Assistant

.DESCRIPTION
    Interactive guide for submitting your MCBDSHost marketing site to all major search engines.
    This script provides step-by-step instructions and links for Google, Bing, DuckDuckGo, etc.

.PARAMETER Domain
    Your domain name (default: mcbdshost.com)

.EXAMPLE
    .\search-engine-submit.ps1
    
.EXAMPLE
    .\search-engine-submit.ps1 -Domain "yourdomain.com"
#>

param(
    [string]$Domain = "mcbdshost.com"
)

$sitemapUrl = "https://$Domain/sitemap.xml"
$robotsUrl = "https://$Domain/robots.txt"
$siteUrl = "https://$Domain"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "?????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "? $($Text.PadRight(59)) ?" -ForegroundColor Cyan
    Write-Host "?????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
}

function Write-SubHeader {
    param([string]$Text)
    Write-Host "`n? $Text" -ForegroundColor Yellow
    Write-Host "?????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
}

function Write-Step {
    param([int]$Number, [string]$Text)
    Write-Host "  $Number. $Text" -ForegroundColor White
}

function Write-Link {
    param([string]$Text, [string]$Url)
    Write-Host "     ?? $Text" -ForegroundColor Cyan
    Write-Host "        $Url" -ForegroundColor DarkCyan
}

function Test-Connectivity {
    Write-SubHeader "Verifying Site Accessibility"
    
    try {
        $response = Invoke-WebRequest -Uri $siteUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "     ? Site is accessible" -ForegroundColor Green
            
            # Check for sitemap
            $sitemapTest = Invoke-WebRequest -Uri $sitemapUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($sitemapTest.StatusCode -eq 200) {
                Write-Host "     ? Sitemap is accessible" -ForegroundColor Green
            } else {
                Write-Host "     ??  Sitemap not found (ensure it's deployed)" -ForegroundColor Yellow
            }
            
            # Check for robots.txt
            $robotsTest = Invoke-WebRequest -Uri $robotsUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($robotsTest.StatusCode -eq 200) {
                Write-Host "     ? Robots.txt is accessible" -ForegroundColor Green
            } else {
                Write-Host "     ??  Robots.txt not found (ensure it's deployed)" -ForegroundColor Yellow
            }
            
            return $true
        }
    } catch {
        Write-Host "     ? Site is not accessible: $_" -ForegroundColor Red
        Write-Host "     Please ensure your site is deployed and accessible." -ForegroundColor Yellow
        return $false
    }
}

function Show-GoogleGuide {
    Write-Header "1. GOOGLE SEARCH CONSOLE (Critical - 90% of search traffic)"
    
    Write-SubHeader "Step 1: Create Google Account"
    Write-Step 1 "Visit: https://accounts.google.com/signup"
    Write-Step 2 "Create account if you don't have one"
    
    Write-SubHeader "Step 2: Open Google Search Console"
    Write-Link "Google Search Console" "https://search.google.com/search-console/about"
    
    Write-SubHeader "Step 3: Add Property"
    Write-Step 1 "Click 'Start now'"
    Write-Step 2 "Sign in with your Google account"
    Write-Step 3 "Select 'URL prefix' property type"
    Write-Step 4 "Enter your site: $siteUrl"
    Write-Step 5 "Click 'Continue'"
    
    Write-SubHeader "Step 4: Verify Ownership"
    Write-Host "  Choose ONE method (Google Analytics is easiest):" -ForegroundColor White
    Write-Host ""
    Write-Host "  Option A: Google Analytics (EASIEST - Already Installed)" -ForegroundColor Green
    Write-Step 1 "Google Search Console will detect your Google Analytics"
    Write-Step 2 "Click 'Verify' next to Google Analytics"
    Write-Step 3 "Done!"
    Write-Host ""
    Write-Host "  Option B: HTML Meta Tag" -ForegroundColor Cyan
    Write-Step 1 "Copy the meta tag provided by Google Search Console"
    Write-Step 2 "Add to MainLayout.razor <head> section"
    Write-Step 3 "Click 'Verify'"
    Write-Host ""
    Write-Host "  Option C: HTML File Upload" -ForegroundColor Cyan
    Write-Step 1 "Download verification file from Google Search Console"
    Write-Step 2 "Upload to: $siteUrl/[verification-file].html"
    Write-Step 3 "Click 'Verify'"
    Write-Host ""
    Write-Host "  Option D: DNS Record (Technical)" -ForegroundColor Cyan
    Write-Step 1 "Add TXT record to your DNS settings"
    Write-Step 2 "Wait 24-48 hours for propagation"
    Write-Step 3 "Click 'Verify'"
    
    Write-SubHeader "Step 5: Submit Sitemap"
    Write-Step 1 "After verification, click 'Sitemaps' in left menu"
    Write-Step 2 "Click 'Add/test sitemap'"
    Write-Step 3 "Enter: $sitemapUrl"
    Write-Step 4 "Click 'Submit'"
    
    Write-SubHeader "Step 6: Request Fast Indexing"
    Write-Step 1 "Click 'Inspect URL' at top"
    Write-Step 2 "Enter: $siteUrl/"
    Write-Step 3 "Click 'Test live URL'"
    Write-Step 4 "Click 'Request indexing' (if available)"
    Write-Step 5 "Repeat for: /features, /get-started, /contact"
    
    Write-Host "`n  ??  Expected: Verification in minutes, indexing in 1-7 days" -ForegroundColor Gray
}

function Show-BingGuide {
    Write-Header "2. BING WEBMASTER TOOLS (Important - 5% of search traffic)"
    
    Write-SubHeader "Step 1: Create Microsoft Account"
    Write-Step 1 "Visit: https://account.microsoft.com/account"
    Write-Step 2 "Create account if needed"
    
    Write-SubHeader "Step 2: Open Bing Webmaster Tools"
    Write-Link "Bing Webmaster Tools" "https://www.bing.com/webmaster/"
    
    Write-SubHeader "Step 3: Add Site"
    Write-Step 1 "Sign in with Microsoft account"
    Write-Step 2 "Click 'Add site'"
    Write-Step 3 "Enter: $siteUrl"
    Write-Step 4 "Click 'Add'"
    
    Write-SubHeader "Step 4: Verify Ownership"
    Write-Host "  Choose verification method:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Method 1: XML Sitemap (EASIEST)" -ForegroundColor Green
    Write-Step 1 "Bing auto-detects your sitemap"
    Write-Step 2 "Click 'Verify' when prompted"
    Write-Step 3 "Done!"
    Write-Host ""
    Write-Host "  Method 2: Robots.txt" -ForegroundColor Cyan
    Write-Step 1 "Bing checks robots.txt"
    Write-Step 2 "Click 'Verify' when prompted"
    Write-Step 3 "Done!"
    Write-Host ""
    Write-Host "  Method 3: Meta Tag" -ForegroundColor Cyan
    Write-Step 1 "Copy meta tag"
    Write-Step 2 "Add to MainLayout.razor"
    Write-Step 3 "Click 'Verify'"
    
    Write-SubHeader "Step 5: Submit Sitemap"
    Write-Step 1 "Go to 'Sitemaps' in left menu"
    Write-Step 2 "Click 'Submit sitemap'"
    Write-Step 3 "Enter: $sitemapUrl"
    Write-Step 4 "Click 'Submit'"
    
    Write-SubHeader "Step 6: Monitor"
    Write-Step 1 "Check 'Crawl' section for indexing status"
    Write-Step 2 "Review 'Index' for indexed pages"
    Write-Step 3 "Monitor for any errors"
    
    Write-Host "`n  ??  Expected: Indexing in 1-2 weeks" -ForegroundColor Gray
}

function Show-DuckDuckGoGuide {
    Write-Header "3. DUCKDUCKGO (Privacy-Focused - 2% of search traffic)"
    
    Write-SubHeader "Automatic Inclusion"
    Write-Host "  DuckDuckGo uses these indexes:" -ForegroundColor White
    Write-Host "     ? Bing (from your Bing submission)" -ForegroundColor Green
    Write-Host "     ? Google (from your Google submission)" -ForegroundColor Green
    Write-Host "     ? Other crawlers" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ?? No separate submission required!" -ForegroundColor Yellow
    Write-Host "  Your site will appear automatically once indexed by Google/Bing" -ForegroundColor White
    
    Write-SubHeader "Optional: Register in DuckDuckGo Directory"
    Write-Host "  If you want to be in their directory:" -ForegroundColor White
    Write-Link "DuckDuckGo Add" "https://duckduckgo.com/add"
    Write-Step 1 "Visit link above"
    Write-Step 2 "Add your site details"
    Write-Step 3 "Not required for search results"
    Write-Host ""
    Write-Host "  ??  DuckDuckGo results appear automatically" -ForegroundColor Gray
}

function Show-YandexGuide {
    Write-Header "4. YANDEX (Russian Search Engine - 1-2% of traffic)"
    
    Write-Host "  ??  Only needed if targeting Russia/CIS markets" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SubHeader "Step 1: Create Account"
    Write-Link "Yandex Webmaster" "https://webmaster.yandex.com/"
    Write-Step 1 "Visit link above"
    Write-Step 2 "Sign up or login with Yandex account"
    
    Write-SubHeader "Step 2: Verify Site"
    Write-Step 1 "Add your domain"
    Write-Step 2 "Choose verification method"
    Write-Step 3 "Verify ownership (meta tag, file, or DNS)"
    
    Write-SubHeader "Step 3: Submit Sitemap"
    Write-Step 1 "Go to 'Sitemaps' section"
    Write-Step 2 "Add: $sitemapUrl"
    Write-Step 3 "Submit for indexing"
    
    Write-Host "`n  ??  Expected: Indexing in 2-4 weeks (Russia market)" -ForegroundColor Gray
}

function Show-BaiduGuide {
    Write-Header "5. BAIDU (Chinese Search Engine - 0% for Western sites)"
    
    Write-Host "  ??  Only needed if targeting China market" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Requirements:" -ForegroundColor Cyan
    Write-Host "     • ICP filing (Chinese government registration)" -ForegroundColor Gray
    Write-Host "     • Server located in China" -ForegroundColor Gray
    Write-Host "     • Chinese phone number" -ForegroundColor Gray
    Write-Host "     • Complex approval process" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ? Skip unless specifically targeting China" -ForegroundColor Red
    Write-Link "Baidu Zhanzhang (if interested)" "https://zhanzhang.baidu.com/"
}

function Show-ChecklistAndSummary {
    Write-Header "SUBMISSION CHECKLIST & SUMMARY"
    
    Write-SubHeader "Quick Submission Status"
    Write-Host ""
    Write-Host "  ?? CRITICAL (Do These First):" -ForegroundColor Red
    Write-Host "     [ ] 1. Google Search Console" -ForegroundColor White
    Write-Host "     [ ] 2. Bing Webmaster Tools" -ForegroundColor White
    Write-Host ""
    Write-Host "  ?? IMPORTANT (Do These Second):" -ForegroundColor Yellow
    Write-Host "     [ ] 3. Verify Google submission" -ForegroundColor White
    Write-Host "     [ ] 4. Verify Bing submission" -ForegroundColor White
    Write-Host ""
    Write-Host "  ?? OPTIONAL (Do If Applicable):" -ForegroundColor Green
    Write-Host "     [ ] 5. Yandex (if targeting Russia)" -ForegroundColor White
    Write-Host "     [ ] 6. Baidu (if targeting China)" -ForegroundColor White
    Write-Host "     [ ] 7. DuckDuckGo directory" -ForegroundColor White
    Write-Host ""
    
    Write-SubHeader "Expected Traffic Impact"
    Write-Host "  Search Engine | Traffic | Priority | Difficulty | Time" -ForegroundColor Cyan
    Write-Host "  ?????????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "  Google        | 90%     | ????? | Easy       | 30 min" -ForegroundColor White
    Write-Host "  Bing          | 5%      | ????  | Easy       | 20 min" -ForegroundColor White
    Write-Host "  DuckDuckGo    | 2%      | ??    | Auto       | 0 min" -ForegroundColor White
    Write-Host "  Yandex        | 1-2%    | ??    | Medium     | 30 min" -ForegroundColor White
    Write-Host "  Baidu         | <1%     | ?     | Hard       | 1+ hour" -ForegroundColor White
    Write-Host ""
    
    Write-SubHeader "Timeline Expectations"
    Write-Host "  Week 1:   Site crawled, initial indexing, brand search results appear" -ForegroundColor Gray
    Write-Host "  Month 1:  6 pages indexed, organic traffic begins" -ForegroundColor Gray
    Write-Host "  Month 2:  Target keywords ranking higher" -ForegroundColor Gray
    Write-Host "  Month 3:  Established rankings, steady growth" -ForegroundColor Gray
}

function Show-MonitoringGuide {
    Write-Header "MONITORING YOUR SUBMISSIONS"
    
    Write-SubHeader "Weekly Tasks"
    Write-Step 1 "Check Google Search Console Coverage"
    Write-Step 2 "Monitor impressions and clicks"
    Write-Step 3 "Check for new crawl errors"
    Write-Step 4 "Review top search queries"
    
    Write-SubHeader "Monthly Tasks"
    Write-Step 1 "Analyze search performance trends"
    Write-Step 2 "Check ranking positions"
    Write-Step 3 "Update sitemap if adding pages"
    Write-Step 4 "Resubmit updated sitemap"
    Write-Step 5 "Create new content for SEO"
    
    Write-SubHeader "Quarterly Tasks"
    Write-Step 1 "Review overall search trends"
    Write-Step 2 "Optimize for top-performing keywords"
    Write-Step 3 "Build quality backlinks"
    Write-Step 4 "Improve site structure/UX"
    
    Write-SubHeader "Key Metrics to Monitor"
    Write-Host "  1. Impressions - How often site appears in search" -ForegroundColor White
    Write-Host "  2. Clicks - How often users visit from search" -ForegroundColor White
    Write-Host "  3. CTR - Click-through rate (target: 3-5%)" -ForegroundColor White
    Write-Host "  4. Position - Average ranking position (target: top 20)" -ForegroundColor White
    Write-Host "  5. Organic Traffic - Monthly visitors from organic search" -ForegroundColor White
}

function Open-InBrowser {
    param([string]$Url, [string]$Description)
    
    Write-Host ""
    Write-Host "  Would you like to open '$Description' in your browser?" -ForegroundColor Cyan
    $response = Read-Host "  (Y)es / (N)o / (C)opy URL"
    
    switch ($response.ToUpper()) {
        'Y' {
            try {
                Start-Process $Url
                Write-Host "  ? Opening in browser..." -ForegroundColor Green
            } catch {
                Write-Host "  ? Could not open browser: $_" -ForegroundColor Red
                Write-Host "  Copy and open manually: $Url" -ForegroundColor Yellow
            }
        }
        'C' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $Url | Set-Clipboard
            } else {
                $Url | clip
            }
            Write-Host "  ? URL copied to clipboard!" -ForegroundColor Green
        }
        default {
            Write-Host "  Skipped. You can visit manually: $Url" -ForegroundColor Yellow
        }
    }
}

# Main Script Flow
Clear-Host
Write-Header "?? MCBDSHost Search Engine Submission Assistant"

Write-Host "  Domain: $Domain" -ForegroundColor Cyan
Write-Host "  Sitemap: $sitemapUrl" -ForegroundColor Cyan
Write-Host "  Robots: $robotsUrl" -ForegroundColor Cyan
Write-Host ""

# Verify connectivity
if (-not (Test-Connectivity)) {
    Write-Host ""
    Write-Host "? Please ensure your site is deployed before submitting!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "? Site is ready for submission!" -ForegroundColor Green

# Interactive Menu
while ($true) {
    Write-Host ""
    Write-Host "?????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host "? What would you like to do?                                    ?" -ForegroundColor DarkGray
    Write-Host "?????????????????????????????????????????????????????????????????" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1. ?? Google Search Console Guide (CRITICAL)" -ForegroundColor Cyan
    Write-Host "  2. ?? Bing Webmaster Tools Guide (IMPORTANT)" -ForegroundColor Cyan
    Write-Host "  3. ?? DuckDuckGo Guide (AUTOMATIC)" -ForegroundColor Cyan
    Write-Host "  4. ?? Yandex Guide (OPTIONAL - Russia)" -ForegroundColor Yellow
    Write-Host "  5. ???? Baidu Guide (OPTIONAL - China)" -ForegroundColor Yellow
    Write-Host "  6. ? View Checklist & Summary" -ForegroundColor Green
    Write-Host "  7. ?? Monitoring Guide" -ForegroundColor Green
    Write-Host "  8. ?? View All Guides (Print)" -ForegroundColor White
    Write-Host "  9. ? Exit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Select option (1-9)"
    
    switch ($choice) {
        '1' { Clear-Host; Show-GoogleGuide; Open-InBrowser "https://search.google.com/search-console/" "Google Search Console" }
        '2' { Clear-Host; Show-BingGuide; Open-InBrowser "https://www.bing.com/webmaster/" "Bing Webmaster Tools" }
        '3' { Clear-Host; Show-DuckDuckGoGuide }
        '4' { Clear-Host; Show-YandexGuide; Open-InBrowser "https://webmaster.yandex.com/" "Yandex Webmaster" }
        '5' { Clear-Host; Show-BaiduGuide; Open-InBrowser "https://zhanzhang.baidu.com/" "Baidu Zhanzhang" }
        '6' { Clear-Host; Show-ChecklistAndSummary }
        '7' { Clear-Host; Show-MonitoringGuide }
        '8' {
            Clear-Host
            Show-GoogleGuide
            Show-BingGuide
            Show-DuckDuckGoGuide
            Show-YandexGuide
            Show-BaiduGuide
            Show-ChecklistAndSummary
            Show-MonitoringGuide
        }
        '9' {
            Write-Host ""
            Write-Host "?? Good luck with your submissions!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid option. Please select 1-9." -ForegroundColor Red
        }
    }
}
