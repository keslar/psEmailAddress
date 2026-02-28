# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## v0.0.2 (2026-02-27)

### Added
- `Set-EmailAddress` cmdlet: returns a new `EmailAddress` object with one component replaced (`-Address`, `-DisplayName`, `-LocalPart`, or `-Domain`), preserving all other components from the original
- Pester unit tests for `Set-EmailAddress` covering all four parameter sets, immutability behavior, pipeline input, and invalid replacement error handling
- `Resolve-EmailAddressInput` private helper function: resolves a parameter value that may be either a plain string, a named mailbox string, or an `[EmailAddress]` object into an `[EmailAddress]` instance; used by `Compare-EmailAddress`
- Pester unit tests for `Resolve-EmailAddressInput`
- Integration test scaffolding in `Tests/Integration/EmailAddress.Integration.Tests.ps1`: locates and imports the built module, with a Module Loading context verifying the module imports cleanly and all 8 cmdlets are exported
- GitHub Actions release workflow (`.github/workflows/release.yml`): triggered on version tags, runs the full Clean → Analyze → Build → Test → Publish pipeline, extracts the matching CHANGELOG section for the GitHub Release body, and creates the GitHub Release
- `InvokeBuild` task `TestIntegration`: runs integration tests against the built module output using `$env:EMAILADDRESS_BUILT_MODULE` to locate the correct build
- `InvokeBuild` task `Test`: convenience task that runs both `TestUnit` and `TestIntegration` in sequence
- `InvokeBuild` task `Release`: full release pipeline — `Clean`, `Analyze`, `Build`, `Test`, `Publish`
- `InvokeBuild` task `Publish`: publishes the built module to the PowerShell Gallery using `Publish-Module`; requires `-GalleryApiKey` or `PS_GALLERY_KEY` environment variable

### Changed
- `Compare-EmailAddress` now uses `Resolve-EmailAddressInput` internally to accept plain strings, named mailbox strings, or `[EmailAddress]` objects for both `-ReferenceAddress` and `-DifferenceAddress`
- `-DifferenceAddress` in `Compare-EmailAddress` is now resolved once in the `begin` block rather than on each pipeline iteration, ensuring consistent behavior across all piped inputs
- Build task (`InvokeBuild` default task) updated from `Analyze, Build, Test` to `Analyze, Build, TestUnit` so the default task does not require a prior build for integration tests

---

## v0.0.1 (2026-02-27)

### Added
- `EmailAddress` class: immutable value type representing a single RFC 5321/5322 email address with an optional display name in named mailbox format (`Display Name <local-part@domain>`)
  - Constructor accepting a plain address string or named mailbox string
  - Static factory methods: `FromString`, `TryFromString` / `TryParseEmailAddressFromString`, `FromComponents`, `TryFromComponents` / `TryParseEmailAddressFromComponents`, `GetEmailAddressFromString`, `GetEmailAddressFromComponents`
  - Instance accessor methods: `GetAddress`, `GetDisplayName`, `GetLocalPart`, `GetDomain`, `GetFriendlyName` (and aliases `FriendlyName`, `NamedMailbox`, `Mailbox`)
  - Formatting methods: `ToString` (plain address), `ToFriendlyString`, `ToRFC5322String` (with display name quoting per RFC 5322)
  - Comparison and equality methods: `Equals`, `EqualsIgnoreDisplayName`, `GetHashCode`
  - Static validation methods: `IsValidEmailAddressFormat`, `IsValidFormat`, `IsValidEmailAddress`, `IsValid`, `GetValidationFailureReason`
  - Static normalization methods: `NormalizeEmailAddress`, `NormalizeEmailAddressObject`
  - Static comparison method: `AreEqualIgnoringDisplayName`
  - Read-only script properties `Address` and `DisplayName` registered via `Update-TypeData`
  - RFC 5321/5322 validation covering: single `@` requirement, local part length (1–64 chars) and allowed characters, dot placement rules, domain length (1–255 chars), label length (1–63 chars), label character and hyphen rules, TLD minimum length (2 chars), and total address length (max 320 chars)
- `New-EmailAddress` cmdlet: creates an `[EmailAddress]` object from a plain/named mailbox string (`FromString` parameter set) or from component parts (`FromComponents` parameter set); invalid input is a terminating error; accepts pipeline input
- `Test-EmailAddress` cmdlet: tests one or more strings against RFC 5321/5322 validation rules; returns `[bool]` by default or a `[PSCustomObject]` with `Input`, `IsValid`, and `Reason` properties when `-Detailed` is specified; never throws; accepts pipeline input
- `ConvertTo-EmailAddress` cmdlet: bulk-converts strings to `[EmailAddress]` objects; invalid input produces a non-terminating error and is skipped (use `-ErrorAction Stop` to make it terminating); accepts pipeline input
- `ConvertTo-NormalizedEmailAddress` cmdlet: returns new `[EmailAddress]` objects with the address portion lowercased and trimmed; preserves display name; accepts `[EmailAddress]` objects (`FromEmailAddress` parameter set) or strings (`FromString` parameter set); accepts pipeline input
- `Format-EmailAddress` cmdlet: formats an `[EmailAddress]` object as a string in one of three modes — `Address` (default), `Friendly`, or `RFC5322`; accepts pipeline input
- `Get-EmailAddress` cmdlet: extracts a single named property from an `[EmailAddress]` object — `Address`, `DisplayName`, `LocalPart`, `Domain`, `Friendly`, or `RFC5322`; accepts pipeline input
- `Compare-EmailAddress` cmdlet: compares two email addresses for equality; supports `-IgnoreDisplayName` to compare address portions only and `-Detailed` to return a `[PSCustomObject]` with `ReferenceAddress`, `DifferenceAddress`, `AreEqual`, and `IgnoredDisplayName` properties; accepts pipeline input on `-ReferenceAddress`
- Pester unit test suites for all public cmdlets and the `EmailAddress` class
- `ModuleBuilder`-based build system via `InvokeBuild` (`.build.ps1`) with tasks: `Clean`, `Analyze`, `Build`, `TestUnit`
- Version resolution chain in `.build.ps1`: `-SemVer` parameter → `version.txt` → GitVersion → git tag → manifest auto-increment
- `{{MODULE_VERSION}}` and `{{BUILD_DATE}}` token substitution in the built `.psm1` at build time
- GitHub Actions CI workflow (`.github/workflows/ci.yml`): runs on every push and pull request to `main`; matrix covers Windows PS 5.1, Windows PS 7, and Ubuntu PS 7; runs Analyze → Build → Unit Tests → Integration Tests; uploads JUnit XML test results and Pester code coverage artifacts
- `PSScriptAnalyzerSettings.ps1`: enforces `Error` and `Warning` severity rules with targeted exclusions
- `RequiredModules.psd1`: declares build tool dependencies (`InvokeBuild`, `ModuleBuilder`, `Pester`, `PSScriptAnalyzer`, `Configuration`, `Metadata`, `PowerShellGet`) with NuGet version range constraints
- GitHub community files: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, `FUNDING.md`, `CODEOWNERS`, bug report and feature request issue templates, bug fix and feature PR templates, `dependabot.yml`
- `Docs/help/en-US/about_EmailAddress.help.txt`: conceptual help topic placeholder
- `LICENSE.md`: MIT License
