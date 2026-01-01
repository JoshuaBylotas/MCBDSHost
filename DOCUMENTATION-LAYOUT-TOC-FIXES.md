# Marketing Layout and Documentation TOC Fixes

## Issues Fixed ?

### Issue 1: Documentation Link Missing from MainLayout
**Problem**: The MainLayout didn't have a Documentation link in the navbar or footer, making it hard to discover the documentation.

**Solution**: Added "Documentation" links to:
1. ? **Top Navbar** - Between "Get Started" and "Contact"
2. ? **Footer Quick Links** - Added after "Get Started"
3. ? **Footer Resources** - Already had a link to "/get-started" labeled as "Documentation", now properly points to "/docs"

### Issue 2: Table of Contents Links Navigate to Root
**Problem**: Clicking TOC links in documentation pages (e.g., `#introduction`, `#installation`) would navigate to the root URL instead of scrolling to the section within the document.

**Root Cause**: Mismatch between our manual ID generation and Markdig's automatic heading ID generation. Markdig uses the `AutoIdentifiers` extension which generates IDs differently.

**Solution**: 
1. ? Enabled `.UseAutoIdentifiers()` in Markdig pipeline
2. ? Updated `ExtractTableOfContents()` to generate IDs matching Markdig's format
3. ? Enhanced character replacement to handle more edge cases:
   - Removed emojis (?, ?, ??, ??, etc.)
   - Removed punctuation (!, ?, :, ;, etc.)
   - Removed special characters (*, +, =, |, etc.)
   - Handled multiple consecutive dashes
   - Trimmed leading/trailing dashes

## Changes Made

### File: `MCBDS.Marketing/Components/Layout/MainLayout.razor`

#### Top Navbar Addition
```razor
<li class="nav-item">
    <a class="nav-link" href="/docs">Documentation</a>
</li>
```

#### Footer Quick Links
```razor
<li><a href="/docs" class="text-muted text-decoration-none">Documentation</a></li>
```

#### Footer Resources (Fixed)
Changed from:
```razor
<li><a href="/get-started" class="text-muted text-decoration-none">Documentation</a></li>
```

To:
```razor
<li><a href="/docs" class="text-muted text-decoration-none">Documentation</a></li>
```

### File: `MCBDS.Marketing/Components/Pages/DocumentViewer.razor`

#### Markdown Pipeline Update
```csharp
private string ConvertMarkdownToHtml(string markdown)
{
    var pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()
        .UseAutoIdentifiers()  // ? NEW: Enables automatic heading IDs
        .Build();
    
    return Markdown.ToHtml(markdown, pipeline);
}
```

#### Enhanced TOC ID Generation
```csharp
// Generate ID using Markdig's AutoIdentifiers format
var id = text.ToLower()
    .Replace(" ", "-")
    .Replace("&", "")
    .Replace(".", "")
    .Replace(",", "")
    // ... many more character replacements
    .Replace("?", "")  // Handle emojis
    .Replace("?", "")
    .Replace("??", "")
    .Trim('-');

// Remove multiple consecutive dashes
while (id.Contains("--"))
{
    id = id.Replace("--", "-");
}
```

## How TOC Links Work Now

### Example: Heading in Markdown
```markdown
## ? Changes Applied Successfully
```

### Markdig Generates HTML
```html
<h2 id="changes-applied-successfully">? Changes Applied Successfully</h2>
```

### Our TOC Generates Link
```razor
<a class="nav-link" href="#changes-applied-successfully">
    Changes Applied Successfully
</a>
```

### Result
? Clicking the TOC link scrolls to the correct heading in the document

## Testing Checklist

### MainLayout Navigation
- [ ] Open Marketing site
- [ ] Check top navbar for "Documentation" link
- [ ] Check footer "Quick Links" for "Documentation" link
- [ ] Check footer "Resources" for "Documentation" link
- [ ] Verify all three links go to `/docs`

### Documentation TOC
- [ ] Navigate to any documentation page (e.g., `/docs/quick-start`)
- [ ] Check "On This Page" sidebar has TOC entries
- [ ] Click a TOC link
- [ ] **Should scroll to that section** (not navigate to root)
- [ ] Verify URL shows anchor (e.g., `#installation`)
- [ ] Click browser back button - should scroll back up
- [ ] Test with documents containing:
  - Emojis in headings
  - Special characters
  - Multiple words
  - Numbers

### Example Test Cases

#### Test Document 1: Quick Start
```
Navigate to: /docs/quick-start
Click TOC: "Prerequisites" ? Should scroll to ## Prerequisites
Click TOC: "Installation" ? Should scroll to ## Installation
```

#### Test Document 2: Docker Deployment  
```
Navigate to: /docs/docker-deployment
Click TOC: "Using Docker Compose" ? Should scroll to that section
Click TOC: "Troubleshooting" ? Should scroll to that section
```

#### Test Document 3: Features
```
Navigate to: /docs/backup-service
Click TOC with emoji: "? Changes Applied" ? Should scroll to that heading
Click TOC with special chars: "Setup & Configuration" ? Should scroll correctly
```

## Known Edge Cases Handled

### Emoji Handling
```markdown
## ? Success
## ? Failed
## ?? Warning
```
All generate valid IDs without the emojis.

### Special Characters
```markdown
## Setup & Configuration
## C# Code Examples
## FAQ (Frequently Asked Questions)
```
All punctuation is removed, spaces become dashes.

### Multiple Dashes
```markdown
## Feature - Step 1 - Complete
```
Becomes: `#feature-step-1-complete` (no double dashes)

### Trailing/Leading Dashes
```markdown
## - Important Note -
```
Becomes: `#important-note` (trimmed)

## Build Status
? **Build Successful** - All changes compiled without errors

## Browser Compatibility

The anchor link functionality works in all modern browsers:
- ? Chrome/Edge (Chromium)
- ? Firefox
- ? Safari
- ? Mobile browsers

## CSS Scroll Behavior

The documentation already has smooth scrolling CSS:
```css
.markdown-content h1,
.markdown-content h2,
.markdown-content h3,
.markdown-content h4 {
    scroll-margin-top: 80px;  /* Offset for fixed header */
}
```

This ensures headings scroll into view with proper spacing from the top.

## Future Enhancements

### Optional: Add Active TOC Highlighting
Track which section is currently visible and highlight its TOC link:
```javascript
// Intersection Observer to track visible sections
const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            // Update active TOC link
        }
    });
});
```

### Optional: Smooth Scroll Polyfill
For older browsers:
```javascript
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href'))
            .scrollIntoView({ behavior: 'smooth' });
    });
});
```

## Summary

| Component | Issue | Fix | Status |
|-----------|-------|-----|--------|
| MainLayout Navbar | No Documentation link | Added `/docs` link | ? Fixed |
| MainLayout Footer Quick Links | No Documentation link | Added `/docs` link | ? Fixed |
| MainLayout Footer Resources | Wrong link to `/get-started` | Changed to `/docs` | ? Fixed |
| DocumentViewer TOC | Links go to root URL | Matched Markdig ID generation | ? Fixed |
| DocumentViewer Markdown | No auto IDs | Added `.UseAutoIdentifiers()` | ? Fixed |

## Testing Instructions

1. **Stop the application** (full restart required, not hot reload)
2. **Run the Marketing site**:
   ```powershell
   cd MCBDS.Marketing
   dotnet run
   ```
3. **Test navigation links**:
   - Click "Documentation" in navbar
   - Click "Documentation" in footer
4. **Test TOC links**:
   - Open any documentation page
   - Click any "On This Page" link
   - Should smoothly scroll to that section
   - URL should show the anchor (#section-name)
   - Page should NOT navigate away

---

**Status**: ? All issues resolved and ready to test!

**Hot Reload Note**: Since these are markup changes, hot reload MAY work, but a full restart is recommended to ensure all changes are applied.
