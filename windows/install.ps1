# Run all Windows install scripts in order. Stops at the first failure.
#   .\install.ps1   # tools, shell, configs

foreach ($step in 'install-tools.ps1', 'install-shell.ps1', 'install-configs.ps1') {
    Write-Host "`n##### $step #####"
    $global:LASTEXITCODE = 0
    & "$PSScriptRoot\$step"
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

Write-Host "`nAll done. Open the 'MSYS2 zsh' profile in Windows Terminal."
