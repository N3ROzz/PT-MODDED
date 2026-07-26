# PROTANKI MODDED — QA Bug Tracker

Baseline reviewed: `c09016c3551937fe587c4f9998358200804731bb`  
Review date: 2026-07-26  
Canonical working workbook: `PROTANKI-QA-BUG-TRACKER.xlsx`

Status values: `פתוח` / `בתיקון` / `ממתין ל-QA` / `דורש החלטה` / `נפתר` / `נדחה`.

| ID | Priority | Release blocker | Area | Status | Issue | Required solution | Acceptance |
|---|---|---:|---|---|---|---|---|
| BUG-001 | P0 | Yes | Battle / Bonuses | Open | `addBonusBoxes()` creates `BonusSpawnData` but never pushes it into `bonuses`; batch initialization receives an empty vector. | Push each resolved bonus into the vector; skip and log unresolved objects. | Existing bonuses at battle load appear, parsed count equals spawned count, and each can be collected. |
| BUG-002 | P0 | Yes | Model Context | Open | `Model.popObject()` underflow leaves stale `currentObject`. | Clear `currentObject` on underflow; preserve generation/logging and consider debug fail-fast. | Intentional underflow leaves `currentObject == null`. |
| BUG-003 | P0 | Yes | Packet Boundary | Open | `PacketInvoker` computes restore need before adding `POP_UNDERFLOW`, so underflow-only corruption may not restore the snapshot. | Compute restore decision after all mismatch and underflow checks. | Underflow-only handler restores entry depth and object. |
| BUG-004 | P0 | Yes | Networking | Open | Frame size is not fully validated and payload/send buffers are not always cleared in `finally`. | Validate minimum/maximum frame length; protect decrypt/decompress/invoke; make logging null-safe; clear buffers in `finally`. | Malformed frames do not contaminate the next packet or trigger secondary logger exceptions. |
| BUG-005 | P1 | No | Packet Dispatch | Open | Handler index is used without bounds/null validation. | Validate handler ID and registered handler before invoke. | Negative, oversized and empty handler slots fail predictably without null dereference. |
| BUG-006 | P1 | Yes | Battle Selection | Open | Full battle snapshots destroy and recreate existing battle objects. | Reconcile/update existing objects; recreate only when game class genuinely changes; keep selection by normalized ID. | Repeated snapshots preserve selection and object identity without stale callbacks. |
| BUG-007 | P1 | No | Battle Selection | Open | Trimmed battle ID fallback is calculated but ignored by the early return. | Resolve exact object first, then normalized object; remove the selected result once. | Remove packets with trailing whitespace remove the correct battle. |
| BUG-008 | P1 | Yes | Weapon Lifecycle | Open | Turret class cleanup iterates dictionary values as keys and does not clear the cache. | Iterate actual keys, destroy the correct class IDs, delete entries and reset the dictionary. | 30 battle enter/exit cycles show no class/cache growth or stale weapon parameters. |
| BUG-009 | P1 | Yes | Ratings / Statistics | Open | Client forces `valuableRound=true` during init/start/finish. | Preserve and propagate the server value; place any compatibility fallback behind an explicit debug flag. | Rated, unranked, private and test rounds follow the server contract. |
| BUG-010 | P1 | Yes | Economy / Bonuses | Open | Local crystal/gold credit can occur in more than one path in addition to authoritative server updates. | Establish one source of truth, preferably server balance; otherwise add explicit optimistic reconciliation. | Crystal, gold and event bonus collection produces exactly one balance update. |
| BUG-011 | P1 | No | Battle Info | Open | Hardcoded placeholders and missing late-packet/null guards can show wrong rules, scores or crash after object replacement. | Map real server fields, document fallbacks, validate object identity and reject late packets safely. | DM/team/private/drones and late user/score packets behave correctly. |
| BUG-012 | P1 | Yes | Tank Lifecycle | Open | Tank unload invokes a model before setting the tank context and assumes every child object exists. | Resolve the tank, use `Model.withObject`, then perform null-safe idempotent teardown. | Normal, duplicate and late unloads leave no mappings/effects and throw no exception. |
| BUG-013 | P1 | No | Gold Context | Open | Gold packet code intentionally uses the battlefield object instead of the model’s real owner. | Resolve the actual model owner and run calls through `Model.withObject`. | Notification, siren, drop-zone and taken flows work across battle transitions. |
| BUG-014 | P1 | No | Garage | Open | `initMounted` may call `hasModel` on a missing item. | Guard lookup failure, do not insert null, log the item ID and return safely. | Existing, missing and late mounted-item packets do not crash garage load. |
| BUG-015 | P2 | No | Garage | Open | Item index is rewritten using price/index magic values. | Fix the data source or map a documented exact item ID with a removal date. | Only the intended item is remapped; price changes do not affect unrelated items. |
| BUG-016 | P2 | No | Architecture / MOD | Open | Core `Game.as` directly imports and initializes MOD/DEBUG systems. | Add `BuildConfig` and `ModBootstrap`; keep vanilla-compatible startup free of MOD dependencies. | Both MODDED and vanilla-compatible builds compile and start. |
| BUG-017 | P2 | No | Weapon SFX | Open | BCSH model is read by fixed `models[3]` index. | Resolve by `BCSHModelBase.modelId`, not model order. | Reordered model vectors still initialize the correct BCSH model. |
| BUG-018 | P1 | No | Hammer Calibration | Decision required | `SPREAD_ANGLE_SCALE=0.75` reduces angle by 25%, not necessarily cone radius by exactly 25%. | Define the contract. For exact radius scaling, multiply `MAX_X/MAX_Y` by `0.75` or use `2*atan(0.75*tan(angle/2))`. | For every Hammer modification, `newRadius/originalRadius == 0.75` within agreed tolerance. |
| BUG-019 | P2 | No | Hammer QA | Open | No complete runtime proof of raw/effective Hammer parameters or local/remote parity. | Add opt-in one-time diagnostics for M0–M3 raw angles, effective spread, pellets and selected models. | ORIGINAL/MODDED comparison passes for local and remote shots, reload, magazine, targets and impact. |
| BUG-020 | P2 | No | Build / QA | Open | No CI compile/static gate was found for the reviewed commit. | Add compile, unresolved-reference, context-balance, debug-default and artifact checks. | Broken test commit fails; valid main commit receives a green status. |

## Work order

1. Gate 1: BUG-001 through BUG-004.
2. Gate 2: lifecycle and server-authority items, BUG-006 through BUG-013.
3. Gate 3: parity debt and Hammer, BUG-014 through BUG-019.
4. Gate 4: BUG-020 CI/release protection.

Start with **BUG-001**. Keep each fix focused, compile it, attach runtime evidence, and close the row only after static and runtime QA pass.
