Function Invoke-WebBrowser
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Url,
        [Switch]$SAMLResponse
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Web

    $Form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
    $WebBrowser = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($Url) }
    
    $DocComp  = {
        $Global:uri = $WebBrowser.Url.AbsoluteUri
        if ($Global:uri -match "error=[^&]*|code=[^&]*") {$Form.Close() }
    }
	$DocNav = {
		if($WebBrowser.DocumentText -match "SAMLResponse")
		{
			$Script:SAMLToken = (([xml]$WebBrowser.DocumentText).GetElementsByTagName("input") | Where-Object name -eq SAMLResponse).value
			$Form.Close()
		}
    }
    $WebBrowser.ScriptErrorsSuppressed = $true
    $WebBrowser.Add_DocumentCompleted($DocComp)
    $WebBrowser.Add_Navigated($DocNav)
    $Form.AutoScaleMode = 'Dpi'
    $Form.text = "Azure AD Authentication"
    $Form.ShowIcon = $False
    $Form.AutoSizeMode = 'GrowAndShrink'
    $Form.StartPosition = 'CenterScreen'
    $Form.Controls.Add($WebBrowser)
    $Form.Add_Shown({$Form.Activate()})
    [Void]$Form.ShowDialog()
    
	if($SAMLResponse)
	{
		$Output = $Script:SAMLToken
	} else {
		$QueryOutput = [System.Web.HttpUtility]::ParseQueryString($WebBrowser.Url.Query)
		$Output = @{}
		foreach($Key in $QueryOutput.Keys){
			$Output["$Key"] = $QueryOutput[$Key]
		}
	}

    Return $Output
}
