# Menubar popover open — Post-fix Comparison

| Run | Baseline hitch rows | Baseline explicit rows | Baseline hitch sum | Baseline max hitch | Post-fix hitch rows | Post-fix explicit rows | Post-fix hitch sum | Post-fix max hitch |
|-----|---------------------|------------------------|--------------------|--------------------|---------------------|------------------------|--------------------|--------------------|
| 1 | 615 | 612 | 33132.91 ms | 80.64 ms | 613 | 608 | 29419.52 ms | 154.08 ms |
| 2 | 611 | 605 | 34203.41 ms | 81.12 ms | 610 | 592 | 24139.34 ms | 105.95 ms |
| 3 | 613 | 611 | 35964.44 ms | 81.29 ms | 613 | 596 | 24363.85 ms | 66.36 ms |

Baseline average: 34433.59 ms
Baseline variance band: 2831.53 ms
Post-fix average: 25974.24 ms
Delta: 8459.35 ms
Gate: PASS

Post-fix trace evidence is stored under ignored `artifacts/perf-postfix/`; baseline trace evidence remains under ignored `artifacts/perf-baseline/`.
