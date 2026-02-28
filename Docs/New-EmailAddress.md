---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# New-EmailAddress

## SYNOPSIS
Creates a new EmailAddress object.

## SYNTAX

### FromString (Default)
```
New-EmailAddress [-Address] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### FromComponents
```
New-EmailAddress [-LocalPart] <String> [-Domain] <String> [[-DisplayName] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates an EmailAddress object from either a full address string or from
individual components (local part, domain, and optional display name).

Two parameter sets are supported:

  FromString    - accepts a plain address ("user@example.com") or a named
                  mailbox string ("Display Name \<user@example.com\>").
                  Accepts pipeline input.

  FromComponents - accepts the local part, domain, and an optional display
                   name as separate parameters, and assembles the address
                   internally.

Validation is performed by the EmailAddress class at construction time
against a practical subset of RFC 5321/5322 rules.
Invalid input results
in a terminating error.

## EXAMPLES

### EXAMPLE 1
```
New-EmailAddress -Address "crk4@pitt.edu"
```

Creates an EmailAddress from a plain address string with no display name.

### EXAMPLE 2
```
"
```

Creates an EmailAddress from a named mailbox string.

### EXAMPLE 3
```
New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"
```

Creates an EmailAddress from component parts with no display name.

### EXAMPLE 4
```
New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"
```

Creates an EmailAddress from component parts with a display name.

### EXAMPLE 5
```
"crk4@pitt.edu", "jdoe@example.com" | New-EmailAddress
```

Creates EmailAddress objects from a pipeline of address strings.

### EXAMPLE 6
```
Import-Csv .\contacts.csv | Select-Object -ExpandProperty Email | New-EmailAddress
```

Creates EmailAddress objects from a column of email addresses in a CSV file.

## PARAMETERS

### -Address
A plain email address string ("user@example.com") or a named mailbox string
in RFC 5322 format ("Display Name \<user@example.com\>").

Accepts pipeline input by value.
Used with parameter set: FromString.

```yaml
Type: String
Parameter Sets: FromString
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LocalPart
The portion of the email address before the @ symbol (e.g.
"crk4").
Used with parameter set: FromComponents.

```yaml
Type: String
Parameter Sets: FromComponents
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
The domain portion of the email address (e.g.
"pitt.edu").
Used with parameter set: FromComponents.

```yaml
Type: String
Parameter Sets: FromComponents
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
The optional human-readable name associated with the address
(e.g.
"Chris Keslar").
When supplied the output object will format as
"DisplayName \<LocalPart@Domain\>".
Used with parameter set: FromComponents.

```yaml
Type: String
Parameter Sets: FromComponents
Aliases:

Required: False
Position: 3
Default value: None
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

### [string] A plain address or named mailbox string may be piped to -Address.
## OUTPUTS

### [EmailAddress]
## NOTES
This cmdlet wraps the EmailAddress class constructor and static factory
methods.
Invalid input produces a terminating error; use a try/catch block
or -ErrorAction if you need to handle failures without stopping the pipeline.

## RELATED LINKS
