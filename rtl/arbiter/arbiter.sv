module arbiter #(
  parameter NUM_INPUTS    = 2    ,
  parameter PRIORITY_MODE = FIXED
) (
  input  logic [NUM_INPUTS-1:0] fifo_empty,
  output logic [NUM_INPUTS-1:0] grant
);

  always_comb begin : proc_arbiter
    grant[0] = !fifo_empty[0];
    for (int i = 1; i < NUM_INPUTS; i++) begin
      grant[i] = !fifo_empty[i] & (&fifo_empty[i-1:0]);
    end
  end

endmodule : arbiter