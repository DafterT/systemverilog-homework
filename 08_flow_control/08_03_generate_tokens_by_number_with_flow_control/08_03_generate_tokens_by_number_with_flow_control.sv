//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.

    localparam [WIDTH-1 : 0] ONE = {{(WIDTH - 1){1'b0}}, 1'b1};

    logic [WIDTH-1 : 0] tokens_left;

    logic busy;
    logic last_token;
    logic up_handshake;
    logic down_handshake;

    assign busy           = tokens_left != '0;
    assign last_token     = tokens_left == ONE;
    assign up_ready       = ~ busy | (last_token & down_ready);
    assign down_valid     = busy;
    assign down_token     = busy;
    assign up_handshake   = up_valid & up_ready;
    assign down_handshake = down_valid & down_ready;

    always_ff @ (posedge clk)
        if (rst)
            tokens_left <= '0;
        else
        begin
            if (down_handshake)
                tokens_left <= tokens_left - ONE;

            if (up_handshake)
                if (down_handshake)
                    tokens_left <= tokens_left - ONE + n_tokens;
                else
                    tokens_left <= n_tokens;
        end

endmodule
