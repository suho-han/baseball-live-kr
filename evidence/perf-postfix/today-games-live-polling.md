# TodayGames during live polling — Post-fix Comparison

| Run | Baseline hitch rows | Baseline explicit rows | Baseline hitch sum | Baseline max hitch | Post-fix hitch rows | Post-fix explicit rows | Post-fix hitch sum | Post-fix max hitch |
|-----|---------------------|------------------------|--------------------|--------------------|---------------------|------------------------|--------------------|--------------------|
| 1 | 611 | 610 | 36960.28 ms | 97.93 ms | 614 | 610 | 29483.66 ms | 82.16 ms |
| 2 | 611 | 608 | 36693.88 ms | 80.63 ms | 612 | 592 | 24513.60 ms | 139.58 ms |
| 3 | 614 | 611 | 34982.07 ms | 81.06 ms | 614 | 597 | 24584.50 ms | 74.64 ms |

Baseline average: 36212.08 ms
Baseline variance band: 1978.21 ms
Post-fix average: 26193.92 ms
Delta: 10018.16 ms
Gate: PASS

Post-fix trace evidence is stored under ignored `artifacts/perf-postfix/`; baseline trace evidence remains under ignored `artifacts/perf-baseline/`.
