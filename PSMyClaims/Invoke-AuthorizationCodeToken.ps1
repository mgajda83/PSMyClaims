Function Invoke-AuthorizationCodeToken
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]    
        [String]$TenantId,
        [Parameter(Mandatory=$true)]
        [String]$ClientId,
        [Parameter(Mandatory=$true)]
        [String]$ClientSecret,
        [Parameter(Mandatory=$true)]
        [String]$RedirectUri,
        [Parameter(Mandatory=$true)]
        [String]$Scope
    )
    Write-Host "Invoke-AuthorizationCodeToken" -ForegroundColor DarkBlue

    # Step 1
    $Url = 'https://login.microsoftonline.com/{0}/oauth2/v2.0/authorize' -f $TenantId

    $QueryParameters = @{ 
        client_id = $ClientID
        response_type = "code"
        redirect_uri = $RedirectUri
        response_mode = "query"
        scope = $Scope
        state = Get-Random #12345
        prompt = "select_account"
    }
    
    Add-Type -AssemblyName System.Web
    $Query = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    ForEach ($Key in $QueryParameters.Keys) { $Query.Add($Key, $QueryParameters.$key) }
    
    $UriRequest = [System.UriBuilder]$Url
    $UriRequest.Query = $Query.ToString()
    
    $Output = Invoke-WebBrowser -Url $UriRequest.Uri.AbsoluteUri

    # Step 2
    $RequestBody = @{ 
        grant_type = "authorization_code"
        redirect_uri = $RedirectUri
        client_id = $ClientID
        client_secret = $ClientSecret
        code = $Output["code"]
        scope = $Scope
    }

    $Request = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = $RequestBody
        Uri = 'https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $TenantId
    }

    #Send request
    $TokenResponse = Invoke-RestMethod @Request

    $Result = New-Object -Type PSObject @{
        TokenRequest = @($QueryParameters,$Request)
        TokenResponse = $TokenResponse
    }

    Write-Host "End Invoke-AuthorizationCodeToken" -ForegroundColor DarkBlue
    Return $Result
}