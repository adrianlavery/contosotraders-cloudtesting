# Import the WebAdministration module
Import-Module WebAdministration

# Define variables
$siteName = "NewWebsite"
$sitePath = "C:\ReactApp"
$newPort = 80
$defaultSitePort = 85

# Add a new website to IIS
New-Website -Name $siteName -PhysicalPath $sitePath -Port $newPort -Force

# Start the new website immediately
Start-WebSite -Name $siteName

# Get the Default Web Site and change its port
$defaultSite = Get-Website "Default Web Site"
$defaultSite.Bindings.Remove("*:80:")
$defaultSite.Bindings.Add("*:$($defaultSitePort):")
$defaultSite | Set-Item
