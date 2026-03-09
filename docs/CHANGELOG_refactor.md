# Refactor Changelog

## 2026-03-02

### Summary
- 

### Files Touched
- 

### Test Checklist
- [ ] 

## 2026-03-08

### Summary
- Recovered the Roblox FPS source snapshot from the restored Studio place into the Rojo repo.
- Extracted real `StarterGui`, `ServerStorage.Maps`, and persistent `Workspace` assets into source-controlled `.rbxmx` files.
- Fixed Rojo mapping issues that were duplicating instances, removed placeholder README sync pollution, and archived legacy runtime code out of mapped paths.
- Restored required shared bootstrap instances (`GameState`, `ClientAction`, `KillSignal`, `AssistSignal`) and added the empty `ReplicatedStorage.Weapons.Models` folder required by the current client boot path.

### Files Touched
- `default.project.json`
- `src/StarterGui/*.rbxmx`
- `src/ServerStorage/Maps/*.rbxmx`
- `src/Workspace/*.rbxmx`
- `src/ServerScriptService/**`
- `src/StarterPlayer/StarterPlayerScripts/**`
- `src/ReplicatedStorage/**`
- `tools/extract-rbxlx-assets.ps1`
- `ARCHIVE/LegacyFromRecovery/**`
- `docs/rojo_folder_notes/**`
- `.gitignore`

### Test Checklist
- [x] `rojo build default.project.json -o build\\rojo-verify.rbxlx`
- [x] Rojo live sync connected in Studio
- [x] Duplicate instances removed from `ReplicatedStorage`, `Workspace`, and mapped services
- [x] Legacy runtime scripts no longer sync into live Studio
- [x] Smoke playtest booted with current active systems initialized and no startup errors

