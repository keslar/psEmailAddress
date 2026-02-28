---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# ConvertTo-EmailAddress

## SYNOPSIS
Converts one or more strings to EmailAddress objects, skipping invalid input.

## SYNTAX

```
ConvertTo-EmailAddress [-InputObject] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Attempts to convert each input string to an EmailAddress object.
Unlike
New-EmailAddress, invalid input does not stop the pipeline: each invalid
string is reported as a non-terminating error and skipped, allowing the
remaining inputs to be processed.

This makes ConvertTo-EmailAddress suitable for bulk or batch conversions
where some inputs may be malformed - for example, importing a list of
addresses from a CSV and discarding the bad ones.

Input may be supplied directly via -InputObject or piped in.
Only plain
address strings ("user@example.com") and named mailbox strings
("Display Name \<user@example.com\>") are accepted; component-based
construction is not supported.
Use New-EmailAddress -LocalPart/-Domain
if you need to build addresses from parts.

Validation is performed by the EmailAddress class against a practical
subset of RFC 5321/5322 rules.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
```

Converts a single address string.
Returns one EmailAddress object.

### EXAMPLE 2
```
"crk4@pitt.edu", "bad-address", "jdoe@example.com" | ConvertTo-EmailAddress
```

Converts a mixed list.
The valid addresses are returned as EmailAddress
objects; "bad-address" is silently skipped (or reported if -ErrorVariable
or -ErrorAction is set).

### EXAMPLE 3
```
"crk4@pitt.edu", "bad-address" | ConvertTo-EmailAddress -ErrorAction Stop
```

Converts addresses from the pipeline but stops on the first invalid input,
behaving like New-EmailAddress.

### EXAMPLE 4
```
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    ConvertTo-EmailAddress -ErrorVariable badAddresses
```

Converts a CSV column of addresses.
Invalid entries are collected in
$badAddresses for inspection without interrupting the pipeline.

### EXAMPLE 5
```
$addresses = "crk4@pitt.edu", "jdoe@example.com", "notvalid"
$valid = $addresses | ConvertTo-EmailAddress -ErrorAction SilentlyContinue
$valid.Count   # 2 - only the valid ones
```

Suppresses error output and collects only the successfully converted objects.

## PARAMETERS

### -InputObject
One or more plain address or named mailbox strings to convert.
Accepts pipeline input by value.

```yaml
Type: String[]
Parameter Sets: (All)
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

### [string] Plain address or named mailbox strings piped directly to the cmdlet.
## OUTPUTS

### [EmailAddress] One object per valid input string. Invalid strings are
### skipped and reported via Write-Error.
## NOTES
The key difference between ConvertTo-EmailAddress and New-EmailAddress:

  New-EmailAddress      - single-object creation; invalid input is a
                          terminating error that stops the pipeline.

  ConvertTo-EmailAddress - bulk conversion; invalid input is a
                           non-terminating error that skips the item
                           and continues.

To treat invalid input as terminating within ConvertTo-EmailAddress,
use -ErrorAction Stop.

## RELATED LINKS
