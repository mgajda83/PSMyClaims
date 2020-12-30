function Format-JWTtoken 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]     
        [String]$Token
    )
 
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) 
    { 
        Write-Error "Invalid token" -ErrorAction Stop 
    }
 
    $TokenParts = $Token.Replace('-', '+').Replace('_', '/').Split(".")

    #Header
    While ($TokenParts[0].Length % 4) { $TokenParts[0] += "=" }
    $TokenHeader = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($TokenParts[0])) | ConvertFrom-Json
    
    #Payload
    While ($TokenParts[1].Length % 4) { $TokenParts[1] += "=" }
    $TokenPayload = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($TokenParts[1])) | ConvertFrom-Json 

    #Signature
    While ($TokenParts[2].Length % 4) { $TokenParts[2] += "=" }
    $TokenSignature = $TokenParts[2]

    $DecodedToken = New-Object -Type PSObject -Property @{
        Header = $TokenHeader
        Payload = $TokenPayload
        Signature = $TokenSignature
    } 
    $DecodedTokenJson = $DecodedToken | ConvertTo-Json

    Return $DecodedTokenJson 
}