

# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog.

## Overview

This project implements a simple IEEE-754 single-precision floating-point classifier.

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

The initial testbench uses directed test cases to verify the main IEEE-754 FP32 categories.

Test cases include:

- Positive zero
- Negative zero
- Subnormal numbers
- Normal numbers
- Positive infinity
- Negative infinity
- NaN

The simulation prints PASS or FAIL for each test case.

## Files

```text
fp32-classifier/
├── fp32_classifier.sv
├── tb_fp32_classifier.sv
└── README.md
```

- `fp32_classifier.sv` — FP32 classifier RTL design
- `tb_fp32_classifier.sv` — SystemVerilog directed testbench
- `README.md` — Project documentation

## Version History

### v1.0 - Initial Version

- Implemented IEEE-754 FP32 classification
- Added classification for Zero, Subnormal, Normal, Infinity, and NaN
- Added basic directed test cases
- Added PASS/FAIL simulation output