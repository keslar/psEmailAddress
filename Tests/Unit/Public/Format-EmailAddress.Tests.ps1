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

    # Dot-source New-EmailAddress — used to create test fixtures
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/Format-EmailAddress.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Plain address — no display name
    $script:plain = New-EmailAddress -Address "crk4@pitt.edu"

    # Named mailbox — display name with only letters and a space (space requires quoting in RFC5322)
    $script:named = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

    # Named mailbox — display name containing a comma (requires quoting in RFC5322)
    $script:comma = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"

    # Named mailbox — display name with no special characters or whitespace (no quoting needed)
    $script:nospace = New-EmailAddress -Address "ChrisKeslar <crk4@pitt.edu>"
}

Describe "Format-EmailAddress Cmdlet Tests" {

    Context "1 Format Address (default)" {

        Context "1.1 Plain Address Input" {
            It "1.1.1 Should return the plain address string" {
                Format-EmailAddress -InputObject $script:plain | Should -Be "crk4@pitt.edu"
            }
            It "1.1.2 Should return a string type" {
                Format-EmailAddress -InputObject $script:plain | Should -BeOfType [string]
            }
        }

        Context "1.2 Named Mailbox Input" {
            It "1.2.1 Should return only the address portion, discarding the display name" {
                Format-EmailAddress -InputObject $script:named | Should -Be "crk4@pitt.edu"
            }
            It "1.2.2 Should return the same result whether or not a display name is present" {
                $resultPlain = Format-EmailAddress -InputObject $script:plain
                $resultNamed = Format-EmailAddress -InputObject $script:named
                $resultPlain | Should -Be $resultNamed
            }
        }

        Context "1.3 Default Parameter" {
            It "1.3.1 Should use Address as the default format when -Format is omitted" {
                $withDefault = Format-EmailAddress -InputObject $script:named
                $withExplicit = Format-EmailAddress -InputObject $script:named -Format Address
                $withDefault  | Should -Be $withExplicit
            }
            It "1.3.2 Should accept Format as a positional parameter" {
                Format-EmailAddress $script:named "Address" | Should -Be "crk4@pitt.edu"
            }
        }
    }

    Context "2 Format Friendly" {

        Context "2.1 Plain Address Input" {
            It "2.1.1 Should return just the address when no display name is set" {
                Format-EmailAddress -InputObject $script:plain -Format Friendly | Should -Be "crk4@pitt.edu"
            }
        }

        Context "2.2 Named Mailbox Input" {
            It "2.2.1 Should return 'Display Name <address>' when a display name is present" {
                Format-EmailAddress -InputObject $script:named -Format Friendly | Should -Be "Chris Keslar <crk4@pitt.edu>"
            }
            It "2.2.2 Should include the display name exactly as stored" {
                Format-EmailAddress -InputObject $script:comma -Format Friendly | Should -Be "Keslar, Chris <crk4@pitt.edu>"
            }
            It "2.2.3 Should not quote the display name regardless of its content" {
                # Friendly format is unquoted — quoting is only applied in RFC5322 format
                $result = Format-EmailAddress -InputObject $script:comma -Format Friendly
                $result | Should -Not -BeLike '"*"*'
            }
        }
    }

    Context "3 Format RFC5322" {

        Context "3.1 Plain Address Input" {
            It "3.1.1 Should return just the address when no display name is set" {
                Format-EmailAddress -InputObject $script:plain -Format RFC5322 | Should -Be "crk4@pitt.edu"
            }
        }

        Context "3.2 Display Name Requiring Quoting" {
            It "3.2.1 Should quote a display name that contains a space" {
                Format-EmailAddress -InputObject $script:named -Format RFC5322 | Should -Be '"Chris Keslar" <crk4@pitt.edu>'
            }
            It "3.2.2 Should quote a display name that contains a comma" {
                Format-EmailAddress -InputObject $script:comma -Format RFC5322 | Should -Be '"Keslar, Chris" <crk4@pitt.edu>'
            }
            It "3.2.3 Should escape embedded double quotes within the quoted display name" {
                $email = New-EmailAddress -Address 'Say "Hello" <sh@example.com>'
                $result = Format-EmailAddress -InputObject $email -Format RFC5322
                $result | Should -BeLike '"Say \"Hello\"*'
            }
        }

        Context "3.3 Display Name Not Requiring Quoting" {
            It "3.3.1 Should not quote a display name that contains only letters" {
                Format-EmailAddress -InputObject $script:nospace -Format RFC5322 | Should -Be "ChrisKeslar <crk4@pitt.edu>"
            }
            It "3.3.2 Should not wrap the result in quotes when quoting is not needed" {
                $result = Format-EmailAddress -InputObject $script:nospace -Format RFC5322
                $result | Should -Not -BeLike '"*'
            }
        }

        Context "3.4 RFC5322 vs Friendly Comparison" {
            It "3.4.1 Should produce a different result from Friendly when the display name requires quoting" {
                $friendly = Format-EmailAddress -InputObject $script:named -Format Friendly
                $rfc5322 = Format-EmailAddress -InputObject $script:named -Format RFC5322
                $friendly | Should -Not -Be $rfc5322
            }
            It "3.4.2 Should produce the same result as Friendly when the display name needs no quoting" {
                $friendly = Format-EmailAddress -InputObject $script:nospace -Format Friendly
                $rfc5322 = Format-EmailAddress -InputObject $script:nospace -Format RFC5322
                $friendly | Should -Be $rfc5322
            }
            It "3.4.3 Should produce the same result as Friendly when no display name is present" {
                $friendly = Format-EmailAddress -InputObject $script:plain -Format Friendly
                $rfc5322 = Format-EmailAddress -InputObject $script:plain -Format RFC5322
                $friendly | Should -Be $rfc5322
            }
        }
    }

    Context "4 All Formats Produce Identical Output When No Display Name Is Present" {
        It "4.1 Address and Friendly should produce the same string for a plain address" {
            $address = Format-EmailAddress -InputObject $script:plain -Format Address
            $friendly = Format-EmailAddress -InputObject $script:plain -Format Friendly
            $address  | Should -Be $friendly
        }
        It "4.2 Address and RFC5322 should produce the same string for a plain address" {
            $address = Format-EmailAddress -InputObject $script:plain -Format Address
            $rfc5322 = Format-EmailAddress -InputObject $script:plain -Format RFC5322
            $address | Should -Be $rfc5322
        }
        It "4.3 All three formats should produce the same string for a plain address" {
            $address = Format-EmailAddress -InputObject $script:plain -Format Address
            $friendly = Format-EmailAddress -InputObject $script:plain -Format Friendly
            $rfc5322 = Format-EmailAddress -InputObject $script:plain -Format RFC5322
            $address  | Should -Be $friendly
            $address  | Should -Be $rfc5322
        }
    }

    Context "5 Output Type and Structure" {
        It "5.1 Should return a string in Address format" {
            Format-EmailAddress -InputObject $script:named -Format Address | Should -BeOfType [string]
        }
        It "5.2 Should return a string in Friendly format" {
            Format-EmailAddress -InputObject $script:named -Format Friendly | Should -BeOfType [string]
        }
        It "5.3 Should return a string in RFC5322 format" {
            Format-EmailAddress -InputObject $script:named -Format RFC5322 | Should -BeOfType [string]
        }
        It "5.4 Should return a single string, not an array, for a single input" {
            $result = Format-EmailAddress -InputObject $script:named -Format Friendly
            ($result -is [System.Array]) | Should -Be $false
        }
        It "5.5 Should reject an invalid Format value" {
            { Format-EmailAddress -InputObject $script:named -Format "Invalid" } | Should -Throw
        }
    }

    Context "6 Pipeline Input" {
        It "6.1 Should accept a single EmailAddress object from the pipeline" {
            $result = $script:plain | Format-EmailAddress
            $result | Should -Be "crk4@pitt.edu"
        }
        It "6.2 Should return one string per object for multiple pipeline inputs" {
            $emails = "crk4@pitt.edu", "Chris Keslar <jdoe@example.com>" | New-EmailAddress
            $results = $emails | Format-EmailAddress -Format Friendly
            $results.Count | Should -Be 2
        }
        It "6.3 Should preserve input order across the pipeline" {
            $emails = "a@example.com", "Chris Keslar <b@example.com>", "c@example.com" | New-EmailAddress
            $results = $emails | Format-EmailAddress -Format Address
            $results[0] | Should -Be "a@example.com"
            $results[1] | Should -Be "b@example.com"
            $results[2] | Should -Be "c@example.com"
        }
        It "6.4 Should apply the chosen format consistently across all pipeline objects" {
            $results = @($script:plain, $script:named) | Format-EmailAddress -Format Friendly
            $results[0] | Should -Be "crk4@pitt.edu"
            $results[1] | Should -Be "Chris Keslar <crk4@pitt.edu>"
        }
        It "6.5 Should work as a formatting step in a longer pipeline" {
            $result = "Chris Keslar <crk4@pitt.edu>" |
                New-EmailAddress |
                Format-EmailAddress -Format RFC5322
            $result | Should -Be '"Chris Keslar" <crk4@pitt.edu>'
        }
    }

    Context "7 ValidateSet Enforcement" {
        It "7.1 Should accept Address as a valid Format value" {
            { Format-EmailAddress -InputObject $script:plain -Format Address } | Should -Not -Throw
        }
        It "7.2 Should accept Friendly as a valid Format value" {
            { Format-EmailAddress -InputObject $script:plain -Format Friendly } | Should -Not -Throw
        }
        It "7.3 Should accept RFC5322 as a valid Format value" {
            { Format-EmailAddress -InputObject $script:plain -Format RFC5322 } | Should -Not -Throw
        }
        It "7.4 Should throw for an unrecognised Format value" {
            { Format-EmailAddress -InputObject $script:plain -Format "Mailbox" } | Should -Throw
        }
        It "7.5 Should throw for an empty Format value" {
            { Format-EmailAddress -InputObject $script:plain -Format "" } | Should -Throw
        }
    }
}
