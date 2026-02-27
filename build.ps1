# build.ps1
param(
    [string]$SemVer,
    [switch]$Test,
    [switch]$Publish
)

$ProjectRoot = $PSScriptRoot
$ModuleName = Split-Path -Path (Get-Location) -Leaf

$buildParams = @{
    SourcePath      = Join-Path -Path $ProjectRoot -ChildPath "Source"
    OutputDirectory = Join-Path -Path $ProjectRoot -ChildPath "Build"
}

# Build
Write-Host "Building module . . . ."
# Determine the version of the module to be built
if ($SemVer) {
    # Set the build version from the command-line 
    $buildParams.SemVer = $SemVer 
} elseif (Test-Path -Path "$ProjectRoot/version.txt") {
    # Set the build version from a text file
    $buildParams.SemVer = (Get-Content "$ProjectRoot/version.txt").Trim()
} elseif ((Test-Path "$ProjectRoot/.git" -PathType Container) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    # Set the build version from the git repository if we are in the root of a repository and git is installed
    if (Get-Command gitversion -ErrorAction SilentlyContinue) {
        # Use gitversion if it is installed
        $version = (gitversion | ConvertFrom-Json).SemVer
        $buildParams.SemVer = $version
    } else {
        # Use a git tag 
        $buildParams.SemVer = (git describe --tags --abbrev=0).TrimStart('v')
    }
} else {
    # Use the version in the manifest after incrementing the patch vrsion
    Write-Warning " PSD1 = $($ProjectRoot)/source/$ModuleName.psd1)"
    $manifest = Import-PowerShellDataFile "$ProjectRoot/source/$ModuleName.psd1"
    $current = [version]$manifest.ModuleVersion
    $buildParams.SemVer = "{0}.{1}.{2}" -f $current.Major, $current.Minor, ($current.Build + 1)
}


$module = Build-Module @buildParams -Passthru

# Replace {{BUILD_DATE}} placeholder in the built .psm1
$psm1Path = Join-Path $module.ModuleBase "$($module.Name).psm1"
if (Test-Path $psm1Path) {
    $buildDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $content = Get-Content $psm1Path -Raw
    $contenUpdated = $false

    if ($content -match '\{\{BUILD_DATE\}\}') {
        $content = $content -replace '\{\{BUILD_DATE\}\}', $buildDate
        $contenUpdated = $true
    }

    if ($content -match '\{\{MODULE_VERSION\}\}') {
        $content = $content -replace '\{\{MODULE_VERSION\}\}', $buildParams.SemVer
        $contenUpdated = $true
    }

    if ($contenUpdated) {
        Set-Content -Path $psm1Path -Value $content -NoNewline
        Write-Host "Stamped build date: $buildDate"
    }
}


Write-Host "Built $($module.Name) $($module.Version) → $($module.ModuleBase)"

# Test
if ($Test) {
    Write-Host "Running tests  . . ."
    $results = Invoke-Pester ./Tests -PassThru
    if ($results.FailedCount -gt 0) { throw "$($results.FailedCount) tests failed" }
}

# Publish
if ($Publish) {
    Write-Host "Publishing module . . ."
    Publish-Module -Path $module.ModuleBase -NuGetApiKey $env:PS_GALLERY_KEY
}