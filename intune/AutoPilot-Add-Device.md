```powershell

$MsGraphVersion = "v1.0"

$MsGraphHost = "graph.microsoft.com"

$ClientID = "<CLIENT ID GUID>"

$TenantId = "<TENANT ID GUID>"

$ClientSecret = "<CLIENT SECRET>"

$Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}

$OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body

$AccessToken = $OAuthReq.access_token

$Hash = "<THE HASH OF THE MACHINE FOR AUTOPILOT>"
$PostData = @{'hardwareIdentifier' = "$hash"} | ConvertTo-Json


$Post =  Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/importedWindowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $PostData

# To check the status
Invoke-RestMethod -Method Get -Uri "https://$MsGraphHost/$MsGraphVersion/Devicemanagement/importedwindowsautopilotdeviceidentities/$($Post.ID)" -Headers @{Authorization = "Bearer $AccessToken"} | Select-Object -ExpandProperty State
```

For the above script to work you must have a Application under App Registration in Entra
1. Create an Application
2. Grant ONLY this permission called `DeviceManagementServiceConfig.ReadWrite.All`
3. Grant Admin permission
4. create and save the app secret somewhere safe


# For script with switches

```powershell
<#
To use this script you MUST put in the 3 switches needed.
Example:
.\GetAndUploadToEntra -ClientID "GUID_String" -TenantID "GUID_String" -ClientSecret "Secret_String"

#>
param([Parameter(Mandatory)]$ClientID, [Parameter(Mandatory)]$TenantID, [Parameter(Mandatory)]$ClientSecret)
#Do not change values below unless something is broken.
$MsGraphVersion = "v1.0"
$MsGraphHost = "graph.microsoft.com"
#$PEHashConfigPath = "X:\MDTExtra\PE-AutoPilot-Hash-Extract"



$session = New-CimSession
$serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber
$devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
$hash = $devDetail.DeviceHardwareData




$Body = @{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials";scope="https://$MSGraphHost/.default";}
$OAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
$AccessToken = $OAuthReq.access_token
#$Hash = $xmlhash.Key.HardwareHash #GetHardwareHash
$PostData = @{'hardwareIdentifier' = "$hash"} | ConvertTo-Json
$Post =  Invoke-RestMethod -Method POST -Uri "https://$MSGraphHost/$MsGraphVersion/devicemanagement/importedWindowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $PostData
```
