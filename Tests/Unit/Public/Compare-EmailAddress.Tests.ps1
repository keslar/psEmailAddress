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

    # Dot-source the helper function for resolving string inputs to EmailAddress objects
    . $ProjectRoot/Source/Private/Resolve-EmailAddressInput.ps1
    
    # Dot-source New-EmailAddress — used to build test fixtures
    . $ProjectRoot/Source/Public/New-EmailAddress.ps1

    # Dot-source the cmdlet under test
    . $ProjectRoot/Source/Public/Compare-EmailAddress.ps1

    #################################################################################
    # Shared test fixtures
    #################################################################################
    # Identical plain addresses
    $script:addrA = New-EmailAddress -Address "crk4@pitt.edu"
    $script:addrB = New-EmailAddress -Address "crk4@pitt.edu"

    # Same address, different display names
    $script:namedA = New-EmailAddress -Address "Chris Keslar <crk4@pitt.edu>"
    $script:namedB = New-EmailAddress -Address "C. Keslar <crk4@pitt.edu>"

    # Different address entirely
    $script:other = New-EmailAddress -Address "jdoe@example.com"

    # Uppercase variant of addrA — same address, different case
    $script:upperA = New-EmailAddress -Address "CRK4@PITT.EDU"
}

Describe "Compare-EmailAddress Cmdlet Tests" {

    Context "1 Default Comparison (Address and Display Name)" {

        Context "1.1 Equal Inputs" {
            It "1.1.1 Should return true for two identical plain addresses" {
                Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB | Should -Be $true
            }
            It "1.1.2 Should return true for two identical named mailboxes" {
                Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedA | Should -Be $true
            }
            It "1.1.3 Should return true when case differs only in the address portion" {
                Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:upperA | Should -Be $true
            }
            It "1.1.4 Should return true for a plain address compared against itself" {
                Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrA | Should -Be $true
            }
        }

        Context "1.2 Unequal Inputs" {
            It "1.2.1 Should return false when display names differ" {
                Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedB | Should -Be $false
            }
            It "1.2.2 Should return false when addresses differ" {
                Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:other | Should -Be $false
            }
            It "1.2.3 Should return false when one has a display name and the other does not" {
                Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:namedA | Should -Be $false
            }
            It "1.2.4 Should return false when both local part and domain differ" {
                $a = New-EmailAddress -Address "alice@example.com"
                $b = New-EmailAddress -Address "bob@other.org"
                Compare-EmailAddress -ReferenceAddress $a -DifferenceAddress $b | Should -Be $false
            }
        }
    }

    Context "2 Comparison with -IgnoreDisplayName" {

        Context "2.1 Equal Addresses" {
            It "2.1.1 Should return true when addresses match and display names differ" {
                Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -IgnoreDisplayName | Should -Be $true
            }
            It "2.1.2 Should return true when one has a display name and the other does not" {
                Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:namedA `
                    -IgnoreDisplayName | Should -Be $true
            }
            It "2.1.3 Should return true for identical plain addresses" {
                Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:addrB `
                    -IgnoreDisplayName | Should -Be $true
            }
            It "2.1.4 Should return true when address case differs" {
                Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:upperA `
                    -IgnoreDisplayName | Should -Be $true
            }
        }

        Context "2.2 Unequal Addresses" {
            It "2.2.1 Should return false when addresses differ regardless of -IgnoreDisplayName" {
                Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:other `
                    -IgnoreDisplayName | Should -Be $false
            }
        }

        Context "2.3 Default vs IgnoreDisplayName" {
            It "2.3.1 Should return false by default but true with -IgnoreDisplayName when only display names differ" {
                $default = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB
                $ignored = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -IgnoreDisplayName
                $default | Should -Be $false
                $ignored | Should -Be $true
            }
            It "2.3.2 Should return the same result with or without -IgnoreDisplayName when addresses differ" {
                $default = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:other
                $ignored = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:other -IgnoreDisplayName
                $default | Should -Be $false
                $ignored | Should -Be $false
            }
            It "2.3.3 Should return the same result with or without -IgnoreDisplayName when both address and display name are identical" {
                $default = Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedA
                $ignored = Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedA -IgnoreDisplayName
                $default | Should -Be $true
                $ignored | Should -Be $true
            }
        }
    }

    Context "3 String Input" {
        It "3.1 Should accept plain address strings for both parameters" {
            Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "crk4@pitt.edu" | Should -Be $true
        }
        It "3.2 Should accept named mailbox strings for both parameters" {
            Compare-EmailAddress `
                -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
                -DifferenceAddress "Chris Keslar <crk4@pitt.edu>" | Should -Be $true
        }
        It "3.3 Should accept a string for one parameter and an EmailAddress object for the other" {
            Compare-EmailAddress `
                -ReferenceAddress  "crk4@pitt.edu" `
                -DifferenceAddress $script:addrA | Should -Be $true
        }
        It "3.4 Should produce the same result from strings as from EmailAddress objects" {
            $fromObjects = Compare-EmailAddress `
                -ReferenceAddress  $script:namedA `
                -DifferenceAddress $script:namedB `
                -IgnoreDisplayName
            $fromStrings = Compare-EmailAddress `
                -ReferenceAddress  "Chris Keslar <crk4@pitt.edu>" `
                -DifferenceAddress "C. Keslar <crk4@pitt.edu>" `
                -IgnoreDisplayName
            $fromObjects | Should -Be $fromStrings
        }
        It "3.5 Should throw a terminating error for an invalid ReferenceAddress string" {
            { Compare-EmailAddress -ReferenceAddress "notvalid" -DifferenceAddress "crk4@pitt.edu" } | Should -Throw
        }
        It "3.6 Should throw a terminating error for an invalid DifferenceAddress string" {
            # DifferenceAddress is resolved in the begin block, so the error fires
            # before process runs — even before any pipeline input is processed.
            { Compare-EmailAddress -ReferenceAddress "crk4@pitt.edu" -DifferenceAddress "notvalid" } | Should -Throw
        }
        It "3.7 Should use the same DifferenceAddress object for every piped ReferenceAddress input" {
            # DifferenceAddress is resolved once in begin, not on each pipeline iteration.
            # This test confirms the comparison is consistent for all piped inputs.
            $results = "crk4@pitt.edu", "crk4@pitt.edu" | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"
            $results[0] | Should -Be $true
            $results[1] | Should -Be $true
        }
    }

    Context "4 Detailed Output" {

        Context "4.1 Structure" {
            BeforeAll {
                $script:detailResult = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -Detailed
            }
            It "4.1.1 Should return a PSCustomObject" {
                ($script:detailResult -is [PSCustomObject]) | Should -Be $true
            }
            It "4.1.2 Should expose a ReferenceAddress property" {
                $script:detailResult.PSObject.Properties.Name | Should -Contain "ReferenceAddress"
            }
            It "4.1.3 Should expose a DifferenceAddress property" {
                $script:detailResult.PSObject.Properties.Name | Should -Contain "DifferenceAddress"
            }
            It "4.1.4 Should expose an AreEqual property" {
                $script:detailResult.PSObject.Properties.Name | Should -Contain "AreEqual"
            }
            It "4.1.5 Should expose an IgnoredDisplayName property" {
                $script:detailResult.PSObject.Properties.Name | Should -Contain "IgnoredDisplayName"
            }
            It "4.1.6 Should return AreEqual as a bool type" {
                $script:detailResult.AreEqual | Should -BeOfType [bool]
            }
            It "4.1.7 Should return IgnoredDisplayName as a bool type" {
                $script:detailResult.IgnoredDisplayName | Should -BeOfType [bool]
            }
        }

        Context "4.2 Equal Addresses" {
            It "4.2.1 Should set AreEqual to true for matching addresses" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:addrB `
                    -Detailed
                $result.AreEqual | Should -Be $true
            }
            It "4.2.2 Should set ReferenceAddress to the formatted reference input" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedA `
                    -Detailed
                $result.ReferenceAddress | Should -Be "Chris Keslar <crk4@pitt.edu>"
            }
            It "4.2.3 Should set DifferenceAddress to the formatted difference input" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -Detailed
                $result.DifferenceAddress | Should -Be "C. Keslar <crk4@pitt.edu>"
            }
        }

        Context "4.3 Unequal Addresses" {
            It "4.3.1 Should set AreEqual to false when addresses differ" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:other `
                    -Detailed
                $result.AreEqual | Should -Be $false
            }
            It "4.3.2 Should set AreEqual to false when display names differ in default mode" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -Detailed
                $result.AreEqual | Should -Be $false
            }
        }

        Context "4.4 IgnoredDisplayName Flag in Detailed Output" {
            It "4.4.1 Should set IgnoredDisplayName to false when -IgnoreDisplayName is not used" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:addrA `
                    -DifferenceAddress $script:addrB `
                    -Detailed
                $result.IgnoredDisplayName | Should -Be $false
            }
            It "4.4.2 Should set IgnoredDisplayName to true when -IgnoreDisplayName is used" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -IgnoreDisplayName `
                    -Detailed
                $result.IgnoredDisplayName | Should -Be $true
            }
            It "4.4.3 Should set AreEqual to true with -IgnoreDisplayName when only display names differ" {
                $result = Compare-EmailAddress `
                    -ReferenceAddress  $script:namedA `
                    -DifferenceAddress $script:namedB `
                    -IgnoreDisplayName `
                    -Detailed
                $result.AreEqual | Should -Be $true
            }
        }

        Context "4.5 Detailed vs Default Consistency" {
            It "4.5.1 Detailed AreEqual should match the default bool output" {
                $bool = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB
                $detail = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB -Detailed
                $detail.AreEqual | Should -Be $bool
            }
            It "4.5.2 Detailed AreEqual should match the default bool output with -IgnoreDisplayName" {
                $bool = Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedB -IgnoreDisplayName
                $detail = Compare-EmailAddress -ReferenceAddress $script:namedA -DifferenceAddress $script:namedB -IgnoreDisplayName -Detailed
                $detail.AreEqual | Should -Be $bool
            }
        }
    }

    Context "5 Pipeline Input on ReferenceAddress" {
        It "5.1 Should accept a single EmailAddress object from the pipeline" {
            $result = $script:addrA | Compare-EmailAddress -DifferenceAddress $script:addrB
            $result | Should -Be $true
        }
        It "5.2 Should accept a plain address string from the pipeline" {
            $result = "crk4@pitt.edu" | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"
            $result | Should -Be $true
        }
        It "5.3 Should return one result per piped input" {
            $results = @($script:addrA, $script:other, $script:addrB) |
                Compare-EmailAddress -DifferenceAddress $script:addrA
            $results.Count | Should -Be 3
        }
        It "5.4 Should evaluate each piped input against the fixed DifferenceAddress" {
            $results = @($script:addrA, $script:other, $script:addrB) |
                Compare-EmailAddress -DifferenceAddress $script:addrA
            $results[0] | Should -Be $true
            $results[1] | Should -Be $false
            $results[2] | Should -Be $true
        }
        It "5.5 Should preserve input order in the output" {
            $inputs = "crk4@pitt.edu", "jdoe@example.com", "crk4@pitt.edu" | New-EmailAddress
            $results = $inputs | Compare-EmailAddress -DifferenceAddress "crk4@pitt.edu"
            $results[0] | Should -Be $true
            $results[1] | Should -Be $false
            $results[2] | Should -Be $true
        }
        It "5.6 Should apply -IgnoreDisplayName consistently across all piped inputs" {
            $results = @($script:namedA, $script:namedB, $script:other) |
                Compare-EmailAddress -DifferenceAddress $script:addrA -IgnoreDisplayName
            $results[0] | Should -Be $true
            $results[1] | Should -Be $true
            $results[2] | Should -Be $false
        }
        It "5.7 Should return Detailed objects for each piped input when -Detailed is used" {
            $results = @($script:addrA, $script:other) |
                Compare-EmailAddress -DifferenceAddress $script:addrA -Detailed
            $results.Count       | Should -Be 2
            $results[0].AreEqual | Should -Be $true
            $results[1].AreEqual | Should -Be $false
        }
    }

    Context "6 Output Type" {
        It "6.1 Should return a bool in default mode" {
            $result = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB
            $result | Should -BeOfType [bool]
        }
        It "6.2 Should return a PSCustomObject in Detailed mode" {
            $result = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB -Detailed
            ($result -is [PSCustomObject]) | Should -Be $true
        }
        It "6.3 Should return a single value, not an array, for a single input in default mode" {
            $result = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB
            ($result -is [System.Array]) | Should -Be $false
        }
        It "6.4 Should return a single PSCustomObject, not an array, for a single input in Detailed mode" {
            $result = Compare-EmailAddress -ReferenceAddress $script:addrA -DifferenceAddress $script:addrB -Detailed
            ($result -is [System.Array]) | Should -Be $false
        }
    }
}
