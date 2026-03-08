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

Each packet is composed of 8-bit words (beats). The fisrt word constains the packet header. Rest of the words contain data payload. 

<pre>
| PACKET HEADER | DATA BEAT 0 | DATA BEAT 1 | DATA BEAT 2 | ... | DATA BEAT <b>SIZE</b> | 
</pre>

### 3.2 Header Word Format
```
| DA[1:0] | SIZE[7:2] |
```

#### Field Definitions
| Field   | Width          | Description                                                      |
| ------- | -------------- | ---------------------------------------------------------------- |
| DA      |  2 bits        | Destination Address (Reserved in v1.0 – not functionally checked)|
| SIZE    |  6 bits        | Number of payload words following the header                     |

**Notes**

- `SIZE` defines the number of payload words after the header.
- Maximum payload size = 63 words.
- `DA` field is reserved for future multi-output versions and is not interpreted in v1.0.

---

## 4. Interface Definition
### 4.1 Input Interface (Per Port)

Each of the four input ports includes:

| Signal      | Direction | Description                   |
| ----------- | --------- | ----------------------------- |
| clk_i       | Input     | System clock                  | 
| rst_i       | Input     | Active-high synchronous reset |
| valid_i     | Input     | Indicates valid input word    |
| data_i[7:0] | Input     | Input data word               |
| start_i     | Input     | Indicates start of packet     |
| ready_o     | Output    | Router ready to accept data   |

##### Input Protocol Rules

- Packet begins when `valid_i` and `start_i` are asserted together.
- First word must be the header.
- Following words are payload words.
- Total payload count must match SIZE field.
- Data transfer occurs when `valid_i && ready_o`.

### 4.2 Output Interface

| Signal        | Direction | Description               |
| ------------- | --------- | ------------------------- |
| valid_o       | Output    | Output data valid         |
| data_o[7:0]   | Output    | Output data word          |
| sop_o         | Output    | Start-of-packet indicator |
| ready_i       | Input     | Downstream ready          |

#### Output Protocol Rules

- Data transfer occurs when `valid_o && ready_i`.
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
- Input backpressure (`ready_o`) is de-asserted when FIFO is full.
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

When `rst_i = 1`:

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
FIFO_DEPTH     = 8
```
Though following parameters exist but may not work for v1.0. It is recommended to not change them
```
DATA_WIDTH     = 8
PRIORITY_MODE  = FIXED
```

---

## 10. Assumptions

- Downstream block eventually asserts `ready_i`.
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