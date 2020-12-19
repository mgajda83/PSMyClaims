Function Invoke-SignOut
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$TenantId,
        [Parameter(Mandatory=$true)]
        [String]$RedirectUri
    )

    $Url = 'https://login.microsoftonline.com/{0}/oauth2/logout?post_logout_redirect_uri={1}' -f $TenantId, $RedirectUri
    [Void](Invoke-WebBrowser -Url $Url)
}