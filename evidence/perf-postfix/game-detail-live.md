# GameDetail live game — Post-fix Comparison

| Run | Baseline hitch rows | Baseline explicit rows | Baseline hitch sum | Baseline max hitch | Post-fix hitch rows | Post-fix explicit rows | Post-fix hitch sum | Post-fix max hitch |
|-----|---------------------|------------------------|--------------------|--------------------|---------------------|------------------------|--------------------|--------------------|
| 1 | 613 | 606 | 29132.12 ms | 114.76 ms | 613 | 592 | 24156.06 ms | 82.86 ms |
| 2 | 614 | 614 | 32007.66 ms | 131.13 ms | 613 | 597 | 24349.26 ms | 79.35 ms |
| 3 | 614 | 605 | 29218.31 ms | 98.47 ms | 614 | 589 | 24205.81 ms | 78.46 ms |

Baseline average: 30119.36 ms
Baseline variance band: 2875.54 ms
Post-fix average: 24237.04 ms
Delta: 5882.32 ms
Gate: PASS

Post-fix trace evidence is stored under ignored `artifacts/perf-postfix/`; baseline trace evidence remains under ignored `artifacts/perf-baseline/`.
