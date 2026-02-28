---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# ConvertTo-NormalizedEmailAddress

## SYNOPSIS
Returns a new EmailAddress object with the address portion normalized to lowercase.

## SYNTAX

### FromEmailAddress (Default)
```
ConvertTo-NormalizedEmailAddress [-InputObject] <EmailAddress[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FromString
```
ConvertTo-NormalizedEmailAddress [-Address] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Normalizes the address portion of each input EmailAddress object by trimming
whitespace and converting it to lowercase.
Returns a new EmailAddress object
for each input; the original is not modified.

Normalization affects only the address portion (local-part@domain).
The display
name, if present, is preserved exactly as-is.

Two input modes are supported:

  -InputObject  - accepts one or more \[EmailAddress\] objects directly or
                  via the pipeline.

  -Address      - accepts one or more plain address or named mailbox strings.
                  Each string is first converted to an EmailAddress object,
                  then normalized.
Invalid strings are reported as non-terminating
                  errors and skipped, consistent with ConvertTo-EmailAddress.

This cmdlet is useful for ensuring consistency before comparison, deduplication,
storage, or display - for example, normalizing a batch of addresses imported
from a case-inconsistent source before inserting them into a database.

## EXAMPLES

### EXAMPLE 1
```
$email = New-EmailAddress -Address "CRK4@PITT.EDU"
ConvertTo-NormalizedEmailAddress -InputObject $email
```

Returns a new EmailAddress with address "crk4@pitt.edu".

### EXAMPLE 2
```
"
ConvertTo-NormalizedEmailAddress -InputObject $email
```

Returns a new EmailAddress with address "crk4@pitt.edu" and display
name "Chris Keslar" (display name is preserved unchanged).

### EXAMPLE 3
```
ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"
```

Converts and normalizes a plain address string in one step.
Returns a new EmailAddress with address "crk4@pitt.edu".

### EXAMPLE 4
```
"
```

Converts and normalizes a named mailbox string in one step.

### EXAMPLE 5
```
$emails = "CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | New-EmailAddress
$emails | ConvertTo-NormalizedEmailAddress
```

Normalizes a pipeline of EmailAddress objects.

### EXAMPLE 6
```
"CRK4@PITT.EDU", "JDOE@EXAMPLE.COM" | ConvertTo-NormalizedEmailAddress -Address
```

Normalizes a pipeline of address strings directly without a separate
New-EmailAddress step.

### EXAMPLE 7
```
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    ConvertTo-NormalizedEmailAddress -Address
```

Normalizes all email addresses from a CSV column in a single pipeline.

## PARAMETERS

### -InputObject
One or more EmailAddress objects to normalize.
Accepts pipeline input by value.
Used with parameter set: FromEmailAddress.

```yaml
Type: EmailAddress[]
Parameter Sets: FromEmailAddress
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Address
One or more plain address or named mailbox strings to normalize.
Each string is converted to an EmailAddress object before normalization.
Invalid strings produce a non-terminating error and are skipped.
Accepts pipeline input by value.
Used with parameter set: FromString.

```yaml
Type: String[]
Parameter Sets: FromString
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### [EmailAddress]  Via -InputObject or pipeline (FromEmailAddress set).
### [string]        Via -Address or pipeline (FromString set).
## OUTPUTS

### [EmailAddress] One normalized EmailAddress object per valid input.
## NOTES
Only the address portion is normalized.
Display names are never modified.

When using the -Address parameter set, invalid strings produce a
non-terminating error and are skipped.
Use -ErrorAction Stop to treat
invalid strings as terminating errors.

ConvertTo-NormalizedEmailAddress always returns a new \[EmailAddress\] object.
The input object is never modified (the class is immutable).

## RELATED LINKS
