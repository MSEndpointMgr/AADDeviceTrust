    <#
    .SYNOPSIS
        HTTP Function App sample
    
    .NOTES
        Author:      Nickolaj Andersen, Maxton Allen
        Contact:     @NickolajA, @AzureToTheMax
        Created:     2022-01-25
        Updated:     2023-05-14
    
        Version history:
        1.0.0 - 2022-01-25 created
        1.0.1 - 2023-05-11 Updated to use X509 class
        1.0.2 - 2023-05-14 Updated to pull Azure AD Device ID from the cert

        
    #>

using namespace System.Net

# Input bindings are passed in via param block.
param(
    [Parameter(Mandatory = $true)]
    $Request,

    [Parameter(Mandatory = $false)]
    $TriggerMetadata
)

# Functions

function Get-SelfGraphAuthToken {
    <#
    .SYNOPSIS
        Use the permissions granted to the Function App itself to obtain a Graph token for running Graph queries. 
        Returns a formated header for use with the original code.
    
    .NOTES
        Author:      Nickolaj Andersen, Maxton Allen
        Contact:     @NickolajA, @AzureToTheMax
        Created:     2021-06-07
        Updated:     2023-02-17
    
        Version history:
        1.0.0 - 2021-06-07 Function created
        1.0.1 - 2023-02-17 @AzureToTheMax - Updated to API Version 2019-08-01 from 2017-09-01
    #>
    Process {

        $resourceURI = "https://graph.microsoft.com"
        $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
        $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthURI

        
        $AuthenticationHeader = @{
            "Authorization" = "Bearer $($tokenResponse.access_token)"
            "ExpiresOn" = $tokenResponse.expires_on
        }
        return $AuthenticationHeader
    }
}#end function 



# Retrieve authentication token
$AuthToken = Get-SelfGraphAuthToken

# Initate variables
$StatusCode = [HttpStatusCode]::OK
$Body = [string]::Empty

# Assign incoming request properties to variables
$DeviceName = $Request.Body.DeviceName
$Signature = $Request.Body.Signature
$PublicKey = $Request.Body.PublicKey

#Get Device ID from the cert
$DeviceID = Get-AzureDeviceIDFromCertificate -Value $PublicKey

# Initiate request handling
Write-Output -InputObject "Initiating request handling for device named as '$($DeviceName)' with cert containing Azure AD identifier: $($DeviceID)"

# Retrieve Azure AD device record based on DeviceID property from incoming request body
$AzureADDeviceRecord = Get-AzureADDeviceRecord -DeviceID $DeviceID -AuthToken $AuthToken
if ($AzureADDeviceRecord -ne $null) {
    Write-Output -InputObject "Found trusted Azure AD device record with object identifier: $($AzureADDeviceRecord.id)"

    # Validate thumbprint from input request with Azure AD device record's alternativeSecurityIds details
    if (Test-AzureADDeviceAlternativeSecurityIds -AlternativeSecurityIdKey $AzureADDeviceRecord.alternativeSecurityIds.key -Type "Thumbprint" -Value $PublicKey) {
        Write-Output -InputObject "Successfully validated certificate thumbprint from inbound request"

        # Validate public key hash from input request with Azure AD device record's alternativeSecurityIds details
        if (Test-AzureADDeviceAlternativeSecurityIds -AlternativeSecurityIdKey $AzureADDeviceRecord.alternativeSecurityIds.key -Type "Hash" -Value $PublicKey) {
            Write-Output -InputObject "Successfully validated certificate SHA256 hash value from inbound request"

            $EncryptionVerification = Test-Encryption -PublicKeyEncoded $PublicKey -Signature $Signature -Content $AzureADDeviceRecord.deviceId
            if ($EncryptionVerification -eq $true) {
                Write-Output -InputObject "Successfully validated inbound request came from a trusted Azure AD device record"

                # Validate that the inbound request came from a trusted device that's not disabled
                if ($AzureADDeviceRecord.accountEnabled -eq $true) {
                    Write-Output -InputObject "Azure AD device record was validated as enabled"

                    #
                    #
                    # Place your code here, at this stage incoming request has been validated as trusted
                    #
                    #
                }
                else {
                    Write-Output -InputObject "Trusted Azure AD device record validation for inbound request failed, record with deviceId '$($DeviceID)' is disabled"
                    $StatusCode = [HttpStatusCode]::Forbidden
                    $Body = "Disabled device record"
                }
            }
            else {
                Write-Warning -Message "Trusted Azure AD device record validation for inbound request failed, could not validate signed content from client"
                $StatusCode = [HttpStatusCode]::Forbidden
                $Body = "Untrusted request"
            }
        }
        else {
            Write-Warning -Message "Trusted Azure AD device record validation for inbound request failed, could not validate certificate SHA256 hash value"
            $StatusCode = [HttpStatusCode]::Forbidden
            $Body = "Untrusted request"
        }
    }
    else {
        Write-Warning -Message "Trusted Azure AD device record validation for inbound request failed, could not validate certificate thumbprint"
        $StatusCode = [HttpStatusCode]::Forbidden
        $Body = "Untrusted request"
    }
}
else {
    Write-Warning -Message "Trusted Azure AD device record validation for inbound request failed, could not find device with deviceId: $($DeviceID)"
    $StatusCode = [HttpStatusCode]::Forbidden
    $Body = "Untrusted request"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body = $Body
})
