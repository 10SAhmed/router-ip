# Router IP – High-Level Functional Specification<br>
### Version: v1.0<br>
#### Type: Word-Based Packet Router (Training IP)<br>

---

## 1. Overview<br>

The Router v1.0 is a word-based packet router designed for internal RTL and Verification training.

The design supports:

- Configurable input ports
- 1 output port
- Per-input FIFO buffering
- Fixed-priority arbitration
- Start-of-packet (SOP) indication
- Packet size defined in header
- Backpressure handling

This IP is intentionally designed to be scalable and versioned for future enhancements.

---

## 2. Architectural Overview
### 2.1 Top-Level Architecture

The router consists of:

- Four independent input interfaces
- Four per-input FIFOs (one per input)
- Central arbitration logic
- Single shared output interface

Each input port feeds its own FIFO.<br>
The arbiter selects one FIFO at a time and forwards its packet to the output.

---

## 3. Packet Format

Each packet is composed of 32-bit words.

### 3.1 Header Word Format
```
| DEST[2:0] | SIZE[5:0] | PAYLOAD[22:0] |
```
#### Field Definitions
| Field   | Width          | Description                                                     |
| ------- | -------------- | --------------------------------------------------------------- |
| DEST    |  3 bits        |  Destination field (Reserved in v1.0 – not functionally checked)|
| SIZE    |  6 bits        |  Number of payload words following the header                   |
| PAYLOAD | 23 bits &nbsp; | User-defined payload data                                       |

**Notes**

- SIZE defines the number of payload words after the header.
- Maximum payload size = 63 words.
- DEST field is reserved for future multi-output versions and is not interpreted in v1.0.

---

## 4. Interface Definition
### 4.1 Input Interface (Per Port)

Each of the four input ports includes:

| Signal        | Direction | Description                   |
| ------------- | --------- | ----------------------------- |
| clk           | Input     | System clock                  | 
| rst           | Input     | Active-high synchronous reset |
| in_valid      | Input     | Indicates valid input word    |
| in_data[31:0] | Input     | Input data word               |
| in_sop        | Input     | Indicates start of packet     |
| in_ready      | Output    | Router ready to accept data   |

##### Input Protocol Rules

- Packet begins when in_valid and in_sop are asserted together.
- First word must be the header.
- Following words are payload words.
- Total payload count must match SIZE field.
- Data transfer occurs when `in_valid && in_ready`.

### 4.2 Output Interface

| Signal         | Direction | Description               |
| -------------- | --------- | ------------------------- |
| out_valid      | Output    | Output data valid         |
| out_data[31:0] | Output    | Output data word          |
| out_sop        | Output    | Start-of-packet indicator |
| out_ready      | Input     | Downstream ready          |

#### Output Protocol Rules

- Data transfer occurs when `out_valid && out_ready`.
- Packets are transmitted in the same order as selected by the arbiter.
- No packet interleaving is allowed.

---

## 5. FIFO Architecture
### 5.1 FIFO Structure

- Each input port connects to a dedicated FIFO.
- FIFO depth: 8 entries (parameterizable).
- Data width: 32 bits.

### 5.2 FIFO Behavior

- FIFO asserts full when capacity reached.
- FIFO asserts empty when no data present.
- Input backpressure (`in_ready`) is de-asserted when FIFO is full.
- FIFO must store entire packet including header.

---

## 6. Arbitration Logic
### 6.1 Arbitration Policy

v1.0 implements **Fixed Priority Arbitration**.<br>
Priority order:
```
Port 0 > Port 1 > Port 2 > Port 3
```

### 6.2 Arbitration Rules

1. Arbiter selects the highest-priority FIFO that is non-empty.
2. Once a packet transmission starts from a selected FIFO:
    - The entire packet must be transmitted before switching.
    - No preemption is allowed.
3. Arbitration decision occurs only after packet completion.

---

## 7. Reset Behavior

When `rst = 1`:

- All FIFOs are cleared.
- Output signals are de-asserted.
- Internal state machines return to IDLE state.
- No partial packet shall remain.

---

## 8. Functional Limitations (v1.0)

The following are intentionally NOT implemented in v1.0:

- Destination-based routing
- Multiple output ports
- Error detection for SIZE mismatch
- Packet dropping mechanism
- Timeout handling
- Round-robin arbitration

These features are reserved for future versions.

---

## 9. Parameterization

The following parameters shall be configurable:
```
NUM_INPUTS     = 4
DATA_WIDTH     = 32
FIFO_DEPTH     = 8
PRIORITY_MODE  = FIXED
```

---

## 10. Assumptions

- Downstream block eventually asserts `out_ready`.
- `SIZE` field is assumed valid in v1.0 (no enforcement).
- Input packets are well-formed.

---

## 11. Prposed Version Roadmap (For Internal Use)
|Version | Planned Enhancement           |
| ------ | ----------------------------- |
| v1.0   | Fixed priority, single output |
| v2.0   | Round-robin arbitration       |
| v3.0   | Multi-output routing          |
| v4.0   | Error detection & packet drop |