//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module one_bit_wide_circular_buffer
# (
    parameter depth = 8
)
(
    input  clk,
    input  rst,

    input  in_data,
    output out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [depth - 1:0] data;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            data <= '0;
        else
            data [ptr] <= in_data;

    assign out_data = data [ptr];

endmodule

//----------------------------------------------------------------------------

module circular_buffer
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk)
        data [ptr] <= in_data;

    assign out_data  = data [ptr];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module circular_buffer_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input                in_valid,
    input  [width - 1:0] in_data,

    output               out_valid,
    output [width - 1:0] out_data
);

    localparam logic [$clog2(depth) - 1:0] MAX_PTR = depth - 1;

    logic [$clog2(depth) - 1: 0] ptr_q;

    logic [width - 1 : 0] data_mem  [0 : depth - 1];
    logic                 valid_mem [0 : depth - 1];

    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ptr_q     <= '0;
            //out_data  <= '0;
            //out_valid <= 1'b0;

            for (i = 0; i < depth; i = i + 1) begin
                data_mem[i]  <= '0;
                valid_mem[i] <= 1'b0;
            end
        end else begin
            //out_data  <= data_mem[ptr_q];
            //out_valid <= valid_mem[ptr_q];

            data_mem[ptr_q]  <= in_data;
            valid_mem[ptr_q] <= in_valid;

            if (ptr_q == MAX_PTR)
                ptr_q <= '0;
            else
                ptr_q <= ptr_q + 1'b1;
        end
    end

    assign out_data = data_mem[ptr_q];
    assign out_valid = valid_mem[ptr_q];

endmodule
