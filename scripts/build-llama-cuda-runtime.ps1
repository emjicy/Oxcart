$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/ggml-org/llama.cpp'
$CloneDir = 'C:\Users\Melox\OneDrive\Documents\llama-cuda-oxcart'
$RuntimeDir = 'C:\Users\Melox\OneDrive\Documents\oxcart-llama-server-cuda-runtime'
$ZipPath = 'C:\Users\Melox\OneDrive\Documents\oxcart-llama-server-cuda-runtime.zip'

function Run-Step([string]$Cmd, [string]$WorkDir) {
    Write-Host "`n>>> $Cmd" -ForegroundColor Cyan
    Push-Location $WorkDir
    try {
        cmd /c $Cmd
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE: $Cmd"
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path $CloneDir)) {
    Run-Step "git clone $RepoUrl $CloneDir" (Get-Location).Path
} else {
    Run-Step "git -C $CloneDir fetch --all --prune" (Get-Location).Path
    Run-Step "git -C $CloneDir reset --hard origin/master" (Get-Location).Path
}

$WebUiDir = Join-Path $CloneDir 'examples\server\webui'
if (Test-Path $WebUiDir) {
    Run-Step 'npm ci' $WebUiDir
    Run-Step 'npm run check' $WebUiDir
    Run-Step 'npm run lint' $WebUiDir
    Run-Step 'npm run build' $WebUiDir
} else {
    Write-Host "WebUI directory not found at $WebUiDir; skipping WebUI build." -ForegroundColor Yellow
}

Run-Step 'cmake -S . -B build-cuda -G "Visual Studio 17 2022" -A x64 -DGGML_CUDA=ON -DGGML_NATIVE=OFF -DLLAMA_CURL=ON -DCMAKE_BUILD_TYPE=Release' $CloneDir
Run-Step 'cmake --build build-cuda --config Release --target llama-server -j' $CloneDir

$BuildDir = Join-Path $CloneDir 'build-cuda'
$LlamaServer = Get-ChildItem -Path $BuildDir -Filter 'llama-server.exe' -Recurse | Select-Object -First 1
if (-not $LlamaServer) {
    throw 'Could not find llama-server.exe in build-cuda output.'
}

if (Test-Path $RuntimeDir) { Remove-Item -LiteralPath $RuntimeDir -Force -Recurse }
New-Item -ItemType Directory -Path $RuntimeDir | Out-Null

Copy-Item -LiteralPath $LlamaServer.FullName -Destination (Join-Path $RuntimeDir 'llama-server.exe') -Force

$Dlls = Get-ChildItem -Path $BuildDir -Filter '*.dll' -Recurse |
    Where-Object { $_.FullName -notmatch '\\Windows\\System32\\' }

foreach ($dll in $Dlls) {
    Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $RuntimeDir $dll.Name) -Force
}

$WebUiCandidates = @(
    (Join-Path $WebUiDir 'dist'),
    (Join-Path $WebUiDir 'build'),
    (Join-Path $WebUiDir 'public')
)

$WebUiCopied = $false
foreach ($candidate in $WebUiCandidates) {
    if (Test-Path $candidate) {
        $target = Join-Path $RuntimeDir 'webui'
        Copy-Item -LiteralPath $candidate -Destination $target -Recurse -Force
        Write-Host "Copied WebUI assets from: $candidate"
        $WebUiCopied = $true
        break
    }
}
if (-not $WebUiCopied) {
    Write-Host 'No WebUI output folder found to copy.' -ForegroundColor Yellow
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item -LiteralPath (Join-Path $ScriptDir 'launch-oxcart-server.bat') -Destination (Join-Path $RuntimeDir 'launch-oxcart-server.bat') -Force

Run-Step '.\llama-server.exe --help' $RuntimeDir

$launchProc = Start-Process -FilePath (Join-Path $RuntimeDir 'launch-oxcart-server.bat') -WorkingDirectory $RuntimeDir -PassThru
Start-Sleep -Seconds 5
if (-not $launchProc.HasExited) {
    Stop-Process -Id $launchProc.Id -Force
}

if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
Compress-Archive -Path (Join-Path $RuntimeDir '*') -DestinationPath $ZipPath

Write-Host "`nRuntime folder: $RuntimeDir" -ForegroundColor Green
Write-Host 'Files:' -ForegroundColor Green
Get-ChildItem -Path $RuntimeDir -Recurse | ForEach-Object { $_.FullName }
Write-Host "`nZip: $ZipPath" -ForegroundColor Green
