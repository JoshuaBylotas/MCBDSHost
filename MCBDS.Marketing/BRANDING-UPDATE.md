# Branding Update: MCBDSHost ? MCBDS Manager

**Date:** January 7, 2025  
**Project:** MCBDS.Marketing  
**Change Type:** Product Name Rebranding

---

## Overview

Changed all references from "MCBDSHost" to "MCBDS Manager" throughout the marketing website to align with the product name used in the Windows Store deployment.

---

## Files Updated

### 1. **Components/App.razor**
- Meta descriptions and keywords
- Open Graph tags
- Twitter Card metadata
- Site name references

### 2. **Components/Pages/Home.razor**
- Page title
- Hero section alt text
- CTA section
- Structured data injection

### 3. **Components/Pages/Features.razor**
- Page title in `<PageTitle>` tag
- Meta description

### 4. **Components/Pages/GetStarted.razor**
- Page title
- Meta descriptions and keywords
- Structured data (HowTo guide)
- Hero section heading

### 5. **Components/Layout/MainLayout.razor**
- Navigation bar brand name
- Meta tags
- Open Graph title
- Page title
- Donation banner
- Footer branding

### 6. **Components/Shared/SeoHead.razor**
- Default title parameter
- Default author parameter
- Open Graph site_name

### 7. **Services/StructuredDataService.cs**
- Organization name in structured data
- Software application name
- Author organization name
- Publisher name

### 8. **wwwroot/robots.txt**
- Site name in header comment

---

## Search & Replace Summary

| Old Value | New Value | Occurrences |
|-----------|-----------|-------------|
| MCBDSHost | MCBDS Manager | 15+ |
| mcbdshost | MCBDS Manager (where appropriate) | Multiple |

---

## SEO Impact

### Updated Metadata
- ? Page titles now use "MCBDS Manager"
- ? Meta descriptions updated
- ? Open Graph data reflects new name
- ? Twitter Cards show new branding
- ? Structured data (JSON-LD) updated
- ? Site navigation updated

### What Stays the Same
- URLs remain unchanged
- Domain (mc-bds.com) unchanged
- GitHub repository references (technical)
- Documentation file names
- Download package names

---

## Consistency Notes

### Where "MCBDS Manager" is used:
- All user-facing branding
- Page titles and meta tags
- Navigation and footer
- SEO structured data
- Social media previews

### Where technical names remain:
- Repository URLs (github.com/JoshuaBylotas/MCBDSHost)
- Download file names (mcbdshost-windows.zip)
- Docker image references
- Internal technical documentation

---

## Testing Checklist

After deployment, verify:

- [ ] Homepage displays "MCBDS Manager" in title
- [ ] Navigation bar shows "MCBDS Manager"
- [ ] Browser tab shows correct title
- [ ] Social media preview shows "MCBDS Manager"
- [ ] Footer copyright shows "MCBDS Manager"
- [ ] All internal links still work
- [ ] SEO meta tags include new name
- [ ] Google Search Console updated

---

## Future Considerations

### Additional Updates Needed (Outside Marketing Project):

1. **GitHub Repository**
   - Consider updating repository name/description
   - Update README.md across all projects

2. **Windows Store Listing**
   - Product name: "MCBDS Manager" ? (Already set)
   - Description consistency

3. **Documentation**
   - Update technical docs to reference "MCBDS Manager"
   - Update deployment guides

4. **Docker Images**
   - Consider retagging images (optional)
   - Update docker-compose.yml descriptions

5. **API/Backend**
   - Update About/Version endpoints
   - Update API documentation

---

## Build Status

? **Build Successful**
- Project: MCBDS.Marketing
- Configuration: Release
- Target: net10.0
- Status: No errors or warnings

---

## Deployment Notes

To deploy the updated branding:

```powershell
# Build for production
cd MCBDS.Marketing
dotnet publish -c Release -o bin\Release\net10.0\publish

# Deploy to IIS (if applicable)
Copy-Item -Path "bin\Release\net10.0\publish\*" `
          -Destination "C:\inetpub\wwwroot\mc-bds-marketing\" `
          -Recurse -Force

# Restart IIS
iisreset
```

---

## Rollback Plan

If needed, revert changes:

```bash
git revert <commit-hash>
# Or manually change all "MCBDS Manager" back to "MCBDSHost"
```

All changes are in source control and can be easily reverted.

---

## Contact

For questions about this change:
- GitHub: https://github.com/JoshuaBylotas/MCBDSHost
- Email: support@mc-bds.com

---

**Change Approved By:** Developer Request  
**Implementation Date:** January 7, 2025  
**Status:** ? Complete
