function Get-AzureADDeviceIDFromCertificate {
     <#
    .SYNOPSIS
        Used to pull the Azure Device ID from the provided Base64 certificate.
    
    .DESCRIPTION
        Used by the function app to pull the Azure Device ID from the provided Base64 certificate.
    
    .NOTES
        Author:      Maxton Allen 
        Contact:     @AzureToTheMax
        Created:     2023-05-14
        Updated:     2023-05-14
    
        Version history:
        1.0.0 - (2023-05-14) created
    #>
    param(    
        [parameter(Mandatory = $true, HelpMessage = "Specify a Base64 encoded value for which an Azure Device ID will be extracted.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    Process {
        # Convert Value (cert) passed back to X502 Object
        $X502 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::New([System.Convert]::FromBase64String($Value))

        # Get the Subject (issued to)
        $Subject = $X502.Subject

        # Remove the leading "CN="
        $SubjectTrimed = $Subject.TrimStart("CN=")

        # Handle return
        Return $SubjectTrimed
    }
}
