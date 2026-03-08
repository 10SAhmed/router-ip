module router_top #(
  parameter NUM_INPUTS    = 2    ,
  parameter DATA_WIDTH    = 8    ,
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
  output logic [NUM_INPUTS-1:0]                 ready_o, // p'd0ort DUT is ready signal
  // Egress Interface
  output logic                                  valid_o, // data validation signal
  output logic [DATA_WIDTH-1:0]                 data_o , // data stream
  output logic                                  start_o, // start of packet indicator
  input  logic                                  ready_i  // Slave is ready signal
);

  // interconnect
  bit [NUM_INPUTS-1:0] wen  ;
  bit [NUM_INPUTS-1:0] ren  ;
  bit [NUM_INPUTS-1:0] full ;
  bit [NUM_INPUTS-1:0] empty;
  bit [NUM_INPUTS-1:0] grant;

  bit get_access;

  logic [NUM_INPUTS-1:0] active_fifo;
  logic [           1:0] dest       ;
  logic [           5:0] size       ;
  logic [           5:0] size_next  ;
  logic [NUM_INPUTS-1:0] empty_mask ;

  logic [NUM_INPUTS-1:0]                 selected_start_o;
  logic [NUM_INPUTS-1:0][DATA_WIDTH-1:0] selected_data_o ;

  // FSM States
  typedef enum logic [0:0] {
    IDLE,
    SEND
  } state_t;

  // FSM variables
  state_t state, next_state;

  // FIFO logic
  assign wen = valid_i & ready_o;
  assign ren = {NUM_INPUTS{valid_o && ready_i}} & active_fifo;

  // per port FIFO
  genvar i;

  generate
    for (i = 0; i < NUM_INPUTS; i++) begin
      fifo_sc #(.D_WIDTH(DATA_WIDTH+1), .DEPTH(FIFO_DEPTH)) fifo_inst (
        .clk_i  (clk_i                                    ),
        .rst_i  (rst_i                                    ),
        .data_i ({data_i[i], start_i[i]}                  ),
        .wen_i  (wen[i]                                   ),
        .ren_i  (ren[i]                                   ),
        .full_o (full[i]                                  ),
        .empty_o(empty[i]                                 ),
        .data_o ({selected_data_o[i], selected_start_o[i]})
      );
    end
  endgenerate

  // Arbiter logic
  assign empty_mask = empty | ~{NUM_INPUTS{get_access}};

  arbiter #(.NUM_INPUTS(NUM_INPUTS), .PRIORITY_MODE(PRIORITY_MODE)) arbiter_inst (
    .fifo_empty(empty_mask),
    .grant     (grant     )
  );

  always_comb begin
    data_o  = '0;
    start_o = 1'b0;
    valid_o = 1'b0;
    ready_o = ~full;
    for (int i = 0; i < NUM_INPUTS; i++) begin
      if (active_fifo[i]) begin
        data_o  = selected_data_o[i];
        start_o = selected_start_o[i];
        valid_o = ~empty[i];
      end
    end
  end

  // Reading header
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      dest <= 'd0;
      size <= 'd0;
    end else if (state == SEND) begin
      if (start_o && valid_o && ready_i) begin  // checking MSB of rdata for start bit
        dest <= data_o[1:0];
        size <= data_o[7:2];
      end else begin
        size <= size_next;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      active_fifo <= 0;
    end else if (state == IDLE && next_state == SEND) begin  // if grant accessed then latched the fifo
      active_fifo <= grant;
    end
  end

  // FSM Implementation
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end


  always_comb begin
    next_state = state;
    size_next  = size;
    get_access = 1'b0;

    case (state)
      IDLE : begin
        get_access = 1'b1;
        if (grant != 'd0) next_state = SEND;
      end
      SEND : begin
        get_access = 1'b0;
        if (size == 6'h01 && valid_o && ready_i) begin
          next_state = IDLE;
          size_next  = size - 1'b1;  // if only 1 byte, then decrement counter and update state
        end else if (size > 6'h00 && valid_o && ready_i) begin
          size_next = size - 1'b1;
        end
      end

      default : next_state = state;
    endcase
  end

endmodule : router_top