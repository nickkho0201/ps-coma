param(
    [switch]$ElevationRequested
)

& {
    param($invocationPath, $elevationRequested)

    $toggleSource = @'
        param(
            [switch]$ElevationRequested,
            [string]$ScriptPath = $PSCommandPath
        )

        $registryKey = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services\Client'
        $valueName = 'RedirectionWarningDialogVersion'
        $exitCode = 1

        try {
            $operation = 'проверка прав администратора'
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]::new($identity)
            if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                $operation = 'запуск с правами администратора'
                if ($ElevationRequested) {
                    throw 'Повторный запуск не получил права администратора.'
                }

                $executable = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'powershell.exe' } else { 'pwsh.exe' }
                $arguments = '-NoProfile -File "{0}" -ElevationRequested' -f $scriptPath
                $process = Start-Process -FilePath (Join-Path $PSHOME $executable) -ArgumentList $arguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
                exit $process.ExitCode
            }

            $operation = 'чтение реестра'
            try {
                $key = Get-Item -LiteralPath "Registry::$registryKey" -ErrorAction Stop
                $valueExists = $key.GetValueNames() -contains $valueName
            }
            catch [System.Management.Automation.ItemNotFoundException] {
                $valueExists = $false
            }

            if ($valueExists) {
                $operation = 'удаление параметра'
                reg.exe delete $registryKey /v $valueName
            }
            else {
                $operation = 'создание параметра'
                reg.exe add $registryKey /v $valueName /t REG_DWORD /d 1 /f
            }

            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
                throw "reg.exe завершилась с кодом $exitCode. Сообщение команды приведено выше."
            }
        }
        catch {
            Write-Host "Сбой при выполнении операции «$operation» для $valueName." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red

            try {
                $null = Read-Host 'Нажмите Enter, чтобы закрыть окно'
            }
            finally {
                exit $exitCode
            }
        }

        if ($valueExists) {
            Write-Host "Параметр $valueName удалён." -ForegroundColor Green
        }
        else {
            Write-Host "Параметр $valueName создан со значением 1 (REG_DWORD)." -ForegroundColor Green
        }

        if ($ElevationRequested) {
            $null = Read-Host 'Нажмите Enter, чтобы закрыть окно'
        }

        exit $exitCode
'@

    # Read the UTF-8 body explicitly when Windows PowerShell opens the file locally.
    if ($invocationPath -and $PSVersionTable.PSEdition -eq 'Desktop') {
        $source = [IO.File]::ReadAllText($invocationPath, [Text.Encoding]::UTF8)
        $tokens = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$null)
        $toggleSource = ($tokens | Where-Object Kind -eq 'HereStringLiteral' | Select-Object -First 1).Value
    }
    $toggle = [scriptblock]::Create($toggleSource)

    if ($invocationPath) {
        # Run the same body when called as a local .ps1 file.
        & $toggle -ElevationRequested:$elevationRequested -ScriptPath $invocationPath
        return
    }

    # Invoke-Expression has no script file for the elevated process to reopen.
    $tempScript = [IO.Path]::ChangeExtension([IO.Path]::GetTempFileName(), '.ps1')
    $tempFile = [IO.Path]::ChangeExtension($tempScript, '.tmp')
    try {
        [IO.File]::WriteAllText($tempFile, $toggle.ToString(), [Text.UTF8Encoding]::new($true))
        [IO.File]::Move($tempFile, $tempScript)
        & $tempScript
    }
    finally {
        [IO.File]::Delete($tempFile)
        [IO.File]::Delete($tempScript)
    }
} $PSCommandPath $ElevationRequested
