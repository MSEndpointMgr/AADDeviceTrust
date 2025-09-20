<#
.SYNOPSIS
    Client-side script sample to demonstrate the usage of the EntraIDDeviceTrust.Client module.

.NOTES
    FileName:    ClientSide.ps1
    Author:      Nickolaj Andersen
    Contact:     @NickolajA
    Created:     2022-03-14
    Updated:     2022-03-14

    Version history:
    1.0.0 - (2022-03-14) Script created
#>
Process {
    # Install required modules
    Install-Module -Name "EntraIDDeviceTrust.Client" -AcceptLicense -Force

    # Use TLS 1.2 connection when calling Azure Function
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Validate that the script is running on an Entra ID joined or hybrid Entra ID joined device
    if (Test-EntraIDDeviceRegistration -eq $true) {
        # Create body for Function App request
        $BodyTable = New-EntraIDDeviceTrustBody

        # Optional - extend body table with additional data
        $BodyTable.Add("Key", "Value")

        # Construct URI for Function App request
        $URI = "https://<function_app_name>.azurewebsites.net/api/<function_name>?code=<function_key>"
        $Response = Invoke-RestMethod -Method "POST" -Uri $URI -Body ($BodyTable | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    }
    else {
        Write-Warning -Message "Script is not running on an Entra ID joined or hybrid Entra ID joined device"
    }
}