//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_circular
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_2_pipe_using_circular
    // that computes the result of the formula defined in the file formula_2_fn.svh.
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
    // 3. Your solution should use circular buffers instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    localparam isqrt_depth = 8;
    localparam width       = 32;
    localparam a_delay     = isqrt_depth + 1 + isqrt_depth;

    logic        sqrt_c_vld;
    logic [15:0] sqrt_c;

    logic        b_dly_vld;
    logic [31:0] b_dly;

    logic        b_plus_sqrt_c_vld;
    logic [31:0] b_plus_sqrt_c;

    logic        sqrt_b_plus_sqrt_c_vld;
    logic [15:0] sqrt_b_plus_sqrt_c;

    logic        a_dly_vld;
    logic [31:0] a_dly;

    logic        a_plus_sqrt_b_plus_sqrt_c_vld;
    logic [31:0] a_plus_sqrt_b_plus_sqrt_c;

    logic        sqrt_formula_vld;
    logic [15:0] sqrt_formula;

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_c
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .x_vld ( arg_vld    ),
        .x     ( c          ),
        .y_vld ( sqrt_c_vld ),
        .y     ( sqrt_c     )
    );

    circular_buffer_with_valid # (.width (width), .depth (isqrt_depth)) i_circular_b
    (
        .clk       ( clk       ),
        .rst       ( rst       ),
        .in_valid  ( arg_vld   ),
        .in_data   ( b         ),
        .out_valid ( b_dly_vld ),
        .out_data  ( b_dly     )
    );

    always_ff @ (posedge clk)
        if (rst)
            b_plus_sqrt_c_vld <= 1'b0;
        else
        begin
            b_plus_sqrt_c_vld <= sqrt_c_vld & b_dly_vld;

            if (sqrt_c_vld & b_dly_vld)
                b_plus_sqrt_c <= b_dly + 32' (sqrt_c);
        end

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_b_plus_sqrt_c
    (
        .clk   ( clk                ),
        .rst   ( rst                ),
        .x_vld ( b_plus_sqrt_c_vld  ),
        .x     ( b_plus_sqrt_c      ),
        .y_vld ( sqrt_b_plus_sqrt_c_vld ),
        .y     ( sqrt_b_plus_sqrt_c )
    );

    circular_buffer_with_valid # (.width (width), .depth (a_delay)) i_circular_a
    (
        .clk       ( clk        ),
        .rst       ( rst        ),
        .in_valid  ( arg_vld    ),
        .in_data   ( a          ),
        .out_valid ( a_dly_vld  ),
        .out_data  ( a_dly      )
    );

    always_ff @ (posedge clk)
        if (rst)
            a_plus_sqrt_b_plus_sqrt_c_vld <= 1'b0;
        else
        begin
            a_plus_sqrt_b_plus_sqrt_c_vld <= sqrt_b_plus_sqrt_c_vld & a_dly_vld;

            if (sqrt_b_plus_sqrt_c_vld & a_dly_vld)
                a_plus_sqrt_b_plus_sqrt_c <= a_dly + 32' (sqrt_b_plus_sqrt_c);
        end

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_formula
    (
        .clk   ( clk                          ),
        .rst   ( rst                          ),
        .x_vld ( a_plus_sqrt_b_plus_sqrt_c_vld ),
        .x     ( a_plus_sqrt_b_plus_sqrt_c   ),
        .y_vld ( sqrt_formula_vld            ),
        .y     ( sqrt_formula                )
    );

    assign res_vld = sqrt_formula_vld;
    assign res     = 32' (sqrt_formula);

endmodule
