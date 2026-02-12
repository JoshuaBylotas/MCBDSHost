OutFile "test-with-msix.exe"
InstallDir "$TEMP\test"

Section "Main"
  SetOutPath "$INSTDIR"
  File "MCBDS.PublicUI.msix"
SectionEnd
