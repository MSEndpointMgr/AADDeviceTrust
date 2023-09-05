function Get-PublicKeyBytesEncodedString {
    <#
    .SYNOPSIS
        Returns the public key byte array encoded as a Base64 string, of the certificate where the thumbprint passed as parameter input is a match.
    
    .DESCRIPTION
        Returns the public key byte array encoded as a Base64 string, of the certificate where the thumbprint passed as parameter input is a match.
        The certificate used must be available in the LocalMachine\My certificate store.

    .PARAMETER Thumbprint
        Specify the thumbprint of the certificate.
    
    .NOTES
        Author:      Nickolaj Andersen / Thomas Kurth
        Contact:     @NickolajA
        Created:     2021-06-07
        Updated:     2023-05-10
    
        Version history:
        1.0.0 - (2021-06-07) Function created
        1.0.1 - (2023-05-10) @AzureToTheMax - Updated to use X509 for the full public key with extended properties in the PEM format

        Credits to Thomas Kurth for sharing his original C# code.
    #>
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the thumbprint of the certificate.")]
        [ValidateNotNullOrEmpty()]
        [string]$Thumbprint
    )
    Process {

        # Determine the certificate based on thumbprint input
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $PSItem.Thumbprint -eq $Thumbprint }
        if ($Certificate -ne $null) {
            # Bring the cert into a X509 object
            $X509 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::New($Certificate)
            #Set the type of export to perform
            $type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
            #Export the public cert
            $PublicKeyBytes = $X509.Export($type, "")

            # Handle return value - convert to Base64
            return [System.Convert]::ToBase64String($PublicKeyBytes)
        }
    }
}
