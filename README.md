# PSMyClaims

PSMyClaims is a PowerShell graphical tool for generate and debuging Azure AD OAuth and SAML tokens.

# Azure AD App registrations

OAuth Authentication:
- Web (Redirect URIs): https://localhost/PSMyClaims or your own unique URI
- Mobile and desktop applications (For devicelogin):   
  - https://login.microsoftonline.com/common/oauth2/nativeclient
  - ms-appx-web://microsoft.aad.brokerplugin/{ApplicationID}

SAML Authentication:
- SAML-based Sign-on
  - Identifier (Entity ID) - your own entity id
  - Reply URL
