# Reproducible benchmark

The benchmark command uses deterministic generated job-shop instances and deterministic FIFO dispatch. It reports schedule quality metrics rather than fabricated throughput claims.

## Environment

- Date: 2026-08-24
- Host: Windows, PowerShell
- Moon CLI: `moon 0.1.20260807`
- Moon compiler: `moonc v0.10.7+bc794d341`
- Command: `moon run cmd/benchmark`

## Results

| Case | Jobs | Machines | Operations | Repeats | Makespan | Tardiness | Score | Checksum length |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| tiny-2x2 | 2 | 2 | 4 | 5 | 11 | 0 | 51 | 124 |
| small-6x3 | 6 | 3 | 24 | 3 | 70 | 74 | 681 | 785 |
| medium-12x4 | 12 | 4 | 60 | 2 | 136 | 446 | 2852 | 2033 |
| large-20x5 | 20 | 5 | 120 | 1 | 219 | 1496 | 8483 | 4220 |

The first three rows are the reference-suite output. The tiny checksum is included in the dataset run; its checksum length is 124. The complete dataset checksum length is 7166 characters.

## Wall-clock repeatability

PowerShell `Measure-Command` around the complete CLI produced:

```text
benchmark_wall_ms_run1=195.57
benchmark_wall_ms_run2=178.08
```

These timings include process startup and local build-cache effects. They are a reproducibility record for this host, not a cross-machine performance promise. For a comparable measurement, run the command twice after `moon check` and record both values.

## Re-run

```bash
moon update
moon check --deny-warn
moon run cmd/benchmark
```
