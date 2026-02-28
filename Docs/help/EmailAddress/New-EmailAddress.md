---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: New-EmailAddress
---

# New-EmailAddress

## SYNOPSIS

Creates a new EmailAddress object.

## SYNTAX

### FromString (Default)

```
New-EmailAddress [-Address] <string> [<CommonParameters>]
```

### FromComponents

```
New-EmailAddress [-LocalPart] <string> [-Domain] <string> [[-DisplayName] <string>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

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
against a practical subset of RFC 5321/5322 rules.
Invalid input results
in a terminating error.

## EXAMPLES

### EXAMPLE 1

New-EmailAddress -Address "crk4@pitt.edu"

Creates an EmailAddress from a plain address string with no display name.

### EXAMPLE 2

"

Creates an EmailAddress from a named mailbox string.

### EXAMPLE 3

New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"

Creates an EmailAddress from component parts with no display name.

### EXAMPLE 4

New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"

Creates an EmailAddress from component parts with a display name.

### EXAMPLE 5

"crk4@pitt.edu", "jdoe@example.com" | New-EmailAddress

Creates EmailAddress objects from a pipeline of address strings.

### EXAMPLE 6

Import-Csv .\contacts.csv | Select-Object -ExpandProperty Email | New-EmailAddress

Creates EmailAddress objects from a column of email addresses in a CSV file.

## PARAMETERS

### -Address

A plain email address string ("user@example.com") or a named mailbox string
in RFC 5322 format ("Display Name <user@example.com>").

Accepts pipeline input by value.
Used with parameter set: FromString.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromString
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

The optional human-readable name associated with the address
(e.g.
"Chris Keslar").
When supplied the output object will format as
"DisplayName <LocalPart@Domain>".
Used with parameter set: FromComponents.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromComponents
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Domain

The domain portion of the email address (e.g.
"pitt.edu").
Used with parameter set: FromComponents.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromComponents
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -LocalPart

The portion of the email address before the @ symbol (e.g.
"crk4").
Used with parameter set: FromComponents.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromComponents
  Position: 0
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

### [string] A plain address or named mailbox string may be piped to -Address.

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## OUTPUTS

### [EmailAddress]

{{ Fill in the Description }}

### EmailAddress

{{ Fill in the Description }}

## NOTES

This cmdlet wraps the EmailAddress class constructor and static factory
methods.
Invalid input produces a terminating error; use a try/catch block
or -ErrorAction if you need to handle failures without stopping the pipeline.


## RELATED LINKS

{{ Fill in the related links here }}

