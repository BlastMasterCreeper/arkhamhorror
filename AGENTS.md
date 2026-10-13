# AGENTS.md

## Cursor Cloud specific instructions

This is a **Godot 4.6 headless GDScript rules engine** (no GUI app, no package
manager). The product is the Arkham Horror LCG rules engine library; its core
behavior is exercised through the headless GDScript test suite.

### Engine
- Uses the `godot` binary (Godot **4.6.3** stable, standard Linux x86_64 build,
  installed at `/usr/local/bin/godot`). The standard build runs fine with
  `--headless`; no separate "server"/"headless" build is required.
- There is no `package.json`/`requirements.txt`. The only "dependency refresh"
  is regenerating the gitignored `.godot/` import cache via `godot --import`
  (the update script handles this).

### Lint / typecheck
- No external linter. GDScript type/parse errors surface during
  `godot --headless --path . --import` and when running scripts. The project
  enables `gdscript/warnings/untyped_declaration` (see `project.godot`).

### Test
- Run the headless suite (canonical entry, see `README.md` / `run_tests.ps1`):
  `godot --headless --path . -s "res://tests/run_headless.gd"`
- It prints `All tests passed.` on success.
- Gotcha (Linux): the `-s` script-mode `SceneTree` runner reliably prints every
  `OK` line and `All tests passed.`, but this Godot 4.6.3 Linux build then
  **aborts during engine shutdown** with a glibc heap message (e.g.
  `corrupted size vs. prev_size in fastbins`) and returns exit code `134`
  AFTER all tests have passed. This shutdown abort is benign and does NOT mean a
  test failed. Judge success by the presence of `All tests passed.` (and the
  absence of any `FAIL`/`FAILED:` line), NOT by exit code `0`.
- Godot may also print benign `ObjectDB instances leaked` /
  `resources still in use at exit` warnings — these do NOT indicate failure
  either.
- `run_tests.ps1` is Windows/PowerShell only; on Linux call the `godot` command
  above directly.

### Run the application
- `godot --headless --path . --quit-after 5` runs the main scene
  (`res://main.tscn`), which just prints a skeleton banner — there is no
  interactive/GUI product to drive.

### Windows local tools (Python / AV)
- See [`docs/setup-local-tools.md`](docs/setup-local-tools.md).
- **Do not** run `winget install`, download `.exe` installers, or
  `powershell -ExecutionPolicy Bypass` on the user's machine — antivirus often
  blocks agent-launched installs.
- If `python` is missing, point the user to manual install (python.org, tick
  **Add to PATH**); only run `python tools/*.py` when `python --version` already
  works in the shell.
