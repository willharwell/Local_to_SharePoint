# Local_to_SharePoint

This PowerShell script replicates a local directory structure into a SharePoint documents folder.

In our Microsoft 365 Tenant, devices and users must be enrolled into the tenant and compliant with set policies before they are allowed to access company resources, such as SharePoint. We also use a Samba server that stores data from a variety of equipment not connected to our network and I needed the ability to easily control who has access to this information, without having to go through the burden of connecting the Samba server both to our tenant, and our local network. Enter Microsoft Graph. Graph gives me the ability to easily and securely connect to our tenant and perform only the functions I have given the app permission to perform.

Only about 2% of this script actually belongs to me, the rest of it was borrowed from other sources around the web

https://tech.nicolonsky.ch/calling-the-microsoft-graph-api/
https://powershell.works/2022/01/22/upload-files-2-sharepoint-online-using-graph-api/
https://stackoverflow.com/questions/71424869/using-powershell-to-call-the-graph-api-to-upload-folders-and-files

The graph app will need application permissions Sites.Read.All, Sites.ReadWrite.All

To Do:
1. Integrate a refresh token. Large amounts of data may take more than an hour to upload, and the token will expire.
2. Sync the local drive and SharePoint site. Currently, the script uploads the directory structure only, it neither removes or renames anything.
3. Find a better method of finding only new and changed files and folders to help eliminate errors when trying and failing to overwrite existing folders.
