#Requires -modules WebServicesPowerShellProxyBuilder

$APIRoot = "https://api.twilio.com"
$TwilioCredential = [System.Management.Automation.PSCredential]::Empty
$GetTwilioCredentialScriptBlock = {
    Import-Clixml -Path $env:USERPROFILE\TwilioCredential.txt
}

function New-TwilioCredential {
    Get-Credential -Message "Enter your Twilio account SID as the username and your auth token as the password" | 
    Export-Clixml -Path $env:USERPROFILE\TwilioCredential.txt
}

function Set-GetTwilioCredentialScriptBlock {
    param (
        $ScriptBlock
    )
    $Script:GetTwilioCredentialScriptBlock = $ScriptBlock
}

function Get-TwilioCredential {
    & $GetTwilioCredentialScriptBlock
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

function Get-TwilioCalls {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts -SubResource Calls
}

function Get-TwilioIncomingPhoneNumbers {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts -SubResource IncomingPhoneNumbers
}

function Get-TwilioAddresses {
    Invoke-TwilioAPIFunction -HttpMethod get -Resource Accounts -SubResource Addresses
}

function Add-TwilioAddresses {
    param(
        [String]$FriendlyName,
        [Parameter(Mandatory)][String]$CustomerName,
        [Parameter(Mandatory)][String]$Street,
        [Parameter(Mandatory)][String]$City,
        [Parameter(Mandatory)][String]$Region,
        [Parameter(Mandatory)][String]$PostalCode,
        [Parameter(Mandatory)][String]$IsoCountry
        
    )
    Invoke-TwilioAPIFunction -HttpMethod post -Resource Accounts -SubResource Addresses -Body $($PSBoundParameters | ConvertTo-URLEncodedQueryStringParameterString)
}

function Remove-TwilioAddresses {
    param(
        [Parameter(Mandatory)]$SubResourceSid
    )

    Invoke-TwilioAPIFunction -HttpMethod delete -Resource Accounts -SubResource Addresses -SubResourceSid $SubResourceSid -Body $($PSBoundParameters | ConvertTo-URLEncodedQueryStringParameterString)

}

function Update-TwilioAddresses {
    param(
        [Parameter(Mandatory)]$SubResourceSid,
        $CustomerName,
        $FriendlyName,
        $Street,
        $street_secondary,
        $City,
        $Region,
        $PostalCode,
        [Parameter][ValidateSet("true","false")]$AutoCorrectAddress
    )

    Invoke-TwilioAPIFunction -HttpMethod post -Resource Accounts -SubResource Addresses -SubResourceSid $SubResourceSid -Body $($PSBoundParameters | ConvertTo-URLEncodedQueryStringParameterString)
}

function Set-TwilioIncomingPhoneNumber {
    param (
       [Parameter(Mandatory)][string]$FriendlyName,
       $ApiVersion,
       $VoiceUrl,
       $VoiceMethod,
       $VoiceFallbackUrl,
       $VoiceFallbackMethod,
       $StatusCallback,
       $StatusCallbackMethod,
       $VoiceCallerIdLookup,
       $VoiceApplicationSid,
       $TrunkSid,
       $SmsUrl,
       $SmsMethod,
       $SmsFallbackUrl,
       $SmsFallbackMethod,
       $SmsApplicationSid,
       $AccountSid, 
       $AddressSid
    )
    $SubResourceSid = Get-TwilioIncomingPhoneNumbers | 
                Select-Object -ExpandProperty incoming_phone_numbers | 
                Where-Object friendly_name -eq $FriendlyName |
                Select-Object -ExpandProperty sid

    Invoke-TwilioAPIFunction -HttpMethod post -Resource Accounts -SubResource IncomingPhoneNumbers -SubResourceSid $SubResourceSid -Body $(
                $PSBoundParameters | ConvertTo-URLEncodedQueryStringParameterString
    )
}

function Invoke-TwilioAPIFunction {
    param (
        $HttpMethod,
        $Resource,
        $SubResource,
        $Body,
        $Header,
        $SubResourceSid,
        [Switch]$Debug
    )
    if ($Debug) {
        Set-CertificatePolicy -TrustAllCerts
    }
    
    $Credential = Get-TwilioCredential

    $URI = if (-not $SubResource ) {
        $APIRoot +"/2010-04-01/$Resource.json"
    } else {
        if (-not $SubResourceSid ) {
            $APIRoot +"/2010-04-01/$Resource/$($Credential.UserName)/$SubResource.json?PageSize=350"
        } else { 
            $APIRoot +"/2010-04-01/$Resource/$($Credential.UserName)/$SubResource/$SubResourceSid.json"
        }    
    }

    #$Response = if ($Header) {
    #    Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI -Header $Header
    #} else {
    #    Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI
    #}

    $Response = if ($Body) {
        Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI  -Body $Body
    } else {
        Invoke-RestMethod -Method $HttpMethod -Credential $Credential -Uri $URI
    }
    
    $Response
}

#$TwilioResources = @"
#Accountsi
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


function Invoke-TwilioFaxAPIFunction {
    param (
        $Method,
        $Body,
        $Sid,
        $Media_Sid,
        [Switch]$Debug
    )     
    if ($Debug) {
        Set-CertificatePolicy -TrustAllCerts
    }

    $Credential = Get-TwilioCredential
    $URI = if ($Media_Sid -and $Sid){
        "https://fax.twilio.com/v1/Faxes/$Sid/Media/$Media_Sid"
    } elseif ($Sid) {
        "https://fax.twilio.com/v1/Faxes/$Sid"        
    } else {
        "https://fax.twilio.com/v1/Faxes"
    }

    $Parameters = $PSBoundParameters | ConvertFrom-PSBoundParameters -ExcludeProperty Debug,Sid,Media_Sid -AsHashTable

    Invoke-RestMethod  -URI $URI -Credential $Credential @Parameters
}

function Get-TwilioFaxes {
    Invoke-TwilioFaxAPIFunction -Method get |
    Select -ExpandProperty Faxes
}

function Remove-TwilioFaxes {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$SID
    )
    process {
        Invoke-TwilioFaxAPIFunction -Method delete @PSBoundParameters
    }
}

function Get-TwilioFaxMedia {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$SID,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Media_sid
    )
    process {
        Invoke-TwilioFaxAPIFunction -Method Get @PSBoundParameters
    }
}

function Invoke-TwilioFaxMediaDownload {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$SID,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Media_sid,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$media_url
    )
    process {        
        $FaxMedia = Get-TwilioFaxMedia -SID $SID -Media_sid $Media_sid
        $Extension = if ($FaxMedia.content_type -eq "image/tiff" ) {
            "tif"
        } elseif ($FaxMedia.content_type -eq "application/pdf") {
            "pdf"
        } else {
            throw "Unrecongized content type"
        }
        Invoke-WebRequest -Uri $media_url -OutFile "$Media_sid.$Extension"
    }
}