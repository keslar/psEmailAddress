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

    # Dot-source New-EmailAddress — used in Context 4 to supply EmailAddress objects
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/Test-EmailAddress.ps1


}

Describe "Test-EmailAddress Cmdlet Tests" {

    Context "1 Default Output - Valid Addresses" {

        Context "1.1 Plain Address Strings" {
            It "1.1.1 Should return true for a simple valid address" {
                Test-EmailAddress -InputObject "crk4@pitt.edu" | Should -Be $true
            }
            It "1.1.2 Should return true for an address with a dot in the local part" {
                Test-EmailAddress -InputObject "user.name@example.com" | Should -Be $true
            }
            It "1.1.3 Should return true for an address with a plus sign in the local part" {
                Test-EmailAddress -InputObject "user+tag@example.com" | Should -Be $true
            }
            It "1.1.4 Should return true for an address with subdomains" {
                Test-EmailAddress -InputObject "user@mail.sub.example.com" | Should -Be $true
            }
            It "1.1.5 Should return true for an address with a multi-part TLD" {
                Test-EmailAddress -InputObject "user@example.co.uk" | Should -Be $true
            }
            It "1.1.6 Should return true for an address with uppercase characters" {
                Test-EmailAddress -InputObject "USER@EXAMPLE.COM" | Should -Be $true
            }
            It "1.1.7 Should return true for an address with a local part of exactly 64 characters" {
                $localPart = "a" * 64
                Test-EmailAddress -InputObject "$localPart@example.com" | Should -Be $true
            }
        }

        Context "1.2 Named Mailbox Strings" {
            It "1.2.1 Should return true for a named mailbox string with a valid address" {
                Test-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>" | Should -Be $true
            }
            It "1.2.2 Should return true for a named mailbox string with a display name containing special characters" {
                Test-EmailAddress -InputObject "Keslar, Chris <crk4@pitt.edu>" | Should -Be $true
            }
            It "1.2.3 Should return true for a bare angle-bracket format with a valid address" {
                Test-EmailAddress -InputObject "<crk4@pitt.edu>" | Should -Be $true
            }
        }
    }

    Context "2 Default Output - Invalid Addresses" {
        It "2.1 Should return false for an empty string" {
            Test-EmailAddress -InputObject "" | Should -Be $false
        }
        It "2.2 Should return false when the @ symbol is missing" {
            Test-EmailAddress -InputObject "notanemail" | Should -Be $false
        }
        It "2.3 Should return false when the local part is missing" {
            Test-EmailAddress -InputObject "@pitt.edu" | Should -Be $false
        }
        It "2.4 Should return false when the domain is missing" {
            Test-EmailAddress -InputObject "user@" | Should -Be $false
        }
        It "2.5 Should return false for multiple @ symbols" {
            Test-EmailAddress -InputObject "a@b@pitt.edu" | Should -Be $false
        }
        It "2.6 Should return false when the local part starts with a dot" {
            Test-EmailAddress -InputObject ".user@example.com" | Should -Be $false
        }
        It "2.7 Should return false when the local part ends with a dot" {
            Test-EmailAddress -InputObject "user.@example.com" | Should -Be $false
        }
        It "2.8 Should return false when the local part contains consecutive dots" {
            Test-EmailAddress -InputObject "us..er@example.com" | Should -Be $false
        }
        It "2.9 Should return false when a domain label starts with a hyphen" {
            Test-EmailAddress -InputObject "user@-example.com" | Should -Be $false
        }
        It "2.10 Should return false when a domain label ends with a hyphen" {
            Test-EmailAddress -InputObject "user@example-.com" | Should -Be $false
        }
        It "2.11 Should return false when the domain has no TLD" {
            Test-EmailAddress -InputObject "user@localdomain" | Should -Be $false
        }
        It "2.12 Should return false when the TLD is only one character" {
            Test-EmailAddress -InputObject "user@example.c" | Should -Be $false
        }
        It "2.13 Should return false when the local part exceeds 64 characters" {
            $localPart = "a" * 65
            Test-EmailAddress -InputObject "$localPart@example.com" | Should -Be $false
        }
        It "2.14 Should return false for a named mailbox string containing an invalid address" {
            Test-EmailAddress -InputObject "Chris Keslar <notvalid>" | Should -Be $false
        }
        It "2.15 Should return false for null input" {
            Test-EmailAddress -InputObject $null | Should -Be $false
        }
    }

    Context "3 Default Output - Never Throws" {
        It "3.1 Should never throw for an empty string" {
            { Test-EmailAddress -InputObject "" } | Should -Not -Throw
        }
        It "3.2 Should never throw for a null value" {
            { Test-EmailAddress -InputObject $null } | Should -Not -Throw
        }
        It "3.3 Should never throw for a completely invalid string" {
            { Test-EmailAddress -InputObject "this is not an email at all" } | Should -Not -Throw
        }
        It "3.4 Should never throw for a named mailbox with an invalid address" {
            { Test-EmailAddress -InputObject "Chris Keslar <notvalid>" } | Should -Not -Throw
        }
    }

    Context "4 EmailAddress Object Input" {
        It "4.1 Should return true when given a valid EmailAddress object" {
            $email = New-EmailAddress -Address "crk4@pitt.edu"
            Test-EmailAddress -InputObject $email | Should -Be $true
        }
        It "4.2 Should return true when given an EmailAddress object with a display name" {
            $email = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
            Test-EmailAddress -InputObject $email | Should -Be $true
        }
        It "4.3 Should return false when given a null EmailAddress reference" {
            $email = $null
            Test-EmailAddress -InputObject $email | Should -Be $false
        }
    }

    Context "5 Detailed Output" {

        Context "5.1 Valid Address - Detailed" {
            BeforeAll {
                $script:detailValid = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
            }
            It "5.1.1 Should return a PSCustomObject" {
                ($script:detailValid -is [PSCustomObject]) | Should -Be $true
            }
            It "5.1.2 Should set IsValid to true for a valid address" {
                $script:detailValid.IsValid | Should -Be $true
            }
            It "5.1.3 Should set Input to the original input string" {
                $script:detailValid.Input | Should -Be "crk4@pitt.edu"
            }
            It "5.1.4 Should set Reason to an empty string for a valid address" {
                $script:detailValid.Reason | Should -Be ""
            }
        }

        Context "5.2 Invalid Address - Detailed" {
            BeforeAll {
                $script:detailInvalid = Test-EmailAddress -InputObject "notanemail" -Detailed
            }
            It "5.2.1 Should return a PSCustomObject" {
                ($script:detailInvalid -is [PSCustomObject]) | Should -Be $true
            }
            It "5.2.2 Should set IsValid to false for an invalid address" {
                $script:detailInvalid.IsValid | Should -Be $false
            }
            It "5.2.3 Should set Input to the original input string" {
                $script:detailInvalid.Input | Should -Be "notanemail"
            }
            It "5.2.4 Should set Reason to a non-empty string for an invalid address" {
                $script:detailInvalid.Reason | Should -Not -BeNullOrEmpty
            }
        }

        Context "5.3 Named Mailbox String - Detailed" {
            It "5.3.1 Should set Input to the full original named mailbox string" {
                $result = Test-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>" -Detailed
                $result.Input | Should -Be "Chris Keslar <crk4@pitt.edu>"
            }
            It "5.3.2 Should set IsValid to true for a named mailbox with a valid address" {
                $result = Test-EmailAddress -InputObject "Chris Keslar <crk4@pitt.edu>" -Detailed
                $result.IsValid | Should -Be $true
            }
            It "5.3.3 Should set IsValid to false for a named mailbox with an invalid address" {
                $result = Test-EmailAddress -InputObject "Chris Keslar <notvalid>" -Detailed
                $result.IsValid | Should -Be $false
            }
        }

        Context "5.4 EmailAddress Object Input - Detailed" {
            It "5.4.1 Should return IsValid true when given a valid EmailAddress object" {
                $email = New-EmailAddress -Address "crk4@pitt.edu"
                $result = Test-EmailAddress -InputObject $email -Detailed
                $result.IsValid | Should -Be $true
            }
            It "5.4.2 Should set Input to the address string of the EmailAddress object" {
                $email = New-EmailAddress -Address "crk4@pitt.edu"
                $result = Test-EmailAddress -InputObject $email -Detailed
                $result.Input | Should -Be "crk4@pitt.edu"
            }
        }

        Context "5.5 Detailed Output Has Required Properties" {
            It "5.5.1 Should expose an Input property" {
                $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
                $result.PSObject.Properties.Name | Should -Contain "Input"
            }
            It "5.5.2 Should expose an IsValid property" {
                $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
                $result.PSObject.Properties.Name | Should -Contain "IsValid"
            }
            It "5.5.3 Should expose a Reason property" {
                $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
                $result.PSObject.Properties.Name | Should -Contain "Reason"
            }
            It "5.5.4 Should return IsValid as a bool type" {
                $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
                $result.IsValid | Should -BeOfType [bool]
            }
            It "5.5.5 Should return Input as a string type" {
                $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
                $result.Input | Should -BeOfType [string]
            }
        }
    }

    Context "6 Pipeline Input" {
        It "6.1 Should accept a single address from the pipeline" {
            $result = "crk4@pitt.edu" | Test-EmailAddress
            $result | Should -Be $true
        }
        It "6.2 Should return one bool per input for multiple pipeline values" {
            $results = "crk4@pitt.edu", "notvalid", "jdoe@example.com" | Test-EmailAddress
            $results.Count | Should -Be 3
        }
        It "6.3 Should return true for valid and false for invalid in a mixed pipeline" {
            $results = "crk4@pitt.edu", "notvalid", "jdoe@example.com" | Test-EmailAddress
            $results[0] | Should -Be $true
            $results[1] | Should -Be $false
            $results[2] | Should -Be $true
        }
        It "6.4 Should preserve input order in the output" {
            $results = "a@example.com", "bad", "b@example.com" | Test-EmailAddress
            $results[0] | Should -Be $true
            $results[1] | Should -Be $false
            $results[2] | Should -Be $true
        }
        It "6.5 Should return one PSCustomObject per input when piped with -Detailed" {
            $results = "crk4@pitt.edu", "notvalid" | Test-EmailAddress -Detailed
            $results.Count | Should -Be 2
            ($results[0] -is [PSCustomObject]) | Should -Be $true
            ($results[1] -is [PSCustomObject]) | Should -Be $true
        }
        It "6.6 Should correctly set IsValid on each Detailed result in a mixed pipeline" {
            $results = "crk4@pitt.edu", "notvalid" | Test-EmailAddress -Detailed
            $results[0].IsValid | Should -Be $true
            $results[1].IsValid | Should -Be $false
        }
        It "6.7 Should work as a pipeline filter when used with Where-Object" {
            $valid = "crk4@pitt.edu", "notvalid", "jdoe@example.com" |
                Test-EmailAddress -Detailed |
                Where-Object { $_.IsValid } |
                Select-Object -ExpandProperty Input
            $valid.Count  | Should -Be 2
            $valid[0]     | Should -Be "crk4@pitt.edu"
            $valid[1]     | Should -Be "jdoe@example.com"
        }
        It "6.8 Should accept EmailAddress objects from the pipeline" {
            $email = New-EmailAddress -Address "crk4@pitt.edu"
            $result = $email | Test-EmailAddress
            $result | Should -Be $true
        }
    }

    Context "7 Output Type" {
        It "7.1 Should return a bool in default mode" {
            $result = Test-EmailAddress -InputObject "crk4@pitt.edu"
            $result | Should -BeOfType [bool]
        }
        It "7.2 Should return a PSCustomObject in Detailed mode" {
            $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
            ($result -is [PSCustomObject]) | Should -Be $true
        }
        It "7.3 Should return a single bool, not an array, for a single input in default mode" {
            $result = Test-EmailAddress -InputObject "crk4@pitt.edu"
            ($result -is [System.Array]) | Should -Be $false
        }
        It "7.4 Should return a single PSCustomObject, not an array, for a single input in Detailed mode" {
            $result = Test-EmailAddress -InputObject "crk4@pitt.edu" -Detailed
            ($result -is [System.Array]) | Should -Be $false
        }
    }
}
