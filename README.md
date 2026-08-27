# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog with self-checking verification, randomized testing, and functional coverage.

## Overview

This project classifies a 32-bit IEEE-754 single-precision floating-point value into one of five categories:

* Zero
* Subnormal
* Normal
* Infinity
* NaN

The project demonstrates a progressive verification flow from directed testing to randomized testing and functional coverage.

## IEEE-754 FP32 Format

```text id="z3bfxa"
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
    1 bit      8 bits          23 bits
```

Classification rules:

| Exponent      | Fraction | Classification |
| ------------- | -------- | -------------- |
| `0x00`        | `0`      | Zero           |
| `0x00`        | non-zero | Subnormal      |
| `0x01`–`0xFE` | any      | Normal         |
| `0xFF`        | `0`      | Infinity       |
| `0xFF`        | non-zero | NaN            |

## Design

The DUT extracts the exponent and fraction fields from the FP32 input and determines the corresponding floating-point class.

### Class Encoding

```text id="yqkxtm"
000  Zero
001  Subnormal
010  Normal
011  Infinity
100  NaN
```

## Verification

The verification environment includes:

* Directed corner-case tests
* Independent reference model
* Self-checking testbench
* 10,000 randomized FP32 test vectors
* Automatic PASS/FAIL detection
* Test statistics
* Functional coverage
* Class and sign coverage

## Reference Model

An independent reference model determines the expected FP32 classification.

For every test vector:

```text id="7hxvyi"
FP32 Input
    |
    +------> DUT ------------+
    |                        |
    +------> Reference Model |
                             |
                     Compare Results
                             |
                        PASS / FAIL
```

## Randomized Testing

The testbench generates 10,000 random FP32 bit patterns using:

```systemverilog id="mhk20r"
$urandom
```

Random testing supplements the directed corner-case tests and exercises a large number of FP32 input patterns.

## Functional Coverage

Version 1.3 introduces functional coverage.

Two testbench implementations are provided.

### 1. Standard SystemVerilog Functional Coverage

File:

```text id="rhbhhf"
tb_fp32_classifier_covergroup.sv
```

This version demonstrates standard SystemVerilog functional coverage constructs:

```systemverilog id="6xknmk"
covergroup
coverpoint
bins
cross
```

Coverage is collected for:

* FP32 classification

  * Zero
  * Subnormal
  * Normal
  * Infinity
  * NaN
* Sign

  * Positive
  * Negative
* Class × Sign cross coverage

This testbench represents the standard SystemVerilog approach to functional coverage.

However, Icarus Verilog does not support SystemVerilog `covergroup` functional coverage, so this file is included primarily as a reference implementation for simulators that support these constructs.

### 2. Icarus-Compatible Manual Coverage

File:

```text id="ohpfjj"
tb_fp32_classifier.sv
```

This is the primary runnable testbench for the current project.

Because Icarus Verilog does not support `covergroup`, this version implements functional coverage manually using counters.

It automatically records hits for:

```text id="6z7rja"
Zero
Subnormal
Normal
Infinity
NaN

Positive
Negative
```

Each category acts as a manual coverage bin.

A bin is considered covered when it has been hit at least once.

The testbench automatically calculates the final coverage percentage:

```text id="if4foa"
Coverage = Covered Bins / Total Bins × 100%
```

This provides a simple Icarus-compatible implementation of the basic functional coverage concept.

## Coverage Testbench Comparison

| Testbench                          | Coverage Method                                | Icarus Verilog | Purpose                                   |
| ---------------------------------- | ---------------------------------------------- | -------------: | ----------------------------------------- |
| `tb_fp32_classifier.sv`            | Manual counters                                |            Yes | Primary runnable testbench                |
| `tb_fp32_classifier_covergroup.sv` | `covergroup` / `coverpoint` / `bins` / `cross` |             No | Standard SystemVerilog coverage reference |

## Example Test Summary

```text id="9fdtfp"
========================================
TEST SUMMARY
========================================

Total Tests : 10009
Passed      : 10009
Failed      : 0

========================================
FUNCTIONAL COVERAGE
========================================

Zero       : ...
Subnormal  : ...
Normal     : ...
Infinity   : ...
NaN        : ...

Positive   : ...
Negative   : ...

Coverage   : 100.00% (7/7 bins)

========================================
TEST PASSED
========================================
```

Exact hit counts may vary between simulations because randomized test vectors are generated using `$urandom`.

## Running with Icarus Verilog

Compile and run the Icarus-compatible testbench:

```bash id="g88sqz"
iverilog -g2012 -o sim fp32_classifier.sv tb_fp32_classifier.sv
vvp sim
```

The `tb_fp32_classifier_covergroup.sv` testbench requires a simulator that supports SystemVerilog functional coverage.

## Project Structure

```text id="sqq8t9"
fp32-classifier/
├── fp32_classifier.sv
├── tb_fp32_classifier.sv
├── tb_fp32_classifier_covergroup.sv
└── README.md
```

* `fp32_classifier.sv` — FP32 classifier RTL
* `tb_fp32_classifier.sv` — Icarus-compatible self-checking testbench with manual coverage calculation
* `tb_fp32_classifier_covergroup.sv` — Standard SystemVerilog functional coverage implementation
* `README.md` — Project documentation

## Version History

### v1.0 — Directed Testing

* Initial FP32 classifier RTL
* Directed corner-case tests
* Basic PASS/FAIL checking

### v1.1 — Self-Checking Verification

* Added independent reference model
* Added automatic DUT/reference comparison
* Added test statistics

### v1.2 — Randomized Testing

* Added 10,000 randomized FP32 test vectors
* Extended verification beyond directed corner cases
* Added automatic PASS/FAIL statistics

### v1.3 — Functional Coverage

* Added functional coverage
* Added class coverage for Zero, Subnormal, Normal, Infinity, and NaN
* Added positive/negative sign coverage
* Added standard SystemVerilog `covergroup` reference testbench
* Added Icarus-compatible manual coverage testbench
* Added automatic manual coverage statistics

## Verification Roadmap

```text id="smw4qr"
v1.0  Directed Testing
  |
  v
v1.1  Reference Model + Self-Checking
  |
  v
v1.2  10,000 Randomized Tests
  |
  v
v1.3  Functional Coverage
      |
      +-- Standard SystemVerilog covergroup
      |
      +-- Icarus-Compatible Manual Coverage
```
# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog.

This project develops an FP32 classifier together with a progressively enhanced verification environment, including:

- Directed testing
- Reference-model-based self-checking
- Randomized testing
- Manual functional coverage
- Immediate assertions
- SystemVerilog Assertion (SVA) reference code

---

## Overview

The DUT classifies a 32-bit IEEE-754 single-precision floating-point value into one of five categories:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

---

## IEEE-754 FP32 Format

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |      Fraction        |
+----------+-----------+----------------------+
   1 bit      8 bits           23 bits
```

Classification rules:

| Exponent | Fraction | Classification |
|---|---|---|
| `0x00` | `0` | Zero |
| `0x00` | non-zero | Subnormal |
| `0x01–0xFE` | any | Normal |
| `0xFF` | `0` | Infinity |
| `0xFF` | non-zero | NaN |

---

# Version History

## v1.0 — Basic Directed Verification

Initial implementation of the FP32 classifier and directed testbench.

### Features

- FP32 classification RTL
- Directed test vectors
- Zero verification
- Subnormal verification
- Normal verification
- Infinity verification
- NaN verification

---

## v1.1 — Reference Model

Added an independent reference model to automatically calculate the expected FP32 classification.

### Verification Flow

```text
FP32 Input
    |
    +--------------------+
    |                    |
    v                    v
   DUT             Reference Model
    |                    |
    v                    v
 Actual              Expected
    |                    |
    +---------+----------+
              |
              v
           Compare
              |
         PASS / FAIL
```

This converts the testbench into a self-checking verification environment.

---

## v1.2 — Randomized Testing

Added randomized verification to increase the number and diversity of FP32 test vectors.

### Features

- 10,000 randomized FP32 test vectors
- Directed corner-case tests
- Reference-model comparison
- Automatic PASS/FAIL checking
- Automatic test statistics

The random tests supplement the directed tests and exercise a much larger FP32 input space.

---

## v1.3 — Manual Functional Coverage

Added functional coverage tracking.

Because the current simulation environment uses Icarus Verilog, functional coverage is implemented manually using counters instead of SystemVerilog `covergroup` constructs.

### Classification Coverage

Coverage is collected for:

```text
Zero
Subnormal
Normal
Infinity
NaN
```

### Sign Coverage

Coverage is also collected for:

```text
Positive
Negative
```

The testbench therefore tracks seven functional coverage bins:

```text
5 classification bins
+
2 sign bins
=
7 total bins
```

Coverage percentage is calculated manually:

```text
Coverage = Hit Bins / Total Bins × 100%
```

This provides an Icarus-compatible way to demonstrate functional coverage concepts.

---

# v1.4 — Assertion-Based Verification

Version 1.4 adds assertion-based verification to the FP32 classifier.

Two assertion testbenches are provided because of the SystemVerilog feature support available in the current simulator.

---

## 1. Icarus-Compatible Assertion Testbench

File:

```text
tb/tb_fp32_classifier_assert_cov.sv
```

This is the runnable assertion-based verification testbench.

It combines:

- Reference-model-based self-checking
- Immediate assertions
- Directed corner-case testing
- 10,000 randomized FP32 tests
- Manual functional coverage
- Automatic PASS/FAIL statistics
- Assertion statistics

### Verification Structure

```text
                 FP32 Input
                     |
          +----------+----------+
          |                     |
          v                     v
         DUT              Reference Model
          |                     |
          v                     v
     class_type              expected
          |                     |
          +----------+----------+
                     |
                     v
                  Compare
                     |
                PASS / FAIL
                     |
                     v
            Immediate Assertions
                     |
                     v
           Manual Coverage Sample
```

---

## Immediate Assertions

Immediate assertions verify that the DUT output satisfies the FP32 classification rules.

Example for Zero:

```systemverilog
if ((fp32[30:23] == 8'h00) &&
    (fp32[22:0]  == 23'h000000)) begin

    assert (class_type == CLASS_ZERO)
        assertion_passed++;
    else begin
        assertion_failed++;
        $error("ZERO assertion failed");
    end

end
```

Similar assertions are implemented for:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

Each FP32 input is checked against the corresponding classification rule.

---

## Reference Model + Assertions

The reference model and assertions perform two related but separate checks.

### Reference Model

The reference model calculates the expected result:

```systemverilog
expected = reference_model(value);
```

The DUT output is then compared against it:

```systemverilog
if (class_type === expected)
```

### Assertions

Assertions independently express required DUT behavior.

For example:

```text
IF

Exponent = FF
AND
Fraction != 0

THEN

class_type MUST be NaN
```

This provides an additional rule-based checking mechanism.

---

## Random Testing

The testbench executes:

```systemverilog
repeat (10000) begin
    check_value($urandom);
end
```

PASS messages are intentionally not printed for every random test.

Only failures are printed during testing, followed by a final summary.

This avoids excessive simulator output when running thousands of random tests.

---

## Manual Functional Coverage

The Icarus-compatible testbench also retains the manual functional coverage introduced in v1.3.

Coverage counters track:

```text
Classification:

Zero
Subnormal
Normal
Infinity
NaN

Sign:

Positive
Negative
```

The final report includes:

```text
Coverage : XX.XX% (hit bins / 7 bins)
```

Directed corner-case tests are included to ensure that important FP32 categories are explicitly exercised.

---

# 2. SVA Reference Testbench

File:

```text
tb/tb_fp32_classifier_sva.sv
```

A second testbench demonstrates standard SystemVerilog concurrent assertions using:

```systemverilog
property
assert property
|->
```

Example:

```systemverilog
property p_zero;

    @(*)

    ((fp32[30:23] == 8'h00) &&
     (fp32[22:0]  == 23'h000000))

    |->

    (class_type == CLASS_ZERO);

endproperty


assert property (p_zero);
```

Properties are defined for:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

---

## SVA Simulation Status

The SVA testbench is currently included as a **learning and reference implementation**.

The current simulation environment uses Icarus Verilog, which does not provide the full SystemVerilog concurrent assertion support required by this testbench.

Therefore:

```text
tb_fp32_classifier_assert_cov.sv
        |
        +-- Immediate Assertions
        +-- Reference Model
        +-- 10,000 Random Tests
        +-- Manual Functional Coverage
        +-- Icarus-Compatible
        +-- Runnable


tb_fp32_classifier_sva.sv
        |
        +-- property
        +-- assert property
        +-- Concurrent SVA
        +-- Reference / Learning Version
        +-- Simulation Pending
```

The SVA version will be simulated later using a simulator with appropriate SystemVerilog Assertion support.

No simulation-pass claim is made for the SVA version in the current environment.

---

# v1.4 Verification Flow

The runnable v1.4 testbench follows this flow:

```text
check_value(value)
       |
       v
fp32 = value
       |
       v
      DUT
       |
       v
class_type
       |
      #1
       |
       +----------------------+
       |                      |
       v                      v
Reference Model       Immediate Assertions
       |                      |
       v                      v
   expected              Rule Checking
       |                      |
       +----------+-----------+
                  |
                  v
          Manual Coverage
                  |
                  v
            Next Test Case
```

At the end of simulation, the testbench reports:

```text
Total Tests
Passed Tests
Failed Tests

Assertions Passed
Assertions Failed

Classification Coverage
Sign Coverage
Overall Functional Coverage

TEST PASSED / TEST FAILED
```

---

# Testbench Files

```text
tb/
|
+-- tb_fp32_classifier.sv
|
+-- tb_fp32_classifier_assert_cov.sv
|     |
|     +-- Reference model
|     +-- Immediate assertions
|     +-- Random testing
|     +-- Manual functional coverage
|     +-- Icarus-compatible
|
+-- tb_fp32_classifier_sva.sv
      |
      +-- property
      +-- assert property
      +-- Concurrent SVA reference
      +-- Simulation pending
```

---

# Verification Progress

```text
v1.0
Directed Testing
      |
      v
v1.1
Reference Model
      |
      v
v1.2
Randomized Testing
      |
      v
v1.3
Manual Functional Coverage
      |
      v
v1.4
Assertion-Based Verification
      |
      +--> Immediate Assertions
      |       |
      |       +--> Icarus-compatible
      |       +--> Simulated version
      |
      +--> Concurrent SVA
              |
              +--> property
              +--> assert property
              +--> Simulation pending
```

---

# Tools

- SystemVerilog
- Icarus Verilog
- EDA Playground
- Git
- GitHub

---

# Future Work

Planned verification improvements include:

- Run concurrent SVA with a simulator supporting the required SVA constructs
- Expand assertion coverage
- Add additional constrained-random scenarios
- Integrate assertions into a UVM verification environment
- Apply the same verification methodology to FP32 arithmetic datapaths