Import-Module Hyper-V

$VM_NAME = "WindowsServer"
$DIR_SCRATCH = "$PSScriptRoot\SCRATCH"
$DIR_DEPENDENCIES = "$PSScriptRoot\DEPENDENCIES"
$DIR_ISO_SERVER = "$DIR_SCRATCH\ISOServer"

#<#
Write-Host "CLEANING" -ForegroundColor Blue
Stop-VM -Name $VM_NAME -Force -ErrorAction SilentlyContinue
Remove-VM -Name $VM_NAME -Force -ErrorAction SilentlyContinue
Remove-Item "$DIR_SCRATCH\WindowsServer.vhdx" -Force -ErrorAction SilentlyContinue
Remove-Item "$DIR_SCRATCH\WindowsServer.iso" -Force -ErrorAction SilentlyContinue
Write-Host "INJECTING UNATTEND FILE" -ForegroundColor Blue
Copy-Item "$DIR_SCRATCH\autounattend-admin-autolog.xml" "$DIR_ISO_SERVER\autounattend.xml"
Write-Host "ISO CREATION" -ForegroundColor Blue
$SOURCE = $DIR_ISO_SERVER
$DESTINATION = "$DIR_SCRATCH\WindowsServer.iso"
$data = '1#pEF,e,b"{0}"' -f "$DIR_ISO_SERVER\efi\microsoft\boot\efisys_noprompt.bin"
Start-Process "$DIR_DEPENDENCIES\oscdimg.exe" -args @("-bootdata:$data", '-u2', '-udfver102', """$Source""", """$DESTINATION""") -Wait -WindowStyle Hidden
if (!(Test-Path "$DIR_SCRATCH\WindowsServer.iso"))
{
    Write-Warning "[ERROR] ISO"
    Remove-Item "$DIR_ISO_SERVER\autounattend.xml" -Confirm:$false
    Exit
}
Remove-Item "$DIR_ISO_SERVER\autounattend.xml" -Confirm:$false
Write-Host "VM CREATION" -ForegroundColor Blue
New-VM -Name $VM_NAME -Generation 2 -NoVHD -BootDevice CD | Out-Null
Set-VM -Name $VM_NAME -ProcessorCount 4 -DynamicMemory -MemoryStartupBytes 1024MB -MemoryMinimumBytes 512MB -MemoryMaximumBytes 8192MB -AutomaticCheckpointsEnabled $false -CheckpointType Standard
Set-VMSecurity -VMName $VM_NAME -EncryptStateAndVmMigrationTraffic $true
Set-VMFirmware -VMName $VM_NAME -EnableSecureBoot On
Set-VMKeyProtector -VMName $VM_NAME -NewLocalKeyProtector
Enable-VMTPM -VMName $VM_NAME
Set-VMDvdDrive -VMName $VM_NAME -Path "$DIR_SCRATCH\$VM_NAME.iso"
New-VHD -Path "$DIR_SCRATCH\$VM_NAME.vhdx" -SizeBytes 30GB -Dynamic | Out-Null
Add-VMHardDiskDrive -VMName $VM_NAME -Path "$DIR_SCRATCH\$VM_NAME.vhdx"
Remove-VMNetworkAdapter $VM_NAME
Add-VMNetworkAdapter -VMName $VM_NAME #-SwitchName "Default Switch"
Enable-VMIntegrationService -VMName $VM_NAME -Name "Arrêt", "Interface de services d’invité", "Pulsation", "Échange de paires clé-valeur", "Synchronisation date/heure", "VSS"
Start-VM $VM_NAME
#VMConnect.exe $env:COMPUTERNAME $VM_NAME -C 1
#>
Write-Host "VM INSTALLATION..." -ForegroundColor Blue
# Waiting Installation
$Password = ConvertTo-SecureString "P4ssword" -AsPlainText -Force
$Username = "Administrateur"
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password )
Do
{
    Write-Host "New PSSession ..." -ForegroundColor Yellow
    $SESSION = New-PSSession -VMName $VM_NAME -Name $VM_NAME -Credential $Credential -ErrorAction SilentlyContinue
    Start-Sleep 1
}
until($SESSION)
Write-Host "INSTALLED." -ForegroundColor Green
Get-PSSession | Remove-PSSession
Stop-VM $VM_NAME -Confirm:$false
