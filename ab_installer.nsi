!include MUI2.nsh
!include LogicLib.nsh 

#Define these prior to building your installer
!define STARTMENU "$SMPROGRAMS\TARMII"
!define INSTALLER_DIR "c:\tarmii_installer"
!define TARGET_DIR "c:\tarmii"
!define SOURCE_DIR "c:\tarmii"
!define TARMII "${SOURCE_DIR}\src\tarmii.theme"

#no non-programmers allowed past this point

;!undef LOGICLIB_VERBOSITY
; For debugging - watch what logiclib does with your code!
;!define LOGICLIB_VERBOSITY 4

!define /file PRODUCT_VERSION version.txt
!define /file BUILD build_number.txt

!define PRODUCT_NAME "TARMII Foundation Phase version ${PRODUCT_VERSION}"
!define PRODUCT_PUBLISHER "Human Sciences Research Council"

#Name the Installer
Name "${PRODUCT_NAME} (build:${BUILD})"
OutFile "TARMII_Installer_v${PRODUCT_VERSION}_build${BUILD}.exe"
AllowRootDirInstall true
InstallDir "${TARGET_DIR}"

# Request application privileges for Windows Vista
RequestExecutionLevel user

# Interface Settings
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP ${INSTALLER_DIR}\banner.bmp
!define MUI_ICON ${INSTALLER_DIR}\icon.ico
!define MUI_ABORTWARNING

# Welcome page text
!define MUI_WELCOMEPAGE_TEXT "The TARMII setup wizard will install \
TARMII on your computer. Click on the Next button below to continue \
with the installation."

# Pages
!insertmacro MUI_PAGE_WELCOME
;!insertmacro MUI_PAGE_LICENSE ${INSTALLER_DIR}\licence.txt
!insertmacro MUI_PAGE_INSTFILES
  
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Languages
!insertmacro MUI_LANGUAGE "English"

# This section installs the pywin32 extensions. It does not call the
# postinstall script, ie the extensions are not registered with windows
# explorer, neither are the COM objects registered.
Section "Python Windows Extensions"
    SectionIn RO
    DetailPrint "=-=-=-=-= Copying PyWin =-=-=-=-=-=-=-="
    SetOutPath $INSTDIR\python
    File "${SOURCE_DIR}\python\Lib\site-packages\win32\*.pyd"
    File "${SOURCE_DIR}\python\Lib\site-packages\win32\pythonservice.exe"
    File "${SOURCE_DIR}\python\Lib\site-packages\pywin32_system32\*.*"
SectionEnd

Section "Install TARMII"
    SectionIn RO
    SetOutPath $INSTDIR
    File /r ${SOURCE_DIR}\*.*
    File /oname=bin\ab.py "${INSTALLER_DIR}\runner.py"
    File /oname=bin\logo.png "${INSTALLER_DIR}\logo.png"
    File /oname=bin\icon.ico "${INSTALLER_DIR}\icon.ico"
    File "${INSTALLER_DIR}\logo.png"
SectionEnd

Section "Start Menu Items"
    SectionIn RO
    CreateDirectory "${STARTMENU}"
    CreateShortCut "${STARTMENU}\TARMII.lnk" "$INSTDIR\python\pythonw.exe" '"$INSTDIR\bin\ab.py" "$INSTDIR"' "$INSTDIR\bin\icon.ico"
    CreateShortCut "${STARTMENU}\Uninstall TARMII.lnk" "$INSTDIR\Uninstall_TARMII.exe"
    CreateShortCut "$DESKTOP\TARMII.lnk" "$INSTDIR\python\pythonw.exe" '"$INSTDIR\bin\ab.py" "$INSTDIR"' "$INSTDIR\bin\icon.ico"
SectionEnd

Section -decompress SecDecompress
;UnTGZ Plugin
;The files are compressed by gzip. Untgz plugin requires -z to denote this.

; extract the Data.fs and Data.fs.index to var\filestorage
untgz::extract -d "$INSTDIR\var\" -k -z "$EXEDIR\filestorage.tgz" 

; check if the filestorage extracted ok.
; if it did we can extract the blobs too.
untgz::extract -d "$INSTDIR\var\" -k -z "$EXEDIR\blobstorage.tgz" 

SectionEnd

Section "Uninstall"
    # Remove tarmii
    RMDir /r $INSTDIR\var
    RMDir /r $INSTDIR\src
    RMDir /r $INSTDIR\python
    RMDir /r $INSTDIR\parts
    RMDir /r $INSTDIR\eggs
    RMDir /r $INSTDIR\mocked-eggs
    RMDir /r $INSTDIR\downloads
    RMDir /r $INSTDIR\docs
    RMDir /r $INSTDIR\develop-eggs
    RMDir /r $INSTDIR\bin
    Delete   $INSTDIR\Uninstall_TARMII.exe
    Delete   $INSTDIR\*.*

    # This should be safe, it will only succeed if INSTDIR is empty
    RMDir $INSTDIR
 
    # Remove shortcuts
    RMDir /r "$STARTMENU"
    Delete "$DESKTOP\TARMII.lnk"
SectionEnd

Function .onInit
# Section Size must be manually set to the size of the required disk space NSIS will not do this for external files.
# set required size of section number of kilobytes
# This is the total disk size all the files occupy together.
SectionSetSize ${SecDecompress} 1384800256
 
;compressed files has be in the same directory as the Setup file.
${If} ${FileExists} "$EXEDIR\filestorage.tgz"
${AndIf} ${FileExists} "$EXEDIR\blobstorage.tgz"
    Return
${Else}
    MessageBox MB_OK|MB_ICONINFORMATION "This copy of the installer is missing a compressed#.tar file.." IDOK stopInstallation

stopInstallation:
  Banner::destroy
  Abort

${EndIf}

FunctionEnd

# Callback function, called after successful install
Function .onInstSuccess
    MessageBox MB_YESNO "Would you like to start TARMII now?" IDNO dontstart
        Exec '"$INSTDIR\python\pythonw.exe" "$INSTDIR\bin\ab.py" "$INSTDIR"'
    dontstart:
FunctionEnd

Section -Uninstall
WriteUninstaller $INSTDIR\Uninstall_TARMII.exe
SectionEnd
