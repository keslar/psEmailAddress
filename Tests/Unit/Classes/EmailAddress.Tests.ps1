BeforeAll {
    # Find the project root by going up three levels from the current script directory
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the EmailAddress class file to make it available for testing
    . $ProjectRoot/source/Classes//EmailAddress.ps1
}

Describe "EmailAddress Class Tests" {

    Context "1 Constructor Tests" {
        It "1.1 Should throw an error if the default constructor is used" {
            { [EmailAddress]::new() } | Should -Throw "*Default constructor is not allowed*"
        }
        It "1.2 Should create an EmailAddress object from a plain address" {
            $email = [EmailAddress]::new("crk4@pitt.edu")
            $email.GetAddress()     | Should -Be "crk4@pitt.edu"
            $email.GetDisplayName() | Should -Be ""
        }
        It "1.3 Should create an EmailAddress object from a named mailbox string" {
            $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
            $email.GetAddress()     | Should -Be "crk4@pitt.edu"
            $email.GetDisplayName() | Should -Be "Chris Keslar"
        }
        It "1.4 Should trim whitespace from a plain address" {
            $email = [EmailAddress]::new("  crk4@pitt.edu  ")
            $email.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "1.5 Should trim whitespace from the display name in a named mailbox string" {
            $email = [EmailAddress]::new("  Chris Keslar  <crk4@pitt.edu>")
            $email.GetDisplayName() | Should -Be "Chris Keslar"
        }
        It "1.6 Should set display name to empty string when bare angle-bracket format is used" {
            $email = [EmailAddress]::new("<crk4@pitt.edu>")
            $email.GetAddress()     | Should -Be "crk4@pitt.edu"
            $email.GetDisplayName() | Should -Be ""
        }
        It "1.7 Should accept a display name containing special characters" {
            $email = [EmailAddress]::new("Keslar, Chris <crk4@pitt.edu>")
            $email.GetDisplayName() | Should -Be "Keslar, Chris"
        }
        It "1.8 Should throw an error for an empty string" {
            { [EmailAddress]::new("") } | Should -Throw
        }
        It "1.9 Should throw an error for whitespace only" {
            { [EmailAddress]::new("   ") } | Should -Throw
        }
        It "1.10 Should throw an error when the @ symbol is missing" {
            { [EmailAddress]::new("notanemail") } | Should -Throw
        }
        It "1.11 Should throw an error when the domain is missing" {
            { [EmailAddress]::new("user@") } | Should -Throw
        }
        It "1.12 Should throw an error when the local part is missing" {
            { [EmailAddress]::new("@pitt.edu") } | Should -Throw
        }
        It "1.13 Should throw an error when multiple @ symbols are present" {
            { [EmailAddress]::new("a@b@pitt.edu") } | Should -Throw
        }
        It "1.14 Should throw an error when a named mailbox contains an invalid address" {
            { [EmailAddress]::new("Chris Keslar <notvalid>") } | Should -Throw
        }
        It "1.15 Should throw an error when the domain has no TLD" {
            { [EmailAddress]::new("user@localdomain") } | Should -Throw
        }
    }

    Context "2 Properties Tests" {
        Context "2.1 Should allow getting but not setting of all properties" {
            BeforeAll {
                $script:propTestEmail = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
            }
            It "2.1.1 Should return correct value for Address property" {
                $script:propTestEmail.Address | Should -Be "crk4@pitt.edu"
            }
            It "2.1.2 Should return correct value for DisplayName property" {
                $script:propTestEmail.DisplayName | Should -Be "Chris Keslar"
            }
            It "2.1.3 Should throw when trying to set Address" {
                { $script:propTestEmail.Address = "other@example.com" } | Should -Throw '*Exception setting "Address"*'
            }
            It "2.1.4 Should throw when trying to set DisplayName" {
                { $script:propTestEmail.DisplayName = "Someone Else" } | Should -Throw '*Exception setting "DisplayName"*'
            }
            It "2.1.5 Should return Address as a string type" {
                $script:propTestEmail.Address | Should -BeOfType [string]
            }
            It "2.1.6 Should return DisplayName as a string type" {
                $script:propTestEmail.DisplayName | Should -BeOfType [string]
            }
        }
    }

    Context "3 Method Tests" {

        Context "3.1 GetAddress Method Tests" {
            It "3.1.1 Should return the address portion from a plain address" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "3.1.2 Should return only the address portion from a named mailbox" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.GetAddress() | Should -Be "crk4@pitt.edu"
            }
        }

        Context "3.2 GetDisplayName Method Tests" {
            It "3.2.1 Should return an empty string when no display name was provided" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetDisplayName() | Should -Be ""
            }
            It "3.2.2 Should return the display name when one was provided" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.GetDisplayName() | Should -Be "Chris Keslar"
            }
        }

        Context "3.3 GetLocalPart Method Tests" {
            It "3.3.1 Should return the portion of the address before the @ symbol" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetLocalPart() | Should -Be "crk4"
            }
            It "3.3.2 Should return the local part from a named mailbox" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.GetLocalPart() | Should -Be "crk4"
            }
            It "3.3.3 Should return a local part that contains a plus sign" {
                $email = [EmailAddress]::new("user+tag@example.com")
                $email.GetLocalPart() | Should -Be "user+tag"
            }
        }

        Context "3.4 GetDomain Method Tests" {
            It "3.4.1 Should return the portion of the address after the @ symbol" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetDomain() | Should -Be "pitt.edu"
            }
            It "3.4.2 Should return the full subdomain chain" {
                $email = [EmailAddress]::new("user@mail.sub.example.co.uk")
                $email.GetDomain() | Should -Be "mail.sub.example.co.uk"
            }
        }

        Context "3.5 ToString Method Tests" {
            It "3.5.1 Should return just the address for a plain address" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.ToString() | Should -Be "crk4@pitt.edu"
            }
            It "3.5.2 Should return just the address even when a display name is present" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.ToString() | Should -Be "crk4@pitt.edu"
            }
            It "3.5.3 Should return just the address when used in PowerShell string interpolation" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                "$email" | Should -Be "crk4@pitt.edu"
            }
        }

        Context "3.6 GetFriendlyName Method Tests" {
            It "3.6.1 Should return just the address when no display name is set" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetFriendlyName() | Should -Be "crk4@pitt.edu"
            }
            It "3.6.2 Should return 'Display Name <address>' when a display name is set" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.GetFriendlyName() | Should -Be "Chris Keslar <crk4@pitt.edu>"
            }
        }

        Context "3.7 FriendlyName, NamedMailbox, and Mailbox Alias Method Tests" {
            BeforeAll {
                $script:aliasEmail = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
            }
            It "3.7.1 FriendlyName should return the same result as GetFriendlyName" {
                $script:aliasEmail.FriendlyName() | Should -Be $script:aliasEmail.GetFriendlyName()
            }
            It "3.7.2 NamedMailbox should return the same result as GetFriendlyName" {
                $script:aliasEmail.NamedMailbox() | Should -Be $script:aliasEmail.GetFriendlyName()
            }
            It "3.7.3 Mailbox should return the same result as GetFriendlyName" {
                $script:aliasEmail.Mailbox() | Should -Be $script:aliasEmail.GetFriendlyName()
            }
        }

        Context "3.8 ToFriendlyString Method Tests" {
            It "3.8.1 Should return the same result as GetFriendlyName" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.ToFriendlyString() | Should -Be $email.GetFriendlyName()
            }
        }

        Context "3.9 ToRFC5322String Method Tests" {
            It "3.9.1 Should return just the address when no display name is set" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.ToRFC5322String() | Should -Be "crk4@pitt.edu"
            }
            It "3.9.2 Should return an unquoted named mailbox when the display name has no special characters" {
                $email = [EmailAddress]::new("ChrisKeslar <crk4@pitt.edu>")
                $email.ToRFC5322String() | Should -Be "ChrisKeslar <crk4@pitt.edu>"
            }
            It "3.9.3 Should quote the display name when it contains a comma" {
                $email = [EmailAddress]::new("Keslar, Chris <crk4@pitt.edu>")
                $email.ToRFC5322String() | Should -Be '"Keslar, Chris" <crk4@pitt.edu>'
            }
            It "3.9.4 Should quote the display name when it contains a space" {
                $email = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $email.ToRFC5322String() | Should -Be '"Chris Keslar" <crk4@pitt.edu>'
            }
            It "3.9.5 Should escape embedded double quotes within the quoted display name" {
                $email = [EmailAddress]::new('Say "Hello" <sh@example.com>')
                $email.ToRFC5322String() | Should -BeLike '"Say \"Hello\"*'
            }
        }

        Context "3.10 Equals Method Tests" {
            BeforeAll {
                $script:emailA = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $script:emailB = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $script:emailC = [EmailAddress]::new("C. Keslar <crk4@pitt.edu>")
                $script:emailD = [EmailAddress]::new("other@pitt.edu")
                $script:emailE = [EmailAddress]::new("Chris Keslar <CRK4@PITT.EDU>")
            }
            It "3.10.1 Should return true for two objects with the same address and display name" {
                $script:emailA.Equals($script:emailB) | Should -Be $true
            }
            It "3.10.2 Should return false when the display names differ" {
                $script:emailA.Equals($script:emailC) | Should -Be $false
            }
            It "3.10.3 Should return false when the addresses differ" {
                $script:emailA.Equals($script:emailD) | Should -Be $false
            }
            It "3.10.4 Should return false when compared to null" {
                $script:emailA.Equals($null) | Should -Be $false
            }
            It "3.10.5 Should return false when compared to a non-EmailAddress object" {
                $script:emailA.Equals("crk4@pitt.edu") | Should -Be $false
            }
            It "3.10.6 Should be case-insensitive for the address" {
                $script:emailA.Equals($script:emailE) | Should -Be $true
            }
        }

        Context "3.11 EqualsIgnoreDisplayName Method Tests" {
            BeforeAll {
                $script:eqA = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $script:eqB = [EmailAddress]::new("C. Keslar <crk4@pitt.edu>")
                $script:eqC = [EmailAddress]::new("other@pitt.edu")
                $script:eqD = [EmailAddress]::new("CRK4@PITT.EDU")
            }
            It "3.11.1 Should return true when addresses match but display names differ" {
                $script:eqA.EqualsIgnoreDisplayName($script:eqB) | Should -Be $true
            }
            It "3.11.2 Should return false when addresses differ" {
                $script:eqA.EqualsIgnoreDisplayName($script:eqC) | Should -Be $false
            }
            It "3.11.3 Should return false when compared to null" {
                $script:eqA.EqualsIgnoreDisplayName($null) | Should -Be $false
            }
            It "3.11.4 Should be case-insensitive" {
                $script:eqA.EqualsIgnoreDisplayName($script:eqD) | Should -Be $true
            }
        }

        Context "3.12 GetHashCode Method Tests" {
            It "3.12.1 Should return the same hash code for two equal objects" {
                $a = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $b = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $a.GetHashCode() | Should -Be $b.GetHashCode()
            }
            It "3.12.2 Should return the same hash code for case-variant addresses" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                $b = [EmailAddress]::new("CRK4@PITT.EDU")
                $a.GetHashCode() | Should -Be $b.GetHashCode()
            }
            It "3.12.3 Should return an integer" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $email.GetHashCode() | Should -BeOfType [int]
            }
            It "3.12.4 Should return different hash codes for clearly different addresses" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                $b = [EmailAddress]::new("other@example.com")
                $a.GetHashCode() | Should -Not -Be $b.GetHashCode()
            }
        }
    }

    Context "4 Static Method Tests" {

        Context "4.1 Static Method Tests - IsValidEmailAddressFormat" {
            It "4.1.1 Should return true for a simple valid address" {
                [EmailAddress]::IsValidEmailAddressFormat("crk4@pitt.edu") | Should -Be $true
            }
            It "4.1.2 Should return true for an address with a dot in the local part" {
                [EmailAddress]::IsValidEmailAddressFormat("user.name@example.com") | Should -Be $true
            }
            It "4.1.3 Should return true for an address with a plus sign in the local part" {
                [EmailAddress]::IsValidEmailAddressFormat("user+tag@example.com") | Should -Be $true
            }
            It "4.1.4 Should return true for an address with subdomains" {
                [EmailAddress]::IsValidEmailAddressFormat("user@mail.sub.example.com") | Should -Be $true
            }
            It "4.1.5 Should return true for an address with a multi-part TLD" {
                [EmailAddress]::IsValidEmailAddressFormat("user@example.co.uk") | Should -Be $true
            }
            It "4.1.6 Should return true for an address with uppercase characters" {
                [EmailAddress]::IsValidEmailAddressFormat("USER@EXAMPLE.COM") | Should -Be $true
            }
            It "4.1.7 Should return false for an empty string" {
                [EmailAddress]::IsValidEmailAddressFormat("") | Should -Be $false
            }
            It "4.1.8 Should return false when the @ symbol is missing" {
                [EmailAddress]::IsValidEmailAddressFormat("noatsign") | Should -Be $false
            }
            It "4.1.9 Should return false when the local part is missing" {
                [EmailAddress]::IsValidEmailAddressFormat("@example.com") | Should -Be $false
            }
            It "4.1.10 Should return false when the domain is missing" {
                [EmailAddress]::IsValidEmailAddressFormat("user@") | Should -Be $false
            }
            It "4.1.11 Should return false for multiple @ symbols" {
                [EmailAddress]::IsValidEmailAddressFormat("a@b@example.com") | Should -Be $false
            }
            It "4.1.12 Should return false when the local part starts with a dot" {
                [EmailAddress]::IsValidEmailAddressFormat(".user@example.com") | Should -Be $false
            }
            It "4.1.13 Should return false when the local part ends with a dot" {
                [EmailAddress]::IsValidEmailAddressFormat("user.@example.com") | Should -Be $false
            }
            It "4.1.14 Should return false when the local part contains consecutive dots" {
                [EmailAddress]::IsValidEmailAddressFormat("us..er@example.com") | Should -Be $false
            }
            It "4.1.15 Should return false when a domain label starts with a hyphen" {
                [EmailAddress]::IsValidEmailAddressFormat("user@-example.com") | Should -Be $false
            }
            It "4.1.16 Should return false when a domain label ends with a hyphen" {
                [EmailAddress]::IsValidEmailAddressFormat("user@example-.com") | Should -Be $false
            }
            It "4.1.17 Should return false when the domain has no TLD" {
                [EmailAddress]::IsValidEmailAddressFormat("user@localdomain") | Should -Be $false
            }
            It "4.1.18 Should return false when the TLD is only one character" {
                [EmailAddress]::IsValidEmailAddressFormat("user@example.c") | Should -Be $false
            }
            It "4.1.19 Should return false when the local part exceeds 64 characters" {
                $localPart = "a" * 65
                [EmailAddress]::IsValidEmailAddressFormat("$localPart@example.com") | Should -Be $false
            }
            It "4.1.20 Should return true when the local part is exactly 64 characters" {
                $localPart = "a" * 64
                [EmailAddress]::IsValidEmailAddressFormat("$localPart@example.com") | Should -Be $true
            }
        }

        Context "4.2 Static Method Tests - IsValidFormat, IsValidEmailAddress, IsValid (aliases)" {
            It "4.2.1 IsValidFormat should return true for a valid address" {
                [EmailAddress]::IsValidFormat("crk4@pitt.edu") | Should -Be $true
            }
            It "4.2.2 IsValidFormat should return false for an invalid address" {
                [EmailAddress]::IsValidFormat("notvalid") | Should -Be $false
            }
            It "4.2.3 IsValidEmailAddress should return true for a valid address" {
                [EmailAddress]::IsValidEmailAddress("crk4@pitt.edu") | Should -Be $true
            }
            It "4.2.4 IsValidEmailAddress should return false for an invalid address" {
                [EmailAddress]::IsValidEmailAddress("notvalid") | Should -Be $false
            }
            It "4.2.5 IsValid should return true for a valid EmailAddress object" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                [EmailAddress]::IsValid($email) | Should -Be $true
            }
            It "4.2.6 IsValid should return false for a null argument" {
                [EmailAddress]::IsValid($null) | Should -Be $false
            }
        }

        Context "4.3 Static Method Tests - FromString and GetEmailAddressFromString" {
            It "4.3.1 Should create an EmailAddress object from a valid plain address" {
                $email = [EmailAddress]::FromString("crk4@pitt.edu")
                ($email -is [EmailAddress]) | Should -Be $true
                $email.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "4.3.2 Should create an EmailAddress object from a valid named mailbox string" {
                $email = [EmailAddress]::GetEmailAddressFromString("Chris Keslar <crk4@pitt.edu>")
                $email.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "4.3.3 Should throw for an invalid address" {
                { [EmailAddress]::FromString("bad-address") } | Should -Throw "*bad-address*"
            }
            It "4.3.4 FromString and GetEmailAddressFromString should produce equivalent objects" {
                $a = [EmailAddress]::FromString("crk4@pitt.edu")
                $b = [EmailAddress]::GetEmailAddressFromString("crk4@pitt.edu")
                $a.Equals($b) | Should -Be $true
            }
        }

        Context "4.4 Static Method Tests - TryFromString and TryParseEmailAddressFromString" {
            It "4.4.1 Should return true and populate the ref variable for a valid address" {
                $result = $null
                $ok = [EmailAddress]::TryFromString("crk4@pitt.edu", [ref]$result)
                $ok                  | Should -Be $true
                $result              | Should -Not -BeNullOrEmpty
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "4.4.2 Should return false and set the ref variable to null for an invalid address" {
                $result = "should be cleared"
                $ok = [EmailAddress]::TryFromString("not-valid", [ref]$result)
                $ok     | Should -Be $false
                $result | Should -BeNullOrEmpty
            }
            It "4.4.3 TryFromString and TryParseEmailAddressFromString should behave identically" {
                $r1 = $null
                $r2 = $null
                $ok1 = [EmailAddress]::TryFromString("crk4@pitt.edu", [ref]$r1)
                $ok2 = [EmailAddress]::TryParseEmailAddressFromString("crk4@pitt.edu", [ref]$r2)
                $ok1             | Should -Be $ok2
                $r1.GetAddress() | Should -Be $r2.GetAddress()
            }
        }

        Context "4.5 Static Method Tests - FromComponents and GetEmailAddressFromComponents" {
            It "4.5.1 Should create an EmailAddress from local part and domain with no display name" {
                # PowerShell class methods do not support optional parameter overloads;
                # the displayName argument must always be supplied explicitly.
                $email = [EmailAddress]::FromComponents("crk4", "pitt.edu", "")
                $email.GetAddress()     | Should -Be "crk4@pitt.edu"
                $email.GetDisplayName() | Should -Be ""
            }
            It "4.5.2 Should create an EmailAddress with a display name when one is supplied" {
                $email = [EmailAddress]::FromComponents("crk4", "pitt.edu", "Chris Keslar")
                $email.GetAddress()     | Should -Be "crk4@pitt.edu"
                $email.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "4.5.3 Should throw when the local part is empty" {
                { [EmailAddress]::FromComponents("", "pitt.edu", "") } | Should -Throw
            }
            It "4.5.4 Should throw when the domain is empty" {
                { [EmailAddress]::FromComponents("crk4", "", "") } | Should -Throw
            }
            It "4.5.5 FromComponents and GetEmailAddressFromComponents should produce equivalent objects" {
                $a = [EmailAddress]::FromComponents("crk4", "pitt.edu", "Chris Keslar")
                $b = [EmailAddress]::GetEmailAddressFromComponents("crk4", "pitt.edu", "Chris Keslar")
                $a.Equals($b) | Should -Be $true
            }
        }

        Context "4.6 Static Method Tests - TryFromComponents and TryParseEmailAddressFromComponents" {
            It "4.6.1 Should return true and populate the ref variable on success" {
                $result = $null
                # displayName must be supplied explicitly; PowerShell class methods do not support optional parameter overloads.
                $ok = [EmailAddress]::TryFromComponents("crk4", "pitt.edu", [ref]$result, "")
                $ok                  | Should -Be $true
                $result              | Should -Not -BeNullOrEmpty
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "4.6.2 Should set the display name on the result when one is supplied" {
                $result = $null
                [EmailAddress]::TryFromComponents("crk4", "pitt.edu", [ref]$result, "Chris Keslar")
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "4.6.3 Should return false and null the ref variable when the local part is empty" {
                $result = "placeholder"
                $ok = [EmailAddress]::TryFromComponents("", "pitt.edu", [ref]$result, "")
                $ok     | Should -Be $false
                $result | Should -BeNullOrEmpty
            }
            It "4.6.4 TryFromComponents and TryParseEmailAddressFromComponents should behave identically" {
                $r1 = $null
                $r2 = $null
                $ok1 = [EmailAddress]::TryFromComponents("crk4", "pitt.edu", [ref]$r1, "")
                $ok2 = [EmailAddress]::TryParseEmailAddressFromComponents("crk4", "pitt.edu", [ref]$r2, "")
                $ok1             | Should -Be $ok2
                $r1.GetAddress() | Should -Be $r2.GetAddress()
            }
        }

        Context "4.7 Static Method Tests - NormalizeEmailAddress" {
            It "4.7.1 Should lowercase a mixed-case address" {
                [EmailAddress]::NormalizeEmailAddress("CRK4@PITT.EDU") | Should -Be "crk4@pitt.edu"
            }
            It "4.7.2 Should throw for an address with surrounding whitespace" {
                # NormalizeEmailAddress validates before trimming; a padded string fails
                # validation and throws. Trim the address before calling if needed.
                { [EmailAddress]::NormalizeEmailAddress("  crk4@pitt.edu  ") } | Should -Throw
            }
            It "4.7.3 Should return an already-lowercase address unchanged" {
                [EmailAddress]::NormalizeEmailAddress("crk4@pitt.edu") | Should -Be "crk4@pitt.edu"
            }
            It "4.7.4 Should throw for an invalid address" {
                { [EmailAddress]::NormalizeEmailAddress("not-valid") } | Should -Throw
            }
        }

        Context "4.8 Static Method Tests - NormalizeEmailAddressObject" {
            It "4.8.1 Should lowercase the address portion and return a new object" {
                $email = [EmailAddress]::new("CRK4@PITT.EDU")
                $result = [EmailAddress]::NormalizeEmailAddressObject($email)
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "4.8.2 Should preserve the display name" {
                $email = [EmailAddress]::new("Chris Keslar <CRK4@PITT.EDU>")
                $result = [EmailAddress]::NormalizeEmailAddressObject($email)
                $result.GetDisplayName() | Should -Be "Chris Keslar"
                $result.GetAddress()     | Should -Be "crk4@pitt.edu"
            }
            It "4.8.3 Should return an object with no display name when the original had none" {
                $email = [EmailAddress]::new("CRK4@PITT.EDU")
                $result = [EmailAddress]::NormalizeEmailAddressObject($email)
                $result.GetDisplayName() | Should -Be ""
            }
            It "4.8.4 Should return a new object and not the same reference" {
                $email = [EmailAddress]::new("crk4@pitt.edu")
                $result = [EmailAddress]::NormalizeEmailAddressObject($email)
                [object]::ReferenceEquals($email, $result) | Should -Be $false
            }
            It "4.8.5 Should throw for a null argument" {
                { [EmailAddress]::NormalizeEmailAddressObject($null) } | Should -Throw
            }
        }

        Context "4.9 Static Method Tests - AreEqualIgnoringDisplayName" {
            It "4.9.1 Should return true when both addresses are identical" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                $b = [EmailAddress]::new("crk4@pitt.edu")
                [EmailAddress]::AreEqualIgnoringDisplayName($a, $b) | Should -Be $true
            }
            It "4.9.2 Should return true when addresses match but display names differ" {
                $a = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
                $b = [EmailAddress]::new("C. Keslar <crk4@pitt.edu>")
                [EmailAddress]::AreEqualIgnoringDisplayName($a, $b) | Should -Be $true
            }
            It "4.9.3 Should be case-insensitive" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                $b = [EmailAddress]::new("CRK4@PITT.EDU")
                [EmailAddress]::AreEqualIgnoringDisplayName($a, $b) | Should -Be $true
            }
            It "4.9.4 Should return false when addresses differ" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                $b = [EmailAddress]::new("other@pitt.edu")
                [EmailAddress]::AreEqualIgnoringDisplayName($a, $b) | Should -Be $false
            }
            It "4.9.5 Should return false when the first argument is null" {
                $b = [EmailAddress]::new("crk4@pitt.edu")
                [EmailAddress]::AreEqualIgnoringDisplayName($null, $b) | Should -Be $false
            }
            It "4.9.6 Should return false when the second argument is null" {
                $a = [EmailAddress]::new("crk4@pitt.edu")
                [EmailAddress]::AreEqualIgnoringDisplayName($a, $null) | Should -Be $false
            }
            It "4.9.7 Should return false when both arguments are null" {
                [EmailAddress]::AreEqualIgnoringDisplayName($null, $null) | Should -Be $false
            }
        }
    }
}
