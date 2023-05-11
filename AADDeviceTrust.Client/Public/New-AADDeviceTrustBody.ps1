function New-AADDeviceTrustBody {
    <#
    .SYNOPSIS
        Construct the body with the elements for a sucessful device trust validation required by a Function App that's leveraging the AADDeviceTrust.FunctionApp module.

    .DESCRIPTION
        Construct the body with the elements for a sucessful device trust validation required by a Function App that's leveraging the AADDeviceTrust.FunctionApp module.

    .EXAMPLE
        .\New-AADDeviceTrustBody.ps1

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2022-03-14
        Updated:     2023-05-10

        Version history:
        1.0.0 - (2022-03-14) Script created
        1.0.1 - (2023-05-10) @AzureToTheMax - Updated to no longer use Thumbprint field, now redundant.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    Process {
        # Retrieve required data for building the request body
        $AzureADDeviceID = Get-AzureADDeviceID
        $CertificateThumbprint = Get-AzureADRegistrationCertificateThumbprint
        $Signature = New-RSACertificateSignature -Content $AzureADDeviceID -Thumbprint $CertificateThumbprint
        $PublicKeyBytesEncoded = Get-PublicKeyBytesEncodedString -Thumbprint $CertificateThumbprint

        # Construct client-side request header
        $BodyTable = [ordered]@{
            DeviceName = $env:COMPUTERNAME
            DeviceID = $AzureADDeviceID
            Signature = $Signature
            #Thumbprint = $CertificateThumbprint
            PublicKey = $PublicKeyBytesEncoded
        }

        # Handle return value
        return $BodyTable
    }
}
