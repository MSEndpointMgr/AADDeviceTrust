using namespace System.Net

# Input bindings are passed in via param block.
param(
    [Parameter(Mandatory = $true)]
    $Request,

    [Parameter(Mandatory = $false)]
    $TriggerMetadata
)

# Functions
function Get-AuthToken {
    <#
    .SYNOPSIS
        Retrieve an access token for the Managed System Identity.
    
    .DESCRIPTION
        Retrieve an access token for the Managed System Identity.
    
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-06-07
        Updated:     2021-06-07
    
        Version history:
        1.0.0 - (2021-06-07) Function created
    #>
    Process {
        # Get Managed Service Identity details from the Azure Functions application settings
        $MSIEndpoint = $env:MSI_ENDPOINT
        $MSISecret = $env:MSI_SECRET

        # Define the required URI and token request params
        $APIVersion = "2017-09-01"
        $ResourceURI = "https://graph.microsoft.com"
        $AuthURI = $MSIEndpoint + "?resource=$($ResourceURI)&api-version=$($APIVersion)"

        # Call resource URI to retrieve access token as Managed Service Identity
        $Response = Invoke-RestMethod -Uri $AuthURI -Method "Get" -Headers @{ "Secret" = "$($MSISecret)" }

        # Construct authentication header to be returned from function
        $AuthenticationHeader = @{
            "Authorization" = "Bearer $($Response.access_token)"
            "ExpiresOn" = $Response.expires_on
        }

        # Handle return value
        return $AuthenticationHeader
    }
}

# Retrieve authentication token
$AuthToken = Get-AuthToken

# Initate variables
$StatusCode = [HttpStatusCode]::OK
$Body = [string]::Empty

# Assign incoming request properties to variables
$DeviceName = $Request.Body.DeviceName
$DeviceID = $Request.Body.DeviceID
$Signature = $Request.Body.Signature
$Thumbprint = $Request.Body.Thumbprint
$PublicKey = $Request.Body.PublicKey

# Initiate request handling
Write-Output -InputObject "Initiating request handling for device named as '$($DeviceName)' with identifier: $($DeviceID)"

# Retrieve Azure AD device record based on DeviceID property from incoming request body
$AzureADDeviceRecord = Get-AzureADDeviceRecord -DeviceID $DeviceID -AuthToken $AuthToken
if ($AzureADDeviceRecord -ne $null) {
    Write-Output -InputObject "Found trusted Azure AD device record with object identifier: $($AzureADDeviceRecord.id)"

    # Validate thumbprint from input request with Azure AD device record's alternativeSecurityIds details
    if (Test-AzureADDeviceAlternativeSecurityIds -AlternativeSecurityIdKey $AzureADDeviceRecord.alternativeSecurityIds.key -Type "Thumbprint" -Value $Thumbprint) {
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