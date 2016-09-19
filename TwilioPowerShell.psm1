#Requires -modules WebServicesPowerShellProxyBuilder

$APIRoot = "https://api.twilio.com"

function New-TwilioCredential {
    Get-Credential -Message "Enter your Twilio account SID as the username and your auth token as the password" | 
    Export-Clixml -Path $env:USERPROFILE\TwilioCredential.txt
}

function Get-TwilioAccounts {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts
}

function New-TwilioCall {
    param (
        [Parameter(Mandatory)]$From,
        [Parameter(Mandatory)]$To,
        [Parameter(Mandatory,ParameterSetName="URL")]$Url,
        [Parameter(Mandatory,ParameterSetName="ApplicationSid")]$ApplicationSid,
        $Method,
        $FallbackURL,
        $FallbackMethod,
        $StatusCallback,
        $StatusCallbackMethod,
        [ValidateSet("initiated","ringing","answered","completed")]$StatusCallbackEvent,
        $SendDigits,
        $IfMachine,
        $Timeout,
        $Record

    )
    Invoke-TwilioAPIFunction -HttpMethod post -Resource Accounts -SubResource Calls -Body $($PSBoundParameters | ConvertTo-URLEncodedQueryStringParameterString)
}

Function Get-TwilioCalls {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts -SubResource Calls
}

Function Get-TwilioIncomingPhoneNumbers {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts -SubResource IncomingPhoneNumbers
}

Function Invoke-TwilioAPIFunction {
    param (
        $HttpMethod,
        $Resource,
        $SubResource,
        $Body,
        $Header,
        [Switch]$Debug
    )
    $Debug = $true
    if ($Debug) {

        add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    
    $Credential = Import-Clixml $env:USERPROFILE\TwilioCredential.txt

    $URI = if (-not $SubResource ) {
        $APIRoot +"/2010-04-01/$Resource.json"
    } else {
        $APIRoot +"/2010-04-01/$Resource/$($Credential.UserName)/$SubResource.json"
    }

    #$Response = if ($Header) {
    #    Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI -Header $Header
    #} else {
    #    Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI
    #}

    $Response = if ($Body) {
        Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI -Body $Body
    } else {
        Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI
    }

    $Response
}


#$TwilioResources = @"
#Accounts
#Addresses
#API Keys
#Applications
#AvailablePhoneNumbers
#Calls
#Call Feedback
#Conferences
#Participants
#Incoming Phone Numbers
#Messages
#Feedback
#Media
#Outgoing Caller IDs
#Queues
#Members
#Recordings
#Short Codes
#Tokens (NAT Traversal)
#Transcriptions
#Usage Records
#Usage Triggers
#"@ -split "`r`n"