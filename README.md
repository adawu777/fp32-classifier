# FP32 Classifier — UVM Verification Environment

SystemVerilog UVM verification environment for an IEEE-754 FP32 classifier.

This version extends the previous self-checking verification environment into a structured UVM testbench.

> **Status:** UVM testbench structure completed.  
> Full UVM simulation is pending because the current Icarus Verilog environment does not provide the required UVM support.

---

## DUT Overview

The DUT classifies a 32-bit IEEE-754 single-precision floating-point value into one of five categories:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

FP32 format:

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

## UVM Verification Architecture

The verification environment uses the following UVM data flow:

```text
                 fp32_test
                     |
                     v
                fp32_sequence
                     |
                     v
                 Sequencer
                     |
                     v
                 fp32_driver
                     |
                     v
                  fp32_if
                     |
                     v
              fp32_classifier
                    DUT
                     |
                     v
                  fp32_if
                     |
                     v
                fp32_monitor
                     |
              analysis_port
                     |
                     v
              fp32_scoreboard
                     |
                     v
              Reference Model
                     |
                     v
               PASS / FAIL
```

---

## UVM Components

### Transaction

`fp32_transaction.sv`

Represents one FP32 verification transaction.

```systemverilog
rand logic [31:0] fp32;
logic [2:0] class_type;
```

`fp32` is randomized by the sequence.

`class_type` records the DUT output observed by the monitor.

---

### Sequence

`fp32_sequence.sv`

Generates randomized FP32 transactions using SystemVerilog constrained-random capabilities.

Main flow:

```text
create transaction
       |
       v
start_item()
       |
       v
randomize()
       |
       v
finish_item()
```

---

### Sequencer

The environment uses the standard parameterized UVM sequencer:

```systemverilog
uvm_sequencer #(fp32_transaction)
```

The sequencer transfers transactions from the sequence to the driver.

---

### Driver

`fp32_driver.sv`

Receives transactions from the sequencer and drives the DUT input through a virtual interface.

Main operation:

```systemverilog
seq_item_port.get_next_item(req);

vif.fp32 = req.fp32;

seq_item_port.item_done();
```

Data direction:

```text
Transaction
     |
     v
   Driver
     |
     v
Virtual Interface
     |
     v
    DUT
```

---

### Interface

`fp32_if.sv`

Contains the DUT input and output signals:

```systemverilog
logic [31:0] fp32;
logic [2:0]  class_type;
```

The real interface is instantiated in `tb_top.sv`.

The driver and monitor access it through a virtual interface obtained using `uvm_config_db`.

---

### Monitor

`fp32_monitor.sv`

Observes DUT input and output signals through the virtual interface.

The monitor creates an observed transaction containing:

```text
fp32
+
class_type
```

and sends it through:

```systemverilog
ap.write(tr);
```

to the scoreboard.

---

### Scoreboard

`fp32_scoreboard.sv`

Receives transactions from the monitor and calculates the expected classification using an independent reference model.

Verification flow:

```text
tr.fp32
    |
    v
Reference Model
    |
    v
 expected
    |
    +----------+
               |
               v
        Compare with
        tr.class_type
               |
        +------+------+
        |             |
       PASS          FAIL
```

The scoreboard also maintains pass/fail statistics.

---

### Agent

`fp32_agent.sv`

Groups the interface-level verification components:

```text
fp32_agent
|
+-- sequencer
|
+-- driver
|
+-- monitor
```

The agent connects:

```systemverilog
driver.seq_item_port.connect(
    sequencer.seq_item_export
);
```

---

### Environment

`fp32_env.sv`

Contains:

```text
fp32_env
|
+-- fp32_agent
|
+-- fp32_scoreboard
```

The environment connects the monitor analysis port to the scoreboard:

```systemverilog
agent.monitor.ap.connect(
    scoreboard.analysis_export
);
```

---

### Test

`fp32_test.sv`

Creates the UVM environment and starts the FP32 sequence.

```systemverilog
seq.start(env.agent.sequencer);
```

UVM objections are used to keep the run phase active while the sequence is executing.

---

### Top-Level Testbench

`tb_top.sv`

The top-level module:

1. Instantiates the FP32 interface
2. Instantiates the DUT
3. Connects the interface to the DUT
4. Places the virtual interface into `uvm_config_db`
5. Starts the UVM test

```systemverilog
run_test("fp32_test");
```

---

## UVM Component Hierarchy

```text
uvm_test_top
|
+-- fp32_test
     |
     +-- env
          |
          +-- agent
          |    |
          |    +-- sequencer
          |    +-- driver
          |    +-- monitor
          |
          +-- scoreboard
```

`fp32_sequence` and `fp32_transaction` are UVM objects and are therefore not part of the UVM component hierarchy.

---

## UVM Phase Flow

The environment follows the standard UVM phase structure:

```text
new()
  |
  v
build_phase()
  |
  v
connect_phase()
  |
  v
run_phase()
  |
  v
report_phase()
```

### Build Phase

Creates and configures the UVM components.

### Connect Phase

Connects:

```text
Sequencer --> Driver

Monitor --> Scoreboard
```

### Run Phase

Executes the sequence and performs DUT verification.

### Report Phase

Reports final verification statistics.

---

## Project Structure

```text
fp32-classifier/
|
+-- rtl/
|   |
|   +-- fp32_classifier.sv
|
+-- tb/
|   |
|   +-- fp32_if.sv
|   +-- fp32_pkg.sv
|   +-- fp32_transaction.sv
|   +-- fp32_sequence.sv
|   +-- fp32_driver.sv
|   +-- fp32_monitor.sv
|   +-- fp32_scoreboard.sv
|   +-- fp32_agent.sv
|   +-- fp32_env.sv
|   +-- fp32_test.sv
|   +-- tb_top.sv
|
+-- README.md
```

---

## Verification Data Flow

```text
Random FP32
    |
    v
Sequence
    |
    v
Transaction
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
Interface
    |
    v
Monitor
    |
    v
Observed Transaction
    |
    v
Scoreboard
    |
    +----> Reference Model
    |
    v
Expected vs Actual
    |
    v
PASS / FAIL
```

---

## Current Status

Completed:

- UVM transaction
- Random sequence
- Sequencer/driver communication
- Virtual interface
- Monitor
- Analysis port
- Reference-model-based scoreboard
- Agent
- Environment
- UVM test
- Top-level testbench
- UVM component hierarchy
- UVM phase structure

Pending:

- Compile with a full UVM-compatible simulator
- Run UVM regression
- Debug simulator-specific issues if required
- Add functional coverage to the UVM environment
- Add assertion integration
- Expand constrained-random test scenarios

---

## Verification Roadmap

# FP32 Classifier

IEEE-754 FP32 classifier implemented in SystemVerilog with a progressively developed verification environment.

## Overview

This project classifies a 32-bit IEEE-754 single-precision floating-point value into five categories:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

The project is developed incrementally, with each version introducing additional verification methodology.

---

## IEEE-754 FP32 Format

```text
31        30        23 22                    0
+----------+-----------+----------------------+
|   Sign   | Exponent  |       Fraction       |
+----------+-----------+----------------------+
   1 bit      8 bits           23 bits
```

Classification rules:

| Exponent | Fraction | Classification |
|---|---|---|
| 0x00 | 0 | Zero |
| 0x00 | non-zero | Subnormal |
| 0x01–0xFE | any | Normal |
| 0xFF | 0 | Infinity |
| 0xFF | non-zero | NaN |

---

# Version v1.6

## Constrained-Random Verification and Functional Coverage

Version v1.6 extends the UVM verification environment with constrained-random stimulus generation, functional coverage, coverage-oriented boundary testing, and improved transaction synchronization.

The goal of this version is to establish the infrastructure required for coverage-driven verification and future coverage closure.

---

## Verification Architecture

```text
                    fp32_test
                        |
                        v
                 fp32_sequence
                        |
                        v
                    Sequencer
                        |
                        v
                     Driver
                        |
                        v
                  fp32_interface
                        |
                        v
                       DUT
                        |
                        v
                     Monitor
                        |
                 analysis_port
                    /       \
                   /         \
                  v           v
            Scoreboard     Coverage
```

The monitor broadcasts each observed transaction to both the scoreboard and the functional coverage collector.

---

## Constrained-Random Stimulus

The transaction contains:

```systemverilog
rand logic [31:0] fp32;
rand bit   [2:0]  class_sel;
```

`class_sel` controls the FP32 category generated by the constraint solver.

The five FP32 classes are generated using weighted distribution constraints:

```systemverilog
class_sel dist {
    CLASS_ZERO      := 20,
    CLASS_SUBNORMAL := 20,
    CLASS_NORMAL    := 20,
    CLASS_INFINITY  := 20,
    CLASS_NAN       := 20
};
```

Class-specific constraints generate valid IEEE-754 bit patterns for:

- Zero
- Subnormal
- Normal
- Infinity
- NaN

The main sequence generates:

```text
10,000 constrained-random transactions
```

---

## Targeted Boundary Sequence

A dedicated boundary sequence is included for coverage-oriented testing.

It explicitly targets important Normal-number exponent boundaries:

```text
Minimum normal exponent : 0x01
Maximum normal exponent : 0xFE
```

Inline constraints are used to generate these targeted transactions.

This provides the infrastructure for supplementing constrained-random testing with directed coverage closure tests.

---

## Functional Coverage

A UVM subscriber-based coverage collector is implemented:

```text
fp32_coverage
    extends
uvm_subscriber #(fp32_transaction)
```

The coverage model includes:

### FP32 Class Coverage

- Zero
- Subnormal
- Normal
- Infinity
- NaN

### Sign Coverage

- Positive
- Negative

### Exponent Coverage

- Zero exponent
- Minimum normal exponent
- Middle normal exponent range
- Maximum normal exponent
- Special exponent (0xFF)

### Fraction Coverage

- Zero fraction
- Non-zero fraction

### Cross Coverage

```text
FP32 Class × Sign
```

This checks positive and negative variants across the FP32 classification space.

---

## Coverage-Directed Verification

The verification flow is designed around:

```text
Constrained Random Testing
          |
          v
Functional Coverage
          |
          v
Identify Coverage Holes
          |
          v
Targeted Boundary Tests
          |
          v
Coverage Closure
```

The targeted boundary sequence provides a mechanism for filling coverage holes that may remain after constrained-random testing.

---

## Driver / Monitor Synchronization

Because the FP32 classifier is combinational and does not use a clock or valid signal, a testbench-only SystemVerilog event is used to synchronize the driver and monitor.

```systemverilog
event sample_event;
```

The driver triggers the event after the DUT output has been allowed to settle:

```systemverilog
vif.fp32 = req.fp32;

#1;

-> vif.sample_event;
```

The monitor waits for the event:

```systemverilog
@(vif.sample_event);
```

This creates one monitor sample for each driven transaction and prevents uncontrolled periodic sampling.

---

## Self-Checking Scoreboard

The scoreboard contains an independent FP32 reference model.

For every monitored transaction:

```text
FP32 Input
    |
    v
Reference Model
    |
    v
Expected Class
    |
    +------ compare ------ DUT class_type
```

The scoreboard tracks:

```text
Total Tests
Passed Tests
Failed Tests
```

Any mismatch is reported using `uvm_error`.

---

## Project Structure

```text
rtl/
    fp32_classifier.sv

tb/
    fp32_if.sv
    fp32_transaction.sv
    fp32_sequence.sv
    fp32_boundary_sequence.sv
    fp32_driver.sv
    fp32_monitor.sv
    fp32_scoreboard.sv
    fp32_coverage.sv
    fp32_agent.sv
    fp32_env.sv
    fp32_test.sv
    fp32_pkg.sv
    tb_top.sv
```

---

## Simulation Status

The v1.6 UVM verification environment has been implemented at the source-code level.

At the time of this release, the complete v1.6 environment has **not yet been executed with a full UVM-capable simulator**.

Therefore:

- Compilation with a full UVM simulator is still pending.
- Runtime test results are not claimed for this release.
- Functional coverage results are not yet claimed.
- 100% functional coverage is **not claimed**.
- Coverage closure remains to be demonstrated by simulation.

A future simulator-backed revision will compile and execute the environment, analyze coverage holes, and add additional targeted tests where required.

---

## Version History

| Version | Verification Feature |
|---|---|
| v1.0 | RTL + Directed Testing |
| v1.1 | Reference Model / Self-Checking |
| v1.2 | Randomized Testing |
| v1.3 | Functional Coverage |
| v1.4 | Assertion-Based Verification |
| v1.5 | UVM Verification Environment |
| **v1.6** | **Constrained-Random UVM + Functional Coverage + Coverage-Directed Testing** |

---

## Next Step

The next development stage will focus on simulator-backed coverage closure:

```text
Compile
   ↓
Run UVM Regression
   ↓
Analyze Coverage Report
   ↓
Identify Coverage Holes
   ↓
Add Targeted Constraints / Sequences
   ↓
Re-run
   ↓
Coverage Closure
```