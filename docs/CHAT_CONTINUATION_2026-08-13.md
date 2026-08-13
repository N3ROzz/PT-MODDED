# PROTANKI ACTION SCRIPT — Chat Continuation Snapshot

Date: 2026-08-13
Repo: `https://github.com/N3ROzz/PT-MODDED`
Local MODDED workspace: `C:\Users\tamir\Desktop\PROTANKI\Code`
ORIGINAL reference: `C:\Users\tamir\Desktop\PROTANKI-CODE\scripts`

## Working style / constraints

- User works through Codex; ChatGPT primarily reviews PLANs, diffs, commits, logs and runtime evidence, then gives a clear verdict.
- Preferred verdicts: `APPROVE / APPROVE WITH CORRECTIONS / REJECT` and `FIXED / PARTIALLY FIXED / NOT FIXED`.
- Do not directly edit production code unless explicitly asked.
- For Battle Select/BattleInfo, prefer ORIGINAL structural/lifecycle parity over new custom architecture.
- Do not add `BattleSelectionState`, canonical IDs, generations, Safe Join, retries, ghost quarantine or fallback routing unless explicitly requested later.

---

# Latest relevant baseline

## Main parity implementation commit

Current reviewed parity commit:

`47541e229f72368ada4e30476072977f5afce908`

Parent:

`776c9d39d1acb9021e27f36dac18f11fe03a6a32`

Codex reported that this commit restored the ORIGINAL two-space Battle Select architecture across 58 production files.

### What this commit restored correctly at structural level

- Battle List objects live only in `BATTLE_SELECT_SPACE`.
- BattleInfo is a separate object in `BATTLE_INFO_SPACE`.
- Four ORIGINAL GameClasses were restored:
  - List DM: `Long(5823623,5812059)`
  - List TEAM: `Long(58236221,58120558)`
  - Info DM: `Long(5823622,5812058)`
  - Info TEAM: `Long(58236223,58120559)`
- ORIGINAL model IDs/vectors were restored for common/list DM/list TEAM/info DM/info TEAM/entrance.
- Handler 31 handles Battle Select/List lifecycle.
- Handler 32 targets Battle Select space and the new dedicated List models.
- Handler 33 targets Battle Info space and Info models.
- Select ACK contract was restored to `String` instead of `IGameObject`.
- `LoadBattleInfo` creates a new object in Battle Info space.
- `UnloadBattleInfo` destroys the exact BattleInfo object via FP10 lifecycle.
- Fight ownership moved to DM/TEAM Info models.
- Spectate ownership moved to common BattleInfo model.
- No new state manager/canonical-ID architecture was introduced.
- `Game.as` was not changed; both required spaces already existed.
- The previous #1009 fix remains conceptually correct: do not manually call `BattleSelectModel.objectUnloaded()` before destroying objects.

### Exact space constants

- `BATTLE_SELECT_SPACE_ID = Long(59235923,646943)`
- `BATTLE_INFO_SPACE_ID = Long(52835823,6349643)`
- `BATTLE_SELECT_OBJECT_ID = Long(53152835,6296493246)`

---

# Runtime regression after parity commit: Battle List completely empty

User runtime evidence after the parity restoration:

- Battle List was completely empty.
- No other obvious runtime bug was initially observed because the empty list blocked further meaningful testing.

## P0 root cause found and confirmed statically

`BattleParamsUtils.setBattleItemParams()` creates a compatibility `BattleCreateParameters` object for the existing MODDED Battle List UI, but after the parity refactor it did not initialize:

`BattleCreateParameters.limits`

The current `BattleListView.createItem()` unconditionally dereferences:

- `createParams.limits.timeLimitInSec`
- `createParams.limits.scoreLimit`

Therefore the first row throws before reaching `DataProvider.addItem()`, aborting the queue flush in `battleItemsPacketJoinSuccess()` and leaving the list visually empty.

The previous one-space implementation explicitly had:

`battleParamInfoCC.params.limits = new BattleLimits();`

So this was identified as a direct regression of the parity implementation, not a server-side empty snapshot.

## Approved targeted fix PLAN

Approved plan:

1. In `BattleParamsUtils.setBattleItemParams()`:
   - import `BattleLimits`;
   - always set:
     `params.limits = new BattleLimits();`
   - do not invent score/time values; both stay `0` because the List snapshot does not supply them.

2. In `BattleItemPacketHandler.withBattle()`:
   - exact lookup in Battle Select space;
   - if object is missing: return;
   - otherwise use `Model.withObject()`;
   - no trim/canonical/fallback.

3. In `BattleInfoPacketHandler.withBattleInfo()`:
   - exact lookup in Battle Info space;
   - if object is missing: return;
   - no fallback to Select space.

4. QA trace only around List creation pipeline:
   - DM/TEAM item `objectLoaded()`
   - common `BattleItemModel.objectLoadedPost()`
   - `battleItemRecord()`
   - `battleItemsPacketJoinSuccess()`
   - `BattleListView.createItem()`

5. Do not touch two-space architecture, GameClasses, String Select ACK, Info object split, Info unload, Fight/Spectate ownership, or #1009 teardown behavior.

`new BattleLimits()` was verified to be safe: its constructor defaults to `scoreLimit=0` and `timeLimitInSec=0`.

### Later runtime evidence from Codex

Codex later reported that the `BattleLimits` fix worked:

- 41 Battle List rows were created successfully.
- one additional row was also created.
- no `createItem` exception was present in that run.
- null guards in handlers 32/33 were present.

This means:

`BATTLE LIST EMPTY — FIXED in the tested QA SWF`

The tested QA SWF reported by Codex:

- SHA-256: `0CF67D2AD8AC58CBC1CDCE212D56F270747CE829CF0E98B4E66EC100FF7EBF14`
- Size: `5,498,219` bytes

Do not assume this SHA is the latest repository Release artifact unless re-verified.

---

# New high-priority finding: trailing-space Select payload

## Current production behavior after parity restoration

`BattleSelectModelServer.as` currently sends:

`battleId + " "`

with ASCII 32 trailing space.

This matches the historical ORIGINAL behavior, but current server compatibility is now strongly questioned.

Important inconsistency:

- production `BattleSelectModelServer` is hardcoded to trailing-space behavior;
- `BattleSelectionTrace` still has:
  - `BATTLE_SELECT_SEND_TRAILING_SPACE = false`
  - `BUILD_VARIANT = "BATTLE_SELECT_PAYLOAD_EXACT"`

So diagnostics can describe the build as exact while production actually sends trailing space.

## Evidence reported by Codex

Codex summarized prior same-server evidence as follows:

- a trailing-space Select frame was written and sent successfully;
- after it, no `Select ACK` and no `LoadBattleInfo` were observed;
- the initial battle selection can still be populated from server-side initial state;
- before parity restoration, the working MODDED path used exact ID without trailing space.

This makes trailing-space incompatibility the highest-priority current hypothesis.

## Current verdict on trailing space

Do NOT call it absolutely proven until a controlled same-HEAD A/B test is done.

Required test:

- same current two-space architecture;
- same build/code except the Select payload;
- Variant A: exact `battleId`;
- Variant B: `battleId + " "`;
- no retry;
- no double-send.

Narrow trace only:

`SELECT_OUT -> SELECT_ACK -> LOAD_BATTLE_INFO -> JOIN -> BEGIN_LAYOUT_SWITCH -> INIT_BATTLE`

If exact consistently produces `ACK + LoadBattleInfo` while trailing-space does not, then:

`TRAILING SPACE SERVER INCOMPATIBILITY — PROVEN`

Production should then use exact IDs even though historical ORIGINAL used trailing space. Structural/lifecycle parity should be retained; obsolete wire quirks should not be preserved if the current server rejects them.

Latest ChatGPT verdict for this stage:

`APPROVE DIAGNOSIS / APPROVE A-B TEST`

NOT `APPROVE FINAL FIX` yet.

---

# PARKOUR infinite loading / wrong battle selection

## Current observed symptom

Earlier runtime symptom:

- user attempted to enter active PARKOUR battle;
- loading did not complete;
- previously there were stale/ghost-looking rows such as `LIBYA DM` and `ZONE DM`;
- previous sessions also showed `SERVER CONNECTION ERROR` in related Battle Select transition failures.

## Current strongest hypothesis

Trailing-space Select rejection can explain a server/client selection desync:

1. User clicks Battle B.
2. Client updates the local selected row immediately.
3. Client sends `Select(B + " ")`.
4. Current server may ignore/reject it.
5. No Select ACK / no new LoadBattleInfo arrives.
6. Server still considers old Battle A selected.
7. `JoinBattleOutPacket` contains only `team`, not `battleId`.
8. Join therefore depends completely on the server's currently selected battle.
9. The client may appear to be joining B while the server is joining A or has invalid/stale selection state.
10. A layout switch may begin without a valid subsequent `InitBattle`, leaving the loader open indefinitely.

Current verdict:

`PARKOUR INFINITE LOADING — STRONGLY SUSPECTED SELECT DESYNC, NOT YET PROVEN`

The next trace must directly cover the pipeline from Select through InitBattle before any new PARKOUR-specific code is added.

Do not blame BUG-004 Network without evidence; prior LIBYA transport diagnostics already ruled transport out as the cause of the earlier #1009 transition failure.

---

# New parity deviation: ENTER_DM / ENTER_TEAM event contract

Codex found another architectural deviation and it was independently accepted as real.

## ORIGINAL behavior

Historical ORIGINAL uses mode-specific BattleInfo UI events:

- `BattleInfoViewEvent.ENTER_DM`
- `BattleInfoViewEvent.ENTER_TEAM`

The DM Info model listens only to the DM event.
The TEAM Info model listens only to the TEAM event.

## Current MODDED behavior

Current MODDED defines only a shared:

`BattleInfoViewEvent.ENTER_BATTLE`

Both `BattleDmInfoModel` and `BattleTeamInfoModel` listen to that shared event through the same `BattleInfoFormService` dispatcher.

## Risk

If multiple Info objects/listeners overlap temporarily in Battle Info space, one UI click may be delivered to more than one Info model and may cause multiple Join requests.

This is a real deviation from ORIGINAL, but there is no current runtime proof that a double Join happened in the latest PARKOUR run.

Important nuance:

Restoring `ENTER_DM` / `ENTER_TEAM` primarily prevents cross-mode listener leakage. It does not replace correct lifecycle cleanup; stale same-mode Info listeners still need proper `UnloadBattleInfo` cleanup.

## Implementation sequencing

Do NOT mix this event-contract refactor into the trailing-space A/B test.

Recommended order:

1. finish controlled exact-vs-trailing-space test;
2. determine production Select payload for current server;
3. then create a separate minimal PLAN to restore ORIGINAL mode-specific `ENTER_DM` / `ENTER_TEAM` events;
4. audit listener registration/unregistration across LoadInfo / UnloadInfo;
5. verify that one click produces exactly one Join.

---

# Handler safety status

## Handler 32

A regression was found in the initial parity implementation:

`BattleItemPacketHandler.withBattle()` performed exact lookup but still called `Model.withObject(null, callback)` when the List object was missing.

ORIGINAL handler 32 ignores updates when the List object is missing.

Approved/follow-up fix:

- exact lookup only;
- missing object -> return;
- no trim/canonical/fallback.

Codex later reported this null guard is now present in the tested QA state.

## Handler 33

`BattleInfoPacketHandler.withBattleInfo()` had the same null-context safety gap.

Approved/follow-up fix:

- exact Info-space lookup;
- missing object -> return;
- no fallback to Select space.

Codex later reported this null guard is present in the tested QA state.

---

# #1009 transition bug that must not regress

Previous LIBYA root cause was already proven:

Packet `-324155151` (`UnloadBattleSelectSpace`) caused TypeError #1009 because MODDED manually invoked `battleSelectModel.objectUnloaded()` before FP10 object destruction.

That destroyed the Battle List controller too early, then `BattleInfoModel.objectUnloadedPost()` tried to remove a battle through an already-null controller.

Correct behavior:

- destroy objects;
- let FP10 lifecycle call unload hooks automatically;
- never manually call `BattleSelectModel.objectUnloaded()` before `destroyObject()`.

The two-space parity implementation's two-phase teardown is conceptually correct:

1. snapshot Battle Select objects;
2. reverse Select vector;
3. destroy Select objects;
4. snapshot Battle Info objects;
5. destroy Info objects.

This fix must remain intact during all upcoming work.

---

# Current status matrix

- Two-space architecture: `STATICALLY RESTORED / KEEP`
- Four ORIGINAL GameClasses: `STATICALLY RESTORED / KEEP`
- Separate BattleInfo object: `RESTORED / KEEP`
- String Select ACK: `RESTORED / KEEP`
- Info-space UnloadBattleInfo: `RESTORED / KEEP`
- Fight ownership DM/TEAM: `RESTORED / KEEP`
- Spectate ownership common Info: `RESTORED / KEEP`
- #1009 teardown correction: `PRESERVED / MUST NOT REGRESS`
- Battle List empty regression: `ROOT CAUSE CONFIRMED; QA FIX REPORTED WORKING`
- Handler 32 null guard: `FOLLOW-UP FIX REPORTED PRESENT`
- Handler 33 null guard: `FOLLOW-UP FIX REPORTED PRESENT`
- trailing-space Select compatibility: `HIGHEST-PRIORITY HYPOTHESIS; A/B REQUIRED`
- PARKOUR infinite loading: `STRONGLY SUSPECTED SELECT DESYNC; NOT PROVEN`
- wrong battle Join: `STRONGLY RELATED TO SERVER SELECTION DESYNC; NOT PROVEN AFTER LATEST FIXES`
- ghost battles: `INCONCLUSIVE AFTER ARCHITECTURE RESTORE`
- ENTER_DM / ENTER_TEAM parity: `REAL STATIC DEVIATION; SEPARATE FIX PLAN LATER`
- Runtime final production approval: `NOT YET`

---

# Immediate next step in a new chat

When continuing, do NOT redesign the system again.

The immediate task is:

## Controlled Select payload A/B

Ask Codex for a minimal same-HEAD A/B test:

- exact `battleId` vs `battleId + " "` only;
- keep all current two-space code unchanged;
- no retry / no dual-send;
- narrow trace:
  `SELECT_OUT -> SELECT_ACK -> LOAD_BATTLE_INFO -> JOIN -> BEGIN_LAYOUT_SWITCH -> INIT_BATTLE`;
- test ordinary DM/TDM and PARKOUR;
- return logs and exact SWF hash for each variant.

Acceptance:

- If exact gets ACK/LoadInfo and trailing-space does not -> production exact ID.
- If both work -> inspect another cause before changing protocol behavior.
- If neither works -> stop and inspect routing/lifecycle; do not add a state manager.

After Select compatibility is resolved, prepare a separate PLAN for `ENTER_DM` / `ENTER_TEAM` event parity and listener cleanup.

---

# Other open project bugs not part of the immediate Select task

Keep these separate unless explicitly requested:

- BUG-005 packet dispatch handler bounds/null validation.
- BUG-006 Battle snapshot recreation semantics (original recreates List objects, but two-space meaning matters).
- turret GameClass cleanup/cache.
- Ratings `valuableRound` forced true.
- local crystal/gold double-credit.
- tank unload wrong context/unsafe teardown.
- gold wrong `Model.object` context.
- Garage `initMounted` null.
- garage magic price/index.
- MOD/DEBUG coupled Game bootstrap.
- BCSH `models[3]`.
- Hammer angle/radius/runtime evidence.
- no CI/static build.
- Death pipeline: remote suicide delayed; normal kill confirmation can be skipped if listener throws; `StatisticsModel.logKillAction()` can null-deref missing ShortUserInfo.
- Map/PARKOUR map builder issues remain separate until Select pipeline is proven.

---

# Canonical continuation instruction

In the next chat, start by saying:

`Continue PROTANKI from docs/CHAT_CONTINUATION_2026-08-13.md. First task: review/approve the controlled exact-vs-trailing-space Select A/B plan and do not redesign the two-space architecture.`
