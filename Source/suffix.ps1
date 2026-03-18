<#
.NOTES
    Version:        {{MODULE_VERSION}}
    Author(s):
#>
# Explicitly restrict exported functions to the public surface.
# Resolve-EmailAddressInput is a private helper and must not be accessible
# outside this module. Export-ModuleMember enforces this even when the .psm1
# is loaded directly rather than through the manifest.
Export-ModuleMember -Function @(
    'Compare-EmailAddress',
    'ConvertTo-EmailAddress',
    'ConvertTo-NormalizedEmailAddress',
    'Format-EmailAddress',
    'Get-EmailAddress',
    'New-EmailAddress',
    'Set-EmailAddress',
    'Test-EmailAddress'
)