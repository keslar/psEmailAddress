# EmailAddress

A PowerShell module providing a strongly-typed `EmailAddress` class and eight cmdlets for parsing, validating, normalizing, formatting, and comparing RFC 5321/5322 email addresses — in both PowerShell 5.1 and PowerShell 7+.

[![CI](https://github.com/keslar/psEmailAddress/actions/workflows/ci.yml/badge.svg)](https://github.com/keslar/psEmailAddress/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/keslar/psEmailAddress/blob/main/LICENSE.md)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/EmailAddress)](https://www.powershellgallery.com/packages/EmailAddress)

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [The EmailAddress Class](#the-emailaddress-class)
- [Cmdlets](#cmdlets)
  - [New-EmailAddress](#new-emailaddress)
  - [Test-EmailAddress](#test-emailaddress)
  - [ConvertTo-EmailAddress](#convertto-emailaddress)
  - [ConvertTo-NormalizedEmailAddress](#convertto-normalizedemailaddress)
  - [Format-EmailAddress](#format-emailaddress)
  - [Get-EmailAddress](#get-emailaddress)
  - [Set-EmailAddress](#set-emailaddress)
  - [Compare-EmailAddress](#compare-emailaddress)
- [Validation Rules](#validation-rules)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Working with email addresses in PowerShell typically means passing raw strings around and hoping they are valid. This module replaces that pattern with a proper value type:

```powershell
# Create once, validated at construction time
$email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

$email.Address      # crk4@pitt.edu
$email.DisplayName  # Chris Keslar

# Objects flow naturally through the pipeline
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    ConvertTo-EmailAddress |
    ConvertTo-NormalizedEmailAddress |
    Format-EmailAddress -Format RFC5322
```

The `EmailAddress` class is **immutable**: all properties are set at construction time and are read-only. Cmdlets that appear to "modify" an address (like `Set-EmailAddress`) always return a new object — the original is never changed.

---

## Requirements

- PowerShell 5.1 or PowerShell 7+
- Windows, Linux, or macOS

---

## Installation

```powershell
Install-Module -Name EmailAddress -Scope CurrentUser
```

Or to install for all users (requires elevation):

```powershell
Install-Module -Name EmailAddress -Scope AllUsers
```

After installation, import the module:

```powershell
Import-Module EmailAddress
```

---

## The EmailAddress Class

The `[EmailAddress]` class is the foundation of the module. All cmdlets produce or consume `[EmailAddress]` objects.

### Constructing an object

You can construct directly from the class, but using `New-EmailAddress` is preferred for pipeline compatibility and better error handling.

```powershell
# From a plain address string
$email = [EmailAddress]::new("crk4@pitt.edu")

# From a named mailbox string (RFC 5322 format)
$email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")

# From component parts
$email = [EmailAddress]::FromComponents("crk4", "pitt.edu", "Chris Keslar")

# Non-throwing factory (returns $false on failure instead of throwing)
$email = $null
if ([EmailAddress]::TryFromString("crk4@pitt.edu", [ref]$email)) {
    Write-Host $email.Address
}
```

### Properties

| Property | Type | Description |
|---|---|---|
| `Address` | `string` | The plain address: `crk4@pitt.edu` |
| `DisplayName` | `string` | The display name, or empty string if none |

Both properties are read-only. Attempting to assign to them throws an error.

### Key methods

| Method | Returns | Description |
|---|---|---|
| `GetAddress()` | `string` | Plain address: `crk4@pitt.edu` |
| `GetDisplayName()` | `string` | Display name, or empty string |
| `GetLocalPart()` | `string` | Portion before `@`: `crk4` |
| `GetDomain()` | `string` | Portion after `@`: `pitt.edu` |
| `GetFriendlyName()` | `string` | `Chris Keslar <crk4@pitt.edu>` if display name present, otherwise plain address |
| `ToRFC5322String()` | `string` | RFC 5322 format with display name quoted where required |
| `ToString()` | `string` | Plain address (used in string interpolation) |
| `Equals($other)` | `bool` | Case-insensitive equality on both address and display name |
| `EqualsIgnoreDisplayName($other)` | `bool` | Case-insensitive equality on address only |

---

## Cmdlets

### New-EmailAddress

Creates a new `[EmailAddress]` object. Invalid input is a **terminating error**.

```powershell
# From a plain address string
New-EmailAddress -Address "crk4@pitt.edu"

# From a named mailbox string
New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

# From component parts
New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"

# From the pipeline
"crk4@pitt.edu", "jdoe@example.com" | New-EmailAddress

# From a CSV column
Import-Csv .\contacts.csv | Select-Object -ExpandProperty Email | New-EmailAddress
```

---

### Test-EmailAddress

Tests whether strings are valid email address formats. **Never throws** — invalid input returns `$false` rather than an error.

```powershell
# Simple bool result
Test-EmailAddress -InputObject "crk4@pitt.edu"   # $true
Test-EmailAddress -InputObject "notanemail"       # $false

# Detailed result with failure reason
Test-EmailAddress -InputObject "notanemail" -Detailed
# Input   : notanemail
# IsValid : False
# Reason  : Address must contain exactly one '@' symbol.

# Pipeline: filter invalid addresses from a CSV
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    Test-EmailAddress -Detailed |
    Where-Object { -not $_.IsValid }
```

---

### ConvertTo-EmailAddress

Bulk-converts strings to `[EmailAddress]` objects. Unlike `New-EmailAddress`, invalid input produces a **non-terminating error** and is skipped — the pipeline continues.

```powershell
# Mixed valid/invalid input — bad addresses are skipped
"crk4@pitt.edu", "bad-address", "jdoe@example.com" | ConvertTo-EmailAddress

# Collect errors separately without stopping the pipeline
$addresses | ConvertTo-EmailAddress -ErrorVariable badAddresses

# Treat invalid input as terminating (behaves like New-EmailAddress)
$addresses | ConvertTo-EmailAddress -ErrorAction Stop
```

---

### ConvertTo-NormalizedEmailAddress

Returns new `[EmailAddress]` objects with the address portion trimmed and lowercased. The display name is preserved unchanged.

```powershell
# Normalize an object
$email = New-EmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"
ConvertTo-NormalizedEmailAddress -InputObject $email
# Address: crk4@pitt.edu  DisplayName: Chris Keslar

# Normalize directly from a string (convert and normalize in one step)
ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"

# Normalize a pipeline of addresses from a CSV
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    ConvertTo-NormalizedEmailAddress -Address
```

---

### Format-EmailAddress

Formats an `[EmailAddress]` object as a string in one of three modes.

| Format | Example output |
|---|---|
| `Address` *(default)* | `crk4@pitt.edu` |
| `Friendly` | `Chris Keslar <crk4@pitt.edu>` |
| `RFC5322` | `"Keslar, Chris" <crk4@pitt.edu>` *(quoted when required)* |

```powershell
$email = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"

Format-EmailAddress -InputObject $email                    # crk4@pitt.edu
Format-EmailAddress -InputObject $email -Format Friendly   # Keslar, Chris <crk4@pitt.edu>
Format-EmailAddress -InputObject $email -Format RFC5322    # "Keslar, Chris" <crk4@pitt.edu>

# Pipeline
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    New-EmailAddress |
    Format-EmailAddress -Format RFC5322
```

---

### Get-EmailAddress

Extracts a single named property from an `[EmailAddress]` object as a string.

```powershell
$email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

Get-EmailAddress -InputObject $email -Property Address      # crk4@pitt.edu
Get-EmailAddress -InputObject $email -Property DisplayName  # Chris Keslar
Get-EmailAddress -InputObject $email -Property LocalPart    # crk4
Get-EmailAddress -InputObject $email -Property Domain       # pitt.edu
Get-EmailAddress -InputObject $email -Property Friendly     # Chris Keslar <crk4@pitt.edu>
Get-EmailAddress -InputObject $email -Property RFC5322      # "Chris Keslar" <crk4@pitt.edu>

# Extract just the domain from every address in a CSV
Import-Csv .\contacts.csv |
    Select-Object -ExpandProperty Email |
    New-EmailAddress |
    Get-EmailAddress -Property Domain
```

---

### Set-EmailAddress

Returns a new `[EmailAddress]` object with one component replaced. The original object is never modified.

```powershell
$email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

# Replace the full address (display name is preserved)
Set-EmailAddress -InputObject $email -Address "crk4@example.com"
# Result: Chris Keslar <crk4@example.com>

# Replace just the display name
Set-EmailAddress -InputObject $email -DisplayName "C. Keslar"
# Result: C. Keslar <crk4@pitt.edu>

# Remove the display name
Set-EmailAddress -InputObject $email -DisplayName ""
# Result: crk4@pitt.edu

# Replace just the local part
Set-EmailAddress -InputObject $email -LocalPart "ckeslar"
# Result: Chris Keslar <ckeslar@pitt.edu>

# Replace just the domain — pipeline example
"crk4@pitt.edu", "jdoe@pitt.edu" |
    New-EmailAddress |
    Set-EmailAddress -Domain "example.com"
# Results: crk4@example.com, jdoe@example.com
```

---

### Compare-EmailAddress

Compares two email addresses for equality. Accepts strings, named mailbox strings, or `[EmailAddress]` objects for both parameters.

```powershell
# Default: compares address and display name (case-insensitive)
Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "crk4@pitt.edu"
# $true

Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>"
# $false — display names differ

# -IgnoreDisplayName: compare address portion only
Compare-EmailAddress `
    -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
    -DifferenceAddress "C. Keslar <crk4@pitt.edu>" `
    -IgnoreDisplayName
# $true

# -Detailed: returns a PSCustomObject
Compare-EmailAddress `
    -ReferenceAddress  "crk4@pitt.edu" `
    -DifferenceAddress "jdoe@example.com" `
    -Detailed
# ReferenceAddress   : crk4@pitt.edu
# DifferenceAddress  : jdoe@example.com
# AreEqual           : False
# IgnoredDisplayName : False

# Pipeline: compare each incoming address against a fixed address
$incoming | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"
```

---

## Validation Rules

Validation is applied at construction time by `[EmailAddress]::GetValidationFailureReason()`. The following rules are enforced:

| Rule | Detail |
|---|---|
| Single `@` | Exactly one `@` symbol required |
| Local part length | 1–64 characters |
| Local part characters | Letters, digits, and: `. ! # $ % & ' * + - / = ? ^ _ \` { \| } ~` |
| Local part dots | Not at start, not at end, no consecutive dots |
| Domain length | 1–255 characters |
| Domain label length | Each label (dot-separated segment) must be 1–63 characters |
| Domain label characters | Letters, digits, and hyphens only |
| Domain label hyphens | Not at start or end of a label |
| TLD | At least one dot required; TLD must be at least 2 characters |
| Total length | Must not exceed 320 characters |

> **Note:** Quoted local parts (e.g. `"john doe"@example.com`) and IP address literals (e.g. `user@[192.168.1.1]`) are intentionally not supported, as they are rarely accepted by real-world mail systems.

To get a human-readable reason for a validation failure:

```powershell
[EmailAddress]::GetValidationFailureReason("user@@example.com")
# Address must contain exactly one '@' symbol.

# Or use Test-EmailAddress -Detailed for pipeline-friendly validation
Test-EmailAddress -InputObject "user@@example.com" -Detailed
```

---

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines on opening issues and submitting pull requests.

---

## License

Distributed under the MIT License. See [LICENSE.md](LICENSE.md) for details.

---

*Copyright © 2026 University of Pittsburgh*
