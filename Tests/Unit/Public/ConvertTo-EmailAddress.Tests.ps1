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

    # Dot-source New-EmailAddress — used in Context 4 and 5 for comparison tests
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1
    
    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/ConvertTo-EmailAddress.ps1
}

Describe "ConvertTo-EmailAddress Cmdlet Tests" {

    Context "1 Valid Input" {

        Context "1.1 Plain Address Strings" {
            It "1.1.1 Should return an EmailAddress object from a plain address" {
                $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.1.2 Should set the correct address from a plain address string" {
                $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.1.3 Should set the display name to empty string from a plain address string" {
                $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
                $result.GetDisplayName() | Should -Be ""
            }
            It "1.1.4 Should accept an address with a plus sign in the local part" {
                $result = ConvertTo-EmailAddress -InputObject "user+tag@example.com"
                $result.GetAddress() | Should -Be "user+tag@example.com"
            }
            It "1.1.5 Should accept an address with subdomains" {
                $result = ConvertTo-EmailAddress -InputObject "user@mail.sub.example.com"
                $result.GetAddress() | Should -Be "user@mail.sub.example.com"
            }
            It "1.1.6 Should accept an address with a multi-part TLD" {
                $result = ConvertTo-EmailAddress -InputObject "user@example.co.uk"
                $result.GetAddress() | Should -Be "user@example.co.uk"
            }
        }

        Context "1.2 Named Mailbox Strings" {
            It "1.2.1 Should return an EmailAddress object from a named mailbox string" {
                $result = ConvertTo-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>"
                ($result -is [EmailAddress]) | Should -Be $true
            }
            It "1.2.2 Should parse the address correctly from a named mailbox string" {
                $result = ConvertTo-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>"
                $result.GetAddress() | Should -Be "crk4@pitt.edu"
            }
            It "1.2.3 Should parse the display name correctly from a named mailbox string" {
                $result = ConvertTo-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>"
                $result.GetDisplayName() | Should -Be "Chris Keslar"
            }
            It "1.2.4 Should accept a display name containing special characters" {
                $result = ConvertTo-EmailAddress -InputObject "Keslar, Chris <crk4@pitt.edu>"
                $result.GetDisplayName() | Should -Be "Keslar, Chris"
            }
        }
    }

    Context "2 Invalid Input - Non-Terminating Error Behaviour" {
        It "2.1 Should not throw for an address missing the @ symbol" {
            { ConvertTo-EmailAddress -InputObject "notanemail" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.2 Should not throw for an address with a missing domain" {
            { ConvertTo-EmailAddress -InputObject "user@" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.3 Should not throw for an address with a missing local part" {
            { ConvertTo-EmailAddress -InputObject "@pitt.edu" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.4 Should not throw for a domain with no TLD" {
            { ConvertTo-EmailAddress -InputObject "user@localdomain" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.5 Should not throw for an empty string" {
            { ConvertTo-EmailAddress -InputObject "" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.6 Should not throw for a named mailbox containing an invalid address" {
            { ConvertTo-EmailAddress -InputObject "Chris Keslar <notvalid>" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "2.7 Should write a non-terminating error for an invalid address" {
            # 2>&1 merges the error stream into the output stream for capture.
            # -ErrorAction SilentlyContinue must NOT be used here — it suppresses
            # errors before they reach the merged stream, resulting in zero captures.
            $errs27 = ConvertTo-EmailAddress -InputObject "notanemail" 2>&1 |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            $errs27.Count | Should -BeGreaterThan 0
        }
        It "2.8 Should include the invalid input string in the error TargetObject" {
            $errs28 = ConvertTo-EmailAddress -InputObject "notanemail" 2>&1 |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            $errs28[0].TargetObject | Should -BeLike "*notanemail*"
        }
        It "2.9 Should produce no output for a single invalid address" {
            $result = ConvertTo-EmailAddress -InputObject "notanemail" -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
        It "2.10 Should throw a terminating error for an invalid address when -ErrorAction Stop is used" {
            { ConvertTo-EmailAddress -InputObject "notanemail" -ErrorAction Stop } | Should -Throw
        }
    }

    Context "3 Pipeline Input" {
        It "3.1 Should accept a single address from the pipeline" {
            $result = "crk4@pitt.edu" | ConvertTo-EmailAddress
            ($result -is [EmailAddress]) | Should -Be $true
            $result.GetAddress() | Should -Be "crk4@pitt.edu"
        }
        It "3.2 Should convert multiple valid addresses from the pipeline" {
            $results = "crk4@pitt.edu", "jdoe@example.com" | ConvertTo-EmailAddress
            $results.Count           | Should -Be 2
            $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
            $results[1].GetAddress() | Should -Be "jdoe@example.com"
        }
        It "3.3 Should skip invalid addresses in the pipeline and return only valid ones" {
            $results = "crk4@pitt.edu", "notvalid", "jdoe@example.com" | ConvertTo-EmailAddress -ErrorAction SilentlyContinue
            $results.Count           | Should -Be 2
            $results[0].GetAddress() | Should -Be "crk4@pitt.edu"
            $results[1].GetAddress() | Should -Be "jdoe@example.com"
        }
        It "3.4 Should write one non-terminating error per invalid address in the pipeline" {
            # 2>&1 merges the error stream into the output stream for capture.
            # -ErrorAction SilentlyContinue must NOT be combined with 2>&1 — it
            # suppresses errors before they reach the merged stream.
            $errs34 = "crk4@pitt.edu", "bad1", "bad2", "jdoe@example.com" |
                ConvertTo-EmailAddress 2>&1 |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            $errs34.Count | Should -Be 2
        }
        It "3.5 Should return no output when all pipeline inputs are invalid" {
            $results = "bad1", "bad2", "bad3" | ConvertTo-EmailAddress -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
        It "3.6 Should preserve the order of valid addresses from the pipeline" {
            $results = "a@example.com", "notvalid", "b@example.com", "c@example.com" |
                ConvertTo-EmailAddress -ErrorAction SilentlyContinue
            $results[0].GetAddress() | Should -Be "a@example.com"
            $results[1].GetAddress() | Should -Be "b@example.com"
            $results[2].GetAddress() | Should -Be "c@example.com"
        }
        It "3.7 Should accept named mailbox strings from the pipeline" {
            $result = "Chris Keslar <crk4@pitt.edu>" | ConvertTo-EmailAddress
            $result.GetAddress()     | Should -Be "crk4@pitt.edu"
            $result.GetDisplayName() | Should -Be "Chris Keslar"
        }
        It "3.8 Should not throw when all pipeline inputs are invalid and -ErrorAction SilentlyContinue is used" {
            { "bad1", "bad2" | ConvertTo-EmailAddress -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
        It "3.9 Should stop on the first invalid address in the pipeline when -ErrorAction Stop is used" {
            { "crk4@pitt.edu", "notvalid", "jdoe@example.com" | ConvertTo-EmailAddress -ErrorAction Stop } | Should -Throw
        }
    }

    Context "4 Output Type and Structure" {
        It "4.1 Should return an object of type EmailAddress" {
            $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
            $result.GetType().Name | Should -Be "EmailAddress"
        }
        It "4.2 Should expose the Address script property on the returned object" {
            $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
            $result.Address | Should -Be "crk4@pitt.edu"
        }
        It "4.3 Should expose the DisplayName script property on the returned object" {
            $result = ConvertTo-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>"
            $result.DisplayName | Should -Be "Chris Keslar"
        }
        It "4.4 Should return a single object, not an array, for a single valid input" {
            $result = ConvertTo-EmailAddress -InputObject "crk4@pitt.edu"
            ($result -is [System.Array]) | Should -Be $false
        }
        It "4.5 Should produce the same result as New-EmailAddress for the same valid input" {
            $fromConvert = ConvertTo-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>"
            $fromNew = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
            $fromConvert.Equals($fromNew) | Should -Be $true
        }
    }

    Context "5 Comparison with New-EmailAddress" {
        It "5.1 Should not throw where New-EmailAddress would throw for invalid input" {
            { New-EmailAddress -Address "notvalid" }                                            | Should -Throw
            { ConvertTo-EmailAddress -InputObject "notvalid" -ErrorAction SilentlyContinue }    | Should -Not -Throw
        }
        It "5.2 Should not stop the pipeline where New-EmailAddress would stop it" {
            # New-EmailAddress throws a terminating error on invalid input, which
            # stops the pipeline entirely. ConvertTo-EmailAddress writes a
            # non-terminating error and continues, so it always returns all valid items.
            $convertResults = "crk4@pitt.edu", "notvalid", "jdoe@example.com" |
                ConvertTo-EmailAddress -ErrorAction SilentlyContinue

            # Confirm ConvertTo-EmailAddress returned both valid addresses
            $convertResults.Count | Should -Be 2

            # Confirm New-EmailAddress throws rather than skipping
            { "crk4@pitt.edu", "notvalid", "jdoe@example.com" | New-EmailAddress } | Should -Throw
        }
    }
}
