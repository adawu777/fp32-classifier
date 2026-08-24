# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog.

## Overview

This project classifies a 32-bit IEEE-754 floating-point number into:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

## IEEE-754 FP32 Format

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |      Fraction        |
|  1 bit   |   8 bits  |       23 bits       |
+----------+-----------+----------------------+ 