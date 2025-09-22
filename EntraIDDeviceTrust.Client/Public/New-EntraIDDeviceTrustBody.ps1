function New-EntraIDDeviceTrustBody {
    <#
    .SYNOPSIS
        Construct the body with the elements for a sucessful device trust validation required by a Function App that's leveraging the EntraIDDeviceTrust.FunctionApp module.

    .DESCRIPTION
        Construct the body with the elements for a sucessful device trust validation required by a Function App that's leveraging the EntraIDDeviceTrust.FunctionApp module.

    .EXAMPLE
        .\New-EntraIDDeviceTrustBody.ps1

    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2022-03-14
        Updated:     2022-03-14

        Version history:
        1.0.0 - (2022-03-14) Script created
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    Process {
        # Retrieve required data for building the request body
        $EntraIDDeviceID = Get-EntraIDDeviceID
        $CertificateThumbprint = Get-EntraIDRegistrationCertificateThumbprint
        $Signature = New-RSACertificateSignature -Content $EntraIDDeviceID -Thumbprint $CertificateThumbprint
        $PublicKeyBytesEncoded = Get-PublicKeyBytesEncodedString -Thumbprint $CertificateThumbprint

        # Construct client-side request header
        $BodyTable = [ordered]@{
            DeviceName = $env:COMPUTERNAME
            DeviceID = $EntraIDDeviceID
            Signature = $Signature
            Thumbprint = $CertificateThumbprint
            PublicKey = $PublicKeyBytesEncoded
        }

        # Handle return value
        return $BodyTable
    }
}