//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    logic               hold_valid;
    logic [width - 1:0] hold_data;

    assign down_valid = ~reset & hold_valid & up_valid;
    assign down_last  = down_valid ? up_first : 1'b0;
    assign down_data  = down_valid ? hold_data : '0;

    always_ff @(posedge clock) begin
        if (reset) begin
            hold_valid <= 1'b0;
            hold_data  <= '0;
        end else if (up_valid) begin
            hold_valid <= 1'b1;
            hold_data  <= up_data;
        end
    end

endmodule
