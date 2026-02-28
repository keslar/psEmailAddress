---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: Set-EmailAddress
---

# Set-EmailAddress

## SYNOPSIS

Returns a new EmailAddress object with one component replaced.

## SYNTAX

### SetAddress

```
Set-EmailAddress [-InputObject] <EmailAddress> -Address <string> [<CommonParameters>]
```

### SetDisplayName

```
Set-EmailAddress [-InputObject] <EmailAddress> -DisplayName <string> [<CommonParameters>]
```

### SetLocalPart

```
Set-EmailAddress [-InputObject] <EmailAddress> -LocalPart <string> [<CommonParameters>]
```

### SetDomain

```
Set-EmailAddress [-InputObject] <EmailAddress> -Domain <string> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Because EmailAddress objects are immutable, Set-EmailAddress does not modify
the input object.
Instead it returns a new EmailAddress object with the
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

Accepts pipeline input on -InputObject.
Returns one new [EmailAddress] per
input.
Invalid replacements produce a terminating error.

## EXAMPLES

### EXAMPLE 1

"
Set-EmailAddress -InputObject $email -Address "crk4@example.com"

Returns a new EmailAddress: Chris Keslar <crk4@example.com>
The display name "Chris Keslar" is preserved.

### EXAMPLE 2

$email = New-EmailAddress -Address "crk4@pitt.edu"
Set-EmailAddress -InputObject $email -DisplayName "Chris Keslar"

Returns a new EmailAddress: Chris Keslar <crk4@pitt.edu>

### EXAMPLE 3

"
Set-EmailAddress -InputObject $email -DisplayName ""

Returns a new EmailAddress: crk4@pitt.edu
The display name is removed.

### EXAMPLE 4

"
Set-EmailAddress -InputObject $email -LocalPart "ckeslar"

Returns a new EmailAddress: Chris Keslar <ckeslar@pitt.edu>
The domain "pitt.edu" and display name are preserved.

### EXAMPLE 5

"
Set-EmailAddress -InputObject $email -Domain "example.com"

Returns a new EmailAddress: Chris Keslar <crk4@example.com>
The local part "crk4" and display name are preserved.

### EXAMPLE 6

"crk4@pitt.edu", "jdoe@pitt.edu" |
    New-EmailAddress |
    Set-EmailAddress -Domain "example.com"

Returns two new EmailAddress objects with the domain replaced:
crk4@example.com, jdoe@example.com

## PARAMETERS

### -Address

The new plain address string (local-part@domain) to use.
The display name from the original object is preserved.
Mutually exclusive with -DisplayName, -LocalPart, and -Domain.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SetAddress
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

The new display name to use.
Supply an empty string to remove the display name.
The address portion from the original object is preserved.
Mutually exclusive with -Address, -LocalPart, and -Domain.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SetDisplayName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Domain

The new domain portion (the portion after the @) to use.
The local part and display name from the original object are preserved.
Mutually exclusive with -Address, -DisplayName, and -LocalPart.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SetDomain
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

The EmailAddress object to copy with a modified component.
Accepts pipeline input by value.

```yaml
Type: EmailAddress
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

### -LocalPart

The new local part (the portion before the @) to use.
The domain and display name from the original object are preserved.
Mutually exclusive with -Address, -DisplayName, and -Domain.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SetLocalPart
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
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

### [EmailAddress]

{{ Fill in the Description }}

### EmailAddress

{{ Fill in the Description }}

## OUTPUTS

### [EmailAddress] A new EmailAddress object with the specified component replaced.

{{ Fill in the Description }}

### EmailAddress

{{ Fill in the Description }}

## NOTES

Set-EmailAddress never modifies the input object.
It always returns a new
[EmailAddress] instance.
The original object is unchanged.

Exactly one replacement parameter must be supplied.
Supplying none or more
than one produces a parameter binding error.


## RELATED LINKS

{{ Fill in the related links here }}

