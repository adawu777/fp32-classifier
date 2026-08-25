# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog.

## Overview

This project implements an IEEE-754 single-precision floating-point classifier.

The classifier takes a 32-bit FP32 value as input and determines whether the value is:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

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

- Sign: 1 bit
- Exponent: 8 bits
- Fraction: 23 bits

## Classification Rules

| Exponent | Fraction | Classification |
|----------|----------|----------------|
| 0 | 0 | Zero |
| 0 | non-zero | Subnormal |
| 1–254 | any | Normal |
| 255 | 0 | Infinity |
| 255 | non-zero | NaN |

## Output Encoding

The classification result is encoded using a 3-bit output:

| Classification | Encoding |
|----------------|----------|
| Zero | `3'b000` |
| Subnormal | `3'b001` |
| Normal | `3'b010` |
| Infinity | `3'b011` |
| NaN | `3'b100` |

## Verification

The v1.1 testbench introduces a reference model for automatic result checking.

For each test vector, the testbench:

1. Applies an FP32 value to the DUT
2. Calculates the expected classification using the reference model
3. Compares the DUT output with the reference model output
4. Automatically reports PASS or FAIL

This creates a self-checking verification environment and removes the need to manually specify the expected result for each test case.

## Reference Model

The reference model independently determines the expected FP32 classification based on the exponent and fraction fields.

The DUT result is compared against the reference model result:

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
```

## Test Cases

Directed tests cover important IEEE-754 FP32 categories, including:

- Positive zero
- Negative zero
- Subnormal numbers
- Normal numbers
- Positive infinity
- Negative infinity
- NaN

## Files

```text
fp32-classifier/
├── fp32_classifier.sv
├── tb_fp32_classifier.sv
└── README.md
```

- `fp32_classifier.sv` — FP32 classifier RTL design
- `tb_fp32_classifier.sv` — SystemVerilog self-checking testbench with reference model
- `README.md` — Project documentation

## Version History

### v1.1 - Reference Model

Added an independent reference model and automatic result checking.

#### Verification Features

- Independent FP32 reference model
- DUT vs. reference model comparison
- Self-checking testbench
- Automatic PASS/FAIL detection
- Directed IEEE-754 corner-case testing

### v1.0 - Initial Version

- Implemented IEEE-754 FP32 classification
- Added classification for Zero, Subnormal, Normal, Infinity, and NaN
- Added basic directed test cases
- Added PASS/FAIL simulation output