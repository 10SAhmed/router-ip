module router_top #(
  parameter NUM_INPUTS    = 2    ,
  parameter DATA_WIDTH    = 32   ,
  parameter FIFO_DEPTH    = 8    ,
  parameter PRIORITY_MODE = FIXED
) (
  //  General Signals
  input  logic                  clk_i              , // Clock
  input  logic                  rst_i              , // Synchronous reset active high
  // Ingress Interface
  input  logic                  valid_i[NUM_INPUTS], // per port data validation signal
  input  logic [DATA_WIDTH-1:0] data_i [NUM_INPUTS], // per port data stream
  input  logic                  start_i[NUM_INPUTS], // per port start of packet indicator
  output logic                  ready_o[NUM_INPUTS], // per port DUT is ready signal
  // Egress Interface
  output logic                  valid_o[NUM_INPUTS], // per port data validation signal
  output logic [DATA_WIDTH-1:0] data_o [NUM_INPUTS], // per port data stream
  output logic                  sop_o  [NUM_INPUTS], // per port start of packet indicator
  input  logic                  ready_i[NUM_INPUTS]  // per port Slave is ready signal
);

  // interconnect
  bit full, empty;
  bit wen, ren;

  // per port FIFO
  genvar i;

  generate
    for (i = 0; i < NUM_INPUTS; i++) begin
      fifo_sc #(.D_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) fifo_inst (
        .clk_i  (clk_i    ),
        .rst_i  (rst_i    ),
        .data_i (data_i[i]),
        .wen_i  (wen      ),
        .ren_i  (ren      ),
        .full_o (full     ),
        .empty_o(empty    ),
        .data_o (data_o[i])
      );
    end
  endgenerate

endmodule : router_top