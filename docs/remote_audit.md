# Remote Audit

Date: 2026-03-02

## Scope
- RemoteEvent instances found: **45**
- RemoteFunction instances found: **0**
- Active remote usage found in: `GameManager`, `CombatManager`, `InventoryManager`, `ShopManager`, `EconomyManager`, `SpawnManager`, `UIStateManager`, `UIController`, `WeaponController`, `WeaponViewmodelController`, `HitmarkerController`
- Legacy/archive remote usage also detected in `_LegacyArchive` scripts.

## Remote Inventory + Usage

| Remote Name | Full Path | Type | Who Fires | Who Listens | Payload Shape (args) | Frequency Guess | Duplicate / Same-Purpose Findings |
|---|---|---|---|---|---|---|---|
| PlayGame | game.ReplicatedStorage.Remotes.UIRemotes.PlayGame | Event | Client: `UIController` | Server: `GameManager` | `FireServer()` / `OnServerEvent(player)` | Per Play press | Primary match-start trigger |
| OpenShop | game.ReplicatedStorage.Remotes.UIRemotes.OpenShop | Event | Server [legacy]: `UISystemServer` | Server [legacy]: `UISystemServer` | mostly none | Legacy menu action | Overlaps local UI page toggles |
| OpenLoadout | game.ReplicatedStorage.Remotes.UIRemotes.OpenLoadout | Event | Server [legacy]: `UISystemServer` | Server [legacy]: `UISystemServer` | mostly none | Legacy menu action | Overlaps local UI page toggles |
| OpenSettings | game.ReplicatedStorage.Remotes.UIRemotes.OpenSettings | Event | None detected | None detected | n/a | Dormant | Legacy candidate |
| CloseShop | game.ReplicatedStorage.Remotes.UIRemotes.CloseShop | Event | Server [legacy]: `UISystemServer` | Server [legacy]: `UISystemServer` | mostly none | Legacy menu action | Overlaps local UI page toggles |
| CloseLoadout | game.ReplicatedStorage.Remotes.UIRemotes.CloseLoadout | Event | Server [legacy]: `UISystemServer` | Server [legacy]: `UISystemServer` | mostly none | Legacy menu action | Overlaps local UI page toggles |
| BuyWeapon | game.ReplicatedStorage.Remotes.UIRemotes.BuyWeapon | Event | Client: `UIController` | Server: `ShopManager` | `FireServer(weaponName)` | Per buy click | Authoritative server purchase path |
| EquipWeapon | game.ReplicatedStorage.Remotes.UIRemotes.EquipWeapon | Event | None detected | None detected | n/a | Dormant | Same purpose as `WeaponEvents.Equip` |
| SpawnPlayer | game.ReplicatedStorage.Remotes.UIRemotes.SpawnPlayer | Event | None detected | None detected | n/a | Dormant | Spawning handled server-side by `SpawnManager` |
| UpdateAmmo | game.ReplicatedStorage.Remotes.UIRemotes.UpdateAmmo | Event | Server [legacy]: `WeaponServer` | Client [legacy]: legacy UI/weapon controllers | `(ammo, maxAmmo, reserve)` | Per shot/reload (legacy) | Superseded by `CombatEvents.AmmoUpdated` |
| UpdateWeapon | game.ReplicatedStorage.Remotes.UIRemotes.UpdateWeapon | Event | Server [legacy]: `WeaponServer` | None active detected | `(weaponName)` | Per weapon change (legacy) | Superseded by `CombatEvents.WeaponUpdated` |
| UpdateHealth | game.ReplicatedStorage.Remotes.UIRemotes.UpdateHealth | Event | None detected | None detected | n/a | Dormant | Superseded by `CombatEvents.HealthUpdated` |
| SetLoadout | game.ReplicatedStorage.Remotes.UIRemotes.SetLoadout | Event | Client: `UIController` | Server: `InventoryManager`, `CombatManager` | `(slotName, weaponName)` or `("RequestSync", "")` | Per loadout action/menu sync | Multi-listener by design |
| LoadoutSync | game.ReplicatedStorage.Remotes.UIRemotes.LoadoutSync | Event | Server: `InventoryManager` | Client: `UIController` | `{OwnedWeapons, EquippedPrimary, EquippedSecondary, EquippedMelee}` | On join + inventory/loadout change | Canonical loadout push |
| ShopPurchaseResult | game.ReplicatedStorage.Remotes.UIRemotes.ShopPurchaseResult | Event | Server: `ShopManager` | Client: `UIController` | `{Success, Code, WeaponName, Coins}` | Per purchase response | Canonical shop response |
| CurrencyUpdated | game.ReplicatedStorage.Remotes.UIRemotes.CurrencyUpdated | Event | Server: `EconomyManager` | Client: `UIController` | `(coins)` | On load + coin changes | Canonical currency push |
| SelectTeam | game.ReplicatedStorage.Remotes.UIRemotes.SelectTeam | Event | Client: `UIController` | Server: `GameManager` | `FireServer(teamName)` | Per team choose/switch | Canonical team selection request |
| SubmitMapVote | game.ReplicatedStorage.Remotes.UIRemotes.SubmitMapVote | Event | Client fallback: `UIController` (only when `RemoteEvents` folder absent) | Server: `GameManager` (legacy submit handler) | `FireServer(mapName)` | Per vote (fallback path) | **Duplicate name/path purpose** with `game.ReplicatedStorage.RemoteEvents.SubmitMapVote` |
| RequestTeamSwitchMenu | game.ReplicatedStorage.Remotes.UIRemotes.RequestTeamSwitchMenu | Event | Client: `UIController` | Server: `GameManager` | `FireServer()` | Per team-switch request | Canonical switch-menu request |
| RequestMainMenu | game.ReplicatedStorage.Remotes.UIRemotes.RequestMainMenu | Event | Client: `UIController` | Server: `GameManager` | `FireServer()` | Per main-menu return request | Canonical out-of-match request |
| StateChanged | game.ReplicatedStorage.Remotes.MatchEvents.StateChanged | Event | Server: `UIStateManager` | Client: `UIController` (+ legacy controllers) | `FireAllClients(state)` / `FireClient(player,state)` | Per state transition + sync | Core game-state broadcast |
| IntermissionStart | game.ReplicatedStorage.Remotes.MatchEvents.IntermissionStart | Event | Server: `UIStateManager` | Client [legacy]: legacy UI controller | `(seconds)` | Per intermission (if used) | Mostly legacy currently |
| MatchStart | game.ReplicatedStorage.Remotes.MatchEvents.MatchStart | Event | Server: `GameManager` | None explicit detected | `{MapName, Duration}` | Per round start | Used as broadcast only currently |
| MatchEnd | game.ReplicatedStorage.Remotes.MatchEvents.MatchEnd | Event | Server: `GameManager` | None explicit detected | `{WinnerTeam, MapName}` | Per round end | Used as broadcast only currently |
| ReturnToLobby | game.ReplicatedStorage.Remotes.MatchEvents.ReturnToLobby | Event | No active client fire detected | Server: `GameManager` | `OnServerEvent(player)` | Manual return (if wired) | Behavior overlaps `RequestMainMenu` intent |
| TeamSelectStart | game.ReplicatedStorage.Remotes.MatchEvents.TeamSelectStart | Event | Server: `GameManager` | Client: `UIController` | `(seconds)` | Per round + late join sync | Canonical team-select timer event |
| CountdownStart | game.ReplicatedStorage.Remotes.MatchEvents.CountdownStart | Event | Server: `GameManager` | Client: `UIController` | `(seconds)` | Per round + late join sync | Canonical pre-match countdown event |
| TeamCounts | game.ReplicatedStorage.Remotes.MatchEvents.TeamCounts | Event | Server: `GameManager` | Client: `UIController` | `{Pink, Purple, YourTeam, SwitchCooldown}` | During team select/switch updates | Canonical team count sync |
| RespawnStart | game.ReplicatedStorage.Remotes.MatchEvents.RespawnStart | Event | Server: `SpawnManager` | Client: `UIController` | `(seconds)` | Per death | Canonical respawn timer event |
| ScoreUpdate | game.ReplicatedStorage.Remotes.MatchEvents.ScoreUpdate | Event | Server: `GameManager` | Client: `UIController` | `{TeamScores, PlayerStats, Rows, TargetKills}` | Per kill/death/assist/team update | Canonical scoreboard data push |
| RoundResult | game.ReplicatedStorage.Remotes.MatchEvents.RoundResult | Event | Server: `GameManager` | Client: `UIController` | `{WinnerTeam, TeamScores, ToLobby}` | Per round end/lobby reset | Canonical round-result UI event |
| KillFeed | game.ReplicatedStorage.Remotes.MatchEvents.KillFeed | Event | Server: `CombatManager` | Client: `UIController` | Preferred table `{KillerName, VictimName, KillerTeam, Weapon, Headshot, IsMelee}` (legacy tuple tolerated) | Per kill | Canonical kill feed event |
| MatchTimerUpdate | game.ReplicatedStorage.Remotes.MatchEvents.MatchTimerUpdate | Event | Server: `GameManager` | Client: `UIController` | `(remainingSeconds)` | Every second in match + sync-on-join | High-frequency round timer event |
| Shoot | game.ReplicatedStorage.Remotes.WeaponEvents.Shoot | Event | Client: `WeaponController` | Server: `CombatManager` | `(origin:Vector3, direction:Vector3, predictedHitPosition?:Vector3)` | Per shot attempt | Core combat request |
| Reload | game.ReplicatedStorage.Remotes.WeaponEvents.Reload | Event | Client: `WeaponController` | Server: `CombatManager` | `FireServer()` | Per reload | Core combat request |
| Equip | game.ReplicatedStorage.Remotes.WeaponEvents.Equip | Event | Client: `WeaponController` | Server: `CombatManager` | `FireServer(request)` where request is `Primary|Secondary|Melee|Switch|weaponName` | Per weapon switch/equip | Replaces `UIRemotes.EquipWeapon` |
| AmmoUpdated | game.ReplicatedStorage.Remotes.CombatEvents.AmmoUpdated | Event | Server: `CombatManager` | Client: `WeaponController` | `(ammo, reserve)` | Per shot/reload/equip/spawn | Canonical ammo sync |
| WeaponUpdated | game.ReplicatedStorage.Remotes.CombatEvents.WeaponUpdated | Event | Server: `CombatManager` | Clients: `WeaponController`, `HitmarkerController`, `WeaponViewmodelController` | `(weaponName)` | Per equip/spawn/loadout sync | Canonical active-weapon sync |
| Hitmarker | game.ReplicatedStorage.Remotes.CombatEvents.Hitmarker | Event | Server: `CombatManager` | Client: `HitmarkerController` | `(damage, headshot, hitPosition, weaponName, isMelee)` | Per confirmed hit | Canonical hit feedback event |
| KillConfirmed | game.ReplicatedStorage.Remotes.CombatEvents.KillConfirmed | Event | Server: `CombatManager` | Client: `HitmarkerController` | `(weaponName, headshot, isMelee)` | Per local kill | Canonical kill confirmation event |
| HealthUpdated | game.ReplicatedStorage.Remotes.CombatEvents.HealthUpdated | Event | Server: `CombatManager` | Clients: `WeaponController`, `HitmarkerController` | `(health, maxHealth)` | On spawn + health changes | Canonical health sync |
| StartMapVote | game.ReplicatedStorage.RemoteEvents.StartMapVote | Event | Server: `GameManager` | Client: `UIController` | `{Candidates, Duration, EndsAt}` | Per round vote start + late join sync | Same purpose as runtime legacy `MatchEvents.MapVoteStart` |
| SubmitMapVote | game.ReplicatedStorage.RemoteEvents.SubmitMapVote | Event | Client: `UIController` | Server: `GameManager` | `FireServer(mapName)` | Per vote click | **Duplicate name/purpose** with `Remotes.UIRemotes.SubmitMapVote` |
| UpdateVoteCounts | game.ReplicatedStorage.RemoteEvents.UpdateVoteCounts | Event | Server: `GameManager` | Client: `UIController` | `{Candidates?, Counts, Votes, TimeRemaining}` | On each vote change + late join sync | Same purpose as runtime legacy `MatchEvents.MapVoteUpdate` |
| EndMapVote | game.ReplicatedStorage.RemoteEvents.EndMapVote | Event | Server: `GameManager` | None explicit detected | `{Winner, Counts}` | Once per vote phase end | End event currently not consumed by client script |

## Runtime-Created Remotes Referenced In Code
These are referenced/created via `ensureRemote()` at runtime and are **not present** in the static 45-instance explorer inventory:

| Remote | Expected Path | Type | Observed Usage |
|---|---|---|---|
| SetCombatState | game.ReplicatedStorage.Remotes.WeaponEvents.SetCombatState | Event | Fired by `WeaponController` (`{State,Sprinting,Crouching}`), listened by `CombatManager` |
| ShotConfirmed | game.ReplicatedStorage.Remotes.CombatEvents.ShotConfirmed | Event | Fired by `CombatManager`, listened by `WeaponViewmodelController` |
| DryFire | game.ReplicatedStorage.Remotes.CombatEvents.DryFire | Event | Fired by `CombatManager`, no active listener detected |
| ReloadConfirmed | game.ReplicatedStorage.Remotes.CombatEvents.ReloadConfirmed | Event | Fired by `CombatManager`, listened by `WeaponController` |
| EquipConfirmed | game.ReplicatedStorage.Remotes.CombatEvents.EquipConfirmed | Event | Fired by `CombatManager`, listened by `WeaponController` |
| VFXEvent | game.ReplicatedStorage.Remotes.CombatEvents.VFXEvent | Event | Fired by `CombatManager`, no active listener detected |
| AssistAwarded | game.ReplicatedStorage.Remotes.MatchEvents.AssistAwarded | Event | Fired by `CombatManager`, listened by `UIController` |
| MapVoteStart | game.ReplicatedStorage.Remotes.MatchEvents.MapVoteStart | Event | Fired by `GameManager` as legacy compatibility; client uses `RemoteEvents.StartMapVote` when available |
| MapVoteUpdate | game.ReplicatedStorage.Remotes.MatchEvents.MapVoteUpdate | Event | Fired by `GameManager` as legacy compatibility; client uses `RemoteEvents.UpdateVoteCounts` when available |

## Duplicate / Split-Purpose Findings
1. **Duplicate name/path purpose:** `SubmitMapVote`
   - `game.ReplicatedStorage.RemoteEvents.SubmitMapVote` (primary)
   - `game.ReplicatedStorage.Remotes.UIRemotes.SubmitMapVote` (legacy fallback)

2. **Same purpose, different paths (map vote):**
   - `RemoteEvents.StartMapVote` vs runtime `MatchEvents.MapVoteStart`
   - `RemoteEvents.UpdateVoteCounts` vs runtime `MatchEvents.MapVoteUpdate`

3. **Legacy combat sync still present:**
   - `UIRemotes.UpdateAmmo/UpdateWeapon/UpdateHealth` overlap with `CombatEvents.AmmoUpdated/WeaponUpdated/HealthUpdated`.

4. **Dormant remotes detected:**
   - `UIRemotes.OpenSettings`, `UIRemotes.EquipWeapon`, `UIRemotes.SpawnPlayer`, `UIRemotes.UpdateHealth` (no active listeners/fires detected).

## Notes
- `RemoteFunction` usage is currently **none**.
- Frequency guesses are behavioral estimates from call sites (not runtime telemetry).

## Map Vote Remote Migration (Final Canonical State) — 2026-03-02

Canonical namespace:
- `game.ReplicatedStorage.Remotes.MatchEvents`

Canonical map vote remotes (only active paths):
- `StartMapVote` (RemoteEvent)
- `SubmitMapVote` (RemoteEvent)
- `UpdateVoteCounts` (RemoteEvent)
- `EndMapVote` (RemoteEvent)

Call sites / listeners:
- `StartMapVote`
  - Fired by server: `game.ServerScriptService.Systems.GameManager.GameManager` (`StartMapVote:FireAllClients`, `StartMapVote:FireClient`)
  - Listened by client: `game.StarterPlayer.StarterPlayerScripts.UIController` (`mapVoteStart.OnClientEvent`)
- `SubmitMapVote`
  - Fired by client: `game.StarterPlayer.StarterPlayerScripts.UIController` (`submitMapVote:FireServer(mapName)`)
  - Listened by server: `game.ServerScriptService.Systems.GameManager.GameManager` (`SubmitMapVote.OnServerEvent`)
- `UpdateVoteCounts`
  - Fired by server: `game.ServerScriptService.Systems.GameManager.GameManager` (`UpdateVoteCounts:FireAllClients`, `UpdateVoteCounts:FireClient`)
  - Listened by client: `game.StarterPlayer.StarterPlayerScripts.UIController` (`mapVoteUpdate.OnClientEvent`)
- `EndMapVote`
  - Fired by server: `game.ServerScriptService.Systems.GameManager.GameManager` (`EndMapVote:FireAllClients`)
  - Client listener: none currently (intentional/non-blocking)

Archived redundant map vote remotes:
- `game.ReplicatedStorage.RemoteEvents` -> `game.ReplicatedStorage._LegacyArchive.RemoteEvents_MapVote_Legacy_1772507640`
- `game.ReplicatedStorage.Remotes.UIRemotes.SubmitMapVote` -> `game.ReplicatedStorage._LegacyArchive.UIRemotes_SubmitMapVote_Legacy_1772507640`

Validation result:
- No script references remain to `ReplicatedStorage.RemoteEvents` for map vote.
- No script references remain to legacy `MatchEvents.MapVoteStart` / `MatchEvents.MapVoteUpdate`.
- Active map vote script references are only canonical MatchEvents names in `GameManager` and `UIController`.
