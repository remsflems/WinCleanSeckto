
# Copyight 2023 - remsflems - At finseckto.com
Write-Host "[+] WinCleanSeckTo - Windows 10 Bloatware removal."


function ChekIfRoot() {
	$currentPrincipal = New-Object security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	$a = ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	if ($a -ne "True") {
		Write-Host "[ERROR] This has to be run AS ADMINISTRATOR PRIVILEGES..exiting.."
		Exit
	}
	# $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
	# Write-Host $scriptPath
	# Set-Location -Path $scriptPath
}

ChekIfRoot




function Service_Startup_type {
	param(
		[String] $Service
	)
	Write-Output (Get-Service -Name $Service -ErrorAction SilentlyContinue|Select-Object -First 1 | Select -ExpandProperty "Starttype")
}

function Service_Status {
	param(
		[String] $Service
	)
	Write-Output (Get-Service -Name $Service -ErrorAction SilentlyContinue|Select-Object -First 1 | Select -ExpandProperty "Status")
}



$windows_services = @(
	"AppReadiness", 
	"BcastDVRUserService", 
	"BthAvctpSvc",
	"camSvc",
	"cbdhsvc",
	"CDPSvc",
	"CDPUserSvc", 
	"CmService",
	"cphs",
	"cplspcon",
	"DeviceAssociationService",
	"DiagTrack",
	"DoSvc",
	"DPS",
	"DusmSvc",
	"fdPHost",
	"fDResPub",
	"hns",
	"iphlpsvc",
	"NcbService",
	"NcdAutoSetup",
	"OneSyncSvc",
	"PcaSvc",
	"RasMan",
	"RmSvc",
	"SEMgrSvc",
	"SharedAccess",
	"ShellHWDetection",
	"SSDPSRV",
	"SstpSvc",
	"StateRepository",
	"StorSvc",
	"TabletInputServce",
	"Themes",
	"TokenBroker",
	"TrkWks",
	"WdiServiceHost",
	"WdiSystemHost",
	"WinHttpAutoProxySvc",
	"WinMgmt",
	"WpnService",
	"WpnUserService"
)

$Windows_store = @(
	"AppXSvc",
	"ClipSVC",
	"LicenseManager"
)

$Sharing_local_network = @(
	"LanmanServer",
	"LanmanWorkstation"
)

$Workgroup = @(
	"lmhosts"
)

#Are you using your system as a server purpose?
$Windows_Servers = @(
	"SysMain"
)

#Microsoft offline account
$Online_accounts = @(
	"wlidsvc"
)


$services_to_remove = $windows_services
##PARAMETERS- QUESTIONS
$confirmation = Read-Host "Disable Windows Store and related services ? [Y/N](yes)"
if ($confirmation -in 'y','Y','Yes','YES','yes','') {
	$services_to_remove = $services_to_remove + $Windows_store
}

$confirmation = Read-Host "Disable Windows sharing features on local network (files, printers, controls) ? [Y/N](yes)"
if ($confirmation -in 'y','Y','Yes','YES','yes','') {
	$services_to_remove = $services_to_remove + $Sharing_local_network
	
}

$confirmation = Read-Host "Disable Windows local network Workgroup feature ? [Y/N](yes)"
if ($confirmation -in 'y','Y','Yes','YES','yes','') {
	$services_to_remove = $services_to_remove + $Workgroup
	
}

$confirmation = Read-Host "Are you using this system for Server purpose (compared to workstation) ? [Y/N](yes)"
if ($confirmation -in 'y','Y','Yes','YES','yes','') {
	$services_to_remove = $services_to_remove + $Windows_Servers
}

$confirmation = Read-Host "Do you use online Windows accounts ? [Y/N](yes)"
if (-Not ($confirmation -in 'y','Y','Yes','YES','yes','')) {
	$services_to_remove = $services_to_remove + $Online_accounts
}

Foreach ($servname in $services_to_remove) {
	if (Get-Service -Name $servname* -erroraction 'silentlycontinue') {		
		$servstatus = (Get-Service -Name $servname* |Select -Property Name,Status,StartType)
		
		$Oname = $servstatus.Name
		$Ostatus = $servstatus.Status
		$Ostarttype = $servstatus.StartType
		
		#Write-Host 	"$servname - $Ostatus - $Ostarttype"
		
		#STOPPING service
		Write-Host "[+] Stopping $Oname..." -NoNewLine
		if ( $Ostatus -eq "Running" ) { #stop if service is running
			#Write-Host "[I] Stopping $Oname (L1)"
			net stop $Oname 2>$null |out-Null
		}
		
		if ((Service_Status $Oname) -ne "Stopped") {
			#Write-Host "[II] Stopping $Oname (L2)"
			Stop-Service -Name $Oname -Force 2>$null |out-Null
		}
		
		#check if service is stopped
		if ((Service_Status $Oname) -ne "Stopped") {
			Write-Host "[FAIL]"
		} else {
			Write-Host "[OK]"
		}
		
		#DISABLING
		Write-Host "[+] Disabling $Oname..." -NoNewLine
		#First disabling trial
		if ( $Ostarttype -ne "Disabled" ) { #disabling a service
			# Write-Host "[I] Disabling $Oname (L1)"
			Set-Service -Name $Oname -StartupType Disabled -erroraction 'silentlycontinue'
		}
		
		#Second disabling trial
		if ((Service_Startup_type $Oname) -ne "Disabled") {
			# Write-Host "[II] Disabling $Oname (L2)"
			sc.exe config "$Oname" start=disabled |Out-Null
		}

		#Third disabling trial
		if ((Service_Startup_type $Oname) -ne "Disabled") {
			#Write-Host "[III] Disabling $Oname (L3)"
			Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$Oname" -Name Start -Value 4
		}
		
		if ((Service_Startup_type $Oname) -ne "Disabled") {
			Write-Host "[FAIL]"
		} else {
			Write-Host "[OK]"
		}	
	}
}

Write-Host "[+] WinCleanSeckTo - Please restart your system!"