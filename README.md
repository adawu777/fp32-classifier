·# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog with self-checking verification, randomized testing, functional coverage, and assertions.

## Overview

This project classifies a 32-bit IEEE-754 single-precision floating-point value into one of five categories:

* Zero
* Subnormal
* Normal
* Infinity
* NaN

The project demonstrates a progressive verification flow, starting with directed testing and gradually adding reference-model checking, randomized testing, functional coverage, and assertions.

---

## IEEE-754 FP32 Format

```text
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

```text
000  Zero
001  Subnormal
010  Normal
011  Infinity
100  NaN
```

---

## Verification Features

The verification environment includes:

* Directed corner-case testing
* Independent reference model
* Self-checking testbench
* 10,000 randomized FP32 test vectors
* Automatic PASS/FAIL detection
* Functional coverage
* Immediate assertions
* SystemVerilog Assertions (SVA) reference implementation

---

## Reference Model

An independent reference model calculates the expected FP32 classification.

For each test vector:

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
```

This provides an independent check of the DUT output.

---

## Randomized Testing

The testbench generates 10,000 random 32-bit FP32 patterns using:

```systemverilog
$urandom
```

Randomized testing supplements the directed corner-case tests and exercises a large number of FP32 input patterns.

---

## Functional Coverage

Version 1.3 introduced functional coverage.

Because Icarus Verilog does not support standard SystemVerilog `covergroup` functional coverage, coverage is implemented using manual counters.

Coverage is collected for:

* Zero
* Subnormal
* Normal
* Infinity
* NaN
* Positive sign
* Negative sign

The testbench automatically calculates the percentage of coverage bins that have been hit.

---

# v1.4 — Assertions

Version 1.4 adds assertion-based verification.

Two assertion testbenches are provided to demonstrate two different SystemVerilog assertion styles.

## 1. Immediate Assertions

File:

```text
tb/tb_fp32_classifier_assertion.sv
```

This testbench uses immediate assertions.

Example:

```systemverilog
if ((fp32[30:23] == 8'h00) &&
    (fp32[22:0]  == 23'h000000)) begin

    assert (class_type == CLASS_ZERO)
    else
        $error("Zero assertion failed");

end
```

The assertion is evaluated when execution reaches the `assert` statement.

Five FP32 classification rules are checked:

```text
Zero:
    exponent = 0
    fraction = 0
        ->
    CLASS_ZERO

Subnormal:
    exponent = 0
    fraction != 0
        ->
    CLASS_SUBNORMAL

Normal:
    exponent = 1..254
        ->
    CLASS_NORMAL

Infinity:
    exponent = 255
    fraction = 0
        ->
    CLASS_INFINITY

NaN:
    exponent = 255
    fraction != 0
        ->
    CLASS_NAN
```

This version is compatible with the current Icarus Verilog simulation environment.

---

## 2. SystemVerilog Assertions (SVA)

File:

```text
tb/tb_fp32_classifier_sva.sv
```

This version expresses the same FP32 classification rules using:

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


a_zero:
    assert property (p_zero)
    else
        $error("ASSERTION FAILED: Zero");
```

The `property` defines the design rule:

```text
Zero input condition
        |
        |  |->
        v
class_type must be CLASS_ZERO
```

The statement:

```systemverilog
assert property (p_zero);
```

instructs the simulator to check that property.

Unlike the immediate assertion version, the SVA properties monitor the relevant signals independently rather than being explicitly called from the `check_value()` task.

### Simulator Note

The current project uses Icarus Verilog.

Icarus Verilog supports the immediate assertion testbench used in this project, but support for full SystemVerilog concurrent assertions is limited.

Therefore:

```text
tb_fp32_classifier_assertion.sv
        |
        +--> Primary runnable assertion testbench
             with Icarus Verilog

tb_fp32_classifier_sva.sv
        |
        +--> SVA learning/reference implementation
             for simulators with full SVA support
```

---

## Assertion vs Reference Model

The reference model and assertions serve different verification purposes.

### Reference Model

Checks whether the DUT result matches an independently calculated expected result:

```text
DUT result == Reference Model result
```

### Assertions

Check whether specific design properties are always satisfied:

```text
Input condition
      |
      v
Required design behavior
```

Using both techniques provides complementary verification.

---

## Testbench Flow

For each test vector:

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
Wait #1 for combinational output
       |
       +----------------------+
       |                      |
       v                      v
Assertions             Reference Model
       |                      |
       v                      v
Check design             expected
properties                   |
       |                      |
       +----------+-----------+
                  |
                  v
       class_type === expected
                  |
                  v
             PASS / FAIL
```

---

## Project Structure

```text
fp32-classifier/
|
├── rtl/
|   └── fp32_classifier.sv
|
├── tb/
|   ├── tb_fp32_classifier.sv
|   ├── tb_fp32_classifier_coverage.sv
|   ├── tb_fp32_classifier_assertion.sv
|   └── tb_fp32_classifier_sva.sv
|
└── README.md
```

### Assertion Testbenches

```text
tb_fp32_classifier_assertion.sv
    Immediate Assertions
    Icarus-compatible

tb_fp32_classifier_sva.sv
    property + assert property
    SVA learning/reference version
```

---

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
* Added FP32 class coverage
* Added sign coverage
* Added automatic coverage statistics
* Maintained compatibility with Icarus Verilog

### v1.4 — Assertions

* Added immediate assertions for all five FP32 classifications
* Added assertion failure reporting using `$error`
* Added SVA `property` definitions
* Added `assert property`
* Introduced overlapped implication (`|->`)
* Added separate immediate-assertion and SVA testbenches
* Maintained an Icarus-compatible immediate assertion implementation

---

## Verification Roadmap

```text
v1.0  Directed Testing
  |
  v
v1.1  Reference Model
      + Self-Checking
  |
  v
v1.2  Randomized Testing
      + 10,000 Tests
  |
  v
v1.3  Functional Coverage
  |
  v
v1.4  Assertions
      |
      +-- Immediate Assertions
      |
      +-- SVA
          property
          assert property
          |->
```
