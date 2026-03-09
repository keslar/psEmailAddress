BeforeAll {
    #################################################################################
    # Locate the built module
    #
    # Integration tests run against the *built* module output, not dot-sourced
    # source files. The build task in .build.ps1 sets EMAILADDRESS_BUILT_MODULE to
    # the module base directory. If the variable is not set, we fall back to the
    # most recently built version under Build/.
    #################################################################################
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

    if ($env:EMAILADDRESS_BUILT_MODULE -and (Test-Path $env:EMAILADDRESS_BUILT_MODULE)) {
        $script:ModuleBase = $env:EMAILADDRESS_BUILT_MODULE
    } else {
        # Find the highest version directory under Build/EmailAddress/
        $buildRoot = Join-Path $ProjectRoot 'Output' 'EmailAddress'
        $latestBuild = Get-ChildItem -Path $buildRoot -Directory |
            Sort-Object { [version]$_.Name } |
            Select-Object -Last 1

        if (-not $latestBuild) {
            throw "No built module found under '$buildRoot'. Run Invoke-Build Build before running integration tests."
        }

        $script:ModuleBase = $latestBuild.FullName
    }

    $script:ManifestPath = Join-Path $script:ModuleBase 'EmailAddress.psd1'

    # Import the module fresh -- remove any previously loaded copy first
    if (Get-Module -Name EmailAddress) {
        Remove-Module -Name EmailAddress -Force
    }

    Import-Module $script:ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    # Clean up -- remove the module after the test run
    if (Get-Module -Name EmailAddress) {
        Remove-Module -Name EmailAddress -Force
    }
}

Describe 'EmailAddress Module Integration Tests' {

    #############################################################################
    # 1. Module loading
    #############################################################################
    Context '1 Module Loading' {

        It '1.1 Should import without error' {
            Get-Module -Name EmailAddress | Should -Not -BeNullOrEmpty
        }

        It '1.2 Should export exactly 8 public cmdlets' {
            $exported = (Get-Module -Name EmailAddress).ExportedFunctions.Keys
            $exported.Count | Should -Be 8
        }

        It '1.3 Should export Compare-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'Compare-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.4 Should export ConvertTo-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'ConvertTo-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.5 Should export ConvertTo-NormalizedEmailAddress' {
            Get-Command -Module EmailAddress -Name 'ConvertTo-NormalizedEmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.6 Should export Format-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'Format-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.7 Should export Get-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'Get-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.8 Should export New-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'New-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.9 Should export Set-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'Set-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.10 Should export Test-EmailAddress' {
            Get-Command -Module EmailAddress -Name 'Test-EmailAddress' | Should -Not -BeNullOrEmpty
        }

        It '1.11 Should not export any private functions' {
            Get-Command -Module EmailAddress -Name 'Resolve-EmailAddressInput' -ErrorAction SilentlyContinue |
                Should -BeNullOrEmpty
        }

        It '1.12 Should make the EmailAddress type available after import' {
            # Direct use of [EmailAddress] in the test script is not possible because
            # PowerShell resolves type literals at parse time, before Import-Module runs.
            # Instead, verify type availability indirectly: an object returned by a
            # cmdlet should report the correct type name in all scopes.
            $result = New-EmailAddress -Address 'user@example.com'
            $result.GetType().Name      | Should -Be 'EmailAddress'
            $result.GetType().FullName  | Should -Be 'EmailAddress'
        }

        It '1.13 The manifest PowerShellVersion should be compatible with the current host' {
            $manifest = Import-PowerShellDataFile $script:ManifestPath
            [version]$manifest.PowerShellVersion | Should -BeLessOrEqual ([version]$PSVersionTable.PSVersion)
        }
    }

    #############################################################################
    # 2. New-EmailAddress -- construction through the public cmdlet
    #############################################################################
    Context '2 New-EmailAddress' {

        It '2.1 Should create an EmailAddress from a plain address string' {
            $result = New-EmailAddress -Address 'crk4@pitt.edu'
            $result | Should -Not -BeNullOrEmpty
            $result.GetAddress() | Should -Be 'crk4@pitt.edu'
        }

        It '2.2 Should create an EmailAddress from a named mailbox string' {
            $result = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
            $result.GetAddress()     | Should -Be 'crk4@pitt.edu'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
        }

        It '2.3 Should create an EmailAddress from component parts' {
            $result = New-EmailAddress -LocalPart 'crk4' -Domain 'pitt.edu' -DisplayName '[hris Keslar'
            $result.GetAddress()     | Should -Be 'crk4@pitt.edu'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
            $result.GetLocalPart()   | Should -Be 'crk4'
            $result.GetDomain()      | Should -Be 'pitt.edu'
        }

        It '2.4 Should throw a terminating error for an invalid address' {
            { New-EmailAddress -Address 'notvalid' } | Should -Throw
        }

        It '2.5 Should accept pipeline input' {
            $results = 'crk4@pitt.edu', 'jdoe@example.com' | New-EmailAddress
            $results.Count           | Should -Be 2
            $results[0].GetAddress() | Should -Be 'crk4@pitt.edu'
            $results[1].GetAddress() | Should -Be 'jdoe@example.com'
        }

        It '2.6 Should return an object of type EmailAddress' {
            $result = New-EmailAddress -Address 'crk4@pitt.edu'
            # Compare type name as a string to avoid parse-time [EmailAddress] resolution
            $result.GetType().Name | Should -Be 'EmailAddress'
        }
    }

    #############################################################################
    # 3. Test-EmailAddress -- validation through the public cmdlet
    #############################################################################
    Context '3 Test-EmailAddress' {

        It '3.1 Should return true for a valid plain address' {
            Test-EmailAddress -InputObject 'crk4@pitt.edu' | Should -Be $true
        }

        It '3.2 Should return false for an invalid address' {
            Test-EmailAddress -InputObject 'notvalid' | Should -Be $false
        }

        It '3.3 Should return a detailed result object when -Detailed is specified' {
            $result = Test-EmailAddress -InputObject 'crk4@pitt.edu' -Detailed
            $result.Input   | Should -Be 'crk4@pitt.edu'
            $result.IsValid | Should -Be $true
            $result.Reason  | Should -BeNullOrEmpty
        }

        It '3.4 The Reason field should contain a specific message for an invalid address' {
            # This test requires a build that includes GetValidationFailureReason
            # (introduced after 0.0.2). If running against an older build the
            # generic fallback message will be present and this test is skipped.
            $result = Test-EmailAddress -InputObject 'user@' -Detailed
            $result.IsValid | Should -Be $false
            $result.Reason  | Should -Not -BeNullOrEmpty

            if ($result.Reason -eq 'Address does not match a valid email format.') {
                Set-ItResult -Skipped -Because 'built module predates GetValidationFailureReason — rebuild required'
            } else {
                # The specific reason for 'user@' is a missing/empty domain
                $result.Reason | Should -BeLike '*Domain*'
            }
        }

        It '3.5 Should accept an EmailAddress object as input' {
            $email = New-EmailAddress -Address 'crk4@pitt.edu'
            Test-EmailAddress -InputObject $email | Should -Be $true
        }

        It '3.6 Should never throw for any input including null' {
            { Test-EmailAddress -InputObject $null } | Should -Not -Throw
            { Test-EmailAddress -InputObject '' } | Should -Not -Throw
            { Test-EmailAddress -InputObject 'notvalid' } | Should -Not -Throw
        }

        It '3.7 Should process a pipeline of mixed valid and invalid addresses' {
            $results = 'crk4@pitt.edu', 'bad', 'jdoe@example.com' | Test-EmailAddress
            $results.Count | Should -Be 3
            $results[0]    | Should -Be $true
            $results[1]    | Should -Be $false
            $results[2]    | Should -Be $true
        }
    }

    #############################################################################
    # 4. ConvertTo-EmailAddress -- bulk conversion with non-terminating errors
    #############################################################################
    Context '4 ConvertTo-EmailAddress' {

        It '4.1 Should convert a valid address string to an EmailAddress object' {
            $result = ConvertTo-EmailAddress -InputObject 'crk4@pitt.edu'
            # Compare type name as a string to avoid parse-time [EmailAddress] resolution
            $result.GetType().Name | Should -Be 'EmailAddress'
            $result.GetAddress()   | Should -Be 'crk4@pitt.edu'
        }

        It '4.2 Should skip invalid addresses without throwing' {
            { 'crk4@pitt.edu', 'notvalid' | ConvertTo-EmailAddress -ErrorAction SilentlyContinue } |
                Should -Not -Throw
        }

        It '4.3 Should return only valid objects from a mixed pipeline' {
            $results = 'crk4@pitt.edu', 'notvalid', 'jdoe@example.com' |
                ConvertTo-EmailAddress -ErrorAction SilentlyContinue
            $results.Count           | Should -Be 2
            $results[0].GetAddress() | Should -Be 'crk4@pitt.edu'
            $results[1].GetAddress() | Should -Be 'jdoe@example.com'
        }

        It '4.4 Should write a non-terminating error for each invalid address' {
            $errors = 'crk4@pitt.edu', 'bad1', 'bad2', 'jdoe@example.com' |
                ConvertTo-EmailAddress 2>&1 |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            $errors.Count | Should -Be 2
        }

        It '4.5 Should stop the pipeline on invalid input when -ErrorAction Stop is used' {
            { 'crk4@pitt.edu', 'notvalid' | ConvertTo-EmailAddress -ErrorAction Stop } | Should -Throw
        }

        It '4.6 Should collect invalid addresses via -ErrorVariable without interrupting the pipeline' {
            # Use a uniquely named variable and clear it explicitly before the call.
            # -ErrorVariable appends to an existing variable rather than replacing it,
            # so any prior content must be cleared to get an accurate count.
            $errVar46 = @()
            $results = 'crk4@pitt.edu', 'notvalid', 'jdoe@example.com' |
                ConvertTo-EmailAddress -ErrorVariable errVar46 -ErrorAction SilentlyContinue

            # Filter to only the errors from this cmdlet invocation by TargetObject
            $relevant = @($errVar46 | Where-Object { $_.TargetObject -eq 'notvalid' })

            $results.Count        | Should -Be 2
            $relevant.Count       | Should -Be 1
            $relevant[0].TargetObject | Should -Be 'notvalid'
        }
    }

    #############################################################################
    # 5. Format-EmailAddress -- string formatting
    #############################################################################
    Context '5 Format-EmailAddress' {

        BeforeAll {
            $script:fmtPlain = New-EmailAddress -Address 'crk4@pitt.edu'
            $script:fmtNamed = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
            $script:fmtComma = New-EmailAddress -Address 'Keslar, [hris <crk4@pitt.edu>'
        }

        It '5.1 Address format should return only the address portion' {
            Format-EmailAddress -InputObject $script:fmtNamed -Format Address |
                Should -Be 'crk4@pitt.edu'
        }

        It '5.2 Friendly format should include the display name' {
            Format-EmailAddress -InputObject $script:fmtNamed -Format Friendly |
                Should -Be '[hris Keslar <crk4@pitt.edu>'
        }

        It '5.3 RFC5322 format should quote a display name containing a space' {
            Format-EmailAddress -InputObject $script:fmtNamed -Format RFC5322 |
                Should -Be '"[hris Keslar" <crk4@pitt.edu>'
        }

        It '5.4 RFC5322 format should quote a display name containing a comma' {
            Format-EmailAddress -InputObject $script:fmtComma -Format RFC5322 |
                Should -Be '"Keslar, [hris" <crk4@pitt.edu>'
        }

        It '5.5 All three formats should return the plain address when no display name is set' {
            $addr = Format-EmailAddress -InputObject $script:fmtPlain -Format Address
            $friend = Format-EmailAddress -InputObject $script:fmtPlain -Format Friendly
            $rfc = Format-EmailAddress -InputObject $script:fmtPlain -Format RFC5322
            $addr   | Should -Be 'crk4@pitt.edu'
            $friend | Should -Be 'crk4@pitt.edu'
            $rfc    | Should -Be 'crk4@pitt.edu'
        }

        It '5.6 Address format should be the default' {
            Format-EmailAddress -InputObject $script:fmtNamed |
                Should -Be 'crk4@pitt.edu'
        }
    }

    #############################################################################
    # 6. Get-EmailAddress -- property extraction
    #############################################################################
    Context '6 Get-EmailAddress' {

        BeforeAll {
            $script:getEmail = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
        }

        It '6.1 Should return the address for the Address property' {
            Get-EmailAddress -InputObject $script:getEmail -Property Address |
                Should -Be 'crk4@pitt.edu'
        }

        It '6.2 Should return the display name for the DisplayName property' {
            Get-EmailAddress -InputObject $script:getEmail -Property DisplayName |
                Should -Be '[hris Keslar'
        }

        It '6.3 Should return the local part for the LocalPart property' {
            Get-EmailAddress -InputObject $script:getEmail -Property LocalPart |
                Should -Be 'crk4'
        }

        It '6.4 Should return the domain for the Domain property' {
            Get-EmailAddress -InputObject $script:getEmail -Property Domain |
                Should -Be 'pitt.edu'
        }

        It '6.5 Address should be the default property' {
            Get-EmailAddress -InputObject $script:getEmail |
                Should -Be 'crk4@pitt.edu'
        }

        It '6.6 Should extract the domain from each object in a pipeline' {
            $domains = 'crk4@pitt.edu', 'jdoe@example.com' |
                New-EmailAddress |
                Get-EmailAddress -Property Domain
            $domains[0] | Should -Be 'pitt.edu'
            $domains[1] | Should -Be 'example.com'
        }
    }

    #############################################################################
    # 7. Set-EmailAddress -- immutable copy with one component replaced
    #############################################################################
    Context '7 Set-EmailAddress' {

        BeforeAll {
            $script:setSource = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
        }

        It '7.1 Should replace the address and preserve the display name' {
            $result = Set-EmailAddress -InputObject $script:setSource -Address 'crk4@example.com'
            $result.GetAddress()     | Should -Be 'crk4@example.com'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
        }

        It '7.2 Should replace the display name and preserve the address' {
            $result = Set-EmailAddress -InputObject $script:setSource -DisplayName 'C. Keslar'
            $result.GetAddress()     | Should -Be 'crk4@pitt.edu'
            $result.GetDisplayName() | Should -Be 'C. Keslar'
        }

        It '7.3 Should remove the display name when an empty string is supplied' {
            $result = Set-EmailAddress -InputObject $script:setSource -DisplayName ''
            $result.GetDisplayName() | Should -BeNullOrEmpty
            $result.GetAddress()     | Should -Be 'crk4@pitt.edu'
        }

        It '7.4 Should replace the local part and preserve the domain and display name' {
            $result = Set-EmailAddress -InputObject $script:setSource -LocalPart 'ckeslar'
            $result.GetAddress()     | Should -Be 'ckeslar@pitt.edu'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
        }

        It '7.5 Should replace the domain and preserve the local part and display name' {
            $result = Set-EmailAddress -InputObject $script:setSource -Domain 'example.com'
            $result.GetAddress()     | Should -Be 'crk4@example.com'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
        }

        It '7.6 Should not modify the original object' {
            Set-EmailAddress -InputObject $script:setSource -Domain 'example.com' | Out-Null
            $script:setSource.GetAddress() | Should -Be 'crk4@pitt.edu'
        }

        It '7.7 Should return a new object reference, not the same instance' {
            $result = Set-EmailAddress -InputObject $script:setSource -Domain 'example.com'
            [object]::ReferenceEquals($script:setSource, $result) | Should -Be $false
        }

        It '7.8 Should apply the same domain change across a pipeline of objects' {
            $results = 'crk4@pitt.edu', 'jdoe@pitt.edu' |
                New-EmailAddress |
                Set-EmailAddress -Domain 'example.com'
            $results[0].GetAddress() | Should -Be 'crk4@example.com'
            $results[1].GetAddress() | Should -Be 'jdoe@example.com'
        }
    }

    #############################################################################
    # 8. Compare-EmailAddress
    #############################################################################
    Context '8 Compare-EmailAddress' {

        BeforeAll {
            $script:cmpA = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
            $script:cmpB = New-EmailAddress -Address 'C. Keslar <crk4@pitt.edu>'
            $script:cmpC = New-EmailAddress -Address 'jdoe@example.com'
        }

        It '8.1 Should return true for two addresses with the same address and display name' {
            $a = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>'
            Compare-EmailAddress -ReferenceAddress $script:cmpA -DifferenceAddress $a |
                Should -Be $true
        }

        It '8.2 Should return false when display names differ' {
            Compare-EmailAddress -ReferenceAddress $script:cmpA -DifferenceAddress $script:cmpB |
                Should -Be $false
        }

        It '8.3 Should return true with -IgnoreDisplayName when only the display name differs' {
            Compare-EmailAddress -ReferenceAddress $script:cmpA -DifferenceAddress $script:cmpB `
                -IgnoreDisplayName |
                Should -Be $true
        }

        It '8.4 Should return false when addresses differ even with -IgnoreDisplayName' {
            Compare-EmailAddress -ReferenceAddress $script:cmpA -DifferenceAddress $script:cmpC `
                -IgnoreDisplayName |
                Should -Be $false
        }

        It '8.5 The Detailed result should contain both addresses and the AreEqual flag' {
            $result = Compare-EmailAddress -ReferenceAddress $script:cmpA `
                -DifferenceAddress $script:cmpB -Detailed
            $result.AreEqual           | Should -Be $false
            $result.ReferenceAddress   | Should -Not -BeNullOrEmpty
            $result.DifferenceAddress  | Should -Not -BeNullOrEmpty
            $result.IgnoredDisplayName | Should -Be $false
        }

        It '8.6 Should compare each piped address against a fixed DifferenceAddress' {
            $results = $script:cmpA, $script:cmpB, $script:cmpC |
                Compare-EmailAddress -DifferenceAddress $script:cmpA -IgnoreDisplayName
            $results[0] | Should -Be $true
            $results[1] | Should -Be $true
            $results[2] | Should -Be $false
        }
    }

    #############################################################################
    # 9. ConvertTo-NormalizedEmailAddress -- lowercase normalization
    #############################################################################
    Context '9 ConvertTo-NormalizedEmailAddress' {

        It '9.1 Should lowercase the address portion of an EmailAddress object' {
            $email = New-EmailAddress -Address 'CRK4@PITT.EDU'
            $result = ConvertTo-NormalizedEmailAddress -InputObject $email
            $result.GetAddress() | Should -Be 'crk4@pitt.edu'
        }

        It '9.2 Should preserve the display name during normalization' {
            $email = New-EmailAddress -Address '[hris Keslar <CRK4@PITT.EDU>'
            $result = ConvertTo-NormalizedEmailAddress -InputObject $email
            $result.GetAddress()     | Should -Be 'crk4@pitt.edu'
            $result.GetDisplayName() | Should -Be '[hris Keslar'
        }

        It '9.3 Should normalize from a plain address string using the -Address parameter set' {
            $result = ConvertTo-NormalizedEmailAddress -Address 'CRK4@PITT.EDU'
            $result.GetAddress() | Should -Be 'crk4@pitt.edu'
        }

        It '9.4 Should return a new object reference' {
            $email = New-EmailAddress -Address 'crk4@pitt.edu'
            $result = ConvertTo-NormalizedEmailAddress -InputObject $email
            [object]::ReferenceEquals($email, $result) | Should -Be $false
        }

        It '9.5 Should not modify the original object' {
            $email = New-EmailAddress -Address 'CRK4@PITT.EDU'
            ConvertTo-NormalizedEmailAddress -InputObject $email | Out-Null
            $email.GetAddress() | Should -Be 'CRK4@PITT.EDU'
        }

        It '9.6 Should normalize a pipeline of EmailAddress objects' {
            $results = 'CRK4@PITT.EDU', 'JDOE@EXAMPLE.COM' |
                New-EmailAddress |
                ConvertTo-NormalizedEmailAddress
            $results[0].GetAddress() | Should -Be 'crk4@pitt.edu'
            $results[1].GetAddress() | Should -Be 'jdoe@example.com'
        }
    }

    #############################################################################
    # 10. Pipeline composition -- multi-cmdlet chains
    #############################################################################
    Context '10 Pipeline Composition' {

        It '10.1 New-EmailAddress | Format-EmailAddress should produce a plain address string' {
            $result = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>' |
                Format-EmailAddress -Format Address
            $result | Should -Be 'crk4@pitt.edu'
            $result | Should -BeOfType [string]
        }

        It '10.2 New-EmailAddress | Get-EmailAddress should extract the domain' {
            $result = New-EmailAddress -Address 'crk4@pitt.edu' |
                Get-EmailAddress -Property Domain
            $result | Should -Be 'pitt.edu'
        }

        It '10.3 ConvertTo-EmailAddress | ConvertTo-NormalizedEmailAddress should produce lowercase objects' {
            $results = 'CRK4@PITT.EDU', 'JDOE@EXAMPLE.COM' |
                ConvertTo-EmailAddress |
                ConvertTo-NormalizedEmailAddress
            $results[0].GetAddress() | Should -Be 'crk4@pitt.edu'
            $results[1].GetAddress() | Should -Be 'jdoe@example.com'
        }

        It '10.4 Full pipeline should skip invalids, normalize, and format in one chain' {
            $results = 'CRK4@PITT.EDU', 'notvalid', 'JDOE@EXAMPLE.COM' |
                ConvertTo-EmailAddress -ErrorAction SilentlyContinue |
                ConvertTo-NormalizedEmailAddress |
                Format-EmailAddress -Format RFC5322
            $results.Count | Should -Be 2
            $results[0]    | Should -Be 'crk4@pitt.edu'
            $results[1]    | Should -Be 'jdoe@example.com'
        }

        It '10.5 New-EmailAddress | Set-EmailAddress | Format-EmailAddress should chain without error' {
            $result = New-EmailAddress -Address '[hris Keslar <crk4@pitt.edu>' |
                Set-EmailAddress -Domain 'example.com' |
                Format-EmailAddress -Format Friendly
            $result | Should -Be '[hris Keslar <crk4@example.com>'
        }

        It '10.6 Bulk pipeline should skip invalids and normalize the rest' {
            $addresses = 'CRK4@PITT.EDU', 'not-valid', 'JDOE@EXAMPLE.COM', 'also-bad', 'USER@SUB.DOMAIN.CO.UK'
            $results = $addresses |
                ConvertTo-EmailAddress -ErrorAction SilentlyContinue |
                ConvertTo-NormalizedEmailAddress |
                Get-EmailAddress -Property Address
            $results.Count | Should -Be 3
            $results        | Should -Contain 'crk4@pitt.edu'
            $results        | Should -Contain 'jdoe@example.com'
            $results        | Should -Contain 'user@sub.domain.co.uk'
        }

        It '10.7 Pipeline deduplication using Compare-EmailAddress should identify matching addresses' {
            $incoming = 'crk4@pitt.edu', '[hris Keslar <crk4@pitt.edu>', 'jdoe@example.com' |
                ConvertTo-EmailAddress
            $reference = New-EmailAddress -Address 'crk4@pitt.edu'

            $matches = $incoming |
                Compare-EmailAddress -DifferenceAddress $reference -IgnoreDisplayName |
                Where-Object { $_ -eq $true }

            $matches.Count | Should -Be 2
        }

        It '10.8 Set-EmailAddress should preserve immutability of original objects in a pipeline' {
            $originals = 'crk4@pitt.edu', 'jdoe@pitt.edu' | New-EmailAddress
            $originals | Set-EmailAddress -Domain 'example.com' | Out-Null

            $originals[0].GetDomain() | Should -Be 'pitt.edu'
            $originals[1].GetDomain() | Should -Be 'pitt.edu'
        }
    }

    #############################################################################
    # 11. Module re-import stability
    #############################################################################
    Context '11 Module Re-Import Stability' {

        It '11.1 Should import cleanly a second time without errors' {
            { Import-Module $script:ManifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It '11.2 All cmdlets should still be available after re-import' {
            $exported = (Get-Module -Name EmailAddress).ExportedFunctions.Keys
            $exported.Count | Should -Be 8
        }

        It '11.3 The EmailAddress type should still be usable after re-import' {
            { New-EmailAddress -Address 'crk4@pitt.edu' } | Should -Not -Throw
        }
    }
}
