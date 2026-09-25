# ZaiiaMovementSpeed

Lightweight movement speed display for **Turtle WoW 1.18.1** (API 1.12).

## Requirements

- **ClassicAPI.dll** — the addon will not load without it.

## What it shows

- **Character pane** — base forward run / swim speed (% of standard 7.0 yd/s).
  Includes mount and buff modifiers, independent of whether you are moving.
- **Test frame** — current movement speed: the speed the engine applies to
  this frame's step. Reads `0.0%` while standing still.

## Install

1. Copy the `ZaiiaMovementSpeed` folder into `Interface\AddOns\`.
   If the folder is named `ZaiiaMovementSpeed-master` (GitHub default),
   rename it to `ZaiiaMovementSpeed` — without the "-master" suffix.
3. Make sure `ClassicAPI.dll` is loaded.
4. `/reload` or restart the client.

## Commands

| Command | Effect |
|---|---|
| `/zms` | Print saved coordinates |
| `/zms X,Y` | Move the label to `(X, Y)` |
| `/zms test` | Toggle the current-speed frame |

Coordinates are saved per account in `SavedVariables`.

## Author

Zaiia
