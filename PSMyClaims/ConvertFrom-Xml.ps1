Function ConvertFrom-Xml 
{
	param
	(
		[parameter(Mandatory, ValueFromPipeline)] 
		$Xml
	)
	
	$Elements = $xml | Get-Member -MemberType Property
	
	$Result = New-Object -Type PSObject
	ForEach($Element in $Elements)
	{
		#Write-Host "$($Element.Name) => $($Element.Definition)"
		if($Element.Definition -match "System.Xml.XmlElement")
		{
			$Node = ConvertFrom-Xml -Xml $xml.$($Element.Name)
			$Result | Add-Member -MemberType NoteProperty -Name $Element.Name -Value $Node
        } elseif($Element.Definition -match "System.Object\[\]") {
            $Attributes = New-Object -Type PSObject
            ForEach($Attribute in $xml.Attribute) 
            {
                $Attributes | Add-Member -MemberType NoteProperty -Name $Attribute.Name -Value $Attribute.AttributeValue
            }

            $Result | Add-Member -MemberType NoteProperty -Name $Element.Name -Value $Attributes
        } else {
			$Result | Add-Member -MemberType NoteProperty -Name $Element.Name -Value $xml.$($Element.Name)
		}
		
	}
	
	Return $Result
}
