<#
    .SYNOPSIS
        Formats an EmailAddress object as a string in one of three standard formats.

    .DESCRIPTION
        Returns a formatted string representation of one or more EmailAddress objects.
        Three formats are available via the -Format parameter:

          Address  — plain address only: "crk4@pitt.edu"
                     Equivalent to EmailAddress.ToString().
                     This is the default.

          Friendly — display name and address if a display name is present, otherwise
                     plain address: "Chris Keslar <crk4@pitt.edu>" or "crk4@pitt.edu"
                     Equivalent to EmailAddress.GetFriendlyName().

          RFC5322  — RFC 5322-compliant format. The display name is quoted if it
                     contains special characters or whitespace; embedded double quotes
                     in the display name are escaped:
                       "Chris Keslar" <crk4@pitt.edu>      (space requires quoting)
                       ChrisKeslar <crk4@pitt.edu>          (no quoting needed)
                       "Keslar, Chris" <crk4@pitt.edu>      (comma requires quoting)
                     Falls back to plain address when no display name is present.
                     Equivalent to EmailAddress.ToRFC5322String().

        Accepts pipeline input. Returns one [string] per input object.

    .PARAMETER InputObject
        One or more EmailAddress objects to format.
        Accepts pipeline input by value.

    .PARAMETER Format
        The output format. Must be one of: Address, Friendly, RFC5322.
        Defaults to Address.

    .INPUTS
        [EmailAddress]

    .OUTPUTS
        [string] One formatted string per input object.

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Format-EmailAddress -InputObject $email

        Returns: crk4@pitt.edu

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Format-EmailAddress -InputObject $email -Format Friendly

        Returns: Chris Keslar <crk4@pitt.edu>

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
        Format-EmailAddress -InputObject $email -Format RFC5322

        Returns: "Chris Keslar" <crk4@pitt.edu>

    .EXAMPLE
        $email = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"
        Format-EmailAddress -InputObject $email -Format RFC5322

        Returns: "Keslar, Chris" <crk4@pitt.edu>

    .EXAMPLE
        $emails = "crk4@pitt.edu", "Chris Keslar <jdoe@example.com>" | New-EmailAddress
        $emails | Format-EmailAddress -Format Friendly

        Formats a pipeline of EmailAddress objects. Returns one string per object.

    .EXAMPLE
        Import-Csv .\contacts.csv |
            Select-Object -ExpandProperty Email |
            New-EmailAddress |
            Format-EmailAddress -Format RFC5322

        Converts a CSV column of addresses to RFC 5322 format strings.

    .NOTES
        Format-EmailAddress always requires an [EmailAddress] object as input.
        To format a raw string, first convert it with New-EmailAddress or
        ConvertTo-EmailAddress.

        The three formats differ only when a display name is present:
          - Address  always strips the display name.
          - Friendly includes the display name as-is.
          - RFC5322  includes the display name, quoting it if required by the standard.

        When no display name is set on the EmailAddress object, all three formats
        produce identical output — the plain address string.
    #>
function Format-EmailAddress {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'The EmailAddress object to format.'
        )]
        [EmailAddress]$InputObject,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = 'The output format: Address, Friendly, or RFC5322.'
        )]
        [ValidateSet('Address', 'Friendly', 'RFC5322')]
        [string]$Format = 'Address'
    )

    process {
        switch ($Format) {
            'Address' { $InputObject.GetAddress() }
            'Friendly' { $InputObject.GetFriendlyName() }
            'RFC5322' { $InputObject.ToRFC5322String() }
        }
    }
}
