<#
    .SYNOPSIS
        Returns a new EmailAddress object with one component replaced.

    .DESCRIPTION
        Because EmailAddress objects are immutable, Set-EmailAddress does not modify
        the input object. Instead it returns a new EmailAddress object with the
        specified component replaced and all other components preserved from the
        original.

        Exactly one of the following mutually exclusive parameters must be supplied
        to specify which component to replace:

          -Address      — replaces the entire address portion (local-part@domain).
                          The display name from the original is preserved.

          -DisplayName  — replaces the display name only.
                          The address portion from the original is preserved.
                          Supplying an empty string removes the display name.

          -LocalPart    — replaces the local part of the address (before the @).
                          The domain and display name from the original are preserved.

          -Domain       — replaces the domain portion of the address (after the @).
                          The local part and display name from the original are preserved.

        Accepts pipeline input on -InputObject. Returns one new [EmailAddress] per
        input. Invalid replacements produce a terminating error.

    .PARAMETER InputObject
        The EmailAddress object to copy with a modified component.
        Accepts pipeline input by value.

    .PARAMETER Address
        The new plain address string (local-part@domain) to use.
        The display name from the original object is preserved.
        Mutually exclusive with -DisplayName, -LocalPart, and -Domain.

    .PARAMETER DisplayName
        The new display name to use. Supply an empty string to remove the display name.
        The address portion from the original object is preserved.
        Mutually exclusive with -Address, -LocalPart, and -Domain.

    .PARAMETER LocalPart
        The new local part (the portion before the @) to use.
        The domain and display name from the original object are preserved.
        Mutually exclusive with -Address, -DisplayName, and -Domain.

    .PARAMETER Domain
        The new domain portion (the portion after the @) to use.
        The local part and display name from the original object are preserved.
        Mutually exclusive with -Address, -DisplayName, and -LocalPart.

    .INPUTS
        [EmailAddress]

    .OUTPUTS
        [EmailAddress] A new EmailAddress object with the specified component replaced.

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Set-EmailAddress -InputObject $email -Address "crk4@example.com"

        Returns a new EmailAddress: Chris Keslar <crk4@example.com>
        The display name "Chris Keslar" is preserved.

    .EXAMPLE
        $email = New-EmailAddress -Address "crk4@pitt.edu"
        Set-EmailAddress -InputObject $email -DisplayName "Chris Keslar"

        Returns a new EmailAddress: Chris Keslar <crk4@pitt.edu>

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Set-EmailAddress -InputObject $email -DisplayName ""

        Returns a new EmailAddress: crk4@pitt.edu
        The display name is removed.

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Set-EmailAddress -InputObject $email -LocalPart "ckeslar"

        Returns a new EmailAddress: Chris Keslar <ckeslar@pitt.edu>
        The domain "pitt.edu" and display name are preserved.

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Set-EmailAddress -InputObject $email -Domain "example.com"

        Returns a new EmailAddress: Chris Keslar <crk4@example.com>
        The local part "crk4" and display name are preserved.

    .EXAMPLE
        "crk4@pitt.edu", "jdoe@pitt.edu" |
            New-EmailAddress |
            Set-EmailAddress -Domain "example.com"

        Returns two new EmailAddress objects with the domain replaced:
        crk4@example.com, jdoe@example.com

    .NOTES
        Set-EmailAddress never modifies the input object. It always returns a new
        [EmailAddress] instance. The original object is unchanged.

        Exactly one replacement parameter must be supplied. Supplying none or more
        than one produces a parameter binding error.
#>
function Set-EmailAddress {
    [CmdletBinding()]
    [OutputType([EmailAddress])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'The EmailAddress object to copy with a modified component.'
        )]
        [EmailAddress]$InputObject,

        # ---- Mutually exclusive replacement parameters -----------------------
        # Each belongs to its own parameter set so PowerShell enforces that
        # exactly one is supplied.

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'SetAddress',
            HelpMessage = 'The new plain address string (local-part@domain).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Address,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'SetDisplayName',
            HelpMessage = 'The new display name. Supply an empty string to remove it.'
        )]
        [AllowEmptyString()]
        [string]$DisplayName,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'SetLocalPart',
            HelpMessage = 'The new local part of the address (before the @).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPart,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'SetDomain',
            HelpMessage = 'The new domain portion of the address (after the @).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Domain
    )

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {

                'SetAddress' {
                    # Replace the address, preserve the display name
                    $currentDisplayName = $InputObject.GetDisplayName()
                    if ([string]::IsNullOrEmpty($currentDisplayName)) {
                        [EmailAddress]::new($Address)
                    } else {
                        [EmailAddress]::new("$currentDisplayName <$Address>")
                    }
                }

                'SetDisplayName' {
                    # Replace the display name, preserve the address
                    $currentAddress = $InputObject.GetAddress()
                    if ([string]::IsNullOrEmpty($DisplayName)) {
                        [EmailAddress]::new($currentAddress)
                    } else {
                        [EmailAddress]::new("$DisplayName <$currentAddress>")
                    }
                }

                'SetLocalPart' {
                    # Replace the local part, preserve the domain and display name
                    $currentDomain = $InputObject.GetDomain()
                    $currentDisplayName = $InputObject.GetDisplayName()
                    $newAddress = "$LocalPart@$currentDomain"
                    if ([string]::IsNullOrEmpty($currentDisplayName)) {
                        [EmailAddress]::new($newAddress)
                    } else {
                        [EmailAddress]::new("$currentDisplayName <$newAddress>")
                    }
                }

                'SetDomain' {
                    # Replace the domain, preserve the local part and display name
                    $currentLocalPart = $InputObject.GetLocalPart()
                    $currentDisplayName = $InputObject.GetDisplayName()
                    $newAddress = "$currentLocalPart@$Domain"
                    if ([string]::IsNullOrEmpty($currentDisplayName)) {
                        [EmailAddress]::new($newAddress)
                    } else {
                        [EmailAddress]::new("$currentDisplayName <$newAddress>")
                    }
                }
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception,
                    'SetEmailAddressFailed',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $InputObject
                )
            )
        }
    }
}
