<#
    .SYNOPSIS
        Tests whether one or more strings are valid email address formats.

    .DESCRIPTION
        Tests each input string against the RFC 5321/5322 validation rules
        implemented by the EmailAddress class and returns a result for each input.

        Two output modes are supported:

          Default  — returns a [bool] for each input: $true if the address is
                     valid, $false otherwise. Suitable for simple conditional
                     checks and pipeline filtering.

          Detailed — returns a [PSCustomObject] for each input containing the
                     original input string, a IsValid flag, and a Reason
                     explaining why the address is invalid (or empty if valid).
                     Suitable for batch validation reports.

        Accepts plain address strings ("user@example.com"), named mailbox strings
        ("Display Name <user@example.com>"), and [EmailAddress] objects.
        Accepts pipeline input.

        This cmdlet never throws. Invalid or empty input always returns $false
        (or a Detailed result with IsValid = $false) rather than an error.

        Validation rules applied by the EmailAddress class:
        - Must contain exactly one @ symbol
        - Local part: 1–64 characters; letters, digits, and special characters
          per RFC 5321 practical subset
        - Local part: dots not allowed at start, end, or consecutively
        - Domain: 1–255 characters; labels separated by dots
        - Domain: each label 1–63 characters; letters, digits, and hyphens only
        - Domain: labels may not start or end with a hyphen
        - Domain: must contain at least one dot (TLD required)
        - Domain: TLD must be at least 2 characters
        - Total length must not exceed 320 characters

    .PARAMETER InputObject
        One or more plain address strings, named mailbox strings, or EmailAddress
        objects to test.
        Accepts pipeline input by value.

    .PARAMETER Detailed
        When specified, returns a [PSCustomObject] for each input instead of a
        [bool]. The object has three properties:

          Input   [string]  — the original input value
          IsValid [bool]    — $true if the address passed validation
          Reason  [string]  — a description of why the address is invalid,
                              or an empty string if it is valid

    .INPUTS
        [string]  A plain address or named mailbox string.
        [EmailAddress]  An existing EmailAddress object.

    .OUTPUTS
        [bool]          One value per input when -Detailed is not specified.
        [PSCustomObject] One object per input when -Detailed is specified.

    .EXAMPLE
        Test-EmailAddress -InputObject "crk4@pitt.edu"

        Returns $true.

    .EXAMPLE
        Test-EmailAddress -InputObject "notanemail"

        Returns $false.

    .EXAMPLE
        Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed

        Returns:
          Input   : crk4@pitt.edu
          IsValid : True
          Reason  :

    .EXAMPLE
        Test-EmailAddress -InputObject "notanemail" -Detailed

        Returns:
          Input   : notanemail
          IsValid : False
          Reason  : Address must contain exactly one '@' symbol.

    .EXAMPLE
        "crk4@pitt.edu", "bad", "jdoe@example.com" | Test-EmailAddress

        Returns: $true, $false, $true

    .EXAMPLE
        "crk4@pitt.edu", "bad", "jdoe@example.com" | Test-EmailAddress -Detailed

        Returns one PSCustomObject per input, each with Input, IsValid, and Reason.

    .EXAMPLE
        Import-Csv .\contacts.csv |
            Select-Object -ExpandProperty Email |
            Test-EmailAddress -Detailed |
            Where-Object { -not $_.IsValid }

        Reports all invalid addresses from a CSV file.

    .EXAMPLE
        $email = New-EmailAddress -Address "crk4@pitt.edu"
        Test-EmailAddress -InputObject $email

        Tests an existing EmailAddress object. Returns $true.

    .NOTES
        Test-EmailAddress never throws regardless of input. Empty strings, nulls,
        and malformed addresses all return $false or a Detailed result with
        IsValid = $false.

        To create an EmailAddress object from a validated string, pipe the result
        of Test-EmailAddress -Detailed through Where-Object { $_.IsValid } and
        then pass the Input property to New-EmailAddress.
    #>
function Test-EmailAddress {
    [CmdletBinding()]
    [OutputType([bool])]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'A plain address string, named mailbox string, or EmailAddress object to test.'
        )]
        [AllowNull()]
        [AllowEmptyString()]
        $InputObject,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Return a detailed result object instead of a plain bool.'
        )]
        [switch]$Detailed
    )

    process {
        # foreach ($item in $null) iterates zero times, producing no output.
        # $null must be handled explicitly before the loop so it emits $false
        # (or a Detailed result) rather than silently returning nothing.
        if ($null -eq $InputObject) {
            if ($Detailed) {
                return [PSCustomObject]@{
                    Input   = ''
                    IsValid = $false
                    Reason  = 'Address must not be null or empty.'
                }
            } else {
                return $false
            }
        }

        foreach ($item in $InputObject) {

            # Resolve the address string to test regardless of input type
            if ($item -is [EmailAddress]) {
                $addressToTest = $item.GetAddress()
                $inputDisplay = $item.ToString()
            } else {
                # For plain or named mailbox strings, extract the address portion
                # using the same parsing logic as the EmailAddress constructor.
                $addressToTest = [string]$item
                $inputDisplay = [string]$item

                # If the input looks like a named mailbox, extract just the address part
                if ($addressToTest -match '^.*<(.+)>$') {
                    $addressToTest = $matches[1].Trim()
                } else {
                    $addressToTest = $addressToTest.Trim()
                }
            }

            $failureReason = [EmailAddress]::GetValidationFailureReason($addressToTest)
            $isValid = [string]::IsNullOrEmpty($failureReason)

            if ($Detailed) {
                [PSCustomObject]@{
                    Input   = $inputDisplay
                    IsValid = $isValid
                    Reason  = if ($isValid) { '' } else { $failureReason }
                }
            } else {
                $isValid
            }
        }
    }
}
