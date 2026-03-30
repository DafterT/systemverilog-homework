//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.

    logic               stored_valid;
    logic [width - 1:0] stored_data;

    logic up_handshake;

    assign up_ready     = ~ stored_valid | down_ready;
    assign up_handshake = up_valid & up_ready;

    assign down_valid   = stored_valid & up_valid;
    assign down_last    = down_valid ? up_first    : 1'b0;
    assign down_data    = down_valid ? stored_data : '0;

    always_ff @ (posedge clock)
        if (reset)
        begin
            stored_valid <= 1'b0;
            stored_data  <= '0;
        end
        else if (up_handshake)
        begin
            stored_valid <= 1'b1;
            stored_data  <= up_data;
        end

endmodule
