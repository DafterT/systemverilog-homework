//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens
(
    input        clk,
    input        rst,
    input        a,
    output       b,
    output logic overflow
);
    // Task:
    // Implement a serial module that doubles each incoming token '1' two times.
    // The module should handle doubling for at least 200 tokens '1' arriving in a row.
    //
    // In case module detects more than 200 sequential tokens '1', it should assert
    // an overflow error. The overflow error should be sticky. Once the error is on,
    // the only way to clear it is by using the "rst" reset signal.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 10010011000110100001100100
    // b -> 11011011110111111001111110
    logic [9:0] pending;
    logic [7:0] run_len;

    assign b = rst ? 1'b0 : ((pending != 0) || a);

    always_ff @(posedge clk) begin
        if (rst) begin
            pending  <= '0;
            run_len  <= '0;
            overflow <= 1'b0;
        end else begin
            if (a) begin
                pending <= pending + 1'b1;
            end else if (pending != 0) begin
                pending <= pending - 1'b1;
            end

            if (a) begin
                if (run_len < 8'd200) begin
                    run_len <= run_len + 1'b1;
                end
            end else begin
                run_len <= '0;
            end

            overflow <= overflow | (a && (run_len >= 8'd200));
        end
    end

endmodule
