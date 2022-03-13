# Overview
When building a Function App API in Azure that accepts incoming HTTP requests from an Azure AD joined devices, being able to validate such a request is only coming from a trusted device in a given Azure AD tenant adds extensive security to the API. By default, the Function App can be configured to only accept incoming requests with a valid client certificate, which is a good security practice. Although, there's also another option to enhance the security of a Function App in terms of validating the incoming request, using the certificate enrolled to the device when it first registered itself with Azure AD.

This module performs the device trust validation and can be embedded in most Function Apps where enhanced request validation is required.

# How the trusted device validation works

To be added...

# How to use this module in a Function App

Enable the module to be installed as a managed dependency by editing your requirements.psd1 file of the Function App, e.g. as shown below:

```PowerShell
@{
    'AADDeviceTrust' = '1.*'
}
```

Another option would also be to clone this module from GitHub and include it in the modules folder of your Function App, to embedd it directly and not have a dependency to PSGallery.

# Usage of module within a Function App

For a full sample Function App function, look at the code in \Samples\FunctionApp-MSI.ps1 in this repo.