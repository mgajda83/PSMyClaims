function Format-SAMLtoken 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]     
        [String]$Token
    )
 
    [xml]$DecodedToken = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Token))
    
    $DecodedTokenObj = ConvertFrom-Xml -Xml $DecodedToken
    $DecodedTokenJson = $DecodedTokenObj | ConvertTo-Json -Depth 5

    Return $DecodedTokenJson 
}
