# Fixture Catalog

This catalog keeps long-lived edge-case snapshots promoted from raw polling or completed dumps.

## Layout

- `cancelled/`: cancelled games, including weather cancellation rows.
- `delayed/`: delayed or suspended games when available.
- `doubleheader/`: same-day duplicate team matchups when available.

Each captured case should keep:

- `*-raw.json`: the smallest raw KBO source slice needed to reproduce the edge case.
- `*-normalized.json`: the normalized contract snapshot expected by backend mapping.

## Current Coverage

- `cancelled/20260614-NCKT0-*`: actual KBO schedule row with `우천취소`.

## Not Yet Captured

- `delayed`: no delayed/suspended raw fixture is currently available in captured data.
- `doubleheader`: no doubleheader raw fixture is currently available in captured data.

Retry delayed/doubleheader capture on rainy game days, makeup-game days, or same-team same-date doubleheader schedule announcements.
