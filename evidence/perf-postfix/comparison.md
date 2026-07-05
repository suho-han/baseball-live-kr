# Post-fix Performance Comparison (G003)

Generated: 2026-07-05T21:33:30+09:00

Metric: explicit exported Animation Hitches duration sum from `hitches-frame-lifetimes` table. Gate: post-fix average must improve beyond baseline variance band (`baseline max - baseline min`).

| Surface | Baseline avg | Baseline variance band | Post-fix avg | Delta | Gate |
|---------|--------------|------------------------|--------------|-------|------|
| Menubar popover open | 34433.59 ms | 2831.53 ms | 25974.24 ms | 8459.35 ms | PASS |
| TodayGames during live polling | 36212.08 ms | 1978.21 ms | 26193.92 ms | 10018.16 ms | PASS |
| GameDetail live game | 30119.36 ms | 2875.54 ms | 24237.04 ms | 5882.32 ms | PASS |

Supporting evidence:
- Offender ranking and trace-gated fix mapping: `evidence/perf-postfix/offender-ranking.md`
- Post-fix native automation and xctrace transcript: `evidence/perf-postfix/postfix-automation-transcript.json`
