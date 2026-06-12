$ErrorActionPreference = "Stop"

$GodotExe = if ($env:GODOT4) { $env:GODOT4 } else {
	"E:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
}

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $GodotExe)) {
	Write-Error "Godot 4.6 not found at: $GodotExe`nSet GODOT4 env var or install to the default path."
}

# Ensure global class cache exists (required on first open with a new engine version).
& $GodotExe --headless --path $ProjectRoot --import | Out-Null

& $GodotExe --headless --path $ProjectRoot -s "res://tests/run_headless.gd"
exit $LASTEXITCODE
