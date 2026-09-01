# FP32 Classifier

## v1.8 AI-Assisted Verification / Codex Agent Workflow

### Evidence status vocabulary

| Status | Meaning |
|---|---|
| **IMPLEMENTED** | The source or configuration exists in the repository. |
| **STATICALLY REVIEWED** | Source consistency was inspected without compiling or simulating it. |
| **NOT EXECUTED** | Dynamic evidence requires a compatible simulator and does not currently exist. |
| **NOT MEASURED** | No simulator-generated coverage result or database currently exists. |
| **BLOCKED** | A missing validated simulator adapter currently prevents automated execution. |

## 1. Executive Summary

Version v1.8 prepares and statically reviews the FP32 Classifier verification environment at source and configuration level. The work refines the primary UVM path, completion accounting, functional-coverage semantics, deterministic NaN stimulus, assertion integration, build manifest, and regression controls.

The current implementation is **IMPLEMENTED** and **STATICALLY REVIEWED**. No compatible UVM simulator was used for dynamic verification; compilation, elaboration, simulation, assertion execution, and regression execution are **NOT EXECUTED**. Functional coverage is **NOT MEASURED**. Automated commercial-simulator regression is **BLOCKED** until one simulator adapter is validated for this repository.

This report records engineering intent, implemented structure, static findings, and the evidence still required. It does not claim dynamic verification results or verification closure.

## 2. Verification Scope

The DUT accepts one IEEE-754 single-precision encoding, `fp32[31:0]`, and produces a three-bit classification, `class_type[2:0]`. The verification scope contains five requirements:

| ID | Requirement | Classification rule |
|---|---|---|
| REQ-001 | Zero | Exponent `00`, fraction zero |
| REQ-002 | Subnormal | Exponent `00`, fraction nonzero |
| REQ-003 | Normal | Exponent `01` through `FE` |
| REQ-004 | Infinity | Exponent `FF`, fraction zero |
| REQ-005 | NaN | Exponent `FF`, fraction nonzero |

The sign bit does not alter classification, but positive and negative encodings remain stimulus and coverage requirements.

## 3. Primary Verification Architecture

The authoritative primary path is:

```text
fp32_test
  ├─ fp32_sequence
  └─ fp32_boundary_sequence
            │
            v
       UVM sequencer
            │
            v
       fp32_driver
            │
            v
         fp32_if ──────> fp32_classifier DUT
            │                    │
            │                    v
            ├────────────> fp32_monitor
            │                    │
            │                    ├─> fp32_scoreboard
            │                    └─> fp32_coverage
            │
            └────────────> fp32_classifier_sva
```

`tb_top` creates one `fp32_if`, one DUT instance, and one assertion-module instance. It supplies the same virtual interface to the UVM driver and monitor. The driver writes `fp32`, allows the combinational output to settle, and triggers `sample_event`. The monitor and assertion module both synchronize on that event. The monitor publishes `fp32` and `class_type` to the scoreboard and coverage subscriber.

Architecture status: **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**.

## 4. Requirement Traceability

| Requirement | Stimulus | Scoreboard checking | Assertion | Functional coverage | Evidence status |
|---|---|---|---|---|---|
| REQ-001 Zero | Weighted random Zero; deterministic positive and negative zero | Reference model expects Zero for exponent zero and fraction zero | `a_zero` | Input/DUT class; sign; class/sign crosses; mapping cross; positive/negative boundary bins | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |
| REQ-002 Subnormal | Weighted random Subnormal; minimum/maximum positive and negative deterministic values | Reference model expects Subnormal for exponent zero and nonzero fraction | `a_subnormal` | Input/DUT class; sign; exponent zero; fraction regions; four boundary bins | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |
| REQ-003 Normal | Weighted random Normal; minimum/maximum positive and negative deterministic values | Reference model expects Normal for exponents `01` through `FE` | `a_normal` | Input/DUT class; sign; exponent regions; fraction regions; four boundary bins | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |
| REQ-004 Infinity | Weighted random Infinity; deterministic positive and negative infinity | Reference model expects Infinity for exponent `FF` and fraction zero | `a_infinity` | Input/DUT class; sign; special exponent; zero fraction; infinity boundary bins | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |
| REQ-005 NaN | Weighted random NaN; six deterministic NaN vectors | Reference model expects NaN for exponent `FF` and nonzero fraction | `a_nan` | Input/DUT class; sign; mapping cross; payload regions; representative qNaN boundaries | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |

## 5. Stimulus Strategy

### Constrained-random stimulus

`fp32_sequence` generates 10,000 transactions. `class_sel` is weighted equally across Zero, Subnormal, Normal, Infinity, and NaN, then class-specific constraints produce a consistent `fp32` encoding. This avoids the Normal-class dominance of uniform 32-bit random stimulus.

### Deterministic stimulus

`fp32_boundary_sequence` contains 18 deterministic transactions. It retains positive/negative zero, subnormal and normal boundaries, positive/negative infinity, representative qNaNs, and four additional payload-targeted NaNs. The sequence checks that its array size equals `TRANSACTION_COUNT`.

### Expected transaction total

```text
Random transactions        10,000
Deterministic transactions     18
                            ------
Expected total             10,018
```

`fp32_test` derives this total from the two sequence constants rather than duplicating the value.

Stimulus implementation: **IMPLEMENTED**, **STATICALLY REVIEWED**. Stimulus execution: **NOT EXECUTED**.

## 6. NaN Coverage Refinement

| Deterministic vector | Sign | Payload | Role | Planned payload bin |
|---|---|---|---|---|
| `32'h7FC00000` | Positive | `23'h400000` | Representative qNaN | `nan_mid_payload` |
| `32'hFFC00000` | Negative | `23'h400000` | Representative qNaN | `nan_mid_payload` |
| `32'h7F800001` | Positive | `23'h000001` | Representative sNaN, minimum payload | `nan_min_payload` |
| `32'hFF800002` | Negative | `23'h000002` | Representative sNaN, low payload | `nan_low_payload` |
| `32'h7FE00000` | Positive | `23'h600000` | High-payload qNaN | `nan_high_payload` |
| `32'hFFFFFFFF` | Negative | `23'h7FFFFF` | Maximum-payload qNaN | `nan_max_payload` |

All five planned NaN payload bins now have deterministic source stimulus. Both NaN signs and representative qNaN and sNaN patterns are represented. This is an implementation statement only: bin sampling is **NOT MEASURED**.

## 7. Checking and Completion

The scoreboard independently decodes exponent and fraction fields from the monitored `fp32` value. It compares that expected class with the DUT-observed `tr.class_type` using case equality.

Transaction fields retain distinct meanings:

- `class_sel` expresses generator intent and controls random constraints.
- `fp32` is the actual DUT input.
- `class_type` is the observed DUT output.
- Monitor-created transactions do not use `class_sel` for checking or coverage.

Before stimulus starts, `fp32_test` configures the scoreboard with the derived expected count of 10,018. After both sequences return, the test waits on:

```systemverilog
wait (total_tests >= expected_tests);
```

The scoreboard subsequently requires exact equality between total and expected transactions and requires:

```text
passed_tests + failed_tests == total_tests
```

Its positive-result condition additionally requires a positive expected count, exact transaction count, consistent accounting, and zero classification failures. Therefore, a zero-transaction execution cannot produce the scoreboard's positive result.

Checking and completion logic: **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**.

## 8. Functional Coverage

The monitor-based coverage subscriber separates stimulus/input meaning from DUT-output meaning:

- `cp_input_class` covers the class decoded from monitored `tr.fp32`.
- `cp_dut_class` covers monitored `tr.class_type` directly and declares binary encodings `101`, `110`, and `111` illegal.
- `cp_sign` covers positive and negative input encodings.
- `cp_exp` covers zero, minimum normal, low, middle, high, maximum normal, and special exponent regions.
- `cp_frac` covers zero, minimum, low, middle, high, and maximum fraction regions.
- `cp_boundary` covers exact planned FP32 boundary encodings.
- `cp_nan_frac` covers five NaN payload regions and is gated by input-decoded NaN classification.
- `input_class_sign_cross` measures input-decoded class across both signs.
- `dut_class_sign_cross` measures DUT-observed class across both input signs.
- `input_dut_class_cross` contains five explicit correct input-to-DUT mappings. Remaining combinations are ignored in coverage; the scoreboard remains responsible for detecting mismatches.

`class_sel` does not participate in monitor-based coverage.

Coverage model: **IMPLEMENTED**, **STATICALLY REVIEWED**. Functional coverage: **NOT MEASURED**.

## 9. Assertions

`fp32_classifier_sva` is a separate module containing five immediate assertions:

- `a_zero`
- `a_subnormal`
- `a_normal`
- `a_infinity`
- `a_nan`

It is instantiated exactly once in `tb_top`, uses the same `fp32_if` as the DUT and UVM components, and samples on `always @(vif.sample_event)`. No delay is added inside the assertion module. The legacy standalone assertion bench is excluded from the primary source manifest.

Assertion integration: **IMPLEMENTED**, **STATICALLY REVIEWED**. Assertion execution: **NOT EXECUTED**.

## 10. Build Structure

The authoritative primary manifest is `filelists/fp32_uvm.f`:

```text
+incdir+tb

tb/fp32_if.sv
rtl/fp32_classifier.sv
tb/fp32_pkg.sv
tb/tb_fp32_classifier_sva.sv
tb/tb_top.sv
```

The primary top is `tb_top`. `fp32_pkg.sv` textually includes the transaction, sequences, driver, monitor, scoreboard, coverage subscriber, agent, environment, and test. Those class files must not also be compiled independently.

The primary manifest excludes these legacy standalone benches:

- `tb/tb_fp32_classifier.sv`
- `tb/tb_fp32_classifier_coverage.sv`
- `tb/tb_fp32_classifier_assertion.sv`

The first two legacy files both define `tb_fp32_classifier`. Wildcard compilation such as `tb/*.sv` is therefore unsafe and would also compile package-included classes separately.

Build configuration: **IMPLEMENTED**, **STATICALLY REVIEWED**. Primary compilation and elaboration: **NOT EXECUTED**.

## 11. Regression Framework

`scripts/run_regression.sh` implements a fail-closed control framework with:

- Repository-root resolution independent of caller working directory.
- Authoritative manifest and `tb_top` selection.
- `SIMULATOR=auto|questa|vcs|xcelium` configuration.
- `NUM_SEEDS`, `FIRST_SEED`, `SEED_TIMEOUT_SECONDS`, and `COVERAGE=0|1` validation.
- Documented automatic discovery order: Questa, VCS, then Xcelium.
- Compile-once/run-many-seeds control structure.
- External per-seed wall-clock watchdog structure.
- Multi-condition seed acceptance analysis.
- Intended metadata, compile log, summary, tabular result, build, seed-log, and coverage directories under `results/regression_<timestamp>/<simulator>/`.

A future seed is accepted only when simulator status is zero, no timeout occurs, a completed UVM report summary exists, UVM error and fatal counts are zero, no assertion-failure marker exists, no negative scoreboard marker exists, and the positive scoreboard marker exists. The positive scoreboard marker alone is never sufficient.

Coverage defaults to disabled. `COVERAGE=1` is recognized, but simulator-specific coverage commands and database handling are not implemented.

Commercial-simulator compile, elaboration, run, seed, UVM, error-exit, and coverage commands remain intentionally unimplemented pending validation with an installed compatible simulator. Regression execution is therefore **BLOCKED**. No fake seed results are produced while unavailable.

Regression controls: **IMPLEMENTED**, **STATICALLY REVIEWED**. Regression execution: **BLOCKED** and **NOT EXECUTED**.

## 12. AI-Assisted Verification Workflow

The v1.8 workflow followed a human-reviewed, evidence-oriented sequence:

```text
Human defines verification intent
  → Codex inspects the existing repository
  → Codex identifies a focused verification gap
  → Human reviews the proposed change
  → Codex implements only the approved change
  → Codex performs static consistency checks
  → Dynamic verification occurs when a compatible simulator is available
  → Evidence-based reporting records actual outcomes
```

The human verification engineer remains the verification sign-off authority. Codex supports inspection, gap analysis, minimal implementation, and reporting; it does not replace engineering judgment or dynamic evidence.

## 13. v1.8 Verification Gap Refinements

| Refinement | Original issue | Implemented refinement | Current evidence status |
|---|---|---|---|
| Driver/monitor structural repair | Driver and monitor existed only as incomplete phase fragments | Added complete UVM component classes, factory registration, virtual-interface acquisition, and monitor analysis port | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED** |
| Completion synchronization | Test could drop its objection before final analysis processing | Added sequence counts, scoreboard expected count, and count-based completion wait | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED** |
| False-positive result prevention | Zero received transactions could satisfy the old zero-failure condition | Required positive expected count, exact count, consistent accounting, and zero classification failures | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED** |
| Coverage semantic refinement | Class coverage decoded only the input while appearing to represent DUT output | Separated input-decoded and DUT-observed class coverpoints and added mapping/sign crosses | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT MEASURED** |
| Deterministic NaN stimulus | Four payload regions and representative sNaNs depended on random generation | Added four targeted NaNs while retaining two representative qNaNs | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED**, **NOT MEASURED** |
| Assertion integration | Assertions lived only in a separate legacy bench | Added one event-synchronized assertion module to the primary `tb_top` | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED** |
| Authoritative source manifest | Wildcard compilation could include duplicate legacy tops and package classes | Added an ordered simulator-neutral primary manifest | **IMPLEMENTED**, **STATICALLY REVIEWED**, **NOT EXECUTED** |
| Regression control framework | Script generated placeholder logs without real simulator execution | Added fail-closed configuration, discovery, timeout, analysis, and result-layout controls | **IMPLEMENTED**, **STATICALLY REVIEWED**, **BLOCKED** |

## 14. Known Risks and Limitations

- Commercial-simulator compatibility has not been established: **NOT EXECUTED**.
- The driver's `#1` combinational settling delay depends on simulator time-unit configuration: **NOT EXECUTED**.
- Coverage syntax including named `binsof` selection and `ignore_bins mismatches = default` requires tool confirmation: **NOT EXECUTED**.
- Explicit illegal DUT bins cover binary values `101` through `111`; handling of `X` or `Z` samples may vary by simulator: **NOT EXECUTED**.
- Assertion module interface-port and named-event behavior require compilation and execution confirmation: **NOT EXECUTED**.
- The external timeout and result parser have not been exercised against a real simulator: **NOT EXECUTED**.
- Legacy files contain a duplicate `tb_fp32_classifier` module name and remain hazardous under wildcard compilation. The authoritative manifest contains this risk by excluding them: **STATICALLY REVIEWED**.
- Commercial-simulator adapters are unvalidated and automated execution is **BLOCKED**.
- README.md has been updated to reflect the current v1.8 source, stimulus counts, coverage terminology, build structure, and fail-closed regression framework: **STATICALLY REVIEWED**.
- For reproducible dynamic verification, future simulator runs should record the repository revision and execution configuration used to produce the evidence: **NOT EXECUTED**.

## 15. Execution Still Required

| Required activity | Current status |
|---|---|
| Compile `filelists/fp32_uvm.f` with a compatible UVM simulator | **NOT EXECUTED** |
| Elaborate primary top `tb_top` | **NOT EXECUTED** |
| Run constrained-random and deterministic stimulus | **NOT EXECUTED** |
| Confirm processing of exactly 10,018 transactions | **NOT EXECUTED** |
| Exercise all five classification assertions | **NOT EXECUTED** |
| Run multiple reproducible seeds | **NOT EXECUTED** |
| Measure functional coverage | **NOT MEASURED** |
| Validate timeout and result parsing | **NOT EXECUTED** |
| Validate one commercial-simulator adapter | **BLOCKED** |
| Optionally generate and merge per-seed coverage databases | **NOT MEASURED** |

## 16. Conclusion

The v1.8 source and configuration implementation is prepared. Static review is complete for the current primary UVM path, stimulus counts, scoreboard completion logic, coverage semantics, assertions, source manifest, and regression controls.

Dynamic verification remains **NOT EXECUTED**. Functional coverage remains **NOT MEASURED**. Commercial-simulator regression remains **BLOCKED** pending a validated adapter. No verification closure is claimed.
