<#
    .SYNOPSIS
        Compares two email addresses for equality.

    .DESCRIPTION
        Compares a reference email address against a difference email address and
        returns a [bool] indicating whether they are equal. Two comparison modes
        are available:

          Default               — compares both the address portion and the display
                                  name, case-insensitively. Equivalent to
                                  EmailAddress.Equals().

          -IgnoreDisplayName    — compares only the address portion, ignoring any
                                  difference in display name. Useful when the same
                                  recipient may appear with different display names.
                                  Equivalent to EmailAddress.EqualsIgnoreDisplayName()
                                  and [EmailAddress]::AreEqualIgnoringDisplayName().

        Both -ReferenceAddress and -DifferenceAddress accept either a plain address
        string ("user@example.com"), a named mailbox string
        ("Display Name <user@example.com>"), or an [EmailAddress] object. Strings
        are converted internally; invalid strings produce a terminating error.

        -ReferenceAddress accepts pipeline input, allowing a single reference
        address to be compared against a fixed -DifferenceAddress across multiple
        pipeline inputs.

        A -Detailed switch returns a [PSCustomObject] instead of a plain [bool],
        with properties showing both inputs and the comparison result.

    .PARAMETER ReferenceAddress
        The reference email address to compare from.
        Accepts a plain address string, named mailbox string, or EmailAddress object.
        Accepts pipeline input by value.

    .PARAMETER DifferenceAddress
        The email address to compare against.
        Accepts a plain address string, named mailbox string, or EmailAddress object.

    .PARAMETER IgnoreDisplayName
        When specified, only the address portion is compared. Display name differences
        are ignored. "Chris Keslar <crk4@pitt.edu>" and "C. Keslar <crk4@pitt.edu>"
        are considered equal under this switch.

    .PARAMETER Detailed
        When specified, returns a [PSCustomObject] instead of a plain [bool].
        The object has the following properties:

          ReferenceAddress   [string]  — the formatted reference address
          DifferenceAddress  [string]  — the formatted difference address
          AreEqual           [bool]    — $true if the addresses are equal
          IgnoredDisplayName [bool]    — whether -IgnoreDisplayName was used

    .INPUTS
        [string]        A plain address or named mailbox string piped to -ReferenceAddress.
        [EmailAddress]  An EmailAddress object piped to -ReferenceAddress.

    .OUTPUTS
        [bool]           When -Detailed is not specified.
        [PSCustomObject] When -Detailed is specified.

    .EXAMPLE
        Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "crk4@pitt.edu"

        Returns $true. Both plain addresses are identical.

    .EXAMPLE
        Compare-EmailAddress `
            -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
            -DifferenceAddress "C. Keslar <crk4@pitt.edu>"

        Returns $false. Addresses are equal but display names differ.

    .EXAMPLE
        Compare-EmailAddress `
            -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
            -DifferenceAddress "C. Keslar <crk4@pitt.edu>" `
            -IgnoreDisplayName

        Returns $true. Display name difference is ignored.

    .EXAMPLE
        Compare-EmailAddress `
            -ReferenceAddress  "CRK4@PITT.EDU" `
            -DifferenceAddress "crk4@pitt.edu"

        Returns $true. Comparison is case-insensitive.

    .EXAMPLE
        Compare-EmailAddress `
            -ReferenceAddress  "crk4@pitt.edu" `
            -DifferenceAddress "crk4@pitt.edu" `
            -Detailed

        Returns:
          ReferenceAddress   : crk4@pitt.edu
          DifferenceAddress  : crk4@pitt.edu
          AreEqual           : True
          IgnoredDisplayName : False

    .EXAMPLE
        $incoming = "crk4@pitt.edu", "other@pitt.edu", "crk4@pitt.edu" | New-EmailAddress
        $incoming | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"

        Compares each piped address against "crk4@pitt.edu".
        Returns: $true, $false, $true

    .NOTES
        Comparison is always case-insensitive for the address portion, regardless
        of whether -IgnoreDisplayName is used.

        Both parameters accept strings as a convenience. Strings are converted to
        EmailAddress objects internally. Invalid strings produce a terminating error;
        use New-EmailAddress or Test-EmailAddress beforehand to validate input if
        needed.
#>
function Compare-EmailAddress {
    [CmdletBinding()]
    [OutputType([bool])]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'The reference email address to compare from.'
        )]
        $ReferenceAddress,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'The email address to compare against.'
        )]
        $DifferenceAddress,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Compare only the address portion, ignoring display name differences.'
        )]
        [switch]$IgnoreDisplayName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Return a detailed result object instead of a plain bool.'
        )]
        [switch]$Detailed
    )

    begin {
        # Resolve -DifferenceAddress once in begin — it is a fixed value for all
        # pipeline inputs, so there is no need to re-resolve it on every iteration.
        $diffEmail = Resolve-EmailAddressInput -InputValue $DifferenceAddress -ParameterName 'DifferenceAddress'
    }

    process {
        $refEmail = Resolve-EmailAddressInput -InputValue $ReferenceAddress -ParameterName 'ReferenceAddress'

        $areEqual = if ($IgnoreDisplayName) {
            $refEmail.EqualsIgnoreDisplayName($diffEmail)
        } else {
            $refEmail.Equals($diffEmail)
        }

        if ($Detailed) {
            [PSCustomObject]@{
                ReferenceAddress   = $refEmail.GetFriendlyName()
                DifferenceAddress  = $diffEmail.GetFriendlyName()
                AreEqual           = $areEqual
                IgnoredDisplayName = $IgnoreDisplayName.IsPresent
            }
        } else {
            $areEqual
        }
    }
}