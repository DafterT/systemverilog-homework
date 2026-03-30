//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.

    typedef enum logic [1:0]
    {
        st_empty,
        st_half,
        st_full
    }
    state_t;

    state_t                state;
    logic [2*width - 1:0]  data;

    logic up_handshake;
    logic down_handshake;

    assign up_ready       = (state != st_full) | down_ready;
    assign down_valid     = state == st_full;
    assign down_data      = data;
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
                    state <= st_half;
                    data  <= {up_data, {width{1'b0}}};
                end

            st_half:
                if (up_handshake)
                begin
                    state <= st_full;
                    data  <= {data[2*width - 1 : width], up_data};
                end

            st_full:
                if (down_handshake)
                    if (up_handshake)
                    begin
                        state <= st_half;
                        data  <= {up_data, {width{1'b0}}};
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
