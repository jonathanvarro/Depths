param(
 [Parameter(Mandatory=$true)][string]$SourceFbx,
 [Parameter(Mandatory=$true)][string]$TexturePng,
 [string]$Godot="E:\GitHub\Depths\build\character3d-runtime\Godot_v4.7.2-stable_win64_console.exe"
)
$ErrorActionPreference="Stop"
$repositoryRoot=[System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$localOutput=[System.IO.Path]::GetFullPath((Join-Path $repositoryRoot "build/local-fbx-trial"))
if (-not $localOutput.StartsWith($repositoryRoot+[System.IO.Path]::DirectorySeparatorChar)) { throw "Output must stay inside this workspace." }
New-Item -ItemType Directory -Force (Join-Path $localOutput "source") | Out-Null
Copy-Item -LiteralPath $SourceFbx -Destination (Join-Path $localOutput "source/character.fbx")
Copy-Item -LiteralPath $TexturePng -Destination (Join-Path $localOutput "body-texture.png")
$originalHashes=@{fbx=(Get-FileHash -LiteralPath $SourceFbx -Algorithm SHA256).Hash;texture=(Get-FileHash -LiteralPath $TexturePng -Algorithm SHA256).Hash}
$originalHashes | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $localOutput "original-hashes.json") -Encoding utf8
$taskProcess=Start-Process -FilePath $Godot -ArgumentList @('--path', ('"'+$PSScriptRoot+'"'), '--position','-10000,-10000','--log-file',('"'+(Join-Path $localOutput 'prepare-log.txt')+'"'),'--script','prepare.gd') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $localOutput 'prepare-stdout.txt') -RedirectStandardError (Join-Path $localOutput 'prepare-stderr.txt')
$taskProcess.WaitForExit()
if ($taskProcess.ExitCode -ne 0) { throw "Local FBX preparation failed; inspect the output logs." }
Get-Content -LiteralPath (Join-Path $localOutput 'prepare-stdout.txt')
