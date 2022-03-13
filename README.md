# Overview
When building a Function App API in Azure that accepts incoming HTTP requests from an Azure AD joined devices, being able to validate such a request is only coming from a trusted device in a given Azure AD tenant adds extensive security to the API. By default, the Function App can be configured to only accept incoming requests with a valid client certificate, which is a good security practice. Although, there's also another option to enhance the security of a Function App in terms of validating the incoming request, using the certificate enrolled to the device when it first registered itself with Azure AD.

This module performs the device trust validation and can be embedded in most Function Apps where enhanced request validation is required.

# How the trusted device validation works

Every Azure AD joined or hybrid Azure AD joined device has a computer certificate that was enrolled when registering the device to Azure AD. This device specific computer certificate's public and private keys are available locally on the device, while the public key is known to Azure AD. The device trust validation functionality occurs in the following scenarios:

- Client-side data gathering
- Function App data validation

## Client-side

On the client-side, a signature hash using the private key of the computer certificate is calculated and sent encoded as a Base64 string to the Function App including the Azure AD device identifier (the common name of the computer certificate), the public key as a byte array encoded as a Base64 string together with the computer certificate thumbprint. These data strings are sent all together as parameter input when calling the Function App API

## Function App

To be added...

# How to use AADDeviceTrust.Client module in a client-side script

To be added...

# How to use AADDeviceTrust.FunctionApp module in a Function App

Enable the module to be installed as a managed dependency by editing your requirements.psd1 file of the Function App, e.g. as shown below:

```PowerShell
@{
    'AADDeviceTrust' = '1.*'
}
```

Another option would also be to clone this module from GitHub and include it in the modules folder of your Function App, to embedd it directly and not have a dependency to PSGallery.

For a full sample Function App function, look at the code in \Samples\FunctionApp-MSI.ps1 in this repo.