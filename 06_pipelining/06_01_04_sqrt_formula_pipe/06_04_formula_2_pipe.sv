//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe (
    input clk,
    input rst,

    input        arg_vld,
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,

    output        res_vld,
    output [31:0] res
);

  // Task:
  //
  // Implement a pipelined module formula_2_pipe that computes the result
  // of the formula defined in the file formula_2_fn.svh.
  //
  // The requirements:
  //
  // 1. The module formula_2_pipe has to be pipelined.
  //
  // It should be able to accept a new set of arguments a, b and c
  // arriving at every clock cycle.
  //
  // It also should be able to produce a new result every clock cycle
  // with a fixed latency after accepting the arguments.
  //
  // 2. Your solution should instantiate exactly 3 instances
  // of a pipelined isqrt module, which computes the integer square root.
  //
  // 3. Your solution should save dynamic power by properly connecting
  // the valid bits.
  //
  // You can read the discussion of this problem
  // in the article by Yuri Panchul published in
  // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
  // You can download this issue from https://fpga-systems.ru/fsm#state_0
  localparam depth = 8;
  localparam width = 32;
  localparam a_delay = depth + 1 + depth;

  logic        isqrt_c_vld;
  logic [15:0] isqrt_c;

  logic        srwv_b_vld;
  logic [31:0] srwv_b;

  isqrt #(depth) isqrt_1 (
      .clk  (clk),
      .rst  (rst),
      .x_vld(arg_vld),
      .x    (c),
      .y_vld(isqrt_c_vld),
      .y    (isqrt_c)
  );

  shift_register_with_valid #(width, depth) srwv_1 (
      .clk     (clk),
      .rst     (rst),
      .in_vld  (arg_vld),
      .in_data (b),
      .out_vld (srwv_b_vld),
      .out_data(srwv_b)
  );

  logic [31:0] sqrt_c_plus_b;
  logic        sqrt_c_plus_b_vld;

  always_ff @( posedge clk ) begin
    if (rst) begin
      sqrt_c_plus_b_vld <= '0;
    end else begin
      sqrt_c_plus_b_vld <= isqrt_c_vld & srwv_b_vld;
      if (isqrt_c_vld & srwv_b_vld) begin
        sqrt_c_plus_b <= 32'(isqrt_c) + srwv_b;
      end 
    end
  end

  logic [15:0] isqrt_2_y;
  logic        isqrt_2_vld;

  isqrt #(depth) isqrt_2 (
      .clk  (clk),
      .rst  (rst),
      .x_vld(sqrt_c_plus_b_vld),
      .x    (sqrt_c_plus_b),
      .y_vld(isqrt_2_vld),
      .y    (isqrt_2_y)
  );

  ///

  logic        srwv_a_vld;
  logic [31:0] srwv_a;

  shift_register_with_valid #(width, a_delay) srwv_2 (
      .clk     (clk),
      .rst     (rst),
      .in_vld  (arg_vld),
      .in_data (a),
      .out_vld (srwv_a_vld),
      .out_data(srwv_a)
  );

  logic [31:0] sqrt_2_plus_a;
  logic        sqrt_2_plus_a_vld;
  logic        isqrt_3_vld;
  logic [15:0] isqrt_3_y;

  always_ff @( posedge clk ) begin
    if (rst) begin
      sqrt_2_plus_a_vld <= '0;
    end else begin
      sqrt_2_plus_a_vld <= isqrt_2_vld & srwv_a_vld;
      if (isqrt_2_vld & srwv_a_vld) begin
        sqrt_2_plus_a <= 32'(isqrt_2_y) + srwv_a;
      end 
    end
  end

  isqrt #(depth) isqrt_3 (
      .clk  (clk),
      .rst  (rst),
      .x_vld(sqrt_2_plus_a_vld),
      .x    (sqrt_2_plus_a),
      .y_vld(isqrt_3_vld),
      .y    (isqrt_3_y)
  );

  assign res_vld = isqrt_3_vld;
  assign res = 32'(isqrt_3_y);

endmodule
