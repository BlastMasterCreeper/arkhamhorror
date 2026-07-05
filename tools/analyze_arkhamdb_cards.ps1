# Analyze ArkhamDB JSON packs (PowerShell).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$dataRoot = Join-Path $repoRoot "data\arkhamdb"
$reports = Join-Path $dataRoot "reports"
New-Item -ItemType Directory -Force -Path $reports | Out-Null

$patterns = [ordered]@{
    reaction        = '\[reaction\]'
    action          = '\[action\]'
    fast            = '\[fast\]'
    elder_sign      = '\[elder_sign\]'
    revelation_bold = '<b>Revelation</b>'
    forced_bold     = '<b>Forced</b>'
    spawn_line      = 'Spawn'
    prey_line       = 'Prey'
    cannot          = '\bcannot\b'
    immune          = '\bimmune\b'
    surge_text      = '\bSurge\b'
    peril_text      = '\bPeril\b'
    aloof_text      = '\bAloof\b'
    hunter_text     = '\bHunter\b'
    retaliate_text  = '\bRetaliate\b'
    massive_text    = '\bMassive\b'
    hidden_text     = '\bHidden\b'
}

function Analyze-Pack($path) {
    $cards = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $packCode = [IO.Path]::GetFileNameWithoutExtension($path)
    $byType = @{}
    $abilityHits = @{}
    $examples = @{}
    foreach ($k in $patterns.Keys) { $abilityHits[$k] = 0; $examples[$k] = @() }

    foreach ($card in $cards) {
        $t = if ($card.type_code) { $card.type_code } else { "?" }
        $q = if ($card.quantity) { [int]$card.quantity } else { 1 }
        if (-not $byType.ContainsKey($t)) { $byType[$t] = 0 }
        $byType[$t] += $q
        $text = @($card.text, $card.back_text) -join "`n"
        foreach ($entry in $patterns.GetEnumerator()) {
            if ($text -and ($text | Select-String -Pattern $entry.Value -Quiet)) {
                $abilityHits[$entry.Key] += 1
                if ($examples[$entry.Key].Count -lt 5) {
                    $examples[$entry.Key] += "$($card.code) $($card.name)"
                }
            }
        }
    }

    $lines = @("# Pack: $packCode", "", "Entries: $($cards.Count)", "", "| type | qty |", "|---|---:|")
    $byType.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { $lines += "| $($_.Key) | $($_.Value) |" }
    $lines += "", "| pattern | hits |", "|---|---:|"
    $abilityHits.GetEnumerator() | Where-Object { $_.Value -gt 0 } | Sort-Object Value -Descending | ForEach-Object {
        $lines += "| $($_.Key) | $($_.Value) |"
    }
    $out = Join-Path $reports "${packCode}_inventory.md"
    Set-Content $out ($lines -join "`n") -Encoding UTF8
    Write-Host "Wrote $out"
    return @{ abilityHits = $abilityHits; examples = $examples }
}

$merged = @{}
foreach ($k in $patterns.Keys) { $merged[$k] = 0 }
$mergedExamples = @{}
foreach ($k in $patterns.Keys) { $mergedExamples[$k] = @() }

Get-ChildItem (Join-Path $dataRoot "pack") -Recurse -Filter "*.json" | ForEach-Object {
    $stat = Analyze-Pack $_.FullName
    foreach ($entry in $stat.abilityHits.GetEnumerator()) { $merged[$entry.Key] += $entry.Value }
    foreach ($entry in $stat.examples.GetEnumerator()) {
        foreach ($ex in $entry.Value) {
            if ($mergedExamples[$entry.Key].Count -lt 8) { $mergedExamples[$entry.Key] += $ex }
        }
    }
}

$gap = @("# Core 2026 design hints", "", "| pattern | hits |", "|---|---:|")
$patterns.Keys | ForEach-Object { $gap += "| $_ | $($merged[$_]) |" }
Set-Content (Join-Path $reports "core_2026_design_gaps.md") ($gap -join "`n") -Encoding UTF8
Write-Host "Done."
