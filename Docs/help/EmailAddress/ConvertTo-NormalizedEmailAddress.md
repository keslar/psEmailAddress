---
document type: cmdlet
external help file: EmailAddress-Help.xml
HelpUri: ''
Locale: en-US
Module Name: EmailAddress
ms.date: 02/27/2026
PlatyPS schema version: 2024-05-01
title: ConvertTo-NormalizedEmailAddress
---

# ConvertTo-NormalizedEmailAddress

## SYNOPSIS

Returns a new EmailAddress object with the address portion normalized to lowercase.

## SYNTAX

### FromEmailAddress (Default)

```
ConvertTo-NormalizedEmailAddress [-InputObject] <EmailAddress[]> [<CommonParameters>]
```

### FromString

```
ConvertTo-NormalizedEmailAddress [-Address] <string[]> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Normalizes the address portion of each input EmailAddress object by trimming
whitespace and converting it to lowercase.
Returns a new EmailAddress object
for each input; the original is not modified.

Normalization affects only the address portion (local-part@domain).
The display
name, if present, is preserved exactly as-is.

Two input modes are supported:

  -InputObject  — accepts one or more [EmailAddress] objects directly or
                  via the pipeline.

  -Address      — accepts one or more plain address or named mailbox strings.
                  Each string is first converted to an EmailAddress object,
                  then normalized.
Invalid strings are reported as non-terminating
                  errors and skipped, consistent with ConvertTo-EmailAddress.

This cmdlet is useful for ensuring consistency before comparison, deduplication,
storage, or display — for example, normalizing a batch of addresses imported
from a case-inconsistent source before inserting them into a database.

## EXAMPLES

### EXAMPLE 1

$email = New-EmailAddress -Address "CRK4@PITT.EDU"
ConvertTo-NormalizedEmailAddress -InputObject $email

Returns a new EmailAddress with address "crk4@pitt.edu".

### EXAMPLE 2

"
ConvertTo-NormalizedEmailAddress -InputObject $email

Returns a new EmailAddress with address "crk4@pitt.edu" and display
name "Chris Keslar" (display name is preserved unchanged).

### EXAMPLE 3

ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"

Converts and normalizes a plain address string in one step.
Returns a new EmailAddress with address "crk4@pitt.edu".

### EXAMPLE 4

"

Converts and normalizes a named mailbox string in one step.

### EXAMPLE 5

$emails = "CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | New-EmailAddress
$emails | ConvertTo-NormalizedEmailAddress

Normalizes a pipeline of EmailAddress objects.

### EXAMPLE 6

"CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | ConvertTo-NormalizedEmailAddress -Address

Normalizes a pipeline of address strings directly without a separate
New-EmailAddress step.

### EXAMPLE 7

Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    ConvertTo-NormalizedEmailAddress -Address

Normalizes all email addresses from a CSV column in a single pipeline.

## PARAMETERS

### -Address

One or more plain address or named mailbox strings to normalize.
Each string is converted to an EmailAddress object before normalization.
Invalid strings produce a non-terminating error and are skipped.
Accepts pipeline input by value.
Used with parameter set: FromString.

```yaml
Type: System.String[]
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

### -InputObject

One or more EmailAddress objects to normalize.
Accepts pipeline input by value.
Used with parameter set: FromEmailAddress.

```yaml
Type: EmailAddress[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromEmailAddress
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

### [EmailAddress]  Via -InputObject or pipeline (FromEmailAddress set).
[string]        Via -Address or pipeline (FromString set).

{{ Fill in the Description }}

### EmailAddress[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### [EmailAddress] One normalized EmailAddress object per valid input.

{{ Fill in the Description }}

### EmailAddress

{{ Fill in the Description }}

## NOTES

Only the address portion is normalized.
Display names are never modified.

When using the -Address parameter set, invalid strings produce a
non-terminating error and are skipped.
Use -ErrorAction Stop to treat
invalid strings as terminating errors.

ConvertTo-NormalizedEmailAddress always returns a new [EmailAddress] object.
The input object is never modified (the class is immutable).


## RELATED LINKS

{{ Fill in the related links here }}

