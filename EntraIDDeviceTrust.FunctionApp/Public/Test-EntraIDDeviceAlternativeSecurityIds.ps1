function Test-EntraIDDeviceAlternativeSecurityIds {
    <#
    .SYNOPSIS
        Validate the thumbprint and publickeyhash property values of the alternativeSecurityIds property from the Entra ID device record.
    
    .DESCRIPTION
        Validate the thumbprint and publickeyhash property values of the alternativeSecurityIds property from the Entra ID device record.

    .PARAMETER AlternativeSecurityIdKey
        Specify the alternativeSecurityIds.Key property from an Entra ID device record.

    .PARAMETER Type
        Specify the type of the AlternativeSecurityIdsKey object, e.g. Thumbprint or Hash.

    .PARAMETER Value
        Specify the value of the type to be validated.
    
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-06-07
        Updated:     2021-06-07
    
        Version history:
        1.0.0 - (2021-06-07) Function created
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the alternativeSecurityIds.Key property from an Entra ID device record.")]
        [ValidateNotNullOrEmpty()]
        [string]$AlternativeSecurityIdKey,

        [parameter(Mandatory = $true, HelpMessage = "Specify the type of the AlternativeSecurityIdsKey object, e.g. Thumbprint or Hash.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Thumbprint", "Hash")]
        [string]$Type,

        [parameter(Mandatory = $true, HelpMessage = "Specify the value of the type to be validated.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    Process {
        # Construct custom object for alternativeSecurityIds property from Entra ID device record, used as reference value when compared to input value
        $EntraIDDeviceAlternativeSecurityIds = Get-EntraIDDeviceAlternativeSecurityIds -Key $AlternativeSecurityIdKey
        
        switch ($Type) {
            "Thumbprint" {
                # Validate match
                if ($Value -match $EntraIDDeviceAlternativeSecurityIds.Thumbprint) {
                    return $true
                }
                else {
                    return $false
                }
            }
            "Hash" {
                # Convert from Base64 string to byte array
                $DecodedBytes = [System.Convert]::FromBase64String($Value)
                
                # Construct a new SHA256Managed object to be used when computing the hash
                $SHA256Managed = New-Object -TypeName "System.Security.Cryptography.SHA256Managed"

                # Compute the hash
                [byte[]]$ComputedHash = $SHA256Managed.ComputeHash($DecodedBytes)

                # Convert computed hash to Base64 string
                $ComputedHashString = [System.Convert]::ToBase64String($ComputedHash)

                # Validate match
                if ($ComputedHashString -like $EntraIDDeviceAlternativeSecurityIds.PublicKeyHash) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }
    }
}