---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# Compare-EmailAddress

## SYNOPSIS
Compares two email addresses for equality.

## SYNTAX

```
Compare-EmailAddress [-ReferenceAddress] <Object> [-DifferenceAddress] <Object> [-IgnoreDisplayName]
 [-Detailed] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Compares a reference email address against a difference email address and
returns a \[bool\] indicating whether they are equal.
Two comparison modes
are available:

  Default               - compares both the address portion and the display
                          name, case-insensitively.
Equivalent to
                          EmailAddress.Equals().

  -IgnoreDisplayName    - compares only the address portion, ignoring any
                          difference in display name.
Useful when the same
                          recipient may appear with different display names.
                          Equivalent to EmailAddress.EqualsIgnoreDisplayName()
                          and \[EmailAddress\]::AreEqualIgnoringDisplayName().

Both -ReferenceAddress and -DifferenceAddress accept either a plain address
string ("user@example.com"), a named mailbox string
("Display Name \<user@example.com\>"), or an \[EmailAddress\] object.
Strings
are converted internally; invalid strings produce a terminating error.

-ReferenceAddress accepts pipeline input, allowing a single reference
address to be compared against a fixed -DifferenceAddress across multiple
pipeline inputs.

A -Detailed switch returns a \[PSCustomObject\] instead of a plain \[bool\],
with properties showing both inputs and the comparison result.

## EXAMPLES

### EXAMPLE 1
```
Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "crk4@pitt.edu"
```

Returns $true.
Both plain addresses are identical.

### EXAMPLE 2
```
Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>"
```

Returns $false.
Addresses are equal but display names differ.

### EXAMPLE 3
```
Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>" `
    -IgnoreDisplayName
```

Returns $true.
Display name difference is ignored.

### EXAMPLE 4
```
Compare-EmailAddress `
    -ReferenceAddress  "CRK4@PITT.EDU" `
    -DifferenceAddress "crk4@pitt.edu"
```

Returns $true.
Comparison is case-insensitive.

### EXAMPLE 5
```
Compare-EmailAddress `
    -ReferenceAddress  "crk4@pitt.edu" `
    -DifferenceAddress "crk4@pitt.edu" `
    -Detailed
```

Returns:
  ReferenceAddress   : crk4@pitt.edu
  DifferenceAddress  : crk4@pitt.edu
  AreEqual           : True
  IgnoredDisplayName : False

### EXAMPLE 6
```
$incoming = "crk4@pitt.edu", "other@pitt.edu", "crk4@pitt.edu" | New-EmailAddress
$incoming | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"
```

Compares each piped address against "crk4@pitt.edu".
Returns: $true, $false, $true

## PARAMETERS

### -ReferenceAddress
The reference email address to compare from.
Accepts a plain address string, named mailbox string, or EmailAddress object.
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

### -DifferenceAddress
The email address to compare against.
Accepts a plain address string, named mailbox string, or EmailAddress object.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDisplayName
When specified, only the address portion is compared.
Display name differences
are ignored.
"Chris Keslar \<crk4@pitt.edu\>" and "C.
Keslar \<crk4@pitt.edu\>"
are considered equal under this switch.

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

### -Detailed
When specified, returns a \[PSCustomObject\] instead of a plain \[bool\].
The object has the following properties:

  ReferenceAddress   \[string\]  - the formatted reference address
  DifferenceAddress  \[string\]  - the formatted difference address
  AreEqual           \[bool\]    - $true if the addresses are equal
  IgnoredDisplayName \[bool\]    - whether -IgnoreDisplayName was used

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

### [string]        A plain address or named mailbox string piped to -ReferenceAddress.
### [EmailAddress]  An EmailAddress object piped to -ReferenceAddress.
## OUTPUTS

### [bool]           When -Detailed is not specified.
### [PSCustomObject] When -Detailed is specified.
## NOTES
Comparison is always case-insensitive for the address portion, regardless
of whether -IgnoreDisplayName is used.

Both parameters accept strings as a convenience.
Strings are converted to
EmailAddress objects internally.
Invalid strings produce a terminating error;
use New-EmailAddress or Test-EmailAddress beforehand to validate input if
needed.

## RELATED LINKS
