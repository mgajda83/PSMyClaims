Function Invoke-SAMLToken
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]    
        [String]$TenantId,
        [Parameter(Mandatory=$true)]
        [String]$RedirectUri,
        [Parameter(Mandatory=$true)]
        [String]$ForceAuthn,
        [Parameter(Mandatory=$true)]
        [String]$NameIDPolicyFormat
    )
    Write-Host "Invoke-SAMLToken" -ForegroundColor DarkBlue

    # Step 1
    $ID = "_$((New-Guid).ToString() -replace '-')" 
    $IssueInstant = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" 
    
    $SAMLRequest = '<?xml version="1.0" encoding="UTF-8"?><saml2p:AuthnRequest AssertionConsumerServiceURL="'+$RedirectUri+'" Destination="https://login.microsoftonline.com/'+$TenantID+'/saml2" ForceAuthn="'+$ForceAuthn+'" ID="'+$ID+'" IsPassive="false" IssueInstant="'+$IssueInstant+'" ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Version="2.0" xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">'+$RedirectUri+'</saml:Issuer><saml2p:NameIDPolicy Format="'+$NameIDPolicyFormat+'"/></saml2p:AuthnRequest>'

    $DeflateSAMLRequest = Invoke-CompressDeflatedBase64 -Content $SAMLRequest

    $Url = 'https://login.microsoftonline.com/{0}/saml2' -f $TenantId

    Add-Type -AssemblyName System.Web

    $QueryParameters = @{ 
        SAMLRequest = $DeflateSAMLRequest
    }
    
    $Query = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    ForEach ($Key in $QueryParameters.Keys) { $Query.Add($Key, $QueryParameters.$key) }
    
    $UriRequest = [System.UriBuilder]$Url
    $UriRequest.Query = $Query.ToString()
    
    #Send request
    $TokenResponse = Invoke-WebBrowser -Url $UriRequest.Uri.AbsoluteUri -SAMLResponse

    $Result = New-Object -Type PSObject @{
        TokenRequest = $SAMLRequest
        TokenResponse = $TokenResponse
    }

    Write-Host "End Invoke-SAMLToken" -ForegroundColor DarkBlue
    Return $Result
}
