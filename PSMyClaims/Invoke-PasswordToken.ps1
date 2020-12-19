Function Invoke-PasswordToken
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
        [String]$Scope
    )
    Write-Host "Invoke-PasswordToken" -ForegroundColor DarkBlue

    $Credential = Get-Credential

    $RequestBody = @{
        Grant_Type    = 'Password'
        Scope         = $Scope
        client_Id     = $ClientId
        Client_Secret = $ClientSecret
        Username      = $Credential.GetNetworkCredential().Username
        Password      = $Credential.GetNetworkCredential().Password
    } 
    
    $Request = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = $RequestBody
        Uri = 'https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $TenantId
    }

    $TokenResponse = Invoke-RestMethod @Request

    $Result = New-Object -Type PSObject @{
        TokenRequest = $Request
        TokenResponse = $TokenResponse
    }

    Write-Host "End Invoke-PasswordToken" -ForegroundColor DarkBlue
    Return $Result
}