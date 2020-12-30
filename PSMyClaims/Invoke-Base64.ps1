Function Invoke-DecodeBase64
{
    param
    (
        $Content
    )

    $Bytes = [System.Convert]::FromBase64String($Content)
    $Result = [System.Text.Encoding]::UTF8.GetString($Bytes)
    
    Return $Result
}

Function Invoke-EncodeBase64
{
    param
    (
        $Content
    )

    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Result = [System.Convert]::ToBase64String($Bytes)

    Return $Result
}