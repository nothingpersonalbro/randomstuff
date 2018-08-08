# This will add 'open powershell here as administrator' option for shift right click in a folder context menu.
# This must be ran as administrator

$Menu = 'Open PowerShell window here (Admin)'
$Command = "$PSHOME\powershell.exe -NoExit -Command ""Set-Location '%V'"""

'directory', 'directory\background', 'drive' | ForEach-Object {
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\$_\shell" -Name runas\command -Force |
    Set-ItemProperty -Name '(default)' -Value $Command -PassThru |
    Set-ItemProperty -Path {$_.PSParentPath} -Name '(default)' -Value $Menu -PassThru |
    Set-ItemProperty -Name HasLUAShield -Value '' -PassThru |
    Set-ItemProperty -Name Extended -Value ''
}
