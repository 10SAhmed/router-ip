# router-ip

This repo contains an N-input configurable router ip. This is created for UVM training purpose. For further information see the docs.

## Versions

The plan is to develop the design in 3-5 versions.

### V1

- `N` input ports.
- Single output port.
- Fixed arbitration (first come first bases).

### V2

All mentioned in **V1** except arbitration.

- Round-robin arbitration.

### V3

All mentioned in **V2** except output ports.

- Multiple output ports.

### V4 (Proposed)

All mentioned in **V3** and:

- Packet size checking.
- Multiple beats per cycle.

### V5 (Proposed)

All mentioned in **V4** and:

- Multi-clock functionality.