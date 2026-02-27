<#
    .SYNOPSIS
        Internal helper function to resolve a parameter that accepts either a string or an EmailAddress.

    .DESCRIPTION
        This function is not intended to be used directly by end users. It is a helper for cmdlets that
        accept parameters which can be either raw strings or EmailAddress objects. It attempts to convert
        the input into an EmailAddress object, throwing a terminating error if the input is invalid.

    .PARAMETER InputValue
        The value to resolve, which may be either a string or an EmailAddress.

    .PARAMETER ParameterName
        The name of the parameter being resolved, used for error messages.

    .OUTPUTS
        [EmailAddress] The resolved EmailAddress object.

    .EXAMPLE
        Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
        Returns an EmailAddress object representing the input string.
        
#>
function Resolve-EmailAddressInput {
    [CmdletBinding()]
    [OutputType([EmailAddress])]
    param (
        [Parameter(Mandatory = $true)] $InputValue,
        [Parameter(Mandatory = $true)] [string]$ParameterName
    )

    if ($InputValue -is [EmailAddress]) {
        return $InputValue
    }

    try {
        return [EmailAddress]::new([string]$InputValue)
    } catch {
        throw "Cannot use '$InputValue' as -$ParameterName`: $($_.Exception.Message)"
    }
}
