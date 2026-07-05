param(
    [string]$SourceRoot = "C:\Users\12162\Documents\arkhamdb-json-data-master\arkhamdb-json-data-master",
    [string[]]$PackCodes = @("core_2026", "core_2026_encounter"),
    [switch]$IncludeSchema,
    [switch]$IncludeIndex,
    [switch]$IncludeZhCn
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$dest = Join-Path $repoRoot "data\arkhamdb"

if (-not (Test-Path $SourceRoot)) {
    Write-Error "Source not found: $SourceRoot"
}

if ($IncludeSchema) {
    Copy-Item "$SourceRoot\schema\*" "$dest\schema\" -Recurse -Force
}

if ($IncludeIndex) {
    Copy-Item "$SourceRoot\types.json", "$SourceRoot\packs.json", "$SourceRoot\cycles.json",
        "$SourceRoot\factions.json", "$SourceRoot\subtypes.json", "$SourceRoot\encounters.json" `
        "$dest\index\" -Force
}

foreach ($code in $PackCodes) {
    $found = Get-ChildItem "$SourceRoot\pack" -Recurse -Filter "$code.json" -File -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Warning "Pack file not found: $code.json"
        continue
    }
    foreach ($file in $found) {
        $rel = $file.FullName.Substring("$SourceRoot\pack\".Length)
        $target = Join-Path "$dest\pack" $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
        Copy-Item $file.FullName $target -Force
        Write-Host "Copied $rel"
    }
}

if ($IncludeZhCn) {
    foreach ($code in $PackCodes) {
        $found = Get-ChildItem "$SourceRoot\translations\zh-cn\pack" -Recurse -Filter "$code.json" -File -ErrorAction SilentlyContinue
        foreach ($file in $found) {
            $rel = $file.FullName.Substring("$SourceRoot\translations\zh-cn\pack\".Length)
            $target = Join-Path "$dest\translations\zh-cn\pack" $rel
            New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
            Copy-Item $file.FullName $target -Force
            Write-Host "Copied zh-cn $rel"
        }
    }
}

Set-Content -Path "$dest\SOURCE.txt" -Encoding UTF8 @(
    "Upstream: $SourceRoot",
    "Repository: https://github.com/Kamalisk/arkhamdb-json-data",
    "Synced packs: $($PackCodes -join ', ')",
    "Synced date: $(Get-Date -Format 'yyyy-MM-dd')"
)

Write-Host "Done."
