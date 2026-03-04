module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    localparam int ptr_width = ( n_inputs <= 1 ) ? 1 : $clog2 ( n_inputs );

    logic [ n_inputs - 1 : 0 ]                    pending_vld;
    logic [ n_inputs - 1 : 0 ][ width - 1 : 0 ]   pending_data;
    logic [ ptr_width - 1 : 0 ]                   rd_ptr;
    logic                                         take_data;

    always_comb
    begin
        take_data = pending_vld [ rd_ptr ];
    end

    assign down_vld  = take_data;
    assign down_data = take_data ? pending_data [ rd_ptr ] : '0;

    always_ff @ ( posedge clk )
    begin
        if ( rst )
        begin
            pending_vld  <= '0;
            pending_data <= '0;
            rd_ptr       <= '0;
        end
        else
        begin
            for ( int i = 0; i < n_inputs; i ++ )
                if ( up_vlds [ i ] )
                begin
                    pending_vld  [ i ] <= 1'b1;
                    pending_data [ i ] <= up_data [ i ];
                end

            if ( take_data )
            begin
                if ( ! up_vlds [ rd_ptr ] )
                    pending_vld [ rd_ptr ] <= 1'b0;

                if ( rd_ptr == ptr_width' ( n_inputs - 1 ) )
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
