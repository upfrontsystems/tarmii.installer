!include MUI2.nsh

#Define these prior to building your installer
!define STARTMENU "$SMPROGRAMS\TARMII"
!define WINDOWS "c:\windows"
!define INSTALLER "c:\tarmii_installer"
!define PLONE "c:\Plone42"
!define TARMII ${PLONE}\src\tarmii.theme

#no non-programmers allowed past this point

!define PRODUCT_NAME "TARMII"
!define PRODUCT_PUBLISHER "Upfront Systems"
!define /file PRODUCT_VERSION ${TARMII}\version.txt

#Name the Installer
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
outFile "TARMII_Installer.exe"
AllowRootDirInstall true
InstallDir "c:\TARMII"

# Request application privileges for Windows Vista
RequestExecutionLevel user

# Interface Settings
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP ${INSTALLER}\banner.bmp
!define MUI_ICON ${INSTALLER}\icon.ico
!define MUI_ABORTWARNING

# Welcome page text
!define MUI_WELCOMEPAGE_TEXT "The TARMII setup wizard will install \
TARMII on your computer. Click on the Next button below to continue \
with the installation."

# Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ${INSTALLER}\licence.txt
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
  
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Languages
!insertmacro MUI_LANGUAGE "English"

Section "Assessment Bank"
    SectionIn RO
    SetOutPath $INSTDIR\instance
    File ${BUILDOUT}\shoelace.py
    File ${BUILDOUT}\windows.cfg
    File ${BUILDOUT}\versions.cfg
    File /r /x .svn ${BUILDOUT}\bin
    File /r /x .svn ${BUILDOUT}\develop-eggs
    File /r /x .svn ${BUILDOUT}\fake-eggs
    File /r /x .svn ${BUILDOUT}\eggs
    File /r /x .svn ${BUILDOUT}\downloads
    File /r /x .svn ${BUILDOUT}\parts
    File /r /x .svn /x ab_installer.nsi ${BUILDOUT}\products
    File /r /x .svn ${BUILDOUT}\src
    File /r /x .svn ${BUILDOUT}\var
    File /r /x .svn ${BUILDOUT}\zope2
    File /r /x .svn ${BUILDOUT}\docs
    File /oname=bin\ab.py "${INSTALLER}\runner.py"
    File /oname=bin\logo.png "${INSTALLER}\logo.png"
    File /oname=bin\icon.ico "${INSTALLER}\icon.ico"
    File "${INSTALLER}\logo.png"
    DetailPrint "=-=-=-=-= Bootstrapping =-=-=-=-=-=-=-="
    ExecWait '"$INSTDIR\python\python.exe" "$OUTDIR\shoelace.py" -c windows.cfg'
    DetailPrint "=-=-=-=-= Calling buildout =-=-=-=-=-=-=-="
    ExecWait '"$INSTDIR\python\python.exe" "$OUTDIR\bin\buildout-script.py" -q -U -N -o -c windows.cfg'
SectionEnd

Section "Start Menu Items"
    SectionIn RO
    CreateDirectory "${STARTMENU}"
    CreateShortCut "${STARTMENU}\TARMII.lnk" "$INSTDIR\python\pythonw.exe" '"$INSTDIR\instance\bin\ab.py" "$INSTDIR\instance"' "$INSTDIR\instance\bin\icon.ico"
    CreateShortCut "${STARTMENU}\Uninstall TARMII.lnk" "$INSTDIR\Uninstall_TARMII.exe"
    CreateShortCut "$DESKTOP\TARMII.lnk" "$INSTDIR\python\pythonw.exe" '"$INSTDIR\instance\bin\ab.py" "$INSTDIR\instance"' "$INSTDIR\instance\bin\icon.ico"
SectionEnd

Section "Uninstall"
    # Remove tarmii
    RMDir /r $INSTDIR\instance
    RMDir /r $INSTDIR\docs
    RMDir /r $INSTDIR\prerequisites
    RMDir /r $INSTDIR\python
    Delete   $INSTDIR\Uninstall_TARMII.exe

    # This should be safe, it will only succeed if INSTDIR is empty
    RMDir $INSTDIR
 
    # Remove shortcuts
    RMDir /r "$STARTMENU"
    Delete "$DESKTOP\TARMII.lnk"
SectionEnd

# Callback function, called after successful install
Function .onInstSuccess
    MessageBox MB_YESNO "Would you like to start TARMII now?" IDNO dontstart
        Exec '"$INSTDIR\python\pythonw.exe" "$INSTDIR\instance\bin\ab.py" "$INSTDIR\instance"'
    dontstart:
FunctionEnd

Section "Firefox"
    SetOutPath . 
    MessageBox MB_YESNO "Install Mozilla Firefox?" /SD IDYES IDNO endFirefox
        File "Firefox3Setup.exe"
        ExecWait "Firefox3Setup.exe"
    endFirefox:
SectionEnd

Section "Adobe Acrobat Reader 9"
    SetOutPath .
    ; http://www.adobe.com/devnet/acrobat/pdfs/deploying_reader9.pdf
    ; We use /sPB and /rs
    ; sPB = Silent mode with minimum UI, Progress Bar only.
    ; rs = Reboot Suppress.
    ;      Setup.exe will not initiate reboot even if it is required.
    ; The msi component can also be customised with command line options.
    ; These can be found at: http://msdn.microsoft.com/en-us/library/Aa367988
    MessageBox MB_YESNO "Install Adobe Acrobat Reader 9?" /SD IDYES IDNO endAdobe
        File "AdbeRdr920_en_US.exe"
        ExecWait 'AdbeRdr920_en_US.exe /sPB /rs'
    endAdobe:
SectionEnd

Section -Uninstall
WriteUninstaller $INSTDIR\Uninstall_TARMII.exe
SectionEnd
