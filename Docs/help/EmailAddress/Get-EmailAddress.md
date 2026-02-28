---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: Get-EmailAddress
---

# Get-EmailAddress

## SYNOPSIS

Retrieves a specific property value from an EmailAddress object.

## SYNTAX

### __AllParameterSets

```
Get-EmailAddress [-InputObject] <EmailAddress> [[-Property] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Extracts and returns a single named property from one or more EmailAddress
objects as a string.
This cmdlet provides a consistent, discoverable way to
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
                otherwise the plain address.
("Chris Keslar <crk4@pitt.edu>")
                Equivalent to EmailAddress.GetFriendlyName().

  RFC5322     — RFC 5322-compliant format with quoting applied to the
                display name where required.
                Equivalent to EmailAddress.ToRFC5322String().

Accepts pipeline input.
Returns one [string] per input object.

## EXAMPLES

### EXAMPLE 1

"
Get-EmailAddress -InputObject $email -Property Address

Returns: crk4@pitt.edu

### EXAMPLE 2

"
Get-EmailAddress -InputObject $email -Property DisplayName

Returns: Chris Keslar

### EXAMPLE 3

$email = New-EmailAddress -Address "crk4@pitt.edu"
Get-EmailAddress -InputObject $email -Property LocalPart

Returns: crk4

### EXAMPLE 4

$email = New-EmailAddress -Address "crk4@pitt.edu"
Get-EmailAddress -InputObject $email -Property Domain

Returns: pitt.edu

### EXAMPLE 5

"
Get-EmailAddress -InputObject $email -Property Friendly

Returns: Chris Keslar <crk4@pitt.edu>

### EXAMPLE 6

"
Get-EmailAddress -InputObject $email -Property RFC5322

Returns: "Keslar, Chris" <crk4@pitt.edu>

### EXAMPLE 7

"crk4@pitt.edu", "jdoe@example.com" |
    New-EmailAddress |
    Get-EmailAddress -Property Domain

Returns the domain of each address in the pipeline: pitt.edu, example.com

## PARAMETERS

### -InputObject

One or more EmailAddress objects to read from.
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

### -Property

The property to retrieve.
Must be one of:
Address, DisplayName, LocalPart, Domain, Friendly, RFC5322.
Defaults to Address.

```yaml
Type: System.String
DefaultValue: Address
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
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

### [string] One value per input object.

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

Get-EmailAddress reads from an [EmailAddress] object.
To read from a raw
string, first convert it with New-EmailAddress or ConvertTo-EmailAddress.

The Address and Friendly properties correspond to the two format modes of
Format-EmailAddress.
Use Format-EmailAddress when formatting is the primary
concern; use Get-EmailAddress when extracting a specific structural component
such as LocalPart or Domain.


## RELATED LINKS

{{ Fill in the related links here }}

