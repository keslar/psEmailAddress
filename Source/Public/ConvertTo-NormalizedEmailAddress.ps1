<#
    .SYNOPSIS
        Returns a new EmailAddress object with the address portion normalized to lowercase.

    .DESCRIPTION
        Normalizes the address portion of each input EmailAddress object by trimming
        whitespace and converting it to lowercase. Returns a new EmailAddress object
        for each input; the original is not modified.

        Normalization affects only the address portion (local-part@domain). The display
        name, if present, is preserved exactly as-is.

        Two input modes are supported:

          -InputObject  — accepts one or more [EmailAddress] objects directly or
                          via the pipeline.

          -Address      — accepts one or more plain address or named mailbox strings.
                          Each string is first converted to an EmailAddress object,
                          then normalized. Invalid strings are reported as non-terminating
                          errors and skipped, consistent with ConvertTo-EmailAddress.

        This cmdlet is useful for ensuring consistency before comparison, deduplication,
        storage, or display — for example, normalizing a batch of addresses imported
        from a case-inconsistent source before inserting them into a database.

    .PARAMETER InputObject
        One or more EmailAddress objects to normalize.
        Accepts pipeline input by value.
        Used with parameter set: FromEmailAddress.

    .PARAMETER Address
        One or more plain address or named mailbox strings to normalize.
        Each string is converted to an EmailAddress object before normalization.
        Invalid strings produce a non-terminating error and are skipped.
        Accepts pipeline input by value.
        Used with parameter set: FromString.

    .INPUTS
        [EmailAddress]  Via -InputObject or pipeline (FromEmailAddress set).
        [string]        Via -Address or pipeline (FromString set).

    .OUTPUTS
        [EmailAddress] One normalized EmailAddress object per valid input.

    .EXAMPLE
        $email = New-EmailAddress -Address "CRK4@PITT.EDU"
        ConvertTo-NormalizedEmailAddress -InputObject $email

        Returns a new EmailAddress with address "crk4@pitt.edu".

    .EXAMPLE
        $email = New-EmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"
        ConvertTo-NormalizedEmailAddress -InputObject $email

        Returns a new EmailAddress with address "crk4@pitt.edu" and display
        name "Chris Keslar" (display name is preserved unchanged).

    .EXAMPLE
        ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"

        Converts and normalizes a plain address string in one step.
        Returns a new EmailAddress with address "crk4@pitt.edu".

    .EXAMPLE
        ConvertTo-NormalizedEmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"

        Converts and normalizes a named mailbox string in one step.

    .EXAMPLE
        $emails = "CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | New-EmailAddress
        $emails | ConvertTo-NormalizedEmailAddress

        Normalizes a pipeline of EmailAddress objects.

    .EXAMPLE
        "CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | ConvertTo-NormalizedEmailAddress -Address

        Normalizes a pipeline of address strings directly without a separate
        New-EmailAddress step.

    .EXAMPLE
        Import-Csv .\contacts.csv |
            Select-Object -ExpandProperty Email |
            ConvertTo-NormalizedEmailAddress -Address

        Normalizes all email addresses from a CSV column in a single pipeline.

    .NOTES
        Only the address portion is normalized. Display names are never modified.

        When using the -Address parameter set, invalid strings produce a
        non-terminating error and are skipped. Use -ErrorAction Stop to treat
        invalid strings as terminating errors.

        ConvertTo-NormalizedEmailAddress always returns a new [EmailAddress] object.
        The input object is never modified (the class is immutable).
    #>
function ConvertTo-NormalizedEmailAddress {
    [CmdletBinding(DefaultParameterSetName = 'FromEmailAddress')]
    [OutputType([EmailAddress])]
    param (
        # ---- FromEmailAddress parameter set ------------------------------------
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'FromEmailAddress',
            HelpMessage = 'The EmailAddress object to normalize.'
        )]
        [EmailAddress[]]$InputObject,

        # ---- FromString parameter set -----------------------------------------
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'FromString',
            HelpMessage = 'A plain address or named mailbox string to convert and normalize.'
        )]
        [AllowEmptyString()]
        [string[]]$Address
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'FromEmailAddress' {
                foreach ($item in $InputObject) {
                    try {
                        [EmailAddress]::NormalizeEmailAddressObject($item)
                    } catch {
                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                $_.Exception,
                                'NormalizeEmailAddressFailed',
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $item
                            )
                        )
                    }
                }
            }

            'FromString' {
                foreach ($item in $Address) {
                    # Construct first — this validates the string and parses any display name.
                    # Use non-terminating Write-Error on failure so the pipeline continues,
                    # consistent with ConvertTo-EmailAddress behaviour.
                    $emailObj = $null
                    try {
                        $emailObj = [EmailAddress]::new($item)
                    } catch {
                        Write-Error -Message "Cannot convert '$item' to EmailAddress: $($_.Exception.Message)" `
                            -Category InvalidArgument `
                            -TargetObject $item `
                            -ErrorId 'InvalidEmailAddressString'
                        continue
                    }

                    try {
                        [EmailAddress]::NormalizeEmailAddressObject($emailObj)
                    } catch {
                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                $_.Exception,
                                'NormalizeEmailAddressFailed',
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $item
                            )
                        )
                    }
                }
            }
        }
    }
}
