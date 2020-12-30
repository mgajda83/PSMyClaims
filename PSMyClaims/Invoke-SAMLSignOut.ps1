Function Invoke-SAMLSignOut
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$TenantId,
        [Parameter(Mandatory=$true)]
        [String]$RedirectUri
    )

    $NameID = "Uz2Pqz1X7pxe4XLWxV9KJQ+n59d573SepSAkuYKSde8="
    $ID = "_$((New-Guid).ToString() -replace '-')" #"_c82f819f9c23ca1f50ae6a6ed6e1d01c"
    $IssueInstant = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" #"2020-12-23T07:09:00Z"

    $SAMLRequest = '<samlp:LogoutRequest xmlns="urn:oasis:names:tc:SAML:2.0:metadata" ID="'+$ID+'" Version="2.0" IssueInstant="'+$IssueInstant+'" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"><Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">'+$RedirectUri+'</Issuer><NameID xmlns="urn:oasis:names:tc:SAML:2.0:assertion">'+$NameID+'</NameID></samlp:LogoutRequest>'
    
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
    [Void](Invoke-WebBrowser -Url $UriRequest.Uri.AbsoluteUri)
}