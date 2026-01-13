# MSIX Store Submission - Quick Cheat Sheet

## ?? The Problem

```
? Invalid package family name: ..._47q1101p6hvwy (expected: ..._n8ws8gp0q633w)
? Invalid package publisher name: CN=MC-BDS (expected: CN=5DB9918C-...)
```

**Root cause:** Package was signed with development certificate instead of being left unsigned for Microsoft to sign.

---

## ? The Solution (3 Commands)

```powershell
# 1. Increment version
.\IncrementPackageVersion.ps1

# 2. Create UNSIGNED Store package
.\CreateMSIXPackage.ps1 -ForStore

# 3. Upload to Partner Center
# Go to: https://partner.microsoft.com/dashboard
# Upload: AppPackages\MCBDS.PublicUI_1.0.18.1_x64.msix
```

---

## ?? Key Points

| ? Wrong | ? Right |
|---------|---------|
| `CreateMSIXPackage.ps1` | `CreateMSIXPackage.ps1 -ForStore` |
| Signed with dev cert | Unsigned (Microsoft signs) |
| CN=MC-BDS | CN=5DB9918C-... (by Microsoft) |
| `..._47q1101p6hvwy` | `..._n8ws8gp0q633w` (by Microsoft) |
| Identity mismatch ? | Identity matches ? |

---

## ?? How to Verify You Did It Right

After running `CreateMSIXPackage.ps1 -ForStore`, you should see:

```
?? Package Type: Microsoft Store Submission (UNSIGNED)  ? Must say UNSIGNED!
? Store identity looks correct
Step X: Skipping signing                                ? Must skip signing!
  ??  Microsoft will sign this package during certification
```

Check package signature:
```powershell
Get-AuthenticodeSignature "AppPackages\MCBDS.PublicUI_1.0.18.1_x64\*.msix"
# Status should be: NotSigned (this is CORRECT!)
```

---

## ?? Complete Workflow

### For Store Submission
```powershell
.\IncrementPackageVersion.ps1        # Bump version
.\CreateMSIXPackage.ps1 -ForStore    # Create unsigned package
# Then upload to Partner Center
```

### For Local Testing
```powershell
.\CreateMSIXPackage.ps1 -Sign        # Create signed package
Add-AppxPackage -Path "path\to\package.msix"
```

---

## ?? Troubleshooting

### Still getting identity mismatch?
- ? Used `-ForStore` parameter?
- ? Package is unsigned? (`Get-AuthenticodeSignature`)
- ? Uploaded the NEW version (1.0.18.x)?

### Build fails?
```powershell
dotnet clean
dotnet restore
.\CreateMSIXPackage.ps1 -ForStore
```

### Can't find output?
```powershell
Get-ChildItem AppPackages -Recurse -Filter "*.msix"
```

---

## ?? Remember

**For Store:** UNSIGNED = CORRECT ?  
**For Local Testing:** SIGNED = CORRECT ?

Never sign packages you're submitting to the Store!

---

## ?? Why This Works

1. You create **unsigned** package with `-ForStore`
2. Package preserves manifest identity: `CN=5DB9918C-...`
3. Microsoft **signs** it during certification
4. Microsoft's signature creates correct hash: `_n8ws8gp0q633w`
5. Package Family Name **matches** Store expectations ?

---

## ?? Time Required

- Increment version: 30 seconds
- Create package: 2-5 minutes
- Upload: 2 minutes
- **Total: ~5-8 minutes**

Then wait 24-72 hours for Microsoft certification.

---

## ?? More Help

- **Detailed guide:** `FIX_IDENTITY_MISMATCH_NOW.md`
- **Before/After comparison:** `BEFORE_AFTER_COMPARISON.md`
- **Full documentation:** `CREATE_MSIX_PACKAGE_USAGE.md`
- **Partner Center:** https://partner.microsoft.com/dashboard

---

## ? Success Looks Like

```
? Package uploaded successfully
? No identity mismatch errors
? Validation passed
? Certification started
? (24-72 hours later) App published!
```

---

**Print this page and keep it handy!**

Command to fix issue:
```
.\CreateMSIXPackage.ps1 -ForStore
```

That's the magic command! ??
