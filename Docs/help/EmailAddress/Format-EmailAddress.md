---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: Format-EmailAddress
---

# Format-EmailAddress

## SYNOPSIS

Formats an EmailAddress object as a string in one of three standard formats.

## SYNTAX

### __AllParameterSets

```
Format-EmailAddress [-InputObject] <EmailAddress> [[-Format] <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns a formatted string representation of one or more EmailAddress objects.
Three formats are available via the -Format parameter:

  Address  — plain address only: "crk4@pitt.edu"
             Equivalent to EmailAddress.ToString().
             This is the default.

  Friendly — display name and address if a display name is present, otherwise
             plain address: "Chris Keslar <crk4@pitt.edu>" or "crk4@pitt.edu"
             Equivalent to EmailAddress.GetFriendlyName().

  RFC5322  — RFC 5322-compliant format.
The display name is quoted if it
             contains special characters or whitespace; embedded double quotes
             in the display name are escaped:
               "Chris Keslar" <crk4@pitt.edu>      (space requires quoting)
               ChrisKeslar <crk4@pitt.edu>          (no quoting needed)
               "Keslar, Chris" <crk4@pitt.edu>      (comma requires quoting)
             Falls back to plain address when no display name is present.
             Equivalent to EmailAddress.ToRFC5322String().

Accepts pipeline input.
Returns one [string] per input object.

## EXAMPLES

### EXAMPLE 1

"
Format-EmailAddress -InputObject $email

Returns: crk4@pitt.edu

### EXAMPLE 2

"
Format-EmailAddress -InputObject $email -Format Friendly

Returns: Chris Keslar <crk4@pitt.edu>

### EXAMPLE 3

"
Format-EmailAddress -InputObject $email -Format RFC5322

Returns: "Chris Keslar" <crk4@pitt.edu>

### EXAMPLE 4

"
Format-EmailAddress -InputObject $email -Format RFC5322

Returns: "Keslar, Chris" <crk4@pitt.edu>

### EXAMPLE 5

" | New-EmailAddress
$emails | Format-EmailAddress -Format Friendly

Formats a pipeline of EmailAddress objects.
Returns one string per object.

### EXAMPLE 6

Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    New-EmailAddress |
    Format-EmailAddress -Format RFC5322

Converts a CSV column of addresses to RFC 5322 format strings.

## PARAMETERS

### -Format

The output format.
Must be one of: Address, Friendly, RFC5322.
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

### -InputObject

One or more EmailAddress objects to format.
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

### [string] One formatted string per input object.

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

Format-EmailAddress always requires an [EmailAddress] object as input.
To format a raw string, first convert it with New-EmailAddress or
ConvertTo-EmailAddress.

The three formats differ only when a display name is present:
  - Address  always strips the display name.
  - Friendly includes the display name as-is.
  - RFC5322  includes the display name, quoting it if required by the standard.

When no display name is set on the EmailAddress object, all three formats
produce identical output — the plain address string.


## RELATED LINKS

{{ Fill in the related links here }}

