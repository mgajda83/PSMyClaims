Function Show-Settings
{
    [CmdletBinding()]
    Param()

    switch ($GrantTypeComboBox.Items[$GrantTypeComboBox.SelectedIndex].Name) 
    {
        "AuthorizationCode" { 
            $SettingsTab.Visibility = "Visible"
            $SAMLSettingsTab.Visibility = "Collapsed"
            $TabControl.SelectedIndex = 0
            break 
        }
        "ClientCredentials" { 
            $SettingsTab.Visibility = "Visible"
            $SAMLSettingsTab.Visibility = "Collapsed"
            $TabControl.SelectedIndex = 0
            break
        }
        "DeviceCode" { 
            $SettingsTab.Visibility = "Visible"
            $SAMLSettingsTab.Visibility = "Collapsed"
            $TabControl.SelectedIndex = 0
            break
        }
        "Password" { 
            $SettingsTab.Visibility = "Visible"
            $SAMLSettingsTab.Visibility = "Collapsed"
            $TabControl.SelectedIndex = 0
            break
        }
        "SAML" { 
            $SettingsTab.Visibility = "Collapsed"
            $SAMLSettingsTab.Visibility = "Visible"
            $TabControl.SelectedIndex = 1
            break
        }
        Default {}
    }
}

Function Show-TokenResponse
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)] 
        $TokenResult
    )

    $SignOutButton.Visibility = "Visible"

    # Token Info Tab
    $TokenInfoText.Text = $TokenResult.TokenResponse | ConvertTo-Json 
   
    if($TokenResult.TokenType -eq "SAML")
    {
        $AccessTokenTab.Visibility = "Collapsed"
        $IdTokenTab.Visibility = "Collapsed"

        try {
            $EncSAMLTokenText.Text = $TokenResult.TokenResponse
            $DecSAMLTokenText.Text = Format-SAMLToken -Token $TokenResult.TokenResponse
            $TokenRequestTab.Visibility = "Visible"
            $TokenInfoTab.Visibility = "Visible"
            $SAMLTokenTab.Visibility = "Visible"
        }
        catch {
            $SAMLTokenTab.Visibility = "Collapsed"
        }
    } else {
        $SAMLTokenTab.Visibility = "Collapsed"

        # Access Token Tab
        if($TokenResult.TokenResponse.access_token)
        {
            try {
                $EncAccessTokenText.Text = $TokenResult.TokenResponse.access_token
                $DecAccessTokenText.Text = Format-JWTtoken -Token $TokenResult.TokenResponse.access_token
                $TokenRequestTab.Visibility = "Visible"
                $TokenInfoTab.Visibility = "Visible"                
                $AccessTokenTab.Visibility = "Visible"
            }
            catch {
                $AccessTokenTab.Visibility = "Collapsed"
            }
        } else {
            $AccessTokenTab.Visibility = "Collapsed"
        }

        # ID Token Tab
        if($TokenResult.TokenResponse.id_token)
        {
            try {
                $EncIdTokenText.Text = $TokenResult.TokenResponse.id_token
                $DecIdTokenText.Text = Format-JWTtoken -Token $TokenResult.TokenResponse.id_token
                $TokenRequestTab.Visibility = "Visible"
                $TokenInfoTab.Visibility = "Visible"                
                $IdTokenTab.Visibility = "Visible"
            }
            catch {
                $IdTokenTab.Visibility = "Collapsed"
            }
        } else {
            $IdTokenTab.Visibility = "Collapsed"
        }
    }
    Set-Variable -Name Token -Value $TokenResult.TokenResponse -Scope Global
}

Function Get-Token
{
    [CmdletBinding()]
    Param()

    $Result = $null
    switch ($GrantTypeComboBox.Items[$GrantTypeComboBox.SelectedIndex].Name) 
    {
        "AuthorizationCode" { 
            $Result = Invoke-AuthorizationCodeToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text -RedirectUri $RedirectURIText.Text
            $Result | Add-Member -MemberType NoteProperty -Name TokenType -Value "JWT"
            break 
        }
        "ClientCredentials" { 
            $Result = Invoke-ClientCredentialsToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text
            $Result | Add-Member -MemberType NoteProperty -Name TokenType -Value "JWT"
            break
        }
        "DeviceCode" { 
            $Result = Invoke-DeviceLoginToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -Scope $ScopeText.Text
            $Result | Add-Member -MemberType NoteProperty -Name TokenType -Value "JWT"
            break
        }
        "Password" { 
            $Result = Invoke-PasswordToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text
            $Result | Add-Member -MemberType NoteProperty -Name TokenType -Value "JWT"
            break
        }
        "SAML" { 
            if($ForceAuthCheckBox.IsChecked) { $ForceAuthn = 1 } else { $ForceAuthn = 0 }
            $NameIDPolicyFormat = $SAMLNameIDPolicyFormatComboBox.Text
            $Result = Invoke-SAMLToken -TenantId $TenantIdText.Text -RedirectUri $RedirectURIText.Text -ForceAuthn $ForceAuthn -NameIDPolicyFormat $NameIDPolicyFormat
            $Result | Add-Member -MemberType NoteProperty -Name TokenType -Value "SAML"

            [xml]$SAMLRequest = $Result.TokenRequest
            $Result.TokenRequest = ConvertFrom-Xml -Xml $SAMLRequest

            break
        }
        Default {}
    }

    # Request Token Tab
    $TokenRequestText.Text = $Result.TokenRequest | ConvertTo-Json

    # Token Info Tab
    Show-TokenResponse -TokenResult $Result
}

Function Invoke-SignOut
{
    if($SAMLTokenTab.Visibility = "Visible")
    {
        Invoke-SAMLSignOut -TenantId $TenantIdText.Text -RedirectUri $RedrectURIText.Text
    } else {
        Invoke-OAuthSignOut -TenantId $TenantIdText.Text -RedirectUri $RedrectURIText.Text
    }
}

<#
    .SYNOPSIS
    Show-PSMyClaims is the Azure AD token debugging tool.

    .DESCRIPTION
    The Show-PSMyClaims cmdlet uses WPF to generate GUI version of app to generate and debugging Azure AD OAuth token.

    .EXAMPLE
    Show-PSMyClaims

#>
Function Show-PSMyClaims
{
    [CmdletBinding()]
    Param
    (
        [String]$TenantId,
        [String]$ClientId,
        [String]$ClientSecret,
        [String]$Scope,
        [String]$RedirectUri,
        [Switch]$ForceAuthn,
        [String]$NameIDPolicyFormat
    )
    
    Add-Type -AssemblyName PresentationFramework
    [xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSMyClaims" Height="450" Width="800" MinHeight="350" MinWidth="600">
    <Grid  Background="Azure">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="41*"/>
            <ColumnDefinition Width="355*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="40"/>
            <RowDefinition Height="381*"/>
        </Grid.RowDefinitions>
        <Label Content="Grant type" Margin="10,10,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="72" />
        <ComboBox x:Name="GrantTypeComboBox" HorizontalAlignment="Left" Margin="5,10,0,0" VerticalAlignment="Top" Width="211" Height="20" SelectedIndex="0" Padding="5,1,0,0" Grid.Column="1">
            <ComboBoxItem Name="AuthorizationCode" Content="Authorization Code" Margin="0,0,0,0" />
            <ComboBoxItem Name="ClientCredentials" Content="Client Credentials" Margin="0,0,0,0" />
            <ComboBoxItem Name="DeviceCode" Content="Device Code" Margin="0,0,0,0" />
            <ComboBoxItem Name="Password" Content="Resource Owner Password Credentials" Margin="0,0,0,0" />
            <ComboBoxItem Name="SAML" Content="SAML" Margin="0,0,0,0" />
        </ComboBox>

        <Button x:Name="GetTokenButton"  Content="Get token" HorizontalAlignment="Left" Padding="0" Margin="221,10,0,10" FontFamily="Segoe Ui" Width="100" Grid.Row="0" Grid.Column="1"/>
        <Button x:Name="SignOutButton"  Content="Sign Out" HorizontalAlignment="Left" Padding="0" Margin="326,10,0,10" FontFamily="Segoe Ui" Width="100" Grid.Row="0" Grid.Column="1" Visibility="Hidden"/>

        <TabControl Name="TabControl" Margin="10"  Grid.Row="1" Grid.ColumnSpan="2">
            <TabItem Name="SettingsTab" Header="Settings" Margin="0,0,-4,-2">
                <Grid Background="#FFE5E5E5" Margin="0,-1,0,1">
                    <Label Content="Tenant Id" Margin="10,10,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="TenantIdText" TextWrapping="Wrap" Margin="130,10,10,0" Text="00000000-0000-0000-0000-000000000000" Height="20" VerticalAlignment="Top" />

                    <Label Content="Client Id" Margin="10,40,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="ClientIdText" TextWrapping="Wrap" Margin="130,40,10,0" FontFamily="Segoe Ui" Text="00000000-0000-0000-0000-000000000000" Height="20" VerticalAlignment="Top" />

                    <Label Content="Client Secret" Margin="10,70,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120"/>
                    <TextBox x:Name="ClientSecretText" TextWrapping="Wrap" Margin="130,70,10,0" FontFamily="Segoe Ui" Text="App_secret" Height="20" VerticalAlignment="Top" />

                    <Label Content="Redirect URI" Margin="10,100,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="RedirectURIText" TextWrapping="Wrap" Margin="130,100,10,0" FontFamily="Segoe Ui" Text="https://localhost/PSMyClaims" Height="20" VerticalAlignment="Top" />

                    <Label Content="Scope" Margin="10,130,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="ScopeText" TextWrapping="Wrap" Margin="130,130,10,0" FontFamily="Segoe Ui" Text="openid profile" Height="20" VerticalAlignment="Top" />
                </Grid>
            </TabItem>
            <TabItem Name="SAMLSettingsTab" Header="SAML Settings" Margin="0,0,-4,-2" Visibility="Collapsed">
                <Grid Background="#FFE5E5E5" Margin="0,-1,0,1">
                    <Label Content="Tenant Id" Margin="10,10,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="SAMLTenantIdText" TextWrapping="Wrap" Margin="130,10,10,0" Text="00000000-0000-0000-0000-000000000000" Height="20" VerticalAlignment="Top" />

                    <Label Content="Redirect URI" Margin="10,40,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120" />
                    <TextBox x:Name="SAMLRedirectURIText" TextWrapping="Wrap" Margin="130,40,10,0" FontFamily="Segoe Ui" Text="https://localhost/PSMyClaims" Height="20" VerticalAlignment="Top" />

                    <Label Content="SAML NameIDPolicy" Margin="10,70,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120"/>
                    <ComboBox x:Name="SAMLNameIDPolicyComboBox" IsEditable="True" HorizontalAlignment="Left" Margin="130,70,0,0" VerticalAlignment="Top" Height="20" SelectedIndex="0" Padding="5,1,0,0">
                        <ComboBoxItem Name="SAML20persistent" Content="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent" Margin="0,0,0,0" />
                        <ComboBoxItem Name="SAML20transient" Content="urn:oasis:names:tc:SAML:2.0:nameid-format:transient" Margin="0,0,0,0" />
                        <ComboBoxItem Name="SAML11emailAddress" Content="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" Margin="0,0,0,0" />
                        <ComboBoxItem Name="SAML11unspecified" Content="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified" Margin="0,0,0,0" />
                    </ComboBox>

                    <Label Content="SAML ForceAuth" Margin="10,100,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="120"/>
                    <CheckBox x:Name="SAMLForceAuthCheckBox" Content="ForceAuth" HorizontalAlignment="Left" Margin="130,100,0,0" VerticalAlignment="Top"/>
                </Grid>
            </TabItem>            
            <TabItem Name="TokenRequestTab" Header="Token Request" Visibility="Collapsed">
                <Grid Background="#FFE5E5E5">
                    <Label Content="Token Request" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" />
                    <TextBox x:Name="TokenRequestText" TextWrapping="Wrap" Margin="10,40,10,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" />
                </Grid>
            </TabItem>
            <TabItem Name="TokenInfoTab" Header="Token Info"  Visibility="Collapsed">
                <Grid Background="#FFE5E5E5">
                    <Label Content="Token Info" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" />
                    <TextBox x:Name="TokenInfoText" TextWrapping="Wrap" Margin="10,40,10,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" />
                </Grid>
            </TabItem>
            <TabItem Name="AccessTokenTab" Header="Access token" Visibility="Collapsed">
                <Grid Background="#FFE5E5E5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition/>
                        <ColumnDefinition/>
                    </Grid.ColumnDefinitions>
                    <Label Content="Encoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="0" />
                    <TextBox x:Name="EncAccessTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="0"/>
                    <GridSplitter Width="5" Margin="0,0,-5,0"/>
                    <Label Content="Decoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="1" />
                    <TextBox x:Name="DecAccessTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="1"/>
                </Grid>
            </TabItem>
            <TabItem Name="IdTokenTab" Header="Id token" Visibility="Collapsed">
                <Grid Background="#FFE5E5E5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition/>
                        <ColumnDefinition/>
                    </Grid.ColumnDefinitions>
                    <Label Content="Encoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="0" />
                    <TextBox x:Name="EncIdTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="0"/>
                    <GridSplitter Width="5" Margin="0,0,-5,0"/>
                    <Label Content="Decoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="1" />
                    <TextBox x:Name="DecIdTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="1"/>
                </Grid>
            </TabItem>
            <TabItem Name="SAMLTokenTab" Header="SAML token" Visibility="Collapsed">
                <Grid Background="#FFE5E5E5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition/>
                        <ColumnDefinition/>
                    </Grid.ColumnDefinitions>
                    <Label Content="Encoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="0" />
                    <TextBox x:Name="EncSAMLTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="0"/>
                    <GridSplitter Width="5" Margin="0,0,-5,0"/>
                    <Label Content="Decoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="1" />
                    <TextBox x:Name="DecSAMLTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="1"/>
                </Grid>
            </TabItem>            
        </TabControl>
    </Grid>
</Window>
"@

    $XmlNodeReader = (New-Object System.Xml.XmlNodeReader $Xaml)
    $Window = [Windows.Markup.XamlReader]::Load($XmlNodeReader)

    # Buttons
    $GetTokenButton = $Window.FindName("GetTokenButton")
    $SignOutButton = $Window.FindName("SignOutButton")
    $GrantTypeComboBox = $Window.FindName("GrantTypeComboBox")
    $TabControl = $Window.FindName("TabControl")

    # Settings Tab
    $SettingsTab = $Window.FindName("SettingsTab")
    $TenantIdText = $Window.FindName("TenantIdText")
    $ClientIdText = $Window.FindName("ClientIdText")
    $ClientSecretText = $Window.FindName("ClientSecretText")
    $RedirectURIText = $Window.FindName("RedirectURIText")
    $ScopeText = $Window.FindName("ScopeText")

    # SAML Settings Tab
    $SAMLSettingsTab = $Window.FindName("SAMLSettingsTab")
    $SAMLNameIDPolicyFormatComboBox = $Window.FindName("SAMLNameIDPolicyComboBox")
    $SAMLForceAuthCheckBox = $Window.FindName("SAMLForceAuthCheckBox")

    # Put value
    if($PSBoundParameters.ContainsKey("TenantId")) { $TenantIdText.Text = $TenantId }
    if($PSBoundParameters.ContainsKey("ClientId")) { $ClientIdText.Text = $ClientId }
    if($PSBoundParameters.ContainsKey("ClientSecret")) { $ClientSecretText.Text = $ClientSecret }
    if($PSBoundParameters.ContainsKey("Scope")) { $ScopeText.Text = $Scope }
    if($PSBoundParameters.ContainsKey("RedirectUri")) { $RedirectURIText.Text = $RedirectUri }
    if($PSBoundParameters.ContainsKey("ForceAuthn")) { $ForceAuthCheckBox.IsChecked = $true }
    #if($PSBoundParameters.ContainsKey("NameIDPolicyFormat")) { $NameIDPolicyFormat = $true }

    # Token Request Tab
    $TokenRequestTab = $Window.FindName("TokenRequestTab")
    $TokenRequestText = $Window.FindName("TokenRequestText")

    # Token Info Tab
    $TokenInfoTab = $Window.FindName("TokenInfoTab")
    $TokenInfoText = $Window.FindName("TokenInfoText")

    # Access Token Tab
    $AccessTokenTab = $Window.FindName("AccessTokenTab")
    $EncAccessTokenText = $Window.FindName("EncAccessTokenText")
    $DecAccessTokenText = $Window.FindName("DecAccessTokenText")

    # Id Token Tab
    $IdTokenTab = $Window.FindName("IdTokenTab")
    $EncIdTokenText = $Window.FindName("EncIdTokenText")
    $DecIdTokenText = $Window.FindName("DecIdTokenText")

    # SAML Token Tab
    $SAMLTokenTab = $Window.FindName("SAMLTokenTab")
    $EncSAMLTokenText = $Window.FindName("EncSAMLTokenText")
    $DecSAMLTokenText = $Window.FindName("DecSAMLTokenText")

    # Put Events
    $GrantTypeComboBoxSelectionChanged = $GrantTypeComboBox.add_selectionchanged
    $GrantTypeComboBoxSelectionChanged.Invoke({Show-Settings})

    $GetTokenButtonClick = $GetTokenButton.add_click
    $GetTokenButtonClick.Invoke({Get-Token})

    $SignOutButtonClick = $SignOutButton.add_click
    $SignOutButtonClick.Invoke({Invoke-SignOut})

    # Run
    [Void]$Window.ShowDialog()

    Return $Global:Token
}
