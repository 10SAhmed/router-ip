module router_top #(
  parameter NUM_INPUTS    = 2    ,
  parameter DATA_WIDTH    = 32   ,
  parameter FIFO_DEPTH    = 8    ,
  parameter PRIORITY_MODE = FIXED
) (
  //  General Signals
  input  logic                                  clk_i  , // Clock
  input  logic                                  rst_i  , // Synchronous reset active high
  // Ingress Interface
  input  logic [NUM_INPUTS-1:0]                 valid_i, // per port data validation signal
  input  logic [NUM_INPUTS-1:0][DATA_WIDTH-1:0] data_i , // per port data stream
  input  logic [NUM_INPUTS-1:0]                 start_i, // per port start of packet indicator
  output logic [NUM_INPUTS-1:0]                 ready_o, // per port DUT is ready signal
  // Egress Interface
  output logic [NUM_INPUTS-1:0]                 valid_o, // per port data validation signal
  output logic [NUM_INPUTS-1:0][DATA_WIDTH-1:0] data_o , // per port data stream
  output logic [NUM_INPUTS-1:0]                 sop_o  , // per port start of packet indicator
  input  logic                                  ready_i  // per port Slave is ready signal
);

  // interconnect
  bit [NUM_INPUTS-1:0] wen  ;
  bit [NUM_INPUTS-1:0] ren  ;
  bit [NUM_INPUTS-1:0] full ;
  bit [NUM_INPUTS-1:0] empty;
  bit [NUM_INPUTS-1:0] grant;

  assign wen = valid_i & ready_o;
  assign ren = {NUM_INPUTS{ready_i}} & grant;

  // per port FIFO
  genvar i;

  generate
    for (i = 0; i < NUM_INPUTS; i++) begin
      fifo_sc #(.D_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) fifo_inst (
        .clk_i  (clk_i    ),
        .rst_i  (rst_i    ),
        .data_i (data_i[i]),
        .wen_i  (wen[i]   ),
        .ren_i  (ren[i]   ),
        .full_o (full[i]  ),
        .empty_o(empty[i] ),
        .data_o (data_o[i])
      );
    end
  endgenerate

  arbiter #(.NUM_INPUTS(NUM_INPUTS), .PRIORITY_MODE(PRIORITY_MODE)) arbiter_inst (
    .fifo_empty(empty),
    .grant     (grant)
  );
endmodule : router_top