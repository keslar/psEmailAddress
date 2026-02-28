---
external help file: EmailAddress-help.xml
Module Name: EmailAddress
online version:
schema: 2.0.0
---

# Resolve-EmailAddressInput

## SYNOPSIS
Internal helper function to resolve a parameter that accepts either a string or an EmailAddress.

## SYNTAX

```
Resolve-EmailAddressInput [-InputValue] <Object> [-ParameterName] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function is not intended to be used directly by end users.
It is a helper for cmdlets that
accept parameters which can be either raw strings or EmailAddress objects.
It attempts to convert
the input into an EmailAddress object, throwing a terminating error if the input is invalid.

## EXAMPLES

### EXAMPLE 1
```
" -ParameterName "ReferenceAddress"
Returns an EmailAddress object representing the input string.
```

## PARAMETERS

### -InputValue
The value to resolve, which may be either a string or an EmailAddress.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParameterName
The name of the parameter being resolved, used for error messages.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

## OUTPUTS

### [EmailAddress] The resolved EmailAddress object.
## NOTES

## RELATED LINKS
