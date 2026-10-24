[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $FlutterArguments
)

$ErrorActionPreference = 'Stop'
$flutterMutex = [System.Threading.Mutex]::new($false, 'Local\MocochoviskFlutter')
try {
    $null = $flutterMutex.WaitOne()
} catch [System.Threading.AbandonedMutexException] {
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$originalPath = $env:PATH
$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;$env:SystemRoot\System32\WindowsPowerShell\v1.0;$env:PATH"
$mappedDrive = $null
$substExecutable = Join-Path $env:SystemRoot 'System32\subst.exe'
if ($projectRoot -match '\s' -and (Test-Path -LiteralPath (Join-Path $projectRoot '.tooling\flutter\bin\flutter.bat'))) {
    foreach ($driveLetter in @('Z', 'Y', 'X', 'W', 'V', 'U', 'T')) {
        if (-not (Test-Path -LiteralPath "${driveLetter}:\")) {
            & $substExecutable "${driveLetter}:" $projectRoot
            if ($LASTEXITCODE -ne 0) { throw 'Não foi possível preparar um caminho curto para o Flutter.' }
            $mappedDrive = "${driveLetter}:"
            $projectRoot = "${driveLetter}:\"
            break
        }
    }
    if ($null -eq $mappedDrive) { throw 'Nenhuma unidade temporária disponível. Execute o projeto em um caminho sem espaços.' }
}
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
    if ($null -ne $mappedDrive) { & $substExecutable $mappedDrive /D }
    $env:PATH = $originalPath
    $flutterMutex.ReleaseMutex()
    $flutterMutex.Dispose()
}
exit $flutterExitCode
