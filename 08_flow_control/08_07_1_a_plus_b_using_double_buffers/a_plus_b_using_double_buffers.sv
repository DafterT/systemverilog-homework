module a_plus_b_using_double_buffers
# (
    parameter width = 8
)
(
    input                clk,
    input                rst,

    input                a_valid,
    output               a_ready,
    input  [width - 1:0] a_data,

    input                b_valid,
    output               b_ready,
    input  [width - 1:0] b_data,

    output               sum_valid,
    input                sum_ready,
    output [width - 1:0] sum_data
);

    //------------------------------------------------------------------------

    wire               a_down_valid;
    wire               a_down_ready;
    wire [width - 1:0] a_down_data;

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_a
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( a_valid      ),
        .up_ready    ( a_ready      ),
        .up_data     ( a_data       ),

        .down_valid  ( a_down_valid ),
        .down_ready  ( a_down_ready ),
        .down_data   ( a_down_data  )
    );

    //------------------------------------------------------------------------

    wire               b_down_valid;
    wire               b_down_ready;
    wire [width - 1:0] b_down_data;

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_b
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( b_valid      ),
        .up_ready    ( b_ready      ),
        .up_data     ( b_data       ),

        .down_valid  ( b_down_valid ),
        .down_ready  ( b_down_ready ),
        .down_data   ( b_down_data  )
    );

    //------------------------------------------------------------------------

    // Task: Add logic using the template below
    //
    // wire               sum_up_valid = ...
    // wire               sum_up_ready;
    // wire [width - 1:0] sum_up_data  = ...
    //
    // assign a_down_ready = ...
    // assign b_down_ready = ...

    logic               a_hold_valid, b_hold_valid;
    logic [width - 1:0] a_hold_data,  b_hold_data;

    wire               sum_up_valid = a_hold_valid & b_hold_valid;
    wire               sum_up_ready;
    wire [width - 1:0] sum_up_data  = a_hold_data + b_hold_data;

    wire a_take   = a_down_valid & a_down_ready;
    wire b_take   = b_down_valid & b_down_ready;
    wire sum_take = sum_up_valid & sum_up_ready;

    assign a_down_ready = ~ a_hold_valid | sum_take;
    assign b_down_ready = ~ b_hold_valid | sum_take;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            a_hold_valid <= 1'b0;
            b_hold_valid <= 1'b0;
            a_hold_data  <= '0;
            b_hold_data  <= '0;
        end
        else
        begin
            a_hold_valid <= (a_hold_valid & ~ sum_take) | a_take;
            b_hold_valid <= (b_hold_valid & ~ sum_take) | b_take;

            if (a_take)
                a_hold_data <= a_down_data;

            if (b_take)
                b_hold_data <= b_down_data;
        end


    //------------------------------------------------------------------------

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_sum
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( sum_up_valid ),
        .up_ready    ( sum_up_ready ),
        .up_data     ( sum_up_data  ),

        .down_valid  ( sum_valid    ),
        .down_ready  ( sum_ready    ),
        .down_data   ( sum_data     )
    );

endmodule
