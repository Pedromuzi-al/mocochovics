[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $FlutterArguments
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localFlutter = Join-Path $projectRoot '.tooling\flutter\bin\flutter.bat'
if (Test-Path -LiteralPath $localFlutter) {
    $flutterExecutable = $localFlutter
} else {
    $flutterExecutable = (Get-Command flutter -ErrorAction Stop).Source
}

Push-Location -LiteralPath $projectRoot
try {
    & $flutterExecutable @FlutterArguments
    $flutterExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $flutterExitCode
