BeforeAll {
    # Find the project root by going up three levels from the current script directory
    # Tests\Unit\Private\ -> Tests\Unit\ -> Tests\ -> ProjectRoot\
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/Source/prefix.ps1

    # Dot-source the EmailAddress class — required before the function can be loaded
    . $ProjectRoot/Source/Classes/EmailAddress.ps1

    # Dot-source the private function under test
    . $ProjectRoot/Source/Private/Resolve-EmailAddressInput.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Pre-built EmailAddress objects for pass-through tests
    $script:plainEmail = [EmailAddress]::new("crk4@pitt.edu")
    $script:namedEmail = [EmailAddress]::new("Chris Keslar <crk4@pitt.edu>")
}

Describe "Resolve-EmailAddressInput Private Function Tests" {

    Context "1 EmailAddress Object Input" {
        It "1.1 Should return the same EmailAddress object when given an EmailAddress" {
            $result = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress"
            ($result -is [EmailAddress]) | Should -Be $true
        }
        It "1.2 Should return the identical object reference when given an EmailAddress" {
            $result = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress"
            [object]::ReferenceEquals($result, $script:plainEmail) | Should -Be $true
        }
        It "1.3 Should return the correct address from a plain EmailAddress object" {
            $result = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "1.4 Should return the correct address from a named mailbox EmailAddress object" {
            $result = Resolve-EmailAddressInput -InputValue $script:namedEmail -ParameterName "ReferenceAddress"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "1.5 Should preserve the display name from a named mailbox EmailAddress object" {
            $result = Resolve-EmailAddressInput -InputValue $script:namedEmail -ParameterName "ReferenceAddress"
            $result.GetDisplayName() | Should -Be "Chris Keslar"
        }
        It "1.6 Should not throw when given a valid EmailAddress object" {
            { Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress" } | Should -Not -Throw
        }
    }

    Context "2 Plain Address String Input" {
        It "2.1 Should return an EmailAddress object from a plain address string" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            ($result -is [EmailAddress]) | Should -Be $true
        }
        It "2.2 Should set the correct address from a plain address string" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "2.3 Should set the display name to empty string from a plain address string" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            $result.GetDisplayName() | Should -Be ""
        }
        It "2.4 Should not throw when given a valid plain address string" {
            { Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress" } | Should -Not -Throw
        }
    }

    Context "3 Named Mailbox String Input" {
        It "3.1 Should return an EmailAddress object from a named mailbox string" {
            $result = Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
            ($result -is [EmailAddress]) | Should -Be $true
        }
        It "3.2 Should parse the address correctly from a named mailbox string" {
            $result = Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "3.3 Should parse the display name correctly from a named mailbox string" {
            $result = Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
            $result.GetDisplayName() | Should -Be "Chris Keslar"
        }
        It "3.4 Should handle a display name containing special characters" {
            $result = Resolve-EmailAddressInput -InputValue "Keslar, Chris <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
            $result.GetDisplayName() | Should -Be "Keslar, Chris"
        }
        It "3.5 Should not throw when given a valid named mailbox string" {
            { Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress" } | Should -Not -Throw
        }
    }

    Context "4 Invalid Input - Terminating Error Behaviour" {
        It "4.1 Should throw for a string missing the @ symbol" {
            { Resolve-EmailAddressInput -InputValue "notanemail" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.2 Should throw for a string with a missing domain" {
            { Resolve-EmailAddressInput -InputValue "user@" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.3 Should throw for a string with a missing local part" {
            { Resolve-EmailAddressInput -InputValue "@pitt.edu" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.4 Should throw for an empty string" {
            { Resolve-EmailAddressInput -InputValue "" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.5 Should throw for a domain with no TLD" {
            { Resolve-EmailAddressInput -InputValue "user@localdomain" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.6 Should throw for a named mailbox string containing an invalid address" {
            { Resolve-EmailAddressInput -InputValue "Chris Keslar <notvalid>" -ParameterName "ReferenceAddress" } | Should -Throw
        }
        It "4.7 Should include the ParameterName in the error message when throwing" {
            $errorMessage = $null
            try {
                Resolve-EmailAddressInput -InputValue "notanemail" -ParameterName "ReferenceAddress"
            } catch {
                $errorMessage = $_.Exception.Message
            }
            $errorMessage | Should -BeLike "*ReferenceAddress*"
        }
        It "4.8 Should include the invalid input value in the error message when throwing" {
            $errorMessage = $null
            try {
                Resolve-EmailAddressInput -InputValue "notanemail" -ParameterName "ReferenceAddress"
            } catch {
                $errorMessage = $_.Exception.Message
            }
            $errorMessage | Should -BeLike "*notanemail*"
        }
        It "4.9 Should use the correct ParameterName in the error message for different parameter names" {
            $errorMessage = $null
            try {
                Resolve-EmailAddressInput -InputValue "notanemail" -ParameterName "DifferenceAddress"
            } catch {
                $errorMessage = $_.Exception.Message
            }
            $errorMessage | Should -BeLike "*DifferenceAddress*"
        }
    }

    Context "5 ParameterName Has No Effect on Successful Resolution" {
        It "5.1 Should return the same result regardless of the ParameterName value for a valid string" {
            $resultA = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            $resultB = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "DifferenceAddress"
            $resultA.GetAddress() | Should -Be $resultB.GetAddress()
        }
        It "5.2 Should return the same result regardless of the ParameterName value for a valid EmailAddress object" {
            $resultA = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress"
            $resultB = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "DifferenceAddress"
            $resultA.GetAddress() | Should -Be $resultB.GetAddress()
        }
    }

    Context "6 Output Type and Structure" {
        It "6.1 Should return an object of type EmailAddress from a string input" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "6.2 Should return an object of type EmailAddress from an EmailAddress input" {
            $result = Resolve-EmailAddressInput -InputValue $script:plainEmail -ParameterName "ReferenceAddress"
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "6.3 Should return a single object, not an array, for a single input" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            ($result -is [System.Array]) | Should -Be $false
        }
        It "6.4 Should expose the Address script property on the returned object" {
            $result = Resolve-EmailAddressInput -InputValue "crk4@pitt.edu" -ParameterName "ReferenceAddress"
            $result.Address | Should -Be "crk4@pitt.edu"
        }
        It "6.5 Should expose the DisplayName script property on the returned object" {
            $result = Resolve-EmailAddressInput -InputValue "Chris Keslar <crk4@pitt.edu>" -ParameterName "ReferenceAddress"
            $result.DisplayName | Should -Be "Chris Keslar"
        }
    }
}
