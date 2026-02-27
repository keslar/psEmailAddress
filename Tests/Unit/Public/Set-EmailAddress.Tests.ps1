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

    # Dot-source New-EmailAddress — used to build test fixtures
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/Set-EmailAddress.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Plain address — no display name
    $script:plain = New-EmailAddress -Address "crk4@pitt.edu"

    # Named mailbox
    $script:named = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
}

Describe "Set-EmailAddress Cmdlet Tests" {

    Context "1 Parameter Set - SetAddress" {

        Context "1.1 Plain Address Input" {
            It "1.1.1 Should return an EmailAddress object" {
                $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.1.2 Should replace the address when no display name is present" {
                $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
                $result.GetAddress() | Should -Be "jdoe@example.com"
            }
            It "1.1.3 Should set display name to empty string when original had none" {
                $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
                $result.GetDisplayName() | Should -Be ""
            }
        }

        Context "1.2 Named Mailbox Input" {
            It "1.2.1 Should replace the address and preserve the display name" {
                $result = Set-EmailAddress -InputObject $script:named -Address "jdoe@example.com"
                $result.GetAddress()     | Should -Be "jdoe@example.com"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.2.2 Should not modify the display name" {
                $result = Set-EmailAddress -InputObject $script:named -Address "jdoe@example.com"
                $result.GetDisplayName() | Should -Be $script:named.GetDisplayName()
            }
        }

        Context "1.3 Invalid Replacement" {
            It "1.3.1 Should throw for an invalid replacement address string" {
                { Set-EmailAddress -InputObject $script:plain -Address "notvalid" } | Should -Throw
            }
            It "1.3.2 Should throw when the replacement address has no domain" {
                { Set-EmailAddress -InputObject $script:plain -Address "user@" } | Should -Throw
            }
            It "1.3.3 Should throw when the replacement address has no local part" {
                { Set-EmailAddress -InputObject $script:plain -Address "@example.com" } | Should -Throw
            }
        }
    }

    Context "2 Parameter Set - SetDisplayName" {

        Context "2.1 Adding a Display Name" {
            It "2.1.1 Should return an EmailAddress object" {
                $result = Set-EmailAddress -InputObject $script:plain -DisplayName "Chris Keslar"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "2.1.2 Should set the new display name" {
                $result = Set-EmailAddress -InputObject $script:plain -DisplayName "Chris Keslar"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "2.1.3 Should preserve the original address" {
                $result = Set-EmailAddress -InputObject $script:plain -DisplayName "Chris Keslar"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
        }

        Context "2.2 Replacing a Display Name" {
            It "2.2.1 Should replace an existing display name" {
                $result = Set-EmailAddress -InputObject $script:named -DisplayName "C. Keslar"
                $result.GetDisplayName() | Should -Be "C. Keslar"
            }
            It "2.2.2 Should preserve the address when replacing the display name" {
                $result = Set-EmailAddress -InputObject $script:named -DisplayName "C. Keslar"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
        }

        Context "2.3 Removing a Display Name" {
            It "2.3.1 Should remove the display name when an empty string is supplied" {
                $result = Set-EmailAddress -InputObject $script:named -DisplayName ""
                $result.GetDisplayName() | Should -Be ""
            }
            It "2.3.2 Should preserve the address when the display name is removed" {
                $result = Set-EmailAddress -InputObject $script:named -DisplayName ""
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "2.3.3 Should accept a display name containing special characters" {
                $result = Set-EmailAddress -InputObject $script:plain -DisplayName "Keslar, Chris"
                $result.GetDisplayName() | Should -Be "Keslar, Chris"
            }
        }
    }

    Context "3 Parameter Set - SetLocalPart" {

        Context "3.1 Plain Address Input" {
            It "3.1.1 Should return an EmailAddress object" {
                $result = Set-EmailAddress -InputObject $script:plain -LocalPart "ckeslar"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "3.1.2 Should replace the local part" {
                $result = Set-EmailAddress -InputObject $script:plain -LocalPart "ckeslar"
                $result.GetLocalPart() | Should -Be "ckeslar"
            }
            It "3.1.3 Should preserve the domain" {
                $result = Set-EmailAddress -InputObject $script:plain -LocalPart "ckeslar"
                $result.GetDomain() | Should -Be "pitt.edu"
            }
            It "3.1.4 Should set display name to empty string when original had none" {
                $result = Set-EmailAddress -InputObject $script:plain -LocalPart "ckeslar"
                $result.GetDisplayName() | Should -Be ""
            }
        }

        Context "3.2 Named Mailbox Input" {
            It "3.2.1 Should replace the local part and preserve the domain" {
                $result = Set-EmailAddress -InputObject $script:named -LocalPart "ckeslar"
                $result.GetLocalPart() | Should -Be "ckeslar"
                $result.GetDomain()    | Should -Be "pitt.edu"
            }
            It "3.2.2 Should preserve the display name" {
                $result = Set-EmailAddress -InputObject $script:named -LocalPart "ckeslar"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "3.2.3 Should produce the correct full address" {
                $result = Set-EmailAddress -InputObject $script:named -LocalPart "ckeslar"
                $result.GetAddress() | Should -Be "ckeslar@pitt.edu"
            }
        }

        Context "3.3 Invalid Replacement" {
            It "3.3.1 Should throw when the new local part produces an invalid address" {
                { Set-EmailAddress -InputObject $script:plain -LocalPart ".invalid" } | Should -Throw
            }
            It "3.3.2 Should throw when the new local part contains a space" {
                { Set-EmailAddress -InputObject $script:plain -LocalPart "bad local" } | Should -Throw
            }
        }
    }

    Context "4 Parameter Set - SetDomain" {

        Context "4.1 Plain Address Input" {
            It "4.1.1 Should return an EmailAddress object" {
                $result = Set-EmailAddress -InputObject $script:plain -Domain "example.com"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "4.1.2 Should replace the domain" {
                $result = Set-EmailAddress -InputObject $script:plain -Domain "example.com"
                $result.GetDomain() | Should -Be "example.com"
            }
            It "4.1.3 Should preserve the local part" {
                $result = Set-EmailAddress -InputObject $script:plain -Domain "example.com"
                $result.GetLocalPart() | Should -Be "crk4"
            }
            It "4.1.4 Should set display name to empty string when original had none" {
                $result = Set-EmailAddress -InputObject $script:plain -Domain "example.com"
                $result.GetDisplayName() | Should -Be ""
            }
        }

        Context "4.2 Named Mailbox Input" {
            It "4.2.1 Should replace the domain and preserve the local part" {
                $result = Set-EmailAddress -InputObject $script:named -Domain "example.com"
                $result.GetDomain()    | Should -Be "example.com"
                $result.GetLocalPart() | Should -Be "crk4"
            }
            It "4.2.2 Should preserve the display name" {
                $result = Set-EmailAddress -InputObject $script:named -Domain "example.com"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "4.2.3 Should produce the correct full address" {
                $result = Set-EmailAddress -InputObject $script:named -Domain "example.com"
                $result.GetAddress() | Should -Be "crk4@example.com"
            }
        }

        Context "4.3 Invalid Replacement" {
            It "4.3.1 Should throw when the new domain has no TLD" {
                { Set-EmailAddress -InputObject $script:plain -Domain "localdomain" } | Should -Throw
            }
            It "4.3.2 Should throw when the new domain label starts with a hyphen" {
                { Set-EmailAddress -InputObject $script:plain -Domain "-example.com" } | Should -Throw
            }
        }
    }

    Context "5 Immutability — Original Object Is Never Modified" {
        It "5.1 Should not modify the original address when -Address is used" {
            $original = $script:plain.GetAddress()
            Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com" | Out-Null
            $script:plain.GetAddress() | Should -Be $original
        }
        It "5.2 Should not modify the original display name when -DisplayName is used" {
            $original = $script:plain.GetDisplayName()
            Set-EmailAddress -InputObject $script:plain -DisplayName "Someone" | Out-Null
            $script:plain.GetDisplayName() | Should -Be $original
        }
        It "5.3 Should not modify the original local part when -LocalPart is used" {
            $original = $script:plain.GetLocalPart()
            Set-EmailAddress -InputObject $script:plain -LocalPart "ckeslar" | Out-Null
            $script:plain.GetLocalPart() | Should -Be $original
        }
        It "5.4 Should not modify the original domain when -Domain is used" {
            $original = $script:plain.GetDomain()
            Set-EmailAddress -InputObject $script:plain -Domain "example.com" | Out-Null
            $script:plain.GetDomain() | Should -Be $original
        }
        It "5.5 Should return a new object reference, not the same instance" {
            $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
            [object]::ReferenceEquals($script:plain, $result) | Should -Be $false
        }
    }

    Context "6 Parameter Set Mutual Exclusivity" {
        It "6.1 Should throw when -Address and -DisplayName are both supplied" {
            { Set-EmailAddress -InputObject $script:plain -Address "a@b.com" -DisplayName "Name" } | Should -Throw
        }
        It "6.2 Should throw when -Address and -LocalPart are both supplied" {
            { Set-EmailAddress -InputObject $script:plain -Address "a@b.com" -LocalPart "a" } | Should -Throw
        }
        It "6.3 Should throw when -Address and -Domain are both supplied" {
            { Set-EmailAddress -InputObject $script:plain -Address "a@b.com" -Domain "b.com" } | Should -Throw
        }
        It "6.4 Should throw when -LocalPart and -Domain are both supplied" {
            { Set-EmailAddress -InputObject $script:plain -LocalPart "a" -Domain "b.com" } | Should -Throw
        }
        It "6.5 Should throw when no replacement parameter is supplied" {
            { Set-EmailAddress -InputObject $script:plain } | Should -Throw
        }
    }

    Context "7 Pipeline Input" {
        It "7.1 Should accept a single EmailAddress object from the pipeline" {
            $result = $script:plain | Set-EmailAddress -Address "jdoe@example.com"
            ($result -is [EmailAddress]) | Should -Be $true
            $result.GetAddress() | Should -Be "jdoe@example.com"
        }
        It "7.2 Should return one new object per piped input" {
            $results = @($script:plain, $script:named) | Set-EmailAddress -Domain "example.com"
            $results.Count | Should -Be 2
        }
        It "7.3 Should apply the replacement consistently across all piped inputs" {
            $emails = "crk4@pitt.edu", "jdoe@pitt.edu" | New-EmailAddress
            $results = $emails | Set-EmailAddress -Domain "example.com"
            $results[0].GetDomain() | Should -Be "example.com"
            $results[1].GetDomain() | Should -Be "example.com"
        }
        It "7.4 Should preserve each object's unique components when replacing the domain" {
            $emails = "crk4@pitt.edu", "jdoe@pitt.edu" | New-EmailAddress
            $results = $emails | Set-EmailAddress -Domain "example.com"
            $results[0].GetLocalPart() | Should -Be "crk4"
            $results[1].GetLocalPart() | Should -Be "jdoe"
        }
        It "7.5 Should preserve input order in the output" {
            $emails = "a@pitt.edu", "b@pitt.edu", "c@pitt.edu" | New-EmailAddress
            $results = $emails | Set-EmailAddress -Domain "example.com"
            $results[0].GetLocalPart() | Should -Be "a"
            $results[1].GetLocalPart() | Should -Be "b"
            $results[2].GetLocalPart() | Should -Be "c"
        }
        It "7.6 Should work as a transformation step in a longer pipeline" {
            $result = "Chris Keslar <crk4@pitt.edu>" |
                New-EmailAddress |
                Set-EmailAddress -Domain "example.com"
            $result.GetAddress()     | Should -Be "crk4@example.com"
            $result.GetDisplayName() | Should -Be "Chris Keslar"
        }
    }

    Context "8 Output Type and Structure" {
        It "8.1 Should return an object of type EmailAddress" {
            $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "8.2 Should expose the Address script property on the returned object" {
            $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
            $result.Address | Should -Be "jdoe@example.com"
        }
        It "8.3 Should expose the DisplayName script property on the returned object" {
            $result = Set-EmailAddress -InputObject $script:named -DisplayName "C. Keslar"
            $result.DisplayName | Should -Be "C. Keslar"
        }
        It "8.4 Should return a single object, not an array, for a single input" {
            $result = Set-EmailAddress -InputObject $script:plain -Address "jdoe@example.com"
            ($result -is [System.Array]) | Should -Be $false
        }
    }

    Context "9 Round-Trip Consistency" {
        It "9.1 Replacing LocalPart then Domain should match constructing from components" {
            $step1 = Set-EmailAddress -InputObject $script:named -LocalPart "ckeslar"
            $step2 = Set-EmailAddress -InputObject $step1 -Domain "example.com"
            $fromNew = New-EmailAddress -LocalPart "ckeslar" -Domain "example.com" -DisplayName "Chris Keslar"
            $step2.Equals($fromNew) | Should -Be $true
        }
        It "9.2 Replacing Domain then adding DisplayName should match a direct named mailbox construction" {
            $step1 = Set-EmailAddress -InputObject $script:plain -Domain "example.com"
            $step2 = Set-EmailAddress -InputObject $step1 -DisplayName "Chris Keslar"
            $fromNew = New-EmailAddress -Address "Chris Keslar <crk4@example.com>"
            $step2.Equals($fromNew) | Should -Be $true
        }
        It "9.3 Removing and re-adding the display name should restore the original" {
            $removed = Set-EmailAddress -InputObject $script:named -DisplayName ""
            $restored = Set-EmailAddress -InputObject $removed -DisplayName "Chris Keslar"
            $restored.Equals($script:named) | Should -Be $true
        }
    }
}
