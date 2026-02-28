<#
    .SYNOPSIS
        Retrieves a specific property value from an EmailAddress object.

    .DESCRIPTION
        Extracts and returns a single named property from one or more EmailAddress
        objects as a string. This cmdlet provides a consistent, discoverable way to
        read any property of an EmailAddress without calling instance methods directly.

        The -Property parameter controls which value is returned:

          Address     — the plain address string ("crk4@pitt.edu").
                        Equivalent to EmailAddress.GetAddress().

          DisplayName — the display name, or empty string if none is set.
                        Equivalent to EmailAddress.GetDisplayName().

          LocalPart   — the portion of the address before the @ symbol ("crk4").
                        Equivalent to EmailAddress.GetLocalPart().

          Domain      — the domain portion of the address ("pitt.edu").
                        Equivalent to EmailAddress.GetDomain().

          Friendly    — the named mailbox string if a display name is present,
                        otherwise the plain address. ("Chris Keslar <crk4@pitt.edu>")
                        Equivalent to EmailAddress.GetFriendlyName().

          RFC5322     — RFC 5322-compliant format with quoting applied to the
                        display name where required.
                        Equivalent to EmailAddress.ToRFC5322String().

        Accepts pipeline input. Returns one [string] per input object.

    .PARAMETER InputObject
        One or more EmailAddress objects to read from.
        Accepts pipeline input by value.

    .PARAMETER Property
        The property to retrieve. Must be one of:
        Address, DisplayName, LocalPart, Domain, Friendly, RFC5322.
        Defaults to Address.

    .INPUTS
        [EmailAddress]

    .OUTPUTS
        [string] One value per input object.

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Get-EmailAddress -InputObject $email -Property Address

        Returns: crk4@pitt.edu

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Get-EmailAddress -InputObject $email -Property DisplayName

        Returns: Chris Keslar

    .EXAMPLE
        $email = New-EmailAddress -Address "crk4@pitt.edu"
        Get-EmailAddress -InputObject $email -Property LocalPart

        Returns: crk4

    .EXAMPLE
        $email = New-EmailAddress -Address "crk4@pitt.edu"
        Get-EmailAddress -InputObject $email -Property Domain

        Returns: pitt.edu

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Get-EmailAddress -InputObject $email -Property Friendly

        Returns: Chris Keslar <crk4@pitt.edu>

    .EXAMPLE
        $email = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"
        Get-EmailAddress -InputObject $email -Property RFC5322

        Returns: "Keslar, Chris" <crk4@pitt.edu>

    .EXAMPLE
        "crk4@pitt.edu", "jdoe@example.com" |
            New-EmailAddress |
            Get-EmailAddress -Property Domain

        Returns the domain of each address in the pipeline: pitt.edu, example.com

    .NOTES
        Get-EmailAddress reads from an [EmailAddress] object. To read from a raw
        string, first convert it with New-EmailAddress or ConvertTo-EmailAddress.

        The Address and Friendly properties correspond to the two format modes of
        Format-EmailAddress. Use Format-EmailAddress when formatting is the primary
        concern; use Get-EmailAddress when extracting a specific structural component
        such as LocalPart or Domain.
#>
function Get-EmailAddress {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'The EmailAddress object to read from.'
        )]
        [EmailAddress]$InputObject,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = 'The property to retrieve: Address, DisplayName, LocalPart, Domain, Friendly, or RFC5322.'
        )]
        [ValidateSet('Address', 'DisplayName', 'LocalPart', 'Domain', 'Friendly', 'RFC5322')]
        [string]$Property = 'Address'
    )

    process {
        switch ($Property) {
            'Address' { $InputObject.GetAddress() }
            'DisplayName' { $InputObject.GetDisplayName() }
            'LocalPart' { $InputObject.GetLocalPart() }
            'Domain' { $InputObject.GetDomain() }
            'Friendly' { $InputObject.GetFriendlyName() }
            'RFC5322' { $InputObject.ToRFC5322String() }
        }
    }
}
