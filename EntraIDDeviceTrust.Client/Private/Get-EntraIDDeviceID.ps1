function Get-EntraIDDeviceID {
    <#
    .SYNOPSIS
        Get the Entra ID device ID from the local device.

    .DESCRIPTION
        Get the Entra ID device ID from the local device.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-05-26
        Updated:     2021-05-26
    
        Version history:
        1.0.0 - (2021-05-26) Function created
    #>
    Process {
        # Define Cloud Domain Join information registry path
        $EntraIDJoinInfoRegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"

        # Retrieve the child key name that is the thumbprint of the machine certificate containing the device identifier guid
        $EntraIDJoinInfoThumbprint = Get-ChildItem -Path $EntraIDJoinInfoRegistryKeyPath | Select-Object -ExpandProperty "PSChildName"
        if ($EntraIDJoinInfoThumbprint -ne $null) {
            # Retrieve the machine certificate based on thumbprint from registry key
            $EntraIDJoinCertificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $PSItem.Thumbprint -eq $EntraIDJoinInfoThumbprint }
            if ($EntraIDJoinCertificate -ne $null) {
                # Determine the device identifier from the subject name
                $EntraIDDeviceID = ($EntraIDJoinCertificate | Select-Object -ExpandProperty "Subject") -replace "CN=", ""

                # Handle return value
                return $EntraIDDeviceID
            }
        }
    }
}