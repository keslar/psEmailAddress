function Get-CodeSigningCertificate {
    # example usage: Get-CodeSigningCertificate -ForceRefresh
    [CmdletBinding()]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )
    logDebug -Message "Get-CodeSigningCertificate :: Called. ForceRefresh = $ForceRefresh"
    $certThumbprint = GetVaultValue -SecretName "CodeSigningCertThumbprint" -ForceRefresh:$ForceRefresh
    if ( -not $certThumbprint ) {
        Write-Build Yellow "No code signing certificate thumbprint found in vault. Skipping code signing."
        return $null
    }
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My\$certThumbprint -ErrorAction SilentlyContinue
    if ( -not $cert ) {
        Write-Build Yellow "Code signing certificate with thumbprint $certThumbprint not found in CurrentUser\My store. Skipping code signing."
        return $null
    }
    return $cert
}

