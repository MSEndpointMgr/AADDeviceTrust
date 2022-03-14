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
        Updated:     2021-06-07
    
        Version history:
        1.0.0 - (2021-06-07) Function created

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
            # Get the public key bytes
            [byte[]]$PublicKeyBytes = $Certificate.GetPublicKey()

            # Handle return value
            return [System.Convert]::ToBase64String($PublicKeyBytes)
        }
    }
}