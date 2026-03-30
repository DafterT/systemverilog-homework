//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    // The module must use the ready-valid protocol.
    //
    //  Expected behavior of the module
    //  1) When the input signals are up_token and up_valid is high, the signal (token) is processed.
    //  2) Every second signal received for processing is sent to the output of the module.
    //  3) When the module cannot process the signal, it sets the up_ready signal to a low level.
    //
    // Example:
    // down_ready     ->   1111_1111_1111_0000
    // up_token       ->   1101_0100_1111_1111
    // up_valid       ->   1111_1111_0101_1111
    // down_valid     ->   1111_1111_1111_1000
    // down_data      ->   0100_0100_0001_0000
    // up_ready       ->   1111_1111_0101_1000

    logic odd_tokens_seen;
    logic emit_token;
    logic up_handshake;

    assign emit_token   = up_token & odd_tokens_seen;
    assign up_handshake = up_valid & up_ready;

    always_ff @ (posedge clk)
        if (rst)
            odd_tokens_seen <= 1'b0;
        else if (up_handshake & up_token)
            odd_tokens_seen <= ~ odd_tokens_seen;

    assign down_valid = up_valid;
    assign down_data  = up_valid & emit_token & down_ready;
    assign up_ready   = up_valid & (down_ready | ~ emit_token);

endmodule
