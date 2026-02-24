module fifo_sc #(
  parameter D_WIDTH = 32,
  parameter DEPTH   = 8
) (
  input  logic               clk_i  , // Clock
  input  logic               rst_i  , // Synchronous reset active high
  input  logic [D_WIDTH-1:0] data_i , // input data stream
  input  logic               wen_i  , // write enable
  input  logic               ren_i  , // read enable
  output logic [D_WIDTH-1:0] data_o , // output data stream
  output logic               full_o , // fifo full flag
  output logic               empty_o  // fifo empty flag
);

  localparam PRT_WIDTH = $clog2(DEPTH);

  bit [  D_WIDTH-1:0] mem  [DEPTH]; // fifo memory
  bit [PRT_WIDTH-1:0] cntr        ; // element counter
  bit [  PRT_WIDTH:0] r_ptr       ; // read pointer
  bit [  PRT_WIDTH:0] w_ptr       ; // write pointer

  // generating full flag if not reset and w_ptr reaches max limit
  assign full_o = (w_ptr[PRT_WIDTH] != r_ptr[PRT_WIDTH]) && (w_ptr[PRT_WIDTH-1:0] == r_ptr[PRT_WIDTH-1:0]);

  // generating empty flag if reset or both pointer match up
  assign empty_o = w_ptr == r_ptr;

  // increment read and write ptrs if not reset and respective enable signal is present

  always_ff @(posedge clk_i) begin
    if (rst_i)
      w_ptr <= 1'b0;
    else if (wen_i && !full_o)
      w_ptr <= w_ptr + 1'b1;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i)
      r_ptr <= 1'b0;
    else if (ren_i && !empty_o)
      r_ptr <= r_ptr + 1'b1;
  end

  // write in memory at wptr position when no reset and write enable is present
  always_ff @(posedge clk_i) begin : proc_mem
    if (wen_i && !full_o)
      mem[w_ptr[PRT_WIDTH-1:0]] <= data_i;
  end

  // read from memory at rptr position when no reset and read enable is present
  always_ff @(posedge clk_i) begin : proc_data_o
    if (ren_i && !empty_o)
      data_o <= mem[r_ptr[PRT_WIDTH-1:0]];
  end

endmodule : fifo_sc