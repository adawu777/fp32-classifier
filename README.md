# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog with a UVM-based verification environment.

## Overview

This project implements and verifies a classifier for 32-bit IEEE-754 single-precision floating-point values.

The DUT classifies each FP32 input into one of five categories:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

The project is developed incrementally, starting from directed RTL testing and gradually introducing reference modeling, randomized testing, functional coverage, assertions, UVM, coverage refinement, boundary testing, and regression infrastructure.

---

## IEEE-754 FP32 Format

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
    1 bit      8 bits          23 bits
```

FP32 values are classified according to the exponent and fraction fields:

| Exponent | Fraction | Classification |
|---|---|---|
| `0x00` | `0` | Zero |
| `0x00` | non-zero | Subnormal |
| `0x01`–`0xFE` | any | Normal |
| `0xFF` | `0` | Infinity |
| `0xFF` | non-zero | NaN |

---

# v1.7 — Coverage Refinement and Multi-Seed Regression

Version 1.7 extends the UVM verification environment with more targeted functional coverage, explicit boundary testing, improved driver/monitor synchronization, and multi-seed regression infrastructure.

The main goal of this version is to move from basic constrained-random verification toward a coverage-driven verification flow.

---

## Verification Architecture

```text
                 fp32_test
                     |
          +----------+----------+
          |                     |
   fp32_sequence      fp32_boundary_sequence
          |                     |
          +----------+----------+
                     |
                 Sequencer
                     |
                   Driver
                     |
                fp32_if
                     |
                    DUT
                     |
                  Monitor
                     |
             analysis_port
               /         \
              /           \
             v             v
       Scoreboard       Coverage
```

The verification environment separates stimulus generation, DUT driving, monitoring, checking, and coverage collection.

---

## UVM Components

### Transaction

`fp32_transaction` represents one FP32 verification transaction.

It contains:

```systemverilog
rand logic [31:0] fp32;
rand bit   [2:0]  class_sel;

logic [2:0] class_type;
```

`class_sel` is used only by the testbench to control constrained-random FP32 generation.

`fp32` is the actual DUT input.

`class_type` is the observed DUT output.

---

## Constrained-Random Stimulus

Pure 32-bit random generation does not efficiently exercise all FP32 classes.

Most randomly generated FP32 bit patterns are Normal values, while exact values such as Zero and Infinity have extremely low probability.

The transaction therefore uses weighted class selection:

```systemverilog
class_sel dist {
    CLASS_ZERO      := 20,
    CLASS_SUBNORMAL := 20,
    CLASS_NORMAL    := 20,
    CLASS_INFINITY  := 20,
    CLASS_NAN       := 20
};
```

This provides approximately equal probability for the five FP32 classes.

The main random sequence generates:

```text
10,000 constrained-random transactions
```

per test execution.

---

## Directed Boundary Sequence

Version 1.7 adds a dedicated boundary sequence to guarantee that important FP32 corner cases are exercised.

The sequence includes:

| FP32 Pattern | Description |
|---|---|
| `0x00000000` | +Zero |
| `0x80000000` | -Zero |
| `0x00000001` | Minimum positive subnormal |
| `0x007FFFFF` | Maximum positive subnormal |
| `0x80000001` | Minimum-magnitude negative subnormal |
| `0x807FFFFF` | Maximum-magnitude negative subnormal |
| `0x00800000` | Minimum positive normal |
| `0x7F7FFFFF` | Maximum positive finite normal |
| `0x80800000` | Minimum-magnitude negative normal |
| `0xFF7FFFFF` | Maximum-magnitude negative finite normal |
| `0x7F800000` | +Infinity |
| `0xFF800000` | -Infinity |
| `0x7FC00000` | Representative positive quiet NaN |
| `0xFFC00000` | Representative negative quiet NaN |

The directed boundary sequence complements constrained-random testing by guaranteeing important exact patterns.

---

## Functional Coverage

The UVM coverage subscriber receives observed transactions directly from the monitor.

Coverage is based on actual DUT-interface activity rather than generator intent.

### Class Coverage

Tracks all five FP32 classes:

```text
Zero
Subnormal
Normal
Infinity
NaN
```

### Sign Coverage

Tracks:

```text
Positive
Negative
```

### Exponent Coverage

Exponent coverage is divided into meaningful regions:

```text
exp_zero
exp_min_normal
exp_low
exp_mid
exp_high
exp_max_normal
exp_special
```

This avoids creating unnecessary coverage requirements for every individual normal exponent value.

### Fraction Coverage

Fraction coverage includes:

```text
frac_zero
frac_min
frac_low
frac_mid
frac_high
frac_max
```

### Boundary Coverage

Exact FP32 boundary patterns are tracked separately.

Non-boundary FP32 values are ignored for this specific coverpoint:

```systemverilog
ignore_bins non_boundary = default;
```

They can still contribute to other coverpoints such as class, sign, exponent, and fraction coverage.

### NaN Payload Coverage

NaN fraction values are sampled separately when:

```systemverilog
observed_class == CLASS_NAN
```

This provides additional visibility into NaN payload variation.

### Cross Coverage

Class and sign are crossed:

```systemverilog
class_sign_cross : cross cp_class, cp_sign;
```

This verifies that sign/class combinations are exercised.

---

## Scoreboard and Reference Model

The scoreboard contains an independent FP32 classification reference model.

For each observed transaction:

```text
FP32 input
    |
    +----------------+
    |                |
    v                v
   DUT        Reference Model
    |                |
    v                v
 actual           expected
       \          /
        \        /
         Scoreboard
```

The scoreboard compares:

```systemverilog
tr.class_type === expected
```

and maintains:

```text
Total Tests
Passed Tests
Failed Tests
```

A final PASS/FAIL result is reported during `report_phase`.

---

## Driver / Monitor Synchronization

Version 1.7 refines transaction synchronization between the driver and monitor.

For every transaction:

```text
Driver gets transaction
        |
        v
Drive fp32
        |
        v
Allow combinational DUT to settle
        |
        v
Trigger sample_event
        |
        v
Monitor samples fp32 and class_type
        |
        v
Scoreboard + Coverage
```

The driver is responsible for triggering:

```systemverilog
-> vif.sample_event;
```

The monitor waits for:

```systemverilog
@(vif.sample_event);
```

This provides a clear one-transaction / one-sample synchronization model.

---

## Analysis Port Fanout

The monitor publishes observed transactions through a UVM analysis port.

```text
                  Monitor
                     |
                 ap.write(tr)
                  /       \
                 /         \
                v           v
          Scoreboard      Coverage
```

The same observed transaction is therefore used for both correctness checking and functional coverage.

---

## Multi-Seed Regression

Version 1.7 introduces multi-seed regression infrastructure.

The regression script is located at:

```text
scripts/run_regression.sh
```

The default configuration is:

```text
20 random seeds
```

Each seed receives its own log:

```text
logs/
├── seed_1.log
├── seed_2.log
├── seed_3.log
├── ...
└── seed_20.log
```

A regression summary is also generated:

```text
logs/regression_summary.log
```

The regression infrastructure tracks:

```text
Total Seeds
Passed Seeds
Failed Seeds
Failed Seed Numbers
Final Regression Status/
```

Saving failed seeds allows random failures to be reproduced later.

---

## Why Multi-Seed Regression?

A single random seed explores only one random trajectory.

Running multiple seeds generates different transaction sequences and improves verification diversity.

If a failure occurs, the corresponding seed can be saved and reused to reproduce the same random stimulus sequence for debugging.

---

## Coverage Closure Strategy

The intended coverage-closure workflow is:

```text
Run Test
    |
    v
Analyze Coverage
    |
    v
Identify Coverage Holes
    |
    v
Determine Cause
    |
    +--> Random probability?
    |
    +--> Constraint issue?
    |
    +--> Missing directed test?
    |
    +--> Unreachable scenario?
    |
    +--> Coverage-model issue?
    |
    v
Refine Stimulus / Coverage
    |
    v
Run Regression Again
```

The objective is not simply to create more coverage bins, but to define meaningful coverage corresponding to DUT functionality and verification risk.

---

## Project Structure

```text
fp32-classifier/
|
├── rtl/
│   └── fp32_classifier.sv
|
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
│   └── tb_top.sv
|
├── scripts/
│   └── run_regression.sh
|
└── README.md
```

---

## Verification Flow

```text
Specification
      |
      v
Transaction
      |
      v
Constrained Random + Directed Boundary
      |
      v
Sequencer
      |
      v
Driver
      |
      v
Interface
      |
      v
DUT
      |
      v
Monitor
   /        \
  v          v
Scoreboard  Coverage
  |           |
  v           v
Correctness  Completeness
       \      /
        v    v
       Regression
           |
           v
    Coverage Closure
```

---

## Simulation Status

The v1.7 UVM environment, refined coverage model, directed boundary sequence, and multi-seed regression infrastructure have been prepared.

A full UVM-capable simulator is currently required to execute the complete environment and collect actual functional coverage results.

Therefore, this version does **not** claim measured 100% functional coverage or completed multi-seed regression results.

The simulator-specific command in `run_regression.sh` is intentionally left configurable for future use with tools such as Questa, VCS, or Xcelium.

---

# Version History

### v1.0 — RTL + Directed Testing

Initial FP32 classifier RTL implementation with directed test cases.

### v1.1 — Reference Model / Self-Checking

Added an independent reference model and automatic DUT result checking.

### v1.2 — Randomized Testing

Added randomized FP32 stimulus generation and automatic test statistics.

### v1.3 — Functional Coverage

Added functional coverage infrastructure.

### v1.4 — Assertion-Based Verification

Added assertion-based verification infrastructure.

### v1.5 — UVM Verification Environment

Migrated the verification environment to UVM with transaction, sequence, sequencer, driver, monitor, scoreboard, agent, environment, and test components.

### v1.6 — Constrained-Random UVM and Functional Coverage

Added constrained-random FP32 class generation and UVM functional coverage collection.

### v1.7 — Coverage Refinement and Multi-Seed Regression

Added:

- Refined exponent and fraction coverage
- Exact FP32 boundary coverage
- NaN payload coverage
- Directed boundary sequence
- Random + directed sequence execution
- Improved driver/monitor synchronization
- Explicit scoreboard regression PASS/FAIL reporting
- Multi-seed regression infrastructure
- Failed-seed tracking for reproducibility
- Coverage-closure-oriented verification structure

---

## Future Work

Potential future improvements include:

- Running the complete environment on a commercial UVM-capable simulator
- Coverage database generation and merging
- Automated coverage-hole analysis
- Assertion coverage
- Additional IEEE-754 corner-case verification
- Regression automation and reporting
- CI integration

---

## Key Verification Concepts Demonstrated

This project demonstrates:

- SystemVerilog RTL
- IEEE-754 FP32 classification
- Self-checking verification
- Reference modeling
- Constrained-random stimulus generation
- SystemVerilog constraints
- Directed corner-case testing
- UVM transaction-level architecture
- UVM factory usage
- Virtual interfaces
- UVM configuration database
- Driver / monitor synchronization
- UVM analysis ports
- Scoreboard checking
- Functional coverage
- Cross coverage
- Boundary coverage
- Coverage closure
- Multi-seed regression
- Random failure reproducibility