BeforeAll {
    # Find the project root by going up three levels from the current script directory
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..")).Path
    
    # Set the data directory to the project Data folder for testing
    $env:EMAILADDRESS_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"
    
    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/source/prefix.ps1
}

Describe "prefix.ps1" {
    Context "1.0 Script Variables - Default State" {
        It "1.1 Should define cacheEmailAddressDataDirectory as a script variable" {
            $result = Get-Variable -Name "cacheEmailAddressDataDirectory" -Scope Script -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }
    }
    Context "2.0 Data Directory - Environment Variable Override" {
        It "2.1 Should set cacheEmailAddressDataDirectory to the EMAILADDRESS_DATA_DIR environment variable when set" {
            $script:cacheEMAILADDRESSDataDirectory | Should -Be $env:EMAILADDRESS_DATA_DIR
        }
        It "2.2 Should set cacheEMAILADDRESSDataDirectory to a valid path" {
            $script:cacheEMAILADDRESSDataDirectory | Should -Not -BeNullOrEmpty
        }
        It "2.3 Should use the PSScriptRoot-relative Data path when EMAILADDRESS_DATA_DIR is not set" {
            # Save and clear the environment variable
            $saved = $env:EMAILADDRESS_DATA_DIR
            Remove-Item Env:EMAILADDRESS_DATA_DIR -ErrorAction SilentlyContinue

            # Re-dot-source to pick up the change
            $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..")).Path
            . (Join-Path -Path $ProjectRoot -ChildPath "source\prefix.ps1")

            $script:cacheEMAILADDRESSDataDirectory | Should -BeLike "*Data*"

            # Restore environment variable and re-dot-source
            $env:EMAILADDRESS_DATA_DIR = $saved
            . (Join-Path -Path $ProjectRoot -ChildPath "source\prefix.ps1")
        }
        It "2.4 Should reflect a changed EMAILADDRESS_DATA_DIR when re-sourced" {
            $saved = $env:EMAILADDRESS_DATA_DIR
            $env:EMAILADDRESS_DATA_DIR = "C:\Temp\TestData"

            $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..")).Path
            . (Join-Path -Path $ProjectRoot -ChildPath "source\prefix.ps1")

            $script:cacheEMAILADDRESSDataDirectory | Should -Be "C:\Temp\TestData"

            # Restore
            $env:EMAILADDRESS_DATA_DIR = $saved
            . (Join-Path -Path $ProjectRoot -ChildPath "source\prefix.ps1")
        }
    }
}