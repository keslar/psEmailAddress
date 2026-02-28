---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# Test-EmailAddress

## SYNOPSIS
Tests whether one or more strings are valid email address formats.

## SYNTAX

```
Test-EmailAddress [-InputObject] <Object> [-Detailed] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Tests each input string against the RFC 5321/5322 validation rules
implemented by the EmailAddress class and returns a result for each input.

Two output modes are supported:

  Default  - returns a \[bool\] for each input: $true if the address is
             valid, $false otherwise.
Suitable for simple conditional
             checks and pipeline filtering.

  Detailed - returns a \[PSCustomObject\] for each input containing the
             original input string, a IsValid flag, and a Reason
             explaining why the address is invalid (or empty if valid).
             Suitable for batch validation reports.

Accepts plain address strings ("user@example.com"), named mailbox strings
("Display Name \<user@example.com\>"), and \[EmailAddress\] objects.
Accepts pipeline input.

This cmdlet never throws.
Invalid or empty input always returns $false
(or a Detailed result with IsValid = $false) rather than an error.

Validation rules applied by the EmailAddress class:
- Must contain exactly one @ symbol
- Local part: 1-64 characters; letters, digits, and special characters
  per RFC 5321 practical subset
- Local part: dots not allowed at start, end, or consecutively
- Domain: 1-255 characters; labels separated by dots
- Domain: each label 1-63 characters; letters, digits, and hyphens only
- Domain: labels may not start or end with a hyphen
- Domain: must contain at least one dot (TLD required)
- Domain: TLD must be at least 2 characters
- Total length must not exceed 320 characters

## EXAMPLES

### EXAMPLE 1
```
Test-EmailAddress -InputObject "crk4@pitt.edu"
```

Returns $true.

### EXAMPLE 2
```
Test-EmailAddress -InputObject "notanemail"
```

Returns $false.

### EXAMPLE 3
```
Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
```

Returns:
  Input   : crk4@pitt.edu
  IsValid : True
  Reason  :

### EXAMPLE 4
```
Test-EmailAddress -InputObject "notanemail" -Detailed
```

Returns:
  Input   : notanemail
  IsValid : False
  Reason  : Address does not match a valid email format.

### EXAMPLE 5
```
"crk4@pitt.edu", "bad", "jdoe@example.com" | Test-EmailAddress
```

Returns: $true, $false, $true

### EXAMPLE 6
```
"crk4@pitt.edu", "bad", "jdoe@example.com" | Test-EmailAddress -Detailed
```

Returns one PSCustomObject per input, each with Input, IsValid, and Reason.

### EXAMPLE 7
```
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    Test-EmailAddress -Detailed |
    Where-Object { -not $_.IsValid }
```

Reports all invalid addresses from a CSV file.

### EXAMPLE 8
```
$email = New-EmailAddress -Address "crk4@pitt.edu"
Test-EmailAddress -InputObject $email
```

Tests an existing EmailAddress object.
Returns $true.

## PARAMETERS

### -InputObject
One or more plain address strings, named mailbox strings, or EmailAddress
objects to test.
Accepts pipeline input by value.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Detailed
When specified, returns a \[PSCustomObject\] for each input instead of a
\[bool\].
The object has three properties:

  Input   \[string\]  - the original input value
  IsValid \[bool\]    - $true if the address passed validation
  Reason  \[string\]  - a description of why the address is invalid,
                      or an empty string if it is valid

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]  A plain address or named mailbox string.
### [EmailAddress]  An existing EmailAddress object.
## OUTPUTS

### [bool]          One value per input when -Detailed is not specified.
### [PSCustomObject] One object per input when -Detailed is specified.
## NOTES
Test-EmailAddress never throws regardless of input.
Empty strings, nulls,
and malformed addresses all return $false or a Detailed result with
IsValid = $false.

To create an EmailAddress object from a validated string, pipe the result
of Test-EmailAddress -Detailed through Where-Object { $_.IsValid } and
then pass the Input property to New-EmailAddress.

## RELATED LINKS
