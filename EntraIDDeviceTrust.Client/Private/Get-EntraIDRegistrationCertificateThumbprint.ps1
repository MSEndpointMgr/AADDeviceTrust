function Get-EntraIDRegistrationCertificateThumbprint {
    <#
    .SYNOPSIS
        Get the thumbprint of the certificate used for Entra ID device registration.

    .DESCRIPTION
        Get the thumbprint of the certificate used for Entra ID device registration.

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-06-03
        Updated:     2021-06-03
    
        Version history:
        1.0.0 - (2021-06-03) Function created
    #>
    Process {
        # Define Cloud Domain Join information registry path
        $EntraIDJoinInfoRegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"

        # Retrieve the child key name that is the thumbprint of the machine certificate containing the device identifier guid
        $EntraIDJoinInfoThumbprint = Get-ChildItem -Path $EntraIDJoinInfoRegistryKeyPath | Select-Object -ExpandProperty "PSChildName"

        # Handle return value
        return $EntraIDJoinInfoThumbprint
    }
}