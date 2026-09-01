# FP32 Classifier

## v1.8 — AI-Assisted Verification / Codex Agent Workflow

## Overview

This project implements an IEEE-754 single-precision floating-point classifier in SystemVerilog. The DUT classifies each 32-bit encoding as:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

The repository combines synthesizable RTL with a UVM-based verification environment. Version v1.8 focuses on human-reviewed AI-assisted verification refinement, requirement traceability, build readiness, and disciplined separation between implemented source and simulator-produced evidence.

## Current Verification Status

| Status | Current state |
|---|---|
| **IMPLEMENTED** | RTL, UVM source, assertions, source manifest, and regression controls exist. |
| **STATICALLY REVIEWED** | The current v1.8 source and configuration have been inspected for structural consistency. |
| **NOT EXECUTED** | Compilation, elaboration, simulation, assertion execution, and multi-seed regression have not been performed with a compatible UVM simulator. |
| **NOT MEASURED** | No functional-coverage database or measured coverage result exists. |
| **BLOCKED** | Commercial-simulator regression awaits a validated simulator adapter. |

No verification closure is claimed. See [verification_report.md](verification_report.md) for detailed requirement traceability, evidence status, risks, and remaining execution work.

## IEEE-754 FP32 Classification

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
    1 bit      8 bits          23 bits
```

| Exponent | Fraction | Classification |
|---|---|---|
| `00` | `0` | Zero |
| `00` | nonzero | Subnormal |
| `01`–`FE` | any | Normal |
| `FF` | `0` | Infinity |
| `FF` | nonzero | NaN |

The sign bit does not change the class, but both positive and negative encodings are part of stimulus and coverage intent.

## v1.8 Highlights

1. Repaired the UVM driver and monitor component structure.
2. Added expected-count completion synchronization.
3. Prevented zero-transaction false-positive scoreboard reporting.
4. Separated input-decoded class coverage from DUT-output coverage.
5. Added deterministic NaN stimulus for all five planned payload regions.
6. Integrated five classification assertions into the primary UVM top.
7. Added an authoritative simulator-neutral source manifest.
8. Replaced placeholder regression behavior with a fail-closed control framework.

These are source-level refinements and have not been dynamically exercised.

## Primary UVM Architecture

```text
sequence
   |
sequencer
   |
driver
   |
fp32_if
   |
  DUT
   |
monitor
   +----> scoreboard
   +----> coverage

fp32_classifier_sva
          |
       fp32_if
```

`tb_top` creates one shared `fp32_if`, one DUT, and one `fp32_classifier_sva` instance. The driver writes the DUT input and triggers `sample_event` after the combinational settling interval. The monitor and assertion module synchronize on the same event and observe the same interface transaction.

## Stimulus and Checking

- `fp32_sequence` defines 10,000 constrained-random transactions.
- `fp32_boundary_sequence` defines 18 deterministic boundary and targeted transactions.
- The derived expected total is 10,018 transactions.
- `class_sel` represents generator intent and controls class-specific constraints.
- `fp32` is the actual DUT stimulus.
- `class_type` is the observed DUT output.
- The scoreboard independently derives the expected classification from exponent and fraction fields.
- The test waits for the scoreboard to receive the expected transaction count.
- Final accounting requires exact count equality and `passed_tests + failed_tests == total_tests`.
- A zero-transaction execution cannot produce the positive scoreboard result.

These transaction counts describe implemented source behavior; execution is **NOT EXECUTED**.

## Deterministic NaN Refinement

| Vector | Sign and kind | Payload | Planned payload bin |
|---|---|---|---|
| `32'h7FC00000` | Positive qNaN | `23'h400000` | `nan_mid_payload` |
| `32'hFFC00000` | Negative qNaN | `23'h400000` | `nan_mid_payload` |
| `32'h7F800001` | Positive sNaN | `23'h000001` | `nan_min_payload` |
| `32'hFF800002` | Negative sNaN | `23'h000002` | `nan_low_payload` |
| `32'h7FE00000` | Positive qNaN | `23'h600000` | `nan_high_payload` |
| `32'hFFFFFFFF` | Negative qNaN | `23'h7FFFFF` | `nan_max_payload` |

These vectors provide deterministic source stimulus for all five planned NaN payload regions and both signs. Coverage-bin sampling is **NOT MEASURED**.

## Functional Coverage

The monitor-based coverage subscriber separates input meaning from observed DUT behavior:

- `cp_input_class` — class decoded from monitored `fp32`.
- `cp_dut_class` — DUT-observed `class_type`, with invalid binary encodings declared illegal.
- `cp_sign` — positive and negative encodings.
- Exponent and fraction coverpoints — meaningful regions and classification boundaries.
- Exact boundary bins — planned zero, subnormal, normal, infinity, and representative qNaN values.
- `cp_nan_frac` — five NaN payload regions.
- `input_class_sign_cross` — input-decoded class across both signs.
- `dut_class_sign_cross` — DUT-observed class across both signs.
- `input_dut_class_cross` — five correct input-to-DUT mappings; mismatches remain scoreboard responsibilities.

Separating input-decoded and DUT-observed class prevents stimulus coverage from being mistaken for DUT-output coverage.

**Functional coverage: NOT MEASURED.** See [verification_report.md](verification_report.md) for the detailed coverage model and compatibility risks.

## Assertions

`fp32_classifier_sva` contains five immediate classification assertions for Zero, Subnormal, Normal, Infinity, and NaN. It is instantiated once in `tb_top` and synchronizes on `sample_event` without adding a delay inside the assertion module.

The legacy standalone assertion bench is excluded from the primary UVM build.

**Assertion execution: NOT EXECUTED.**

## Build and Regression Readiness

Primary source manifest:

```text
filelists/fp32_uvm.f
```

Primary top:

```text
tb_top
```

`fp32_pkg.sv` textually includes the UVM class files, so those files must not also be compiled separately. Legacy standalone benches are excluded from the primary manifest. Wildcard compilation such as `tb/*.sv` is unsafe because it would include package class sources separately and encounter a duplicate legacy module name.

`scripts/run_regression.sh` is a regression control framework with this configuration interface:

```text
SIMULATOR=auto|questa|vcs|xcelium
NUM_SEEDS=20
FIRST_SEED=1
SEED_TIMEOUT_SECONDS=300
COVERAGE=0|1
```

The framework provides simulator discovery, compile-once/run-many control structure, an external timeout structure, multi-condition result analysis, and an intended `results/regression_<timestamp>/<simulator>/` layout.

A future seed result requires successful simulator exit, no timeout, a completed UVM summary, zero UVM error/fatal counts, no assertion-failure marker, no negative scoreboard marker, and the positive scoreboard marker. `TEST PASSED` alone is insufficient.

Simulator-specific compilation, elaboration, execution, seed, UVM, error-exit, and coverage commands remain intentionally unimplemented until validated with an installed compatible simulator. The framework fails closed rather than generating fake positive results.

**Regression execution: BLOCKED pending a validated compatible simulator adapter.**

## Repository Structure

```text
fp32-classifier/
├── rtl/
│   └── fp32_classifier.sv
├── tb/
│   ├── fp32_if.sv
│   ├── fp32_pkg.sv
│   ├── fp32_transaction.sv
│   ├── fp32_sequence.sv
│   ├── fp32_boundary_sequence.sv
│   ├── fp32_driver.sv
│   ├── fp32_monitor.sv
│   ├── fp32_scoreboard.sv
│   ├── fp32_coverage.sv
│   ├── fp32_agent.sv
│   ├── fp32_env.sv
│   ├── fp32_test.sv
│   ├── tb_fp32_classifier_sva.sv
│   ├── tb_top.sv
│   └── legacy standalone benches
├── filelists/
│   └── fp32_uvm.f
├── scripts/
│   └── run_regression.sh
├── AGENTS.md
├── verification_plan.md
├── verification_report.md
└── README.md
```

Legacy standalone benches remain available for historical context but are deliberately excluded from `filelists/fp32_uvm.f`.

## AI-Assisted Verification Workflow

```text
Human defines verification intent
  → Codex inspects the repository
  → Codex identifies focused verification gaps
  → Human reviews proposed changes
  → Codex implements only approved minimal changes
  → Static review
  → Dynamic verification when a compatible simulator becomes available
  → Evidence-based reporting
```

The human verification engineer remains the verification sign-off authority.

## Documentation

- [verification_plan.md](verification_plan.md) — verification intent, requirements, coverage goals, and closure criteria.
- [verification_report.md](verification_report.md) — requirement traceability, v1.8 refinements, evidence status, risks, and remaining execution work.
- [AGENTS.md](AGENTS.md) — rules for AI-assisted inspection, implementation, reporting, and the prohibition on fabricated verification results.

## Version History

- **v1.0 — RTL + Directed Testing:** Initial classifier and directed stimulus.
- **v1.1 — Reference Model / Self-Checking:** Independent expected-value checking.
- **v1.2 — Randomized Testing:** Broader randomized input exploration.
- **v1.3 — Functional Coverage:** Initial coverage infrastructure.
- **v1.4 — Assertion-Based Verification:** Standalone classification assertions.
- **v1.5 — UVM Verification Environment:** Agent, environment, sequences, driver, monitor, and scoreboard.
- **v1.6 — Constrained-Random + Coverage:** Class-aware randomization and UVM coverage subscriber.
- **v1.7 — Coverage Refinement + Boundary + Multi-Seed Infrastructure:** Refined bins, deterministic boundaries, and initial regression scaffolding.
- **v1.8 — AI-Assisted Verification / Codex Agent Workflow:** Human-reviewed driver/monitor repair, completion accounting, coverage semantic refinement, deterministic NaN payload stimulus, primary assertion integration, authoritative source manifest, fail-closed regression controls, and evidence-status documentation. These source-level refinements are **IMPLEMENTED** and **STATICALLY REVIEWED**; dynamic verification is **NOT EXECUTED**.

## Execution Still Required

- Compile `filelists/fp32_uvm.f` with a compatible UVM simulator.
- Elaborate `tb_top`.
- Execute the implemented 10,018-transaction test.
- Exercise the five classification assertions.
- Run multiple reproducible seeds.
- Measure functional coverage.
- Validate timeout and result parsing.
- Validate one commercial-simulator adapter.
- Optionally collect and merge per-seed coverage databases.

Until those activities produce real evidence, compilation, simulation, regression, assertion, and coverage outcomes remain unclaimed.
