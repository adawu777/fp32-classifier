# verification_plan.md

# FP32 Classifier Verification Plan

## 1. Purpose

This document defines the verification intent for the FP32 Classifier project.

The goal is to verify that the DUT correctly classifies every IEEE-754 FP32 input into one of five categories:

* Zero
* Subnormal
* Normal
* Infinity
* NaN

Version v1.8 extends the existing verification environment with an AI-assisted verification workflow focused on verification-gap analysis, targeted stimulus, coverage closure, and traceability.

This document is the primary source of verification intent for the AI verification agent.

---

# 2. DUT Specification

Input:

```systemverilog
logic [31:0] fp32;
```

Output:

```systemverilog
logic [2:0] class_type;
```

FP32 format:

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
    1 bit      8 bits          23 bits
```

Classification is determined by:

```text
Exponent = fp32[30:23]
Fraction = fp32[22:0]
```

The sign bit:

```text
fp32[31]
```

does not change the classification result.

---

# 3. Classification Requirements

## REQ-001 — Zero Classification

Condition:

```text
Exponent == 0x00
Fraction == 0
```

Expected result:

```text
ZERO
```

Required stimulus includes:

```text
+Zero = 0x00000000
-Zero = 0x80000000
```

Verification methods:

```text
Stimulus:
    directed boundary sequence
    constrained-random sequence

Checker:
    scoreboard reference model

Coverage:
    class ZERO
    sign positive
    sign negative
    ZERO × sign cross
```

---

## REQ-002 — Subnormal Classification

Condition:

```text
Exponent == 0x00
Fraction != 0
```

Expected result:

```text
SUBNORMAL
```

Required boundary stimulus:

```text
0x00000001
0x007FFFFF
0x80000001
0x807FFFFF
```

Important verification intent:

* minimum positive subnormal
* maximum positive subnormal
* minimum-magnitude negative subnormal
* maximum-magnitude negative subnormal
* intermediate subnormal fraction values

Verification methods:

```text
Stimulus:
    constrained-random subnormal generation
    boundary sequence

Checker:
    scoreboard reference model

Coverage:
    SUBNORMAL class
    both sign values
    fraction regions
    SUBNORMAL × sign
```

---

## REQ-003 — Normal Classification

Condition:

```text
0x01 <= Exponent <= 0xFE
```

Expected result:

```text
NORMAL
```

Fraction may contain any value.

Important boundary stimulus:

```text
0x00800000
0x7F7FFFFF
0x80800000
0xFF7FFFFF
```

Additional verification should exercise:

```text
minimum normal exponent
low exponent region
middle exponent region
high exponent region
maximum normal exponent
fraction == 0
fraction != 0
both signs
```

Verification methods:

```text
Stimulus:
    constrained-random normal generation
    boundary sequence

Checker:
    scoreboard reference model

Coverage:
    NORMAL class
    exponent regions
    fraction regions
    both signs
```

---

## REQ-004 — Infinity Classification

Condition:

```text
Exponent == 0xFF
Fraction == 0
```

Expected result:

```text
INFINITY
```

Required stimulus:

```text
+Infinity = 0x7F800000
-Infinity = 0xFF800000
```

Verification methods:

```text
Stimulus:
    directed boundary sequence
    constrained-random infinity generation

Checker:
    scoreboard reference model

Coverage:
    INFINITY class
    both signs
    INFINITY × sign
```

---

## REQ-005 — NaN Classification

Condition:

```text
Exponent == 0xFF
Fraction != 0
```

Expected result:

```text
NAN
```

Required stimulus includes representative positive and negative NaNs.

Examples:

```text
0x7FC00000
0xFFC00000
```

Additional NaN patterns should exercise:

```text
small non-zero fraction
large non-zero fraction
different fraction bit patterns
positive sign
negative sign
```

The classifier is only required to distinguish NaN from Infinity.

Unless the DUT specification explicitly distinguishes them, the verification environment must not require separate classification outputs for:

```text
quiet NaN
signaling NaN
```

However, those patterns may still be used as stimulus diversity.

Verification methods:

```text
Stimulus:
    constrained-random NaN generation
    targeted NaN sequence if required

Checker:
    scoreboard reference model

Coverage:
    NAN class
    both signs
    fraction regions
    NAN × sign
```

---

# 4. Reference Model

The scoreboard reference model shall determine expected classification directly from the FP32 exponent and fraction fields.

Pseudo-code:

```text
if exponent == 0:
    if fraction == 0:
        expected = ZERO
    else:
        expected = SUBNORMAL

else if exponent == 255:
    if fraction == 0:
        expected = INFINITY
    else:
        expected = NAN

else:
    expected = NORMAL
```

The reference model shall not use DUT output to determine the expected value.

Reference-model correctness is a critical part of verification.

---

# 5. Stimulus Plan

The verification environment shall use a combination of:

```text
constrained-random stimulus
+
directed boundary stimulus
+
targeted coverage-closure stimulus
```

These three stimulus types serve different purposes.

## 5.1 Constrained-Random Stimulus

Purpose:

```text
broad exploration of FP32 encoding space
```

Class generation should intentionally balance the five FP32 classes.

Pure uniform randomization of all 32 bits is insufficient because NORMAL encodings dominate the FP32 space.

Target classes:

```text
ZERO
SUBNORMAL
NORMAL
INFINITY
NAN
```

Each class should be generated with meaningful probability.

---

## 5.2 Boundary Stimulus

Purpose:

```text
guarantee important exact values
```

Required boundary patterns:

```text
0x00000000
0x80000000

0x00000001
0x007FFFFF
0x80000001
0x807FFFFF

0x00800000
0x7F7FFFFF
0x80800000
0xFF7FFFFF

0x7F800000
0xFF800000

0x7FC00000
0xFFC00000
```

---

## 5.3 Targeted Coverage-Closure Stimulus

Purpose:

```text
exercise meaningful uncovered bins identified after regression
```

Targeted sequences must only be added after a real verification gap or coverage hole is identified.

The AI agent should not generate targeted tests arbitrarily.

For every new targeted sequence, document:

```text
Coverage hole:
Why existing random stimulus missed it:
Targeted values or constraints:
Expected coverage bins:
```

---

# 6. Functional Coverage Plan

Functional coverage shall measure actual DUT-interface transactions observed by the monitor.

Coverage must not rely only on sequence-generator intent.

---

## COV-001 — Class Coverage

Required bins:

```text
ZERO
SUBNORMAL
NORMAL
INFINITY
NAN
```

Closure criterion:

```text
All five bins hit.
```

---

## COV-002 — Sign Coverage

Required bins:

```text
positive
negative
```

Closure criterion:

```text
Both bins hit.
```

---

## COV-003 — Class × Sign Cross

Required combinations:

```text
ZERO × positive
ZERO × negative

SUBNORMAL × positive
SUBNORMAL × negative

NORMAL × positive
NORMAL × negative

INFINITY × positive
INFINITY × negative

NAN × positive
NAN × negative
```

Closure criterion:

```text
All meaningful combinations hit.
```

All ten combinations are reachable for this DUT.

---

# 7. Exponent Coverage

Exponent coverage should represent meaningful regions instead of 256 individual exponent bins.

Recommended regions:

```text
exp_zero          = 0x00

exp_min_normal    = 0x01

exp_low           = 0x02 : 0x3F

exp_mid           = 0x40 : 0xBF

exp_high          = 0xC0 : 0xFD

exp_max_normal    = 0xFE

exp_special       = 0xFF
```

These regions verify transitions around important FP32 boundaries.

Important transitions include:

```text
0x00 → 0x01

0xFE → 0xFF
```

---

# 8. Fraction Coverage

Fraction coverage should distinguish important fraction patterns.

Recommended bins:

```text
frac_zero
frac_min
frac_low
frac_mid
frac_high
frac_max
```

Special attention should be given to:

```text
0x000000
0x000001
0x7FFFFF
```

These values participate directly in classification boundaries.

---

# 9. Boundary Coverage

Boundary coverage should explicitly track important FP32 encodings.

Recommended bins include:

```text
positive_zero
negative_zero

min_positive_subnormal
max_positive_subnormal
min_negative_subnormal
max_negative_subnormal

min_positive_normal
max_positive_normal
min_negative_normal
max_negative_normal

positive_infinity
negative_infinity

representative_positive_nan
representative_negative_nan
```

Boundary coverage is important because some exact patterns have extremely low probability under random generation.

---

# 10. Assertions Plan

Where simulator support exists, assertions should verify the classification rules independently.

Suggested properties:

```text
A_ZERO

A_SUBNORMAL

A_NORMAL

A_INFINITY

A_NAN
```

Example intent:

```text
Exponent == 0 and Fraction == 0
→ class_type == ZERO
```

Assertions provide immediate local checking and complement the scoreboard.

---

# 11. Scoreboard Plan

The scoreboard shall:

```text
receive transactions from the monitor

calculate expected class

compare expected class with observed DUT class_type

count total transactions

count passed transactions

count failed transactions

report mismatches
```

For a mismatch, the report should include at minimum:

```text
FP32 input
sign
exponent
fraction
expected class
actual class
```

This information should make failures easy to debug.

---

# 12. Monitor Plan

The monitor shall capture actual interface activity.

Observed transaction fields should include:

```text
fp32
class_type
```

The monitor shall publish transactions through an analysis port.

Recommended data flow:

```text
Monitor
   |
   +------> Scoreboard
   |
   +------> Coverage
```

Synchronization must ensure that DUT output is stable before the monitor samples it.

---

# 13. Regression Plan

Regression should execute the main constrained-random test across multiple seeds.

Each run should identify:

```text
test name
seed
PASS / FAIL
error count
```

Where simulator support exists, coverage should be collected and merged across runs.

Example conceptual regression:

```text
seed 1
seed 2
seed 3
seed 4
seed 5
...
```

The exact number of seeds should be chosen based on simulator availability and runtime.

A failed seed must be reproducible.

---

# 14. Verification Gap Analysis Plan

The AI agent shall inspect the existing environment and classify findings as:

```text
Already implemented

Partially implemented

Missing

Potential defect

Cannot verify without simulation
```

Potential areas for gap analysis:

```text
class coverage

class × sign cross coverage

boundary coverage

exponent-region coverage

fraction coverage

NaN diversity

subnormal diversity

normal exponent diversity

constraint correctness

monitor sampling synchronization

reference-model independence

scoreboard diagnostics

regression seed handling

assertion completeness

coverage closure mechanism
```

---

# 15. Coverage Hole Workflow

When an uncovered bin is discovered:

```text
Step 1
Confirm that the coverage requirement is valid.

Step 2
Confirm that the bin is reachable.

Step 3
Inspect stimulus constraints.

Step 4
Inspect monitor sampling.

Step 5
Inspect covergroup definition.

Step 6
Determine root cause.

Step 7
Apply the smallest meaningful fix.

Step 8
Rerun verification.

Step 9
Document whether the hole is closed.
```

Possible root causes:

```text
insufficient random probability

incorrect constraint

missing targeted stimulus

incorrect monitor timing

incorrect coverpoint definition

invalid cross

unreachable condition
```

---

# 16. Verification Traceability Matrix

| Requirement       | Stimulus                   | Checker                | Coverage                    |
| ----------------- | -------------------------- | ---------------------- | --------------------------- |
| REQ-001 Zero      | random + boundary          | scoreboard + assertion | class + sign + boundary     |
| REQ-002 Subnormal | random + boundary          | scoreboard + assertion | class + sign + fraction     |
| REQ-003 Normal    | random + boundary          | scoreboard + assertion | class + exponent + fraction |
| REQ-004 Infinity  | random + boundary          | scoreboard + assertion | class + sign + boundary     |
| REQ-005 NaN       | random + targeted patterns | scoreboard + assertion | class + sign + fraction     |

This matrix should be updated when new verification requirements are added.

---

# 17. AI-Assisted Verification Tasks

The AI verification agent may assist with:

```text
repository inspection

verification-plan analysis

verification-gap detection

constraint review

coverage review

assertion review

boundary-test review

targeted sequence generation

regression script review

code consistency review

verification documentation
```

The AI must explain the engineering reason for proposed changes.

AI-generated code is not considered verified merely because it is syntactically plausible.

---

# 18. Human Review Responsibilities

The human verification engineer remains responsible for:

```text
interpreting the specification

accepting verification requirements

reviewing AI-generated changes

evaluating coverage relevance

deciding whether a coverage hole is meaningful

reviewing regression failures

verification sign-off
```

The AI is an engineering assistant, not the final sign-off authority.

---

# 19. Simulation Status Rules

The project must distinguish between:

```text
source code prepared

source code reviewed

source code compiled

simulation executed

regression executed

coverage measured

coverage closed
```

These states must never be treated as equivalent.

No simulation result may be claimed without actual simulator output.

No coverage percentage may be claimed without an actual coverage report.

---

# 20. v1.8 Closure Criteria

The AI-assisted v1.8 workflow is structurally complete when:

```text
[ ] AGENTS.md exists.

[ ] verification_plan.md exists.

[ ] Existing v1.7 verification code has been inspected.

[ ] Verification gaps have been documented.

[ ] Important requirements are traceable to stimulus, checking, and coverage.

[ ] Boundary cases are represented.

[ ] Functional coverage intent is documented.

[ ] Coverage-hole workflow is defined.

[ ] Regression strategy is defined.

[ ] AI-generated changes are reviewed.

[ ] Simulator limitations are documented.

[ ] verification_report.md documents the v1.8 AI-assisted workflow.
```

Actual verification closure additionally requires:

```text
[ ] Simulation executed with a compatible simulator.

[ ] No unresolved functional failures.

[ ] Required assertions pass.

[ ] Required coverage goals are measured.

[ ] Meaningful coverage holes are closed or justified.

[ ] Regression results are reproducible.
```

If these conditions have not been executed and demonstrated, the project must not claim full verification sign-off.
