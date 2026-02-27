<#
.SYNOPSIS
    
.DESCRIPTION

.NOTES
    Version:        {{MODULE_VERSION}}
    Author(s):      [.Keslar <crk4@pitt.edu>
    Date:           {{BUILD_DATE}}

.LINK

#>
###############################################################################
## CONSTANTS and Script Variables
$script:cacheEmailAddressDataDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Data"


###############################################################################
## Update the data directory if the environment variable is set
if ($env:EMAILADDRESS_DATA_DIR) {
    $script:cacheEmailAddressDataDirectory = $env:EMAILADDRESS_DATA_DIR
}