#Requires -Version 5.1
<#
.SYNOPSIS
    Defines the EmailAddress class for encapsulating and working with email addresses.

.DESCRIPTION
    The EmailAddress class represents a single email address, optionally with a display name,
    in the RFC 5322 "named mailbox" format: Display Name <local-part@domain>

    The class is designed to be effectively immutable: all fields are set at construction
    time and exposed only through read-only script properties and getter methods.
    No setters are provided. Methods that would logically "change" an address instead
    return a new EmailAddress instance.

    Validation is performed at construction time against a practical subset of RFC 5321/5322
    rules. See IsValidEmailAddressFormat for full validation details.

.NOTES
    Author  : [.Keslar <crk4@pitt.edu>
    Version : 1.0
    Requires: PowerShell 5.1 or later

.EXAMPLE
    # Construct from a plain address
    $email = [EmailAddress]::new("crk4@pitt.edu")

    # Construct from a named mailbox string
    $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")

    # Construct from components
    $email = [EmailAddress]::FromComponents("crk4", "pitt.edu", "Chris Keslar")

    # Use the factory method with error handling
    $email = $null
    if ([EmailAddress]::TryFromString("crk4@pitt.edu", [ref]$email)) {
        Write-Host $email.ToRFC5322String()
    }
#>
class EmailAddress {

    #------------------------------------------------------------------
    # Private backing fields
    # Named with underscore prefix to distinguish from the public
    # script properties registered via Update-TypeData below.
    #------------------------------------------------------------------
    hidden [string]$_Address
    hidden [string]$_DisplayName

    #------------------------------------------------------------------
    # Constructors
    #------------------------------------------------------------------

    # Disabled default constructor — an email address is meaningless without a value.
    EmailAddress() {
        throw "Default constructor is not allowed. Use the parameterized constructor or a static factory method."
    }

    <#
    .SYNOPSIS
        Constructs an EmailAddress from a string.

    .DESCRIPTION
        Accepts either a plain address ("user@example.com") or a named mailbox
        string in RFC 5322 format ("Display Name <user@example.com>").

        If the named mailbox format is detected, the display name and address are
        parsed separately. Otherwise the string is treated as a plain address with
        no display name.

        Throws if the resulting address portion fails format validation.

    .PARAMETER Address
        A plain email address or named mailbox string.

    .EXAMPLE
        [EmailAddress]::new("crk4@pitt.edu")

    .EXAMPLE
        [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
    #>
    EmailAddress([string]$Address) {
        # Detect the named mailbox format: "Display Name <local-part@domain>"
        # Capture group 1 = display name (may be empty), group 2 = address
        if ($Address -match '^(.*)<(.+)>$') {
            $this._DisplayName = $matches[1].Trim()
            $this._Address = $matches[2].Trim()
        } else {
            # Plain address — no display name
            $this._DisplayName = ''
            $this._Address = $Address.Trim()
        }

        # Validate the address portion only (not the full original string)
        if (-not [EmailAddress]::IsValidEmailAddressFormat($this._Address)) {
            throw "Invalid email address format: '$($this._Address)'"
        }
    }

    #------------------------------------------------------------------
    # Instance Methods — Accessors
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Returns the email address (local-part@domain), without the display name.
    #>
    [string] GetAddress() {
        return $this._Address
    }

    <#
    .SYNOPSIS
        Returns the display name, or an empty string if none was provided.
    #>
    [string] GetDisplayName() {
        return $this._DisplayName
    }

    <#
    .SYNOPSIS
        Returns the local part of the address (the portion before the @ symbol).
    #>
    [string] GetLocalPart() {
        $atIndex = $this._Address.IndexOf('@')
        if ($atIndex -gt 0) {
            return $this._Address.Substring(0, $atIndex)
        } else {
            return $this._Address
        }
    }

    <#
    .SYNOPSIS
        Returns the domain portion of the address (the portion after the @ symbol).
    #>
    [string] GetDomain() {
        $atIndex = $this._Address.IndexOf('@')
        if ($atIndex -gt 0 -and $atIndex -lt $this._Address.Length - 1) {
            return $this._Address.Substring($atIndex + 1)
        } else {
            return ''
        }
    }

    #------------------------------------------------------------------
    # Instance Methods — Formatting
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Returns the address in "Display Name <address>" format if a display name
        is present, or just the plain address otherwise.
    #>
    [string] GetFriendlyName() {
        if (-not [string]::IsNullOrEmpty($this._DisplayName)) {
            return "$($this._DisplayName) <$($this._Address)>"
        } else {
            return $this._Address
        }
    }

    # Aliases for GetFriendlyName — provided for naming-convention flexibility.
    # All three delegate to GetFriendlyName and produce identical output.
    [string] FriendlyName() { return $this.GetFriendlyName() }
    [string] NamedMailbox() { return $this.GetFriendlyName() }
    [string] Mailbox() { return $this.GetFriendlyName() }

    <#
    .SYNOPSIS
        Returns the plain email address string (local-part@domain).

    .DESCRIPTION
        Overrides the default ToString() to return just the address, consistent
        with how PowerShell uses this method in string interpolation and output.
        Use ToFriendlyString() or ToRFC5322String() to include the display name.
    #>
    [string] ToString() {
        return $this._Address
    }

    <#
    .SYNOPSIS
        Returns the address in friendly format, identical to GetFriendlyName().
    #>
    [string] ToFriendlyString() {
        return $this.GetFriendlyName()
    }

    <#
    .SYNOPSIS
        Returns the address formatted according to RFC 5322.

    .DESCRIPTION
        If a display name is present, it is quoted if it contains any characters
        that require quoting under RFC 5322 (spaces, special characters, etc.),
        and the result is returned as: "Display Name" <address> or: Display Name <address>

        If no display name is present, just the plain address is returned.

    .OUTPUTS
        [string] RFC 5322-formatted address string.

    .EXAMPLE
        # No special characters — no quoting needed
        "Chris Keslar <crk4@pitt.edu>"

    .EXAMPLE
        # Display name contains a comma — quoting applied
        '"Keslar, Chris" <crk4@pitt.edu>'
    #>
    [string] ToRFC5322String() {
        $address = $this._Address
        $displayName = $this._DisplayName

        if (-not [string]::IsNullOrEmpty($displayName)) {
            # Quote the display name if it contains RFC 5322 special characters or whitespace
            if ($displayName -match '[\s"(),:;<>@\[\\\]]') {
                $quotedDisplayName = '"' + ($displayName -replace '"', '\"') + '"'
            } else {
                $quotedDisplayName = $displayName
            }
            return "$quotedDisplayName <$address>"
        } else {
            return $address
        }
    }

    #------------------------------------------------------------------
    # Instance Methods — Comparison
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Determines whether this EmailAddress is equal to another.

    .DESCRIPTION
        Compares both the address and display name, case-insensitively.
        Returns $false if the other object is $null or not an EmailAddress.

    .PARAMETER other
        The object to compare against.
    #>
    [bool] Equals([object]$other) {
        if ($null -eq $other -or -not ($other -is [EmailAddress])) {
            return $false
        }
        return ( ($this._Address -ieq $other._Address) -and
            ($this._DisplayName -ieq $other._DisplayName) )
    }

    <#
    .SYNOPSIS
        Determines whether this EmailAddress refers to the same address as another,
        ignoring any difference in display name.

    .DESCRIPTION
        Useful when you want to treat "Chris Keslar <crk4@pitt.edu>" and
        "C. Keslar <crk4@pitt.edu>" as the same recipient.
        Returns $false if the other object is $null or not an EmailAddress.

    .PARAMETER other
        The object to compare against.
    #>
    [bool] EqualsIgnoreDisplayName([object]$other) {
        if ($null -eq $other -or -not ($other -is [EmailAddress])) {
            return $false
        }
        return ($this._Address -ieq $other._Address)
    }

    <#
    .SYNOPSIS
        Returns a hash code for this EmailAddress.

    .DESCRIPTION
        Combines the hash codes of the normalized (lowercased) address and display name.
        Normalization is required to satisfy the contract that objects considered equal
        by Equals() must produce the same hash code, since Equals() is case-insensitive.

    .OUTPUTS
        [int] Hash code value.
    #>
    [int] GetHashCode() {
        # Normalize to lowercase before hashing to match the case-insensitive Equals() contract
        $addressHash = if ($this._Address) { $this._Address.ToLowerInvariant().GetHashCode() } else { 0 }
        $displayNameHash = if ($this._DisplayName) { $this._DisplayName.ToLowerInvariant().GetHashCode() } else { 0 }
        return $addressHash -bxor $displayNameHash
    }

    #------------------------------------------------------------------
    # Static Methods — Validation
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Returns a human-readable reason string if the address is invalid, or
        $null if the address is valid.

    .DESCRIPTION
        Contains all validation logic for RFC 5321/5322 address format checking.
        This is the single source of truth for validation; IsValidEmailAddressFormat
        and its aliases all delegate here.

        Returning an empty string for success (rather than $null) allows callers to
        use [string]::IsNullOrEmpty(): if ([string]::IsNullOrEmpty(GetValidationFailureReason($addr))) { valid }.
        Note: PowerShell coerces $null to '' on return from a [string]-typed method,
        so callers must use IsNullOrEmpty rather than a $null check.

        Validation rules applied:
        - Must contain exactly one @ symbol
        - Local part: 1–64 characters; allows letters, digits, and: . ! # $ % & ' * + - / = ? ^ _ ` { | } ~
        - Local part: dots not allowed at start, end, or consecutively
        - Domain: 1–255 characters; labels separated by dots
        - Domain: each label 1–63 characters; letters, digits, and hyphens only
        - Domain: labels not allowed to start or end with a hyphen
        - Domain: must contain at least one dot (i.e. a TLD is required)
        - Domain: TLD must be at least 2 characters
        - Total length must not exceed 320 characters

        Note: quoted local parts (e.g. "john doe"@example.com) and IP address
        literals (e.g. user@[192.168.1.1]) are intentionally not supported, as
        they are rarely accepted by real-world mail systems.

    .PARAMETER address
        The plain email address string to validate (local-part@domain).

    .OUTPUTS
        [string] A specific failure reason, or $null if the address is valid.

    .EXAMPLE
        [EmailAddress]::GetValidationFailureReason("john.doe@example.com")
        # Returns: $null  (address is valid)

    .EXAMPLE
        [EmailAddress]::GetValidationFailureReason("user@@example.com")
        # Returns: "Address must contain exactly one '@' symbol."
    #>
    static [string] GetValidationFailureReason([string]$address) {
        # Must not be null or whitespace
        if ([string]::IsNullOrWhiteSpace($address)) {
            return 'Address must not be null or empty.'
        }

        # Total length must not exceed 320 characters (RFC 5321)
        if ($address.Length -gt 320) {
            return "Address exceeds the maximum length of 320 characters (actual: $($address.Length))."
        }

        # Must contain exactly one @ symbol
        $atIndex = $address.IndexOf('@')
        if ($atIndex -le 0 -or $atIndex -ne $address.LastIndexOf('@')) {
            return "Address must contain exactly one '@' symbol."
        }

        $localPart = $address.Substring(0, $atIndex)
        $domain = $address.Substring($atIndex + 1)

        #--------------------------------------------------------------
        # Validate local part
        #--------------------------------------------------------------

        # Local part length: 1–64 characters (RFC 5321)
        if ($localPart.Length -lt 1 -or $localPart.Length -gt 64) {
            return "Local part '$localPart' must be between 1 and 64 characters (actual: $($localPart.Length))."
        }

        # Local part: allowed characters (RFC 5321/5322 practical subset)
        # Letters, digits, and: . ! # $ % & ' * + - / = ? ^ _ ` { | } ~
        if ($localPart -notmatch '^[a-zA-Z0-9.!#$%&''*+\-/=?^_`{|}~]+$') {
            return "Local part '$localPart' contains invalid characters. Only letters, digits, and the characters . ! # `$ % & ' * + - / = ? ^ _ `` { | } ~ are allowed."
        }

        # Local part: dot not allowed at start or end
        if ($localPart.StartsWith('.') -or $localPart.EndsWith('.')) {
            return "Local part '$localPart' must not start or end with a dot."
        }

        # Local part: no consecutive dots
        if ($localPart -match '\.\.') {
            return "Local part '$localPart' must not contain consecutive dots."
        }

        #--------------------------------------------------------------
        # Validate domain
        #--------------------------------------------------------------

        # Domain must not be empty
        if ([string]::IsNullOrWhiteSpace($domain)) {
            return 'Domain must not be empty.'
        }

        # Domain length: 1–255 characters (RFC 5321)
        if ($domain.Length -gt 255) {
            return "Domain '$domain' exceeds the maximum length of 255 characters (actual: $($domain.Length))."
        }

        # Domain must contain at least one dot (TLD required)
        if (-not $domain.Contains('.')) {
            return "Domain '$domain' must contain at least one dot (a top-level domain is required)."
        }

        # Domain must not start or end with a dot or hyphen
        if ($domain.StartsWith('.') -or $domain.EndsWith('.')) {
            return "Domain '$domain' must not start or end with a dot."
        }
        if ($domain.StartsWith('-') -or $domain.EndsWith('-')) {
            return "Domain '$domain' must not start or end with a hyphen."
        }

        # Validate each domain label
        $labels = $domain.Split('.')
        foreach ($label in $labels) {
            # Each label must be 1–63 characters
            if ($label.Length -lt 1 -or $label.Length -gt 63) {
                return "Domain label '$label' must be between 1 and 63 characters (actual: $($label.Length))."
            }

            # Each label: only letters, digits, and hyphens
            if ($label -notmatch '^[a-zA-Z0-9-]+$') {
                return "Domain label '$label' contains invalid characters. Only letters, digits, and hyphens are allowed."
            }

            # Each label must not start or end with a hyphen
            if ($label.StartsWith('-') -or $label.EndsWith('-')) {
                return "Domain label '$label' must not start or end with a hyphen."
            }
        }

        # TLD (last label) must be at least 2 characters
        if ($labels[-1].Length -lt 2) {
            return "Top-level domain '$($labels[-1])' must be at least 2 characters."
        }

        return $null
    }

    <#
    .SYNOPSIS
        Determines whether a string is a valid email address format.

    .DESCRIPTION
        Validates an email address against the practical subset of RFC 5321/5322 rules
        used by real-world mail systems. Delegates all logic to GetValidationFailureReason;
        returns $true if that method returns $null (no failure reason), $false otherwise.

        For a human-readable explanation of why an address is invalid, call
        GetValidationFailureReason directly.

        Note: quoted local parts (e.g. "john doe"@example.com) and IP address
        literals (e.g. user@[192.168.1.1]) are intentionally not supported, as
        they are rarely accepted by real-world mail systems.

    .PARAMETER address
        The email address string to validate. Should be a plain address only
        (local-part@domain), not a named mailbox string.

    .OUTPUTS
        [bool] $true if the address is valid, $false otherwise.

    .EXAMPLE
        [EmailAddress]::IsValidEmailAddressFormat("john.doe@example.com")
        # Returns: $true

    .EXAMPLE
        [EmailAddress]::IsValidEmailAddressFormat("invalid@")
        # Returns: $false

    .EXAMPLE
        [EmailAddress]::IsValidEmailAddressFormat("user+tag@sub.domain.org")
        # Returns: $true
    #>
    static [bool] IsValidEmailAddressFormat([string]$address) {
        return [string]::IsNullOrEmpty([EmailAddress]::GetValidationFailureReason($address))
    }

    <#
    .SYNOPSIS
        Shorthand alias for IsValidEmailAddressFormat.

    .PARAMETER address
        The plain email address string to validate.
    #>
    static [bool] IsValidFormat([string]$address) {
        return [EmailAddress]::IsValidEmailAddressFormat($address)
    }

    <#
    .SYNOPSIS
        Shorthand alias for IsValidEmailAddressFormat.

    .PARAMETER address
        The plain email address string to validate.
    #>
    static [bool] IsValidEmailAddress([string]$address) {
        return [EmailAddress]::IsValidEmailAddressFormat($address)
    }

    <#
    .SYNOPSIS
        Determines whether an existing EmailAddress object contains a valid address.

    .DESCRIPTION
        Returns $false if the object is $null; otherwise validates the address
        portion of the object. This overload is useful when you hold an EmailAddress
        reference that may have been assigned $null.

    .PARAMETER emailAddress
        The EmailAddress object to validate.
    #>
    static [bool] IsValid([EmailAddress]$emailAddress) {
        if ($null -eq $emailAddress) {
            return $false
        }
        return [EmailAddress]::IsValidEmailAddressFormat($emailAddress.GetAddress())
    }

    #------------------------------------------------------------------
    # Static Methods — Factory / Parsing
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Creates an EmailAddress from a plain address or named mailbox string.

    .DESCRIPTION
        Wraps the constructor with a descriptive exception message on failure.
        Note: the inner exception detail is included in the message but the
        original exception type is not preserved; use the constructor directly
        if you need to catch typed exceptions.

    .PARAMETER text
        A plain address or named mailbox string.

    .OUTPUTS
        [EmailAddress]
    #>
    static [EmailAddress] GetEmailAddressFromString([string]$text) {
        try {
            return [EmailAddress]::new($text)
        } catch {
            throw "Failed to create EmailAddress from input '$text': $_"
        }
    }

    <#
    .SYNOPSIS
        Shorthand alias for GetEmailAddressFromString.

    .PARAMETER text
        A plain address or named mailbox string.
    #>
    static [EmailAddress] FromString([string]$text) {
        return [EmailAddress]::GetEmailAddressFromString($text)
    }

    <#
    .SYNOPSIS
        Attempts to create an EmailAddress from a string without throwing.

    .DESCRIPTION
        Returns $true and sets the $emailAddress reference on success.
        Returns $false and sets $emailAddress to $null on failure.

    .PARAMETER text
        A plain address or named mailbox string.

    .PARAMETER emailAddress
        A [ref] variable that receives the resulting EmailAddress, or $null on failure.

    .OUTPUTS
        [bool]

    .EXAMPLE
        $result = $null
        if ([EmailAddress]::TryFromString("crk4@pitt.edu", [ref]$result)) {
            Write-Host $result.GetAddress()
        }
    #>
    static [bool] TryParseEmailAddressFromString([string]$text, [ref]$emailAddress) {
        try {
            $emailAddress.Value = [EmailAddress]::new($text)
            return $true
        } catch {
            $emailAddress.Value = $null
            return $false
        }
    }

    <#
    .SYNOPSIS
        Shorthand alias for TryParseEmailAddressFromString.
    #>
    static [bool] TryFromString([string]$text, [ref]$emailAddress) {
        return [EmailAddress]::TryParseEmailAddressFromString($text, $emailAddress)
    }

    <#
    .SYNOPSIS
        Creates an EmailAddress from its component parts.

    .DESCRIPTION
        Constructs a valid address from a local part, domain, and optional display name.
        Throws if either the local part or domain is null or whitespace, or if the
        resulting address fails format validation.

    .PARAMETER localPart
        The portion of the address before the @ symbol (e.g. "crk4").

    .PARAMETER domain
        The domain portion of the address (e.g. "pitt.edu").

    .PARAMETER displayName
        Optional. The human-readable name associated with the address (e.g. "Chris Keslar").

    .OUTPUTS
        [EmailAddress]

    .EXAMPLE
        [EmailAddress]::FromComponents("crk4", "pitt.edu", "Chris Keslar")
    #>
    static [EmailAddress] GetEmailAddressFromComponents([string]$localPart, [string]$domain, [string]$displayName = '') {
        if ([string]::IsNullOrWhiteSpace($localPart) -or [string]::IsNullOrWhiteSpace($domain)) {
            throw "Local part and domain must not be null or whitespace."
        }
        $address = "$localPart@$domain"
        if (-not [string]::IsNullOrEmpty($displayName)) {
            return [EmailAddress]::new("$displayName <$address>")
        } else {
            return [EmailAddress]::new($address)
        }
    }

    <#
    .SYNOPSIS
        Shorthand alias for GetEmailAddressFromComponents.
    #>
    static [EmailAddress] FromComponents([string]$localPart, [string]$domain, [string]$displayName = '') {
        return [EmailAddress]::GetEmailAddressFromComponents($localPart, $domain, $displayName)
    }

    <#
    .SYNOPSIS
        Attempts to create an EmailAddress from component parts without throwing.

    .DESCRIPTION
        Returns $true and sets $emailAddress on success.
        Returns $false and sets $emailAddress to $null on failure.

    .PARAMETER localPart
        The local part of the address (before the @).

    .PARAMETER domain
        The domain portion (after the @).

    .PARAMETER emailAddress
        A [ref] variable that receives the result, or $null on failure.

    .PARAMETER displayName
        Optional display name.
    #>
    static [bool] TryParseEmailAddressFromComponents([string]$localPart, [string]$domain, [ref]$emailAddress, [string]$displayName = '') {
        try {
            $emailAddress.Value = [EmailAddress]::GetEmailAddressFromComponents($localPart, $domain, $displayName)
            return $true
        } catch {
            $emailAddress.Value = $null
            return $false
        }
    }

    <#
    .SYNOPSIS
        Shorthand alias for TryParseEmailAddressFromComponents.
    #>
    static [bool] TryFromComponents([string]$localPart, [string]$domain, [ref]$emailAddress, [string]$displayName = '') {
        return [EmailAddress]::TryParseEmailAddressFromComponents($localPart, $domain, $emailAddress, $displayName)
    }

    #------------------------------------------------------------------
    # Static Methods — Normalization and Comparison
    #------------------------------------------------------------------

    <#
    .SYNOPSIS
        Returns a normalized (trimmed, lowercased) version of a plain address string.

    .DESCRIPTION
        Validates the address first and throws if it is invalid.
        Only the address string is normalized; display names are not affected.

    .PARAMETER address
        The plain email address string to normalize.

    .OUTPUTS
        [string] Normalized address string.
    #>
    static [string] NormalizeEmailAddress([string]$address) {
        if ([EmailAddress]::IsValidEmailAddressFormat($address)) {
            return $address.Trim().ToLowerInvariant()
        } else {
            throw "Cannot normalize invalid email address: '$address'"
        }
    }

    <#
    .SYNOPSIS
        Returns a new EmailAddress with the address portion normalized to lowercase.

    .DESCRIPTION
        Preserves the original display name. If no display name was present,
        returns a plain-address EmailAddress with a lowercased address.
        Throws if the input is $null.

    .PARAMETER emailAddress
        The EmailAddress object to normalize.

    .OUTPUTS
        [EmailAddress] A new EmailAddress instance with a normalized address.
    #>
    static [EmailAddress] NormalizeEmailAddressObject([EmailAddress]$emailAddress) {
        if ($null -eq $emailAddress) {
            throw "Cannot normalize a null EmailAddress object."
        }
        $normalizedAddress = [EmailAddress]::NormalizeEmailAddress($emailAddress.GetAddress())
        $displayName = $emailAddress.GetDisplayName()

        # Only include the display name in the constructor string if one was actually set
        if (-not [string]::IsNullOrEmpty($displayName)) {
            return [EmailAddress]::new("$displayName <$normalizedAddress>")
        } else {
            return [EmailAddress]::new($normalizedAddress)
        }
    }

    <#
    .SYNOPSIS
        Compares two EmailAddress objects by address only, ignoring display name.

    .DESCRIPTION
        Comparison is case-insensitive. Returns $false if either argument is $null.

    .PARAMETER email1
        The first EmailAddress to compare.

    .PARAMETER email2
        The second EmailAddress to compare.

    .OUTPUTS
        [bool] $true if both addresses are equal (case-insensitive), ignoring display names.
    #>
    static [bool] AreEqualIgnoringDisplayName([EmailAddress]$email1, [EmailAddress]$email2) {
        if ($null -eq $email1 -or $null -eq $email2) {
            return $false
        }
        return ($email1.GetAddress().Trim().ToLowerInvariant() -eq $email2.GetAddress().Trim().ToLowerInvariant())
    }

}

#----------------------------------------------------------------------
# Read-only script properties
# Registered via Update-TypeData so they appear as natural properties
# (e.g. $email.Address) while remaining immutable — the setter throws.
#----------------------------------------------------------------------

Update-TypeData -TypeName EmailAddress `
    -MemberName Address `
    -MemberType ScriptProperty `
    -Value { $this._Address } `
    -SecondValue { throw "Address is a read-only property." } `
    -Force

Update-TypeData -TypeName EmailAddress `
    -MemberName DisplayName `
    -MemberType ScriptProperty `
    -Value { $this._DisplayName } `
    -SecondValue { throw "DisplayName is a read-only property." } `
    -Force
