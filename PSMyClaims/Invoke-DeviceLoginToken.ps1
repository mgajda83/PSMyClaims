Function Invoke-DeviceLoginToken
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]     
        [String]$TenantId,
        [Parameter(Mandatory=$true)] 
        [String]$ClientId,
        [Parameter(Mandatory=$true)] 
        [String]$Scope
    )
    Write-Host "Invoke-DeviceLoginToken" -ForegroundColor DarkBlue

    #Step 1
    $RequestBody = @{ 
        client_id = $ClientId
        scope = $Scope
    }
    
    $Request1 = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = $RequestBody
        Uri = "https://login.microsoftonline.com/{0}/oauth2/v2.0/devicecode" -f $TenantId
    }

    $ResponseDeviceCode = Invoke-RestMethod @Request1
    Write-Host $ResponseDeviceCode.message

    #Step 2
    #Start-Process "https://www.microsoft.com/devicelogin"
    Invoke-WebBrowser -Url "https://www.microsoft.com/devicelogin"

    #Step 3
    $RequestBody = @{ 
        grant_type = "urn:ietf:params:oauth:grant-type:device_code"
        client_id = $ClientId
        device_code = $ResponseDeviceCode.device_code
    }
    
    $Request2 = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = $RequestBody
        Uri = "https://login.microsoftonline.com/{0}/oauth2/v2.0/token" -f $TenantId
    }
    
    $Pending = $null
    While($true)
    {
        Try
        {
            Start-Sleep -Seconds 10
            $TokenResponse = Invoke-RestMethod @Request2
            break
        }
        catch
        {
            if($null -eq $Pending)
            { 
                $Pending = $_.ErrorDetails.Message | ConvertFrom-Json 
                Write-Host $($Pending.error_description) -NoNewline
            }
            Write-Host "." -NoNewline
        }
    }
    
    $Result = New-Object -Type PSObject @{
        TokenRequest = @($Request1,$Request2)
        TokenResponse = $TokenResponse
    }

    Write-Host "End Invoke-DeviceLoginToken" -ForegroundColor DarkBlue
    Return $Result
}