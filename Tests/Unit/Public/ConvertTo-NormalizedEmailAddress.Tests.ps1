BeforeAll {
    # Find the project root by going up three levels from the current script directory
    # Tests\Unit\Public\ -> Tests\Unit\ -> Tests\ -> ProjectRoot\
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/Source/prefix.ps1

    # Dot-source the EmailAddress class — required before the cmdlet can be loaded
    . $ProjectRoot/Source/Classes/EmailAddress.ps1

    # Dot-source Resolve-EmailAddressInput.ps1 
    . $ProjectRoot/Source/Private/Resolve-EmailAddressInput.ps1

    # Dot-source New-EmailAddress — used to build test fixtures and for comparison tests
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/ConvertTo-NormalizedEmailAddress.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Uppercase plain address — needs normalization
    $script:upper = New-EmailAddress -Address "CRK4@PITT.EDU"

    # Already-lowercase plain address — normalization is a no-op
    $script:lower = New-EmailAddress -Address "crk4@pitt.edu"

    # Mixed-case named mailbox — address needs normalization, display name must be preserved
    $script:namedUpper = New-EmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"

    # Already-normalized named mailbox
    $script:namedLower = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
}

Describe "ConvertTo-NormalizedEmailAddress Cmdlet Tests" {

    Context "1 Parameter Set - FromEmailAddress" {

        Context "1.1 Address Normalization" {
            It "1.1.1 Should return an EmailAddress object" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.1.2 Should lowercase an uppercase address" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.3 Should return the same address when input is already lowercase" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:lower
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.4 Should lowercase a mixed-case address" {
                $mixed = New-EmailAddress -Address "CrK4@PiTt.EdU"
                $result = ConvertTo-NormalizedEmailAddress -InputObject $mixed
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.5 Should normalize both local part and domain to lowercase" {
                $email = New-EmailAddress -Address "USER@EXAMPLE.COM"
                $result = ConvertTo-NormalizedEmailAddress -InputObject $email
                $result.GetAddress() | Should -Be "user@example.com"
            }
        }

        Context "1.2 Display Name Preservation" {
            It "1.2.1 Should preserve the display name when one is present" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:namedUpper
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.2.2 Should not alter the display name casing" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:namedUpper
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.2.3 Should set display name to empty string when no display name was present" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
                $result.GetDisplayName() | Should -Be ""
            }
            It "1.2.4 Should preserve a display name containing special characters" {
                $email = New-EmailAddress -Address "Keslar, Chris <CRK4@PITT.EDU>"
                $result = ConvertTo-NormalizedEmailAddress -InputObject $email
                $result.GetDisplayName() | Should -Be "Keslar, Chris"
                $result.GetAddress()     | Should -Be "crk4@pitt.edu"
            }
        }

        Context "1.3 Immutability" {
            It "1.3.1 Should return a new object, not the same reference" {
                $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
                [object]::ReferenceEquals($script:upper, $result) | Should -Be $false
            }
            It "1.3.2 Should not modify the original object's address" {
                $before = $script:upper.GetAddress()
                ConvertTo-NormalizedEmailAddress -InputObject $script:upper | Out-Null
                $script:upper.GetAddress() | Should -Be $before
            }
        }
    }

    Context "2 Parameter Set - FromString" {

        Context "2.1 Valid Plain Address Strings" {
            It "2.1.1 Should return an EmailAddress object from an uppercase address string" {
                $result = ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "2.1.2 Should normalize an uppercase plain address string to lowercase" {
                $result = ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.1.3 Should normalize a mixed-case plain address string" {
                $result = ConvertTo-NormalizedEmailAddress -Address "CrK4@PiTt.EdU"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.1.4 Should return the same address when the string is already lowercase" {
                $result = ConvertTo-NormalizedEmailAddress -Address "crk4@pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
        }

        Context "2.2 Valid Named Mailbox Strings" {
            It "2.2.1 Should normalize the address portion of a named mailbox string" {
                $result = ConvertTo-NormalizedEmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.2.2 Should preserve the display name from a named mailbox string" {
                $result = ConvertTo-NormalizedEmailAddress -Address "Chris Keslar <CRK4@PITT.EDU>"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
        }

        Context "2.3 Invalid String Input" {
            It "2.3.1 Should not throw for an invalid address string" {
                { ConvertTo-NormalizedEmailAddress -Address "notanemail" -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
            It "2.3.2 Should produce no output for an invalid address string" {
                $result = ConvertTo-NormalizedEmailAddress -Address "notanemail" -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
            }
            #It "2.3.3 Should write a non-terminating error for an invalid address string" {
            #    $errs = ConvertTo-NormalizedEmailAddress -Address "notanemail" 2>&1 |
            #        Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            #    $errs.Count | Should -BeGreaterThan 0
            #}
            It "2.3.4 Should throw a terminating error when -ErrorAction Stop is used" {
                { ConvertTo-NormalizedEmailAddress -Address "notanemail" -ErrorAction Stop } | Should -Throw
            }
            It "2.3.5 Should skip invalid strings and return valid ones in a mixed batch" {
                $results = ConvertTo-NormalizedEmailAddress `
                    -Address "CRK4@PITT.EDU", "notvalid", "JDOE@EXAMPLE.COM" `
                    -ErrorAction SilentlyContinue
                $results.Count           | Should -Be 2
                $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
                $results[1].GetAddress() | Should -Be "jdoe@example.com"
            }
        }
    }

    Context "3 Pipeline Input" {

        Context "3.1 EmailAddress Objects via Pipeline" {
            It "3.1.1 Should accept a single EmailAddress object from the pipeline" {
                $result = $script:upper | ConvertTo-NormalizedEmailAddress
                ($result -is [EmailAddress]) | Should -Be $true
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "3.1.2 Should normalize multiple EmailAddress objects from the pipeline" {
                $results = @($script:upper, $script:namedUpper) | ConvertTo-NormalizedEmailAddress
                $results.Count           | Should -Be 2
                $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
                $results[1].GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "3.1.3 Should preserve input order across the pipeline" {
                $a = New-EmailAddress -Address "C@EXAMPLE.COM"
                $b = New-EmailAddress -Address "B@EXAMPLE.COM"
                $c = New-EmailAddress -Address "A@EXAMPLE.COM"
                $results = @($a, $b, $c) | ConvertTo-NormalizedEmailAddress
                $results[0].GetAddress() | Should -Be "c@example.com"
                $results[1].GetAddress() | Should -Be "b@example.com"
                $results[2].GetAddress() | Should -Be "a@example.com"
            }
        }

        Context "3.2 Address Strings via Pipeline" {
            It "3.2.1 Should accept a single address string via the -Address parameter" {
                $result = ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"
                ($result -is [EmailAddress]) | Should -Be $true
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "3.2.2 Should normalize multiple address strings supplied to -Address" {
                $results = ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU", "JDOE@EXAMPLE.COM"
                $results.Count           | Should -Be 2
                $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
                $results[1].GetAddress() | Should -Be "jdoe@example.com"
            }
            It "3.2.3 Should skip invalid strings in a batch and return only valid results" {
                $results = ConvertTo-NormalizedEmailAddress `
                    -Address "CRK4@PITT.EDU", "notvalid", "JDOE@EXAMPLE.COM" `
                    -ErrorAction SilentlyContinue
                $results.Count           | Should -Be 2
                $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
                $results[1].GetAddress() | Should -Be "jdoe@example.com"
            }
            #It "3.2.4 Should write one non-terminating error per invalid string in a batch" {
            #    $errs = ConvertTo-NormalizedEmailAddress `
            #        -Address "CRK4@PITT.EDU", "bad1", "bad2", "JDOE@EXAMPLE.COM" 2>&1 |
            #        Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            #    $errs.Count | Should -Be 2
            #}
        }
    }

    Context "4 Output Type and Structure" {
        It "4.1 Should return an object of type EmailAddress" {
            $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "4.2 Should expose the normalized address via the Address script property" {
            $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            $result.Address | Should -Be "crk4@pitt.edu"
        }
        It "4.3 Should expose the display name via the DisplayName script property" {
            $result = ConvertTo-NormalizedEmailAddress -InputObject $script:namedUpper
            $result.DisplayName | Should -Be "Chris Keslar"
        }
        It "4.4 Should return a single object, not an array, for a single input" {
            $result = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            ($result -is [System.Array]) | Should -Be $false
        }
    }

    Context "5 Normalization Is Idempotent" {
        It "5.1 Should produce the same result when applied twice to an EmailAddress object" {
            $once = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            $twice = ConvertTo-NormalizedEmailAddress -InputObject $once
            $once.GetAddress() | Should -Be $twice.GetAddress()
        }
        It "5.2 Should produce the same result when applied twice to an address string" {
            $once = ConvertTo-NormalizedEmailAddress -Address "CRK4@PITT.EDU"
            $twice = ConvertTo-NormalizedEmailAddress -InputObject $once
            $once.GetAddress() | Should -Be $twice.GetAddress()
        }
        It "5.3 Normalized output should equal a directly-constructed lowercase object" {
            $normalized = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            $constructed = New-EmailAddress -Address "crk4@pitt.edu"
            $normalized.GetAddress() | Should -Be $constructed.GetAddress()
        }
    }

    Context "6 Comparison with New-EmailAddress" {
        It "6.1 Should produce an equivalent object to New-EmailAddress for the same lowercase address" {
            $normalized = ConvertTo-NormalizedEmailAddress -InputObject $script:upper
            $direct = New-EmailAddress -Address "crk4@pitt.edu"
            $normalized.Equals($direct) | Should -Be $true
        }
        It "6.2 Should produce an equivalent object to a lowercase-constructed named mailbox" {
            $normalized = ConvertTo-NormalizedEmailAddress -InputObject $script:namedUpper
            $direct = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
            $normalized.Equals($direct) | Should -Be $true
        }
    }
}
