 <#
    .SYNOPSIS
        Export the CERT to be uploaded in .cer/PEM format to the running directory.
    
    .DESCRIPTION
        Export the CERT to be uploaded in .cer/PEM format to the running directory. Used for testing and validaiton. 
        Provides visual confirmation that the private key is not part of the cert.
        Provides visual confirmation that the CN is the Azure AD Device ID.
    
    .NOTES
        Author:      Maxton Allen 
        Contact:     @AzureToTheMax
        Created:     2023-05-14
        Updated:     2023-05-14
    
        Version history:
        1.0.0 - (2023-05-14) created
    #>


function Get-AzureADRegistrationCertificateThumbprint {
    <#
    .SYNOPSIS
        Get the thumbprint of the certificate used for Azure AD device registration.
    
    .DESCRIPTION
        Get the thumbprint of the certificate used for Azure AD device registration.
    
    .NOTES
        Author:      Nickolaj Andersen
        Contact:     @NickolajA
        Created:     2021-06-03
        Updated:     2021-06-03
    
        Version history:
        1.0.0 - (2021-06-03) Function created
        1.0.1 - (2023-05-10) @AzureToTheMax Updated for Cloud PCs which don't have their thumbprint as their JoinInfo key name.
    #>
    Process {
        # Define Cloud Domain Join information registry path
        $AzureADJoinInfoRegistryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"

        # Retrieve the child key name that is the thumbprint of the machine certificate containing the device identifier guid
        $AzureADJoinInfoThumbprint = Get-ChildItem -Path $AzureADJoinInfoRegistryKeyPath | Select-Object -ExpandProperty "PSChildName"
        # Check for a cert matching that thumbprint
        $AzureADJoinCertificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $PSItem.Thumbprint -eq $AzureADJoinInfoThumbprint }

            if($AzureADJoinCertificate -ne $null){
            # if a matching cert was found tied to that reg key (thumbprint) value, then that is the thumbprint and it can be returned.
            $AzureADThumbprint = $AzureADJoinInfoThumbprint

            # Handle return value
            return $AzureADThumbprint

            } else {

            # If a cert was not found, that reg key was not the thumbprint but can be used to locate the cert as it is likely the Azure ID which is in the certs common name.
            $AzureADJoinCertificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $PSItem.Subject -like "CN=$($AzureADJoinInfoThumbprint)" }
            
            #Pull thumbprint from cert
            $AzureADThumbprint = $AzureADJoinCertificate.Thumbprint

            # Handle return value
            return $AzureADThumbprint
            }

    }
}

$thumbprint = Get-AzureADRegistrationCertificateThumbprint
#Get the cert as base64
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" -Recurse | Where-Object { $PSItem.Thumbprint -eq $Thumbprint }
        if ($Certificate -ne $null) {
            # Bring the cert into a X509 object
            $X509 = [System.Security.Cryptography.X509Certificates.X509Certificate2]::New($Certificate)
            #Set the type of export to perform
            $type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
            #Export the public cert
            $PublicKeyBytes = $X509.Export($type, "")

            # Handle return value - convert to Base64
            $PublicKeyEncoded = [System.Convert]::ToBase64String($PublicKeyBytes)
        }

#Alter formatting
    #Break it every 64 characters to make it into the CER format
    $PublicKeyBroken = $PublicKeyEncoded |
    ForEach-Object {
        $line = $_
    
        for ($i = 0; $i -lt $line.Length; $i += 64)
        {
            $length = [Math]::Min(64, $line.Length - $i)
            $line.SubString($i, $length)
        }
    }

#Set cer content to current working directory
Set-Content ".\cert.cer" "-----BEGIN CERTIFICATE-----
$PublicKeyBroken
-----END CERTIFICATE-----"

#Your cert should now be in the working directory as cert.cer and can be opened natively by Windows for inspection. 