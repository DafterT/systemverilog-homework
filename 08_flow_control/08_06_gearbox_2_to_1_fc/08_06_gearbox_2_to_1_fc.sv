//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.

    typedef enum logic [1:0]
    {
        st_empty,
        st_hi,
        st_lo
    }
    state_t;

    state_t               state;
    logic [2*width - 1:0] data;

    logic up_handshake;
    logic down_handshake;

    assign up_ready       = (state == st_empty) | ((state == st_lo) & down_ready);
    assign down_valid     = state != st_empty;
    assign down_data      = state == st_hi ? data[2*width - 1 : width]
                                           : data[  width - 1 :     0];
    assign up_handshake   = up_valid & up_ready;
    assign down_handshake = down_valid & down_ready;

    always_ff @ (posedge clk)
        if (rst)
        begin
            state <= st_empty;
            data  <= '0;
        end
        else
            case (state)
            st_empty:
                if (up_handshake)
                begin
                    state <= st_hi;
                    data  <= up_data;
                end

            st_hi:
                if (down_handshake)
                    state <= st_lo;

            st_lo:
                if (down_handshake)
                    if (up_handshake)
                    begin
                        state <= st_hi;
                        data  <= up_data;
                    end
                    else
                        state <= st_empty;

            default:
            begin
                state <= st_empty;
                data  <= '0;
            end
            endcase

endmodule
