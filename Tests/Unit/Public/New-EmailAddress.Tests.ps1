BeforeAll {
    # Find the project root by going up four levels from the current script directory
    # Tests\Unit\Public\ -> Tests\Unit\ -> Tests\ -> ProjectRoot\
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/Source/prefix.ps1

    # Dot-source the EmailAddress class — required before the cmdlet can be loaded
    . $ProjectRoot/Source/Classes/EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1
}

Describe "New-EmailAddress Cmdlet Tests" {

    Context "1 Parameter Set - FromString" {

        Context "1.1 Valid Input" {
            It "1.1.1 Should return an EmailAddress object from a plain address" {
                $result = New-EmailAddress -Address "crk4@pitt.edu"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.1.2 Should set the correct address from a plain address string" {
                $result = New-EmailAddress -Address "crk4@pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.3 Should set the display name to empty string from a plain address string" {
                $result = New-EmailAddress -Address "crk4@pitt.edu"
                $result.GetDisplayName() | Should -Be ""
            }
            It "1.1.4 Should return an EmailAddress object from a named mailbox string" {
                $result = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.1.5 Should parse the address correctly from a named mailbox string" {
                $result = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.6 Should parse the display name correctly from a named mailbox string" {
                $result = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.1.7 Should accept the address as a positional parameter" {
                $result = New-EmailAddress "crk4@pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.8 Should accept a display name with special characters" {
                $result = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"
                $result.GetDisplayName() | Should -Be "Keslar, Chris"
            }
            It "1.1.9 Should accept an address with a plus sign in the local part" {
                $result = New-EmailAddress -Address "user+tag@example.com"
                $result.GetAddress() | Should -Be "user+tag@example.com"
            }
            It "1.1.10 Should accept an address with subdomains" {
                $result = New-EmailAddress -Address "user@mail.sub.example.com"
                $result.GetAddress() | Should -Be "user@mail.sub.example.com"
            }
        }

        Context "1.2 Invalid Input" {
            It "1.2.1 Should throw a terminating error for an empty string" {
                { New-EmailAddress -Address "" } | Should -Throw
            }
            It "1.2.2 Should throw a terminating error when the @ symbol is missing" {
                { New-EmailAddress -Address "notanemail" } | Should -Throw
            }
            It "1.2.3 Should throw a terminating error when the domain is missing" {
                { New-EmailAddress -Address "user@" } | Should -Throw
            }
            It "1.2.4 Should throw a terminating error when the local part is missing" {
                { New-EmailAddress -Address "@pitt.edu" } | Should -Throw
            }
            It "1.2.5 Should throw a terminating error when the domain has no TLD" {
                { New-EmailAddress -Address "user@localdomain" } | Should -Throw
            }
            It "1.2.6 Should throw a terminating error for a named mailbox with an invalid address" {
                { New-EmailAddress -Address "Chris Keslar <notvalid>" } | Should -Throw
            }
        }

        Context "1.3 Pipeline Input" {
            It "1.3.1 Should accept a single address from the pipeline" {
                $result = "crk4@pitt.edu" | New-EmailAddress
                ($result -is [EmailAddress]) | Should -Be $true
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.3.2 Should accept multiple addresses from the pipeline and return one object per input" {
                $results = "crk4@pitt.edu", "jdoe@example.com" | New-EmailAddress
                $results.Count           | Should -Be 2
                $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
                $results[1].GetAddress() | Should -Be "jdoe@example.com"
            }
            It "1.3.3 Should accept named mailbox strings from the pipeline" {
                $result = "Chris Keslar <crk4@pitt.edu>" | New-EmailAddress
                $result.GetAddress()     | Should -Be "crk4@pitt.edu"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.3.4 Should produce EmailAddress objects that preserve input order" {
                $inputs = "a@example.com", "b@example.com", "c@example.com"
                $results = $inputs | New-EmailAddress
                $results[0].GetAddress() | Should -Be "a@example.com"
                $results[1].GetAddress() | Should -Be "b@example.com"
                $results[2].GetAddress() | Should -Be "c@example.com"
            }
            It "1.3.5 Should throw a terminating error when an invalid address is encountered in the pipeline" {
                { "crk4@pitt.edu", "notvalid", "jdoe@example.com" | New-EmailAddress } | Should -Throw
            }
        }
    }

    Context "2 Parameter Set - FromComponents" {

        Context "2.1 Valid Input" {
            It "2.1.1 Should return an EmailAddress object from local part and domain" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "2.1.2 Should assemble the correct address from local part and domain" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.1.3 Should set display name to empty string when DisplayName is not supplied" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"
                $result.GetDisplayName() | Should -Be ""
            }
            It "2.1.4 Should set the display name when DisplayName is supplied" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "2.1.5 Should return an EmailAddress object when all three parameters are supplied" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "2.1.6 Should accept local part as a positional parameter when Domain is named" {
                # Position 0 is shared by -Address (FromString) and -LocalPart (FromComponents).
                # Supplying -Domain by name unambiguously selects the FromComponents set,
                # allowing -LocalPart to be supplied positionally.
                $result = New-EmailAddress "crk4" -Domain "pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.1.7 Should accept all three components when Domain is named and the rest are positional" {
                $result = New-EmailAddress "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"
                $result.GetAddress()     | Should -Be "crk4@pitt.edu"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "2.1.8 Should accept a display name containing special characters" {
                $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Keslar, Chris"
                $result.GetDisplayName() | Should -Be "Keslar, Chris"
            }
            It "2.1.9 Should accept a subdomain as the domain parameter" {
                $result = New-EmailAddress -LocalPart "user" -Domain "mail.sub.example.com"
                $result.GetDomain() | Should -Be "mail.sub.example.com"
            }
        }

        Context "2.2 Invalid Input" {
            It "2.2.1 Should throw a terminating error when the local part is empty" {
                { New-EmailAddress -LocalPart "" -Domain "pitt.edu" } | Should -Throw
            }
            It "2.2.2 Should throw a terminating error when the domain is empty" {
                { New-EmailAddress -LocalPart "crk4" -Domain "" } | Should -Throw
            }
            It "2.2.3 Should throw a terminating error when the local part contains invalid characters" {
                { New-EmailAddress -LocalPart "bad local" -Domain "pitt.edu" } | Should -Throw
            }
            It "2.2.4 Should throw a terminating error when the domain has no TLD" {
                { New-EmailAddress -LocalPart "crk4" -Domain "localdomain" } | Should -Throw
            }
            It "2.2.5 Should throw a terminating error when the domain label starts with a hyphen" {
                { New-EmailAddress -LocalPart "crk4" -Domain "-pitt.edu" } | Should -Throw
            }
        }
    }

    Context "3 Output Type and Structure" {
        It "3.1 Should return an object of type EmailAddress" {
            $result = New-EmailAddress -Address "crk4@pitt.edu"
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "3.2 Should expose the Address script property" {
            $result = New-EmailAddress -Address "crk4@pitt.edu"
            $result.Address | Should -Be "crk4@pitt.edu"
        }
        It "3.3 Should expose the DisplayName script property" {
            $result = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
            $result.DisplayName | Should -Be "Chris Keslar"
        }
        It "3.4 Should return a single object, not an array, for a single input" {
            $result = New-EmailAddress -Address "crk4@pitt.edu"
            ($result -is [System.Array]) | Should -Be $false
        }
        It "3.5 FromString and FromComponents should produce equivalent objects for the same address" {
            $fromString = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
            $fromComponents = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu" -DisplayName "Chris Keslar"
            $fromString.Equals($fromComponents) | Should -Be $true
        }
    }

    Context "4 Default Parameter Set" {
        It "4.1 Should use FromString as the default parameter set" {
            $result = New-EmailAddress "crk4@pitt.edu"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "4.2 Should use FromComponents when LocalPart and Domain are supplied explicitly" {
            # Two bare positional strings are ambiguous at the default parameter set boundary;
            # at least one named parameter from the FromComponents set must be used to
            # select it unambiguously.
            $result = New-EmailAddress -LocalPart "crk4" -Domain "pitt.edu"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
    }
}
