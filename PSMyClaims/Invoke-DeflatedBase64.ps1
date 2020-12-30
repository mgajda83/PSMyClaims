Function Invoke-DecompressDeflatedBase64
{
    param
    (
        $Content
    )

    $Data = [System.Convert]::FromBase64String($Content)
    $MemoryStream = New-Object System.IO.MemoryStream
    $MemoryStream.Write($Data, 0, $Data.Length)
    [Void]$MemoryStream.Seek(0,0) 

    $DeflateStream = New-Object System.IO.Compression.DeflateStream($MemoryStream, [System.IO.Compression.CompressionMode]::Decompress)
    $StreamReader = New-Object System.IO.StreamReader($DeflateStream)

    $Result = @()
    while ($Line = $StreamReader.ReadLine()) 
    {  
        $Result += $Line
    }

    Return $Result
}

Function Invoke-CompressDeflatedBase64
{
    param
    (
        $Content
    )

    $MemoryStream = New-Object System.IO.MemoryStream
    $DeflateStream = New-Object System.IO.Compression.DeflateStream($MemoryStream, [System.IO.Compression.CompressionMode]::Compress)

    $StreamWriter = New-Object System.IO.StreamWriter($DeflateStream)
    $StreamWriter.Write($Content)
    $StreamWriter.Close()

    $Bytes = $MemoryStream.ToArray()
    $Result = [System.Convert]::ToBase64String($Bytes)

    Return $Result
}
