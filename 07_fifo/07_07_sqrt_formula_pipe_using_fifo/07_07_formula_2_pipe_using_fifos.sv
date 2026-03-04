//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    localparam isqrt_depth = 8;
    localparam width       = 32;
    localparam a_depth     = isqrt_depth + 1 + isqrt_depth;

    //------------------------------------------------------------------------
    // isqrt(c)

    logic        sqrt_c_vld;
    logic [15:0] sqrt_c;

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_c
    (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .x_vld ( arg_vld    ),
        .x     ( c          ),
        .y_vld ( sqrt_c_vld ),
        .y     ( sqrt_c     )
    );

    //------------------------------------------------------------------------
    // FIFO for b to align with isqrt(c)

    logic        fifo_b_push;
    logic        fifo_b_pop;
    logic [31:0] fifo_b_read_data;
    logic        fifo_b_empty;
    logic        fifo_b_full;

    assign fifo_b_pop  = sqrt_c_vld & ~ fifo_b_empty;
    assign fifo_b_push = arg_vld & (~ fifo_b_full | fifo_b_pop);

    flip_flop_fifo_with_counter
    # (
        .width (width),
        .depth (isqrt_depth)
    )
    i_fifo_b
    (
        .clk        ( clk             ),
        .rst        ( rst             ),
        .push       ( fifo_b_push     ),
        .pop        ( fifo_b_pop      ),
        .write_data ( b               ),
        .read_data  ( fifo_b_read_data),
        .empty      ( fifo_b_empty    ),
        .full       ( fifo_b_full     )
    );

    //------------------------------------------------------------------------
    // b + isqrt(c), then isqrt(...)

    logic        b_plus_sqrt_c_vld;
    logic [31:0] b_plus_sqrt_c;

    always_ff @ (posedge clk)
        if (rst)
            b_plus_sqrt_c_vld <= 1'b0;
        else
        begin
            b_plus_sqrt_c_vld <= fifo_b_pop;

            if (fifo_b_pop)
                b_plus_sqrt_c <= fifo_b_read_data + 32' (sqrt_c);
        end

    logic        sqrt_b_plus_sqrt_c_vld;
    logic [15:0] sqrt_b_plus_sqrt_c;

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_b_plus_sqrt_c
    (
        .clk   ( clk                   ),
        .rst   ( rst                   ),
        .x_vld ( b_plus_sqrt_c_vld     ),
        .x     ( b_plus_sqrt_c         ),
        .y_vld ( sqrt_b_plus_sqrt_c_vld),
        .y     ( sqrt_b_plus_sqrt_c    )
    );

    //------------------------------------------------------------------------
    // FIFO for a to align with isqrt(b + isqrt(c))

    logic        fifo_a_push;
    logic        fifo_a_pop;
    logic [31:0] fifo_a_read_data;
    logic        fifo_a_empty;
    logic        fifo_a_full;

    assign fifo_a_pop  = sqrt_b_plus_sqrt_c_vld & ~ fifo_a_empty;
    assign fifo_a_push = arg_vld & (~ fifo_a_full | fifo_a_pop);

    flip_flop_fifo_with_counter
    # (
        .width (width),
        .depth (a_depth)
    )
    i_fifo_a
    (
        .clk        ( clk             ),
        .rst        ( rst             ),
        .push       ( fifo_a_push     ),
        .pop        ( fifo_a_pop      ),
        .write_data ( a               ),
        .read_data  ( fifo_a_read_data),
        .empty      ( fifo_a_empty    ),
        .full       ( fifo_a_full     )
    );

    //------------------------------------------------------------------------
    // a + isqrt(b + isqrt(c)), then final isqrt(...)

    logic        a_plus_sqrt_b_plus_sqrt_c_vld;
    logic [31:0] a_plus_sqrt_b_plus_sqrt_c;

    always_ff @ (posedge clk)
        if (rst)
            a_plus_sqrt_b_plus_sqrt_c_vld <= 1'b0;
        else
        begin
            a_plus_sqrt_b_plus_sqrt_c_vld <= fifo_a_pop;

            if (fifo_a_pop)
                a_plus_sqrt_b_plus_sqrt_c <= fifo_a_read_data + 32' (sqrt_b_plus_sqrt_c);
        end

    logic        sqrt_formula_vld;
    logic [15:0] sqrt_formula;

    isqrt # (.n_pipe_stages (isqrt_depth)) i_isqrt_formula
    (
        .clk   ( clk                         ),
        .rst   ( rst                         ),
        .x_vld ( a_plus_sqrt_b_plus_sqrt_c_vld),
        .x     ( a_plus_sqrt_b_plus_sqrt_c  ),
        .y_vld ( sqrt_formula_vld           ),
        .y     ( sqrt_formula               )
    );

    assign res_vld = sqrt_formula_vld;
    assign res     = 32' (sqrt_formula);

endmodule
