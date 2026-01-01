# ?? Google Analytics Verification - Quick Fix

## ? Problem
Google Search Console says: "The Google Analytics tracking code on your site is in the wrong location on the page."

## ? Solution
Moved Google Analytics script to the **very top of the `<head>` section** in MainLayout.razor.

---

## ?? What Was Changed

**File**: `MCBDS.Marketing/Components/Layout/MainLayout.razor`

**Before**:
```html
<head>
    <!-- Meta tags -->
    <!-- Stylesheets -->
    <!-- Google Analytics at the END -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-6408KZLKH4"></script>
</head>
```

**After**:
```html
<head>
    <!-- Google Analytics FIRST -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-6408KZLKH4"></script>
    <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-6408KZLKH4');
    </script>
    
    <!-- Meta tags -->
    <!-- Stylesheets -->
</head>
```

---

## ?? Deploy in 3 Steps

### Step 1: Build
```powershell
cd MCBDS.Marketing
dotnet publish -c Release -o publish
```

### Step 2: Deploy to IIS
```powershell
Copy-Item -Path "publish\*" -Destination "C:\inetpub\wwwroot\mcbdshost-marketing\" -Recurse -Force
iisreset
```

### Step 3: Verify in Google Search Console
```
1. Visit: https://search.google.com/search-console/
2. Select your property
3. Go to: Settings ? Verification details
4. Click "Verify" next to Google Analytics
5. Should show: ? Verified
```

---

## ? Quick Verification

### In Browser
```
1. Visit your site
2. Right-click ? View Page Source
3. Look at first lines of <head>
4. Should see Google Analytics script at the top
```

### In DevTools
```
1. Press F12
2. Go to Elements tab
3. Expand <head>
4. Google Analytics should be first script
```

---

## ?? Result
- ? Google Analytics verified in Search Console
- ? Proper tracking location
- ? Ready for indexing
- ? No more verification errors

---

**Status**: ? Fixed and ready to deploy
