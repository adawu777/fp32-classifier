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
