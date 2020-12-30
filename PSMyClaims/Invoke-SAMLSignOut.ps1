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
    $ID = "_$((New-Guid).ToString() -replace '-')" 
    $IssueInstant = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" 

    $SAMLRequest = '<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" Destination="https://login.microsoftonline.com/' + $TenantId + '/saml2" ID="' + $ID + '" IssueInstant="' + $IssueInstant + '" Version="2.0"><saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">' + $RedirectUri + '</saml:Issuer><saml:NameID xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">' + $NameID + '</saml:NameID></samlp:LogoutRequest>'
    
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