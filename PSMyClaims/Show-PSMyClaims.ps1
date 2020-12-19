Function Show-TokenResponse
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)] 
        $TokenResponse
    )

    # Token Info Tab
    $TokenInfoText.Text = $TokenResponse | ConvertTo-Json 
   
    # Access Token Tab
    if($TokenResponse.access_token)
    {
        try {
            $EncAccessTokenText.Text = $TokenResponse.access_token
            $DecAccessTokenText.Text = Show-JWTtoken -Token $TokenResponse.access_token
            $AccessTokenTab.Visibility = "Visible"
        }
        catch {
            $AccessTokenTab.Visibility = "Hidden"
        }
    } else {
        $AccessTokenTab.Visibility = "Hidden"
    }

    # ID Token Tab
    if($TokenResponse.id_token)
    {
        try {
            $EncIdTokenText.Text = $TokenResponse.id_token
            $DecIdTokenText.Text = Show-JWTtoken -Token $TokenResponse.id_token
            $IdTokenTab.Visibility = "Visible"
        }
        catch {
            $IdTokenTab.Visibility = "Hidden"
        }
    } else {
        $IdTokenTab.Visibility = "Hidden"
    }

    Set-Variable -Name Token -Value $TokenResponse -Scope Global
}

Function Get-Token
{
    [CmdletBinding()]
    Param()

    $Result = $null
    switch ($GrantTypeComboBox.Items[$GrantTypeComboBox.SelectedIndex].Name) 
    {
        "AuthorizationCode" { $Result = Invoke-AuthorizationCodeToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text -RedirectUri $RedrectURIText.Text; break }
        "ClientCredentials" { $Result = Invoke-ClientCredentialsToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text; break; }
        "DeviceCode" { $Result = Invoke-DeviceLoginToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -Scope $ScopeText.Text; break; }
        "Password" { $Result = Invoke-PasswordToken -TenantId $TenantIdText.Text -ClientId $ClientIdText.Text -ClientSecret $ClientSecretText.Text -Scope $ScopeText.Text; break;  }
        Default {}
    }

    # Request Token Tab
    $TokenRequestText.Text = $Result.TokenRequest | ConvertTo-Json

    # Token Info Tab
    Show-TokenResponse -TokenResponse $Result.TokenResponse
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
    Param()
    
    Add-Type -AssemblyName PresentationFramework
    [xml]$xaml = @"
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
        </ComboBox>

        <Button x:Name="GetTokenButton"  Content="Get token" HorizontalAlignment="Left" Padding="0" Margin="221,10,0,10" FontFamily="Segoe Ui" Width="100" Grid.Row="0" Grid.Column="1"/>
        <Button x:Name="SignOutButton"  Content="Sign Out" HorizontalAlignment="Left" Padding="0" Margin="326,10,0,10" FontFamily="Segoe Ui" Width="100" Grid.Row="0" Grid.Column="1"/>

        <TabControl Margin="10"  Grid.Row="1" Grid.ColumnSpan="2">
            <TabItem Header="Settings" Margin="0,0,-4,-2">
                <Grid Background="#FFE5E5E5" Margin="0,-1,0,1">
                    <Label Content="Tenant Id" Margin="10,10,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="100" />
                    <TextBox x:Name="TenantIdText" TextWrapping="Wrap" Margin="115,10,10,0" Text="12345678-1234-1234-1234-123456789012" Height="20" VerticalAlignment="Top" />

                    <Label Content="Client Id" Margin="10,40,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="100" />
                    <TextBox x:Name="ClientIdText" TextWrapping="Wrap" Margin="115,40,10,0" FontFamily="Segoe Ui" Text="11111111-2222-3333-4444-555555555555" Height="20" VerticalAlignment="Top" />

                    <Label Content="Client Secret" Margin="10,70,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="100"/>
                    <TextBox x:Name="ClientSecretText" TextWrapping="Wrap" Margin="115,70,10,0" FontFamily="Segoe Ui" Text="<Application_secret..............>" Height="20" VerticalAlignment="Top" />

                    <Label Content="Redrect URI" Margin="10,100,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="100" />
                    <TextBox x:Name="RedrectURIText" TextWrapping="Wrap" Margin="115,100,10,0" FontFamily="Segoe Ui" Text="https://localhost/PSMyClaims" Height="20" VerticalAlignment="Top" />

                    <Label Content="Scope" Margin="10,130,0,0" FontFamily="Segoe Ui" Height="20" VerticalAlignment="Top" Padding="0" HorizontalAlignment="Left" Width="100" />
                    <TextBox x:Name="ScopeText" TextWrapping="Wrap" Margin="115,130,10,0" FontFamily="Segoe Ui" Text="openid profile" Height="20" VerticalAlignment="Top" />
               </Grid>
            </TabItem>
            <TabItem Header="Token Request">
                <Grid Background="#FFE5E5E5">
                    <Label Content="Token Request" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" />
                    <TextBox x:Name="TokenRequestText" TextWrapping="Wrap" Margin="10,40,10,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" />
                </Grid>
            </TabItem>
            <TabItem Header="Token Info">
                <Grid Background="#FFE5E5E5">
                    <Label Content="Token Info" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" />
                    <TextBox x:Name="TokenInfoText" TextWrapping="Wrap" Margin="10,40,10,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" />
                </Grid>
            </TabItem>
            <TabItem Name="AccessTokenTab" Header="Access token" Visibility="Hidden">
                <Grid Background="#FFE5E5E5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition/>
                        <ColumnDefinition/>
                    </Grid.ColumnDefinitions>
                    <Label Content="Encoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="0" />
                    <TextBox x:Name="EncAccessTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="0"/>
                    <Label Content="Decoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="1" />
                    <TextBox x:Name="DecAccessTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="1"/>
                </Grid>
            </TabItem>
            <TabItem Name="IdTokenTab" Header="Id token" Visibility="Hidden">
                <Grid Background="#FFE5E5E5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition/>
                        <ColumnDefinition/>
                    </Grid.ColumnDefinitions>
                    <Label Content="Encoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="0" />
                    <TextBox x:Name="EncIdTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="0"/>
                    <Label Content="Decoded" Margin="10,10,10,0" FontFamily="Segoe Ui" Height="25" VerticalAlignment="Top" Grid.Column="1" />
                    <TextBox x:Name="DecIdTokenText" TextWrapping="Wrap" Margin="10,40,4,10" FontFamily="Segoe Ui" VerticalScrollBarVisibility="Auto" Panel.ZIndex="-1" VerticalContentAlignment="Stretch" MinHeight="2" MinWidth="2" Grid.Column="1"/>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

    $XmlNodeReader = (New-Object System.Xml.XmlNodeReader $xaml)
    $Window = [Windows.Markup.XamlReader]::Load($XmlNodeReader)

    # Buttons
    $GetTokenButton = $Window.FindName("GetTokenButton")
    $SignOutButton = $Window.FindName("SignOutButton")
    $GrantTypeComboBox = $Window.FindName("GrantTypeComboBox")

    # Settings Tab
    $TenantIdText = $Window.FindName("TenantIdText")
    $ClientIdText = $Window.FindName("ClientIdText")
    $ClientSecretText = $Window.FindName("ClientSecretText")
    $RedrectURIText = $Window.FindName("RedrectURIText")
    $ScopeText = $Window.FindName("ScopeText")

    # Token Request Tab
    $TokenRequestText = $Window.FindName("TokenRequestText")

    # Token Info Tab
    $TokenInfoText = $Window.FindName("TokenInfoText")

    # Access Token Tab
    $AccessTokenTab = $Window.FindName("AccessTokenTab")
    $EncAccessTokenText = $Window.FindName("EncAccessTokenText")
    $DecAccessTokenText = $Window.FindName("DecAccessTokenText")

    # Id Token Tab
    $IdTokenTab = $Window.FindName("IdTokenTab")
    $EncIdTokenText = $Window.FindName("EncIdTokenText")
    $DecIdTokenText = $Window.FindName("DecIdTokenText")


    $GetTokenButtonClick = $GetTokenButton.add_click
    $GetTokenButtonClick.Invoke({Get-Token})

    $SignOutButtonClick = $SignOutButton.add_click
    $SignOutButtonClick.Invoke({Invoke-SignOut -TenantId $TenantIdText.Text -RedirectUri $RedrectURIText.Text})

    [Void]$Window.ShowDialog()

    Return $Global:Token
}
