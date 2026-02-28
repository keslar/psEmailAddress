---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: Compare-EmailAddress
---

# Compare-EmailAddress

## SYNOPSIS

Compares two email addresses for equality.

## SYNTAX

### __AllParameterSets

```
Compare-EmailAddress [-ReferenceAddress] <Object> [-DifferenceAddress] <Object> [-IgnoreDisplayName]
 [-Detailed] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Compares a reference email address against a difference email address and
returns a [bool] indicating whether they are equal.
Two comparison modes
are available:

  Default               — compares both the address portion and the display
                          name, case-insensitively.
Equivalent to
                          EmailAddress.Equals().

  -IgnoreDisplayName    — compares only the address portion, ignoring any
                          difference in display name.
Useful when the same
                          recipient may appear with different display names.
                          Equivalent to EmailAddress.EqualsIgnoreDisplayName()
                          and [EmailAddress]::AreEqualIgnoringDisplayName().

Both -ReferenceAddress and -DifferenceAddress accept either a plain address
string ("user@example.com"), a named mailbox string
("Display Name <user@example.com>"), or an [EmailAddress] object.
Strings
are converted internally; invalid strings produce a terminating error.

-ReferenceAddress accepts pipeline input, allowing a single reference
address to be compared against a fixed -DifferenceAddress across multiple
pipeline inputs.

A -Detailed switch returns a [PSCustomObject] instead of a plain [bool],
with properties showing both inputs and the comparison result.

## EXAMPLES

### EXAMPLE 1

Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "crk4@pitt.edu"

Returns $true.
Both plain addresses are identical.

### EXAMPLE 2

Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>"

Returns $false.
Addresses are equal but display names differ.

### EXAMPLE 3

Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>" `
    -IgnoreDisplayName

Returns $true.
Display name difference is ignored.

### EXAMPLE 4

Compare-EmailAddress `
    -ReferenceAddress  "CRK4@PITT.EDU" `
    -DifferenceAddress "crk4@pitt.edu"

Returns $true.
Comparison is case-insensitive.

### EXAMPLE 5

Compare-EmailAddress `
    -ReferenceAddress  "crk4@pitt.edu" `
    -DifferenceAddress "crk4@pitt.edu" `
    -Detailed

Returns:
  ReferenceAddress   : crk4@pitt.edu
  DifferenceAddress  : crk4@pitt.edu
  AreEqual           : True
  IgnoredDisplayName : False

### EXAMPLE 6

$incoming = "crk4@pitt.edu", "other@pitt.edu", "crk4@pitt.edu" | New-EmailAddress
$incoming | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"

Compares each piped address against "crk4@pitt.edu".
Returns: $true, $false, $true

## PARAMETERS

### -Detailed

When specified, returns a [PSCustomObject] instead of a plain [bool].
The object has the following properties:

  ReferenceAddress   [string]  — the formatted reference address
  DifferenceAddress  [string]  — the formatted difference address
  AreEqual           [bool]    — $true if the addresses are equal
  IgnoredDisplayName [bool]    — whether -IgnoreDisplayName was used

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DifferenceAddress

The email address to compare against.
Accepts a plain address string, named mailbox string, or EmailAddress object.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IgnoreDisplayName

When specified, only the address portion is compared.
Display name differences
are ignored.
"Chris Keslar <crk4@pitt.edu>" and "C.
Keslar <crk4@pitt.edu>"
are considered equal under this switch.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ReferenceAddress

The reference email address to compare from.
Accepts a plain address string, named mailbox string, or EmailAddress object.
Accepts pipeline input by value.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]        A plain address or named mailbox string piped to -ReferenceAddress.
[EmailAddress]  An EmailAddress object piped to -ReferenceAddress.

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### [bool]           When -Detailed is not specified.
[PSCustomObject] When -Detailed is specified.

{{ Fill in the Description }}

### System.Boolean

{{ Fill in the Description }}

### System.Management.Automation.PSObject

{{ Fill in the Description }}

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

{{ Fill in the related links here }}

