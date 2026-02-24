module fifo_sc_tb ();
  parameter           D_WIDTH  = 32;
  logic               clk          ;
  logic               rst          ;
  logic [D_WIDTH-1:0] data_in      ;
  logic               wen          ;
  logic               ren          ;
  logic               full         ;
  logic               empty        ;
  logic [D_WIDTH-1:0] data_out     ;

  initial begin
    clk <= 1'b0;
    forever #5 clk <= ~clk;
  end

  fifo_sc #(.D_WIDTH(D_WIDTH), .DEPTH(8)) fifo_dut (
    .clk_i  (clk     ),
    .rst_i  (rst     ),
    .data_i (data_in ),
    .wen_i  (wen     ),
    .ren_i  (ren     ),
    .full_o (full    ),
    .empty_o(empty   ),
    .data_o (data_out)
  );

  initial begin
    rst <= 1'b1;
    data_in <= 'd0;
    wen <= 1'b0;
    ren <= 1'b0;
    repeat (5) @(posedge clk);
    rst <= 1'b0;
    $display("Start writing till full %0t", $time());
    while (!full) begin
      wen <= 1'b1;
      data_in <= $urandom_range(0,D_WIDTH**2-1);
      @(posedge clk);
    end

    $display("Start reading till empty %0t", $time());
    while (!empty) begin
      wen <= 1'b0;
      ren <= 1'b1;
      @(posedge clk);
    end

    $display("Doing nothing %0t", $time());
      wen <= 1'b0;
      ren <= 1'b0;
    repeat (10) @(posedge clk);

    $display("Start read write at the same time %0t", $time());
    repeat (100) begin
      wen <= 1'b1;
      data_in <= $urandom_range(0,D_WIDTH**2-1);
      ren <= 1'b1;
      @(posedge clk);
    end
    $stop;
  end

endmodule : fifo_sc_tb