
# Locate signtool.exe in Windows 10/11 SDK (x64)
$kitsPath = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
$signTool = Get-ChildItem -Path $kitsPath -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
            Select-Object -First 1

if (-not $signTool) {
    throw "signtool.exe not found. Install the Windows SDK (Apps → Windows SDK) and re-run."
}

# Sign (SHA-256). Timestamp optional but recommended if you have internet: add /tr and /td sha256.
& $signTool.FullName sign /fd sha256 /f $pfxPath /p ( [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)) ) /v $msix
