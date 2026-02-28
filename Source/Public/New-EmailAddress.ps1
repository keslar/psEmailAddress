<#
    .SYNOPSIS
        Creates a new EmailAddress object.

    .DESCRIPTION
        Creates an EmailAddress object from either a full address string or from
        individual components (local part, domain, and optional display name).

        Two parameter sets are supported:

          FromString    — accepts a plain address ("user@example.com") or a named
                          mailbox string ("Display Name <user@example.com>").
                          Accepts pipeline input.

          FromComponents — accepts the local part, domain, and an optional display
                           name as separate parameters, and assembles the address
                           internally.

        Validation is performed by the EmailAddress class at construction time
        against a practical subset of RFC 5321/5322 rules. Invalid input results
        in a terminating error.

    .PARAMETER Address
        A plain email address string ("user@example.com") or a named mailbox string
        in RFC 5322 format ("Display Name <user@example.com>").

        Accepts pipeline input by value.
        Used with parameter set: FromString.

    .PARAMETER LocalPart
        The portion of the email address before the @ symbol (e.g. "crk4").
        Used with parameter set: FromComponents.

    .PARAMETER Domain
        The domain portion of the email address (e.g. "pitt.edu").
        Used with parameter set: FromComponents.

    .PARAMETER DisplayName
        The optional human-readable name associated with the address
        (e.g. "Chris Keslar"). When supplied the output object will format as
        "DisplayName <LocalPart@Domain>".
        Used with parameter set: FromComponents.

    .INPUTS
        [string] A plain address or named mailbox string may be piped to -Address.

    .OUTPUTS
        [EmailAddress]

    .EXAMPLE
        New-EmailAddress -Address "crk4@pitt.edu"

        Creates an EmailAddress from a plain address string with no display name.

    .EXAMPLE
        New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

        Creates an EmailAddress from a named mailbox string.

    .EXAMPLE
        New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"

        Creates an EmailAddress from component parts with no display name.

    .EXAMPLE
        New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"

        Creates an EmailAddress from component parts with a display name.

    .EXAMPLE
        "crk4@pitt.edu", "jdoe@example.com" | New-EmailAddress

        Creates EmailAddress objects from a pipeline of address strings.

    .EXAMPLE
        Import-Csv .\contacts.csv | Select-Object -ExpandProperty Email | New-EmailAddress

        Creates EmailAddress objects from a column of email addresses in a CSV file.

    .NOTES
        This cmdlet wraps the EmailAddress class constructor and static factory
        methods. Invalid input produces a terminating error; use a try/catch block
        or -ErrorAction if you need to handle failures without stopping the pipeline.
#>
function New-EmailAddress {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'New-EmailAddress is a pure factory that constructs and returns a value object. It does not modify system state.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'FromString')]
    [OutputType([EmailAddress])]
    param (
        # ---- FromString parameter set ----------------------------------------
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'FromString',
            HelpMessage = 'A plain email address or named mailbox string.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Address,

        # ---- FromComponents parameter set ------------------------------------
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'FromComponents',
            HelpMessage = 'The local part of the email address (before the @).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$LocalPart,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'FromComponents',
            HelpMessage = 'The domain portion of the email address (after the @).'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,

        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = 'FromComponents',
            HelpMessage = 'The optional display name associated with the address.'
        )]
        [string]$DisplayName = ''
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'FromString' {
                try {
                    [EmailAddress]::new($Address)
                } catch {
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            $_.Exception,
                            'InvalidEmailAddressString',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Address
                        )
                    )
                }
            }

            'FromComponents' {
                try {
                    [EmailAddress]::GetEmailAddressFromComponents($LocalPart, $Domain, $DisplayName)
                } catch {
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            $_.Exception,
                            'InvalidEmailAddressComponents',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            "$LocalPart@$Domain"
                        )
                    )
                }
            }
        }
    }
}