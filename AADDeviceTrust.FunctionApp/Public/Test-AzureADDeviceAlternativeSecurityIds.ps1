function Test-AzureADDeviceAlternativeSecurityIds {
    <#
    .SYNOPSIS
        Validate the thumbprint and publickeyhash property values of the alternativeSecurityIds property from the Azure AD device record.
    
    .DESCRIPTION
        Validate the thumbprint and publickeyhash property values of the alternativeSecurityIds property from the Azure AD device record.

    .PARAMETER AlternativeSecurityIdKey
        Specify the alternativeSecurityIds.Key property from an Azure AD device record.

    .PARAMETER Type
        Specify the type of the AlternativeSecurityIdsKey object, e.g. Thumbprint or Hash.

    .PARAMETER Value
        Specify the value of the type to be validated.
    
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-06-07
        Updated:     2023-05-10
    
        Version history:
        1.0.0 - (2021-06-07) Function created
        1.0.1 - (2023-05-10) @AzureToTheMax
            1. Updated Thumbprint compare to use actual PEM cert via X502 class rather than simply a passed and separate thumbprint value.
            2. Updated Hash compare to use full PEM cert via the X502 class, pull out just the public key data, and compare from that like before.

    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the alternativeSecurityIds.Key property from an Azure AD device record.")]
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
        # Construct custom object for alternativeSecurityIds property from Azure AD device record, used as reference value when compared to input value
        $AzureADDeviceAlternativeSecurityIds = Get-AzureADDeviceAlternativeSecurityIds -Key $AlternativeSecurityIdKey
        
        switch ($Type) {
            "Thumbprint" {
                Write-Output "Using new X502 Thumbprint compare"

                # Convert Value (cert) passed back to X502 Object
                $X502 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::New([System.Convert]::FromBase64String($Value))

                # Validate match
                if ($X502.thumbprint -match $AzureADDeviceAlternativeSecurityIds.Thumbprint) {
                    return $true
                }
                else {
                    return $false
                }
            }
            "Hash" {
                Write-Output "Using new X502 hash compare"

                # Convert Value (cert) passed back to X502 Object
                $X502 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::New([System.Convert]::FromBase64String($Value))

                # Pull out just the public key, removing extended values
                $X502Pub = [System.Convert]::ToBase64String($X502.PublicKey.EncodedKeyValue.rawData)
        
                # Convert from Base64 string to byte array
                $DecodedBytes = [System.Convert]::FromBase64String($X502Pub)
                
                # Construct a new SHA256Managed object to be used when computing the hash
                $SHA256Managed = New-Object -TypeName "System.Security.Cryptography.SHA256Managed"

                # Compute the hash
                [byte[]]$ComputedHash = $SHA256Managed.ComputeHash($DecodedBytes)

                # Convert computed hash to Base64 string
                $ComputedHashString = [System.Convert]::ToBase64String($ComputedHash)

                # Validate match
                if ($ComputedHashString -like $AzureADDeviceAlternativeSecurityIds.PublicKeyHash) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }
    }
}
