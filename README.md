# FP32 Classifier

IEEE-754 FP32 classifier implemented and verified using SystemVerilog.

## Overview

This project implements an IEEE-754 single-precision floating-point classifier.

The classifier takes a 32-bit FP32 value as input and determines whether the value is:

* Zero
* Subnormal
* Normal
* Infinity
* NaN

Version 1.2 extends the verification environment with **10,000 randomized FP32 test vectors** and automatic test statistics.

## IEEE-754 FP32 Format

An IEEE-754 single-precision floating-point number contains 32 bits:

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
    1 bit      8 bits          23 bits
```

The fields are:

* Sign: 1 bit
* Exponent: 8 bits
* Fraction: 23 bits

## Classification Rules

| Exponent | Fraction | Classification |
| -------- | -------- | -------------- |
| 0        | 0        | Zero           |
| 0        | non-zero | Subnormal      |
| 1–254    | any      | Normal         |
| 255      | 0        | Infinity       |
| 255      | non-zero | NaN            |

## Output Encoding

The classification result is encoded using a 3-bit output:

| Classification | Encoding |
| -------------- | -------- |
| Zero           | `3'b000` |
| Subnormal      | `3'b001` |
| Normal         | `3'b010` |
| Infinity       | `3'b011` |
| NaN            | `3'b100` |

## Verification Architecture

The SystemVerilog testbench uses a self-checking verification approach.

For each test vector, the testbench:

1. Applies an FP32 value to the DUT
2. Calculates the expected classification using the reference model
3. Compares the DUT output with the expected result
4. Automatically records PASS or FAIL
5. Updates the test statistics

The verification flow is:

```text
                +------------------+
FP32 Input ---->|       DUT        |----> Actual Result
     |          +------------------+
     |
     |          +------------------+
     +--------->| Reference Model  |----> Expected Result
                +------------------+
                         |
                         v
                  Compare Results
                         |
                    PASS / FAIL
                         |
                         v
                   Test Statistics
```

## Reference Model

The reference model independently determines the expected FP32 classification from the exponent and fraction fields.

The DUT result is automatically compared against the reference model result.

This allows the testbench to verify large numbers of test vectors without manually specifying the expected result for every input.

## Directed Testing

Directed tests are used to verify important IEEE-754 FP32 categories and corner cases.

The directed tests include:

* Positive zero
* Negative zero
* Subnormal numbers
* Normal numbers
* Positive infinity
* Negative infinity
* NaN

## Randomized Testing

Version 1.2 adds randomized verification.

The testbench generates:

**10,000 randomized 32-bit FP32 test vectors**

Each random FP32 bit pattern is:

1. Applied to the DUT
2. Evaluated by the reference model
3. Automatically compared
4. Recorded as PASS or FAIL

Randomized testing provides broader input-space exploration beyond the directed corner-case tests.

## Test Statistics

The testbench automatically tracks:

* Total number of tests
* Number of passed tests
* Number of failed tests

Example simulation result:

```text
========================================
FP32 CLASSIFIER VERIFICATION
========================================
Total Tests  : 10009
Passed       : 10009
Failed       : 0
TEST PASSED
========================================
```

A total of **10,009 tests** were executed:

* 9 directed tests
* 10,000 randomized tests
* 10,009 total tests
* 10,009 passed
* 0 failed

## Files

```text
fp32-classifier/
├── fp32_classifier.sv
├── tb_fp32_classifier.sv
└── README.md
```

* `fp32_classifier.sv` — FP32 classifier RTL design
* `tb_fp32_classifier.sv` — SystemVerilog self-checking testbench with reference model and randomized testing
* `README.md` — Project documentation

## Version History

### v1.2 - Randomized Testing

Added large-scale randomized verification and automatic test statistics.

#### Verification Features

* 10,000 randomized FP32 test vectors
* Directed corner-case testing
* Independent reference model
* DUT vs. reference model comparison
* Self-checking testbench
* Automatic PASS/FAIL detection
* Automatic test statistics

#### Test Result

```text
Total Tests  : 10009
Passed       : 10009
Failed       : 0
```

### v1.1 - Reference Model

Added an independent reference model and automatic result checking.

* Added FP32 reference model
* Added DUT vs. reference model comparison
* Added self-checking verification
* Added automatic PASS/FAIL detection

### v1.0 - Initial Version

* Implemented IEEE-754 FP32 classification
* Added classification for Zero, Subnormal, Normal, Infinity, and NaN
* Added basic directed test cases
* Added PASS/FAIL simulation output
