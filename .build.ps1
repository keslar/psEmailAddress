<#
.SYNOPSIS
    InvokeBuild script for the EmailAddress module.

.DESCRIPTION
    Defines build tasks for the EmailAddress module using InvokeBuild.
    Tasks cover the full pipeline: clean, analyze, build, test, and publish.

.NOTES
    Author(s):  [.Keslar <crk4@pitt.edu>
    Requires:   InvokeBuild, ModuleBuilder, Pester, PSScriptAnalyzer
                Install via: Resolve-Dependency (RequiredModules.psd1)

.EXAMPLE
    # Run the default task (Analyze → Build → Test)
    Invoke-Build

.EXAMPLE
    # Clean, then run the full pipeline
    Invoke-Build Clean, Analyze, Build, Test

.EXAMPLE
    # Build and run only unit tests
    Invoke-Build Build, TestUnit

.EXAMPLE
    # Full release pipeline: clean, analyze, build, test, publish
    Invoke-Build Release
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    # Semantic version to stamp on the build. If omitted, resolved automatically
    # via version.txt, git tags, GitVersion, or manifest auto-increment (in that order).
    [string]$SemVer,

    # NuGet API key for PowerShell Gallery publication.
    # Defaults to the PS_GALLERY_KEY environment variable.
    [string]$GalleryApiKey = $env:PS_GALLERY_KEY
)

###############################################################################
## Script-level constants
###############################################################################

$Script:ProjectRoot = $BuildRoot
$Script:ModuleName = 'EmailAddress'
$Script:SourcePath = Join-Path $BuildRoot 'Source'
$Script:BuildOutput = Join-Path $BuildRoot 'Build'
$Script:TestsPath = Join-Path $BuildRoot 'Tests'
$Script:UnitTestsPath = Join-Path $BuildRoot 'Tests' 'Unit'
$Script:IntTestsPath = Join-Path $BuildRoot 'Tests' 'Integration'
$Script:AnalyzerSettings = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.ps1'

###############################################################################
## Version resolution — shared by Build and any task that needs the version
###############################################################################

function Get-BuildVersion {
    <#
    .SYNOPSIS
        Resolves the semantic version for this build using a priority chain.
    #>
    if ($SemVer) {
        Write-Build DarkCyan "  Version source: -SemVer parameter ($SemVer)"
        return $SemVer
    }

    $versionFile = Join-Path $Script:ProjectRoot 'version.txt'
    if (Test-Path $versionFile) {
        $v = (Get-Content $versionFile -Raw).Trim()
        Write-Build DarkCyan "  Version source: version.txt ($v)"
        return $v
    }

    $gitDir = Join-Path $Script:ProjectRoot '.git'
    if ((Test-Path $gitDir -PathType Container) -and (Get-Command git -ErrorAction SilentlyContinue)) {
        if (Get-Command gitversion -ErrorAction SilentlyContinue) {
            $v = (gitversion | ConvertFrom-Json).SemVer
            Write-Build DarkCyan "  Version source: GitVersion ($v)"
            return $v
        }
        $tag = git describe --tags --abbrev=0 2>$null
        if ($tag) {
            $v = $tag.TrimStart('v')
            Write-Build DarkCyan "  Version source: git tag ($v)"
            return $v
        }
    }

    # Fall back: read manifest and auto-increment the patch segment
    $manifestPath = Join-Path $Script:SourcePath "$Script:ModuleName.psd1"
    $manifest = Import-PowerShellDataFile $manifestPath
    $current = [version]$manifest.ModuleVersion
    $v = '{0}.{1}.{2}' -f $current.Major, $current.Minor, ($current.Build + 1)
    Write-Build Yellow "  Version source: manifest auto-increment ($v)"
    return $v
}

###############################################################################
## Tasks
###############################################################################

# Default task — run when Invoke-Build is called with no task name
task . Analyze, Build, TestUnit

#------------------------------------------------------------------------------
# Clean — remove all build output
#------------------------------------------------------------------------------
task Clean {
    Write-Build Cyan 'Cleaning build output...'
    $moduleOutput = Join-Path $Script:BuildOutput $Script:ModuleName
    if (Test-Path $moduleOutput) {
        Remove-Item -Path $moduleOutput -Recurse -Force
        Write-Build Green "  Removed: $moduleOutput"
    } else {
        Write-Build DarkGray '  Nothing to clean.'
    }
}

#------------------------------------------------------------------------------
# Analyze — run PSScriptAnalyzer against all source files
#------------------------------------------------------------------------------
task Analyze {
    Write-Build Cyan 'Running PSScriptAnalyzer...'

    $analyzeParams = @{
        Path        = $Script:SourcePath
        Settings    = $Script:AnalyzerSettings
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
    }

    $findings = Invoke-ScriptAnalyzer @analyzeParams

    if ($findings) {
        $errors = @($findings | Where-Object Severity -EQ 'Error')
        $warnings = @($findings | Where-Object Severity -EQ 'Warning')

        foreach ($finding in $findings) {
            $color = if ($finding.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
            Write-Build $color "  [$($finding.Severity)] $($finding.RuleName)"
            Write-Build $color "    $($finding.ScriptName) line $($finding.Line): $($finding.Message)"
        }

        Write-Build White "  Errors: $($errors.Count)   Warnings: $($warnings.Count)"

        if ($errors.Count -gt 0) {
            throw "PSScriptAnalyzer found $($errors.Count) error(s). Fix before building."
        }
    } else {
        Write-Build Green '  No issues found.'
    }
}

#------------------------------------------------------------------------------
# Build — compile source into a single .psm1 via ModuleBuilder
#------------------------------------------------------------------------------
task Build {
    Write-Build Cyan 'Building module...'

    $version = Get-BuildVersion

    $buildParams = @{
        SourcePath      = $Script:SourcePath
        OutputDirectory = $Script:BuildOutput
        SemVer          = $version
    }

    $module = Build-Module @buildParams -Passthru

    # Stamp {{BUILD_DATE}} and {{MODULE_VERSION}} placeholders in the built .psm1
    $psm1Path = Join-Path $module.ModuleBase "$($module.Name).psm1"
    if (Test-Path $psm1Path) {
        $buildDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $content = Get-Content $psm1Path -Raw
        $contentUpdated = $false

        if ($content -match '\{\{BUILD_DATE\}\}') {
            $content = $content -replace '\{\{BUILD_DATE\}\}', $buildDate
            $contentUpdated = $true
        }

        if ($content -match '\{\{MODULE_VERSION\}\}') {
            $content = $content -replace '\{\{MODULE_VERSION\}\}', $version
            $contentUpdated = $true
        }

        if ($contentUpdated) {
            Set-Content -Path $psm1Path -Value $content -NoNewline
            Write-Build DarkCyan "  Stamped version $version and build date $buildDate"
        }
    }

    Write-Build Green "  Built: $($module.Name) $($module.Version) → $($module.ModuleBase)"

    # Persist the resolved module base path for downstream tasks
    $Script:BuiltModuleBase = $module.ModuleBase
    $Script:BuiltVersion = $module.Version
}

#------------------------------------------------------------------------------
# TestUnit — run unit tests against dot-sourced source files (no Import-Module)
#------------------------------------------------------------------------------
task TestUnit {
    Write-Build Cyan 'Running unit tests...'

    $config = New-PesterConfiguration
    $config.Run.Path = $Script:UnitTestsPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Normal'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'JUnitXml'
    $config.TestResult.OutputPath = Join-Path $Script:ProjectRoot 'TestResults-Unit.xml'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $Script:SourcePath
    $config.CodeCoverage.OutputPath = Join-Path $Script:ProjectRoot 'Coverage-Unit.xml'
    $config.CodeCoverage.Threshold = 90

    $results = Invoke-Pester -Configuration $config

    Write-Build White "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

    if ($results.FailedCount -gt 0) {
        throw "Unit tests: $($results.FailedCount) test(s) failed."
    }

    if ($results.CodeCoverage.CoveragePercent -lt 90) {
        throw "Code coverage $([math]::Round($results.CodeCoverage.CoveragePercent, 1))% is below the 90% threshold."
    }

    Write-Build Green "  All unit tests passed. Coverage: $([math]::Round($results.CodeCoverage.CoveragePercent, 1))%"
}

#------------------------------------------------------------------------------
# TestIntegration — run integration tests against the *built* module output
#------------------------------------------------------------------------------
task TestIntegration Build, {
    Write-Build Cyan 'Running integration tests...'

    if (-not $Script:BuiltModuleBase) {
        throw 'BuiltModuleBase is not set. Run the Build task first.'
    }

    if (-not (Test-Path $Script:IntTestsPath)) {
        Write-Build Yellow '  No integration tests found — skipping.'
        return
    }

    # Integration tests import the built module, not dot-sourced source files
    $env:EMAILADDRESS_BUILT_MODULE = $Script:BuiltModuleBase

    $config = New-PesterConfiguration
    $config.Run.Path = $Script:IntTestsPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Normal'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'JUnitXml'
    $config.TestResult.OutputPath = Join-Path $Script:ProjectRoot 'TestResults-Integration.xml'

    $results = Invoke-Pester -Configuration $config

    Write-Build White "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

    if ($results.FailedCount -gt 0) {
        throw "Integration tests: $($results.FailedCount) test(s) failed."
    }

    Write-Build Green '  All integration tests passed.'
}

#------------------------------------------------------------------------------
# Test — run both unit and integration test suites
#------------------------------------------------------------------------------
task Test TestUnit, TestIntegration

#------------------------------------------------------------------------------
# Publish — publish the built module to the PowerShell Gallery
#------------------------------------------------------------------------------
task Publish Build, Test, {
    Write-Build Cyan 'Publishing to PowerShell Gallery...'

    if (-not $Script:BuiltModuleBase) {
        throw 'BuiltModuleBase is not set. Run the Build task first.'
    }

    if ([string]::IsNullOrWhiteSpace($GalleryApiKey)) {
        throw 'No Gallery API key. Pass -GalleryApiKey or set the PS_GALLERY_KEY environment variable.'
    }

    Publish-Module -Path $Script:BuiltModuleBase -NuGetApiKey $GalleryApiKey
    Write-Build Green "  Published $Script:ModuleName $Script:BuiltVersion to the PowerShell Gallery."
}

#------------------------------------------------------------------------------
# Release — full pipeline: clean, analyze, build, test, publish
#------------------------------------------------------------------------------
task Release Clean, Analyze, Build, Test, Publish
