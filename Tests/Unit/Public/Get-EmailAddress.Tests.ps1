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
    . $ProjectRoot/Source/Public/Get-EmailAddress.ps1

    # Dot-source Format-EmailAddress — used in Context 10 for cross-cmdlet consistency tests
    . $ProjectRoot/Source/Public/Format-EmailAddress.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Plain address — no display name
    $script:plain = New-EmailAddress -Address "crk4@pitt.edu"

    # Named mailbox — space in display name (requires RFC5322 quoting)
    $script:named = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"

    # Named mailbox — comma in display name (also requires RFC5322 quoting)
    $script:comma = New-EmailAddress -Address "Keslar, Chris <crk4@pitt.edu>"

    # Named mailbox — no special characters (no RFC5322 quoting needed)
    $script:nospace = New-EmailAddress -Address "ChrisKeslar <crk4@pitt.edu>"

    # Address with a subdomain
    $script:subdomain = New-EmailAddress -Address "user@mail.example.co.uk"

    # Address with a plus sign in the local part
    $script:tagged = New-EmailAddress -Address "user+tag@example.com"
}

Describe "Get-EmailAddress Cmdlet Tests" {

    Context "1 Property - Address (default)" {
        It "1.1 Should return the plain address string from a plain address" {
            Get-EmailAddress -InputObject $script:plain -Property Address | Should -Be "crk4@pitt.edu"
        }
        It "1.2 Should return only the address portion from a named mailbox" {
            Get-EmailAddress -InputObject $script:named -Property Address | Should -Be "crk4@pitt.edu"
        }
        It "1.3 Should return Address as the default when -Property is omitted" {
            Get-EmailAddress -InputObject $script:named | Should -Be "crk4@pitt.edu"
        }
        It "1.4 Should return a string type" {
            Get-EmailAddress -InputObject $script:plain -Property Address | Should -BeOfType [string]
        }
    }

    Context "2 Property - DisplayName" {
        It "2.1 Should return the display name from a named mailbox" {
            Get-EmailAddress -InputObject $script:named -Property DisplayName | Should -Be "Chris Keslar"
        }
        It "2.2 Should return an empty string when no display name is set" {
            Get-EmailAddress -InputObject $script:plain -Property DisplayName | Should -Be ""
        }
        It "2.3 Should return a display name containing special characters" {
            Get-EmailAddress -InputObject $script:comma -Property DisplayName | Should -Be "Keslar, Chris"
        }
        It "2.4 Should return a string type" {
            Get-EmailAddress -InputObject $script:named -Property DisplayName | Should -BeOfType [string]
        }
    }

    Context "3 Property - LocalPart" {
        It "3.1 Should return the portion before the @ symbol" {
            Get-EmailAddress -InputObject $script:plain -Property LocalPart | Should -Be "crk4"
        }
        It "3.2 Should return the local part from a named mailbox" {
            Get-EmailAddress -InputObject $script:named -Property LocalPart | Should -Be "crk4"
        }
        It "3.3 Should return a local part containing a plus sign" {
            Get-EmailAddress -InputObject $script:tagged -Property LocalPart | Should -Be "user+tag"
        }
        It "3.4 Should return a string type" {
            Get-EmailAddress -InputObject $script:plain -Property LocalPart | Should -BeOfType [string]
        }
    }

    Context "4 Property - Domain" {
        It "4.1 Should return the portion after the @ symbol" {
            Get-EmailAddress -InputObject $script:plain -Property Domain | Should -Be "pitt.edu"
        }
        It "4.2 Should return the domain from a named mailbox" {
            Get-EmailAddress -InputObject $script:named -Property Domain | Should -Be "pitt.edu"
        }
        It "4.3 Should return the full subdomain chain" {
            Get-EmailAddress -InputObject $script:subdomain -Property Domain | Should -Be "mail.example.co.uk"
        }
        It "4.4 Should return a string type" {
            Get-EmailAddress -InputObject $script:plain -Property Domain | Should -BeOfType [string]
        }
    }

    Context "5 Property - Friendly" {
        It "5.1 Should return just the address when no display name is set" {
            Get-EmailAddress -InputObject $script:plain -Property Friendly | Should -Be "crk4@pitt.edu"
        }
        It "5.2 Should return 'Display Name <address>' when a display name is present" {
            Get-EmailAddress -InputObject $script:named -Property Friendly | Should -Be "Chris Keslar <crk4@pitt.edu>"
        }
        It "5.3 Should include a display name containing special characters without quoting" {
            Get-EmailAddress -InputObject $script:comma -Property Friendly | Should -Be "Keslar, Chris <crk4@pitt.edu>"
        }
        It "5.4 Should return a string type" {
            Get-EmailAddress -InputObject $script:named -Property Friendly | Should -BeOfType [string]
        }
    }

    Context "6 Property - RFC5322" {
        It "6.1 Should return just the address when no display name is set" {
            Get-EmailAddress -InputObject $script:plain -Property RFC5322 | Should -Be "crk4@pitt.edu"
        }
        It "6.2 Should quote a display name containing a space" {
            Get-EmailAddress -InputObject $script:named -Property RFC5322 | Should -Be '"Chris Keslar" <crk4@pitt.edu>'
        }
        It "6.3 Should quote a display name containing a comma" {
            Get-EmailAddress -InputObject $script:comma -Property RFC5322 | Should -Be '"Keslar, Chris" <crk4@pitt.edu>'
        }
        It "6.4 Should not quote a display name that needs no quoting" {
            Get-EmailAddress -InputObject $script:nospace -Property RFC5322 | Should -Be "ChrisKeslar <crk4@pitt.edu>"
        }
        It "6.5 Should return a string type" {
            Get-EmailAddress -InputObject $script:named -Property RFC5322 | Should -BeOfType [string]
        }
    }

    Context "7 ValidateSet Enforcement" {
        It "7.1 Should accept Address as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property Address } | Should -Not -Throw
        }
        It "7.2 Should accept DisplayName as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property DisplayName } | Should -Not -Throw
        }
        It "7.3 Should accept LocalPart as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property LocalPart } | Should -Not -Throw
        }
        It "7.4 Should accept Domain as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property Domain } | Should -Not -Throw
        }
        It "7.5 Should accept Friendly as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property Friendly } | Should -Not -Throw
        }
        It "7.6 Should accept RFC5322 as a valid Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property RFC5322 } | Should -Not -Throw
        }
        It "7.7 Should throw for an unrecognised Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property "Invalid" } | Should -Throw
        }
        It "7.8 Should throw for an empty Property value" {
            { Get-EmailAddress -InputObject $script:plain -Property "" } | Should -Throw
        }
    }

    Context "8 Pipeline Input" {
        It "8.1 Should accept a single EmailAddress object from the pipeline" {
            $result = $script:plain | Get-EmailAddress -Property Address
            $result | Should -Be "crk4@pitt.edu"
        }
        It "8.2 Should return one string per object for multiple pipeline inputs" {
            $results = @($script:plain, $script:named) | Get-EmailAddress -Property Address
            $results.Count | Should -Be 2
        }
        It "8.3 Should preserve input order across the pipeline" {
            $emails = "a@example.com", "b@example.com", "c@example.com" | New-EmailAddress
            $results = $emails | Get-EmailAddress -Property Address
            $results[0] | Should -Be "a@example.com"
            $results[1] | Should -Be "b@example.com"
            $results[2] | Should -Be "c@example.com"
        }
        It "8.4 Should apply the chosen property consistently across all pipeline objects" {
            $results = @($script:plain, $script:named) | Get-EmailAddress -Property Domain
            $results[0] | Should -Be "pitt.edu"
            $results[1] | Should -Be "pitt.edu"
        }
        It "8.5 Should work as a projection step in a longer pipeline" {
            $domains = "crk4@pitt.edu", "jdoe@example.com" |
                New-EmailAddress |
                Get-EmailAddress -Property Domain
            $domains[0] | Should -Be "pitt.edu"
            $domains[1] | Should -Be "example.com"
        }
    }

    Context "9 Output Type and Structure" {
        It "9.1 Should return a single string, not an array, for a single input" {
            $result = Get-EmailAddress -InputObject $script:plain -Property Address
            ($result -is [System.Array]) | Should -Be $false
        }
        It "9.2 Should return a string type for all properties" {
            $properties = 'Address', 'DisplayName', 'LocalPart', 'Domain', 'Friendly', 'RFC5322'
            foreach ($prop in $properties) {
                Get-EmailAddress -InputObject $script:named -Property $prop | Should -BeOfType [string]
            }
        }
    }

    Context "10 Consistency with Other Cmdlets" {
        It "10.1 Address property should match Format-EmailAddress -Format Address" {
            $get = Get-EmailAddress -InputObject $script:named -Property Address
            $format = Format-EmailAddress -InputObject $script:named -Format Address
            $get | Should -Be $format
        }
        It "10.2 Friendly property should match Format-EmailAddress -Format Friendly" {
            $get = Get-EmailAddress -InputObject $script:named -Property Friendly
            $format = Format-EmailAddress -InputObject $script:named -Format Friendly
            $get | Should -Be $format
        }
        It "10.3 RFC5322 property should match Format-EmailAddress -Format RFC5322" {
            $get = Get-EmailAddress -InputObject $script:named -Property RFC5322
            $format = Format-EmailAddress -InputObject $script:named -Format RFC5322
            $get | Should -Be $format
        }
    }
}
