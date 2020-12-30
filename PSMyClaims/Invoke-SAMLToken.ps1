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
        [String]$ForceAuthn
    )
    Write-Host "Invoke-SAMLToken" -ForegroundColor DarkBlue

    # Step 1
    #$TenantID = "88152bde-cfa3-4a5c-b981-a785c624bb42"
    #$ForceAuthn = 0
    $ID = "_$((New-Guid).ToString() -replace '-')" #"_c82f819f9c23ca1f50ae6a6ed6e1d01c"
    $IssueInstant = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" #"2020-12-23T07:09:00Z"
    #$RedirectUri = "https://vpn-waw.asseco.pl/dana-na/auth/saml-endpoint.cgi?p=sp1"
    
    $SAMLRequest = '<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" Destination="https://login.microsoftonline.com/'+$TenantID+'/saml2" ForceAuthn="'+$ForceAuthn+'" ID="'+$ID+'" IssueInstant="'+$IssueInstant+'" ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" ProviderName="'+$RedirectUri+'" Version="2.0"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">'+$RedirectUri+'</saml:Issuer><samlp:NameIDPolicy AllowCreate="1"/></samlp:AuthnRequest>'
    
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
