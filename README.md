# Overview
When building a Function App API in Azure that accepts incoming HTTP requests from Azure AD joined devices, being able to validate such a request is only coming from a trusted device in a given Azure AD tenant adds extensive security to the API. By default, the Function App can be configured to only accept incoming requests with a valid client certificate, which is a good security practice. Although, there's also another option to enhance the security of a Function App in terms of validating the incoming request, using the certificate enrolled to the device when it first registered itself with Azure AD.

This module performs the device trust validation and can be embedded in most Function Apps where enhanced request validation is required.

# How the trusted device validation works

Every Azure AD joined or hybrid Azure AD joined device has a computer certificate that was generated when registering the device to Azure AD. This device specific computer certificate's public and private keys are available locally on the device. When registering the device, a special field called the ["alternativeSecurityIds"](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dvrj/f900e812-8f1c-4345-9ab0-b91111068651) is added to the Device's Azure record which contains a "key" field with a value that is a Base64 encoded representation of that same private/public key pairs SHA1 Thumbprint, as well as the entire public keys SHA1 hash.

The device trust validation functionality occurs in the two parts:

- Client-side data gathering
- Function App data validation

## Client-side

On the client side, a table of information is built which will both serve to carry the data needed to authenticate to our Function App, as well as any other payload required for your specific needs. By default, this table contains...

* The devices name.
* A copy of the computers public certificate in PEM format which has been encoded as a Base64 string for ease of transport.
* And last but not least, a signature generated from the SHA256 hash of the devices Azure ID which was signed using the devices private certificate.

...And again, all of that data will be passed to the Function App along with any other data you add. Details on how to add more fields can be found in the use section.

Note: The signature is *not* an encrypted form of the SHA256 hash of the devices Azure ID, nor does it contain the hash of the Azure ID at all. It also does not contain the Private key. It is merely a method to validate and authenticate a SHA256 hash, and thus the chunk of data it represents (the Azure ID), when combined with the public certificate. How this comes into play is explained in the next section.


## Function App

When the Function App receives a request, it will start by pulling the various information sent by the client out of the body of the request. 

The first thing The Function App does is pull the devices Azure AD ID from the certificate provided. It will then use its Graph permissions* to pull the full Azure AD record for that Azure AD Device ID. As mentioned, this record contains a "alternativeSecurityIds" field with a key value that has a base64 representation of the SHA1 thumbprint and SHA1 hash of the full X.509 public certificate used when the machine originally registered.

***Function App needs Device.Read.All permissions**

1. The authentication then starts by taking the full PEM X.509 public cert provided in our request and pulling out the SHA1 thumbprint of the certificate. It then confirms that thumbprint matches the SHA1 thumbprint stored in the alternativeSecurityIds/keys field. With this, we can confirm that the public key we have provided in our request is at least related to the public key (or more so private key) originally used when the device registered with Azure.

2. Next, we confirm that the SHA1 hash of the entire public key that was provided matches the SHA1 hash of the devices public key that was stored in the alternativeSecurityIds/keys field. At this point, we know the public certificate provided is not just related to the same private certificate but is indeed the exact same public certificate originally made when the device was registered.

3. Now that we know our public key is legitimate and not just some random key, we are going to test the signature against the SHA256 hash of the devices Azure ID using that public key. In order to do this, we must take our Base64 encoded Public Key, turn it back into a byte array, and convert that back into a functional RSA key. We then pull the devices Azure AD ID, this time from Azure itself, and again calculate it’s SHA256 hash. We can then use our public key to validate that signature against that hash (the hash of the Azure ID) proving that we must also have the matching private key.

4. Lastly, we do a simple check to ensure that the Azure AD Device ID is enabled. 

With all this confirmed, we know that...

* The request contained a public certificate issued to a valid Azure Device ID
* The request contained a public certificate with a thumbprint that matches the thumbprint stored in Azure. Now we know this public cert is at least related to the same private cert.
* The request contained a public certificate with a hash that matches the hash of the original public certificate stored in Azure. Now we know that this is the same public cert originally used to register the device.
* The signature file provided is indeed a signed copy of the devices Azure AD ID which, since we know this is the original public key, we can infer/know the original private key was used to sign it.
* That Azure Device ID in question is Enabled

At this point, the device is authenticated and the remainder of the request (your custom code) can begin to process.


# How to use AADDeviceTrust.Client module in a client-side script
Ensure the AADDeviceTrust.Client module is installed on the device prior to running the sample code below. Use the `Test-AzureADDeviceRegistration` function to ensure the device where the code is running on fulfills the device registration requirements. Then use the `New-AADDeviceTrustBody` function to automatically generate a hash-table object containing the gathered data required for the body of the request. Finally, use built-in `Invoke-RestMethod` cmdlet to invoke the request against the Function App, passing the gathered data to be validated by the Function App, if the request comes from a trusted device.

```PowerShell
if (Test-AzureADDeviceRegistration -eq $true) {
    # Create body for Function App request
    $BodyTable = New-AADDeviceTrustBody

    # Extend body table with custom data to be processed by Function App
    $BodyTable.Add("Key", "Value") #Example Only

    # Send log data to Function App
    $URI = "https://<function_app_name>.azurewebsites.net/api/<function_name>?code=<function_key>"
    Invoke-RestMethod -Method "POST" -Uri $URI -Body ($BodyTable | ConvertTo-Json) -ContentType "application/json"
}
else {
    Write-Warning -Message "Script is not running on an Azure AD joined or hybrid Azure AD joined device"
}
```

For a full sample of the client-side script, explore the code in \Samples\ClientSide.ps1 in this repo.


# How to use AADDeviceTrust.FunctionApp module in a Function App
Enable the module to be installed as a managed dependency by editing your requirements.psd1 file of the Function App, e.g. as shown below:

```PowerShell
@{
    'AADDeviceTrust.FunctionApp' = '1.*'
}
```
You will also need to grant your Function App Device.Read.All Graph permissions using it's managed identity. This is done such that the Function App can pull the devices Azure AD records.

Another option would also be to clone this module from GitHub and include it in the modules folder of your Function App, to embed it directly and not have a dependency to PSGallery.

For a full sample Function App function, explore the code in \Samples\FunctionApp-MSI.ps1 in this repo.


# What certificate is sent to the Function App?
If you are curious to know and see the Certificate sent to the Function App in a friendly format, you can use the \Samples\Cert-Exporter-Sample.ps1 to generate a .CER file. This is done by taking the same Base64 content and slightly re-arranging it into the PEM format. The Base64 itself simply needs to be broken at every 64th character, then the appropriete cert start and end headers are added to the top and bottom.

This will allow you to visually see the cert, visually confirm the private key is not attached, and confirm the cert is issues to your devices Azure AD ID. The file is generated in the run location of the script and will be named Cert.cer.
