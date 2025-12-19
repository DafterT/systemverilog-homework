//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    logic [width - 1:0] first_word;
    logic               have_first;

    assign down_vld  = ~rst & have_first & up_vld;
    assign down_data = down_vld ? {first_word, up_data} : '0;

    always_ff @(posedge clk) begin
        if (rst) begin
            first_word <= '0;
            have_first <= 1'b0;
        end else if (up_vld) begin
            if (have_first) begin
                have_first <= 1'b0;
            end else begin
                first_word <= up_data;
                have_first <= 1'b1;
            end
        end
    end


endmodule
