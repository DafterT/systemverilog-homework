module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    localparam int n_blocks = 20;
    localparam int ptr_width = $clog2 (n_blocks);

    logic [ptr_width - 1:0] wr_ptr;

    logic [n_blocks - 1:0] blocks_arg_vld;
    logic [n_blocks - 1:0] blocks_res_vld;
    logic [31:0]           blocks_res [0:n_blocks - 1];

    logic [31:0]           blocks_a [0:n_blocks - 1];
    logic [31:0]           blocks_b [0:n_blocks - 1];
    logic [31:0]           blocks_c [0:n_blocks - 1];

    logic                  res_sel_vld;
    logic [ptr_width - 1:0] res_sel_idx;

    assign res_vld = res_sel_vld;
    assign res     = blocks_res [res_sel_idx];

    //------------------------------------------------------------------------
    // Round-robin task distribution

    always_comb
    begin
        blocks_arg_vld = '0;

        if (arg_vld)
            blocks_arg_vld [wr_ptr] = '1;
    end

    always_ff @ (posedge clk)
        if (rst)
            wr_ptr <= '0;
        else if (arg_vld)
            if (wr_ptr == n_blocks - 1)
                wr_ptr <= '0;
            else
                wr_ptr <= wr_ptr + 1'b1;

    //------------------------------------------------------------------------
    // Per-block argument storage

    always_ff @ (posedge clk)
        if (rst)
            for (int i = 0; i < n_blocks; i ++)
            begin
                blocks_a [i] <= '0;
                blocks_b [i] <= '0;
                blocks_c [i] <= '0;
            end
        else if (arg_vld)
        begin
            blocks_a [wr_ptr] <= a;
            blocks_b [wr_ptr] <= b;
            blocks_c [wr_ptr] <= c;
        end

    //------------------------------------------------------------------------
    // Result collection (N-to-1 mux)

    always_comb
    begin
        res_sel_vld = '0;
        res_sel_idx = '0;

        for (int i = 0; i < n_blocks; i ++)
            if (! res_sel_vld && blocks_res_vld [i])
            begin
                res_sel_vld = '1;
                res_sel_idx = ptr_width' (i);
            end
    end

    //------------------------------------------------------------------------
    // Computational blocks

    generate
        genvar i;

        if (formula == 1 && impl == 1)
        begin : g_formula_1_impl_1

            for (i = 0; i < n_blocks; i ++)
            begin : g_blocks
                formula_1_impl_1_top i_formula_1_impl_1_top
                (
                    .clk     ( clk               ),
                    .rst     ( rst               ),
                    .arg_vld ( blocks_arg_vld[i] ),
                    .a       ( blocks_arg_vld[i] ? a : blocks_a[i] ),
                    .b       ( blocks_arg_vld[i] ? b : blocks_b[i] ),
                    .c       ( blocks_arg_vld[i] ? c : blocks_c[i] ),
                    .res_vld ( blocks_res_vld[i] ),
                    .res     ( blocks_res[i]     )
                );
            end
        end
        else if (formula == 1 && impl == 2)
        begin : g_formula_1_impl_2

            for (i = 0; i < n_blocks; i ++)
            begin : g_blocks
                formula_1_impl_2_top i_formula_1_impl_2_top
                (
                    .clk     ( clk               ),
                    .rst     ( rst               ),
                    .arg_vld ( blocks_arg_vld[i] ),
                    .a       ( blocks_arg_vld[i] ? a : blocks_a[i] ),
                    .b       ( blocks_arg_vld[i] ? b : blocks_b[i] ),
                    .c       ( blocks_arg_vld[i] ? c : blocks_c[i] ),
                    .res_vld ( blocks_res_vld[i] ),
                    .res     ( blocks_res[i]     )
                );
            end
        end
        else
        begin : g_formula_2

            for (i = 0; i < n_blocks; i ++)
            begin : g_blocks
                formula_2_top i_formula_2_top
                (
                    .clk     ( clk               ),
                    .rst     ( rst               ),
                    .arg_vld ( blocks_arg_vld[i] ),
                    .a       ( blocks_arg_vld[i] ? a : blocks_a[i] ),
                    .b       ( blocks_arg_vld[i] ? b : blocks_b[i] ),
                    .c       ( blocks_arg_vld[i] ? c : blocks_c[i] ),
                    .res_vld ( blocks_res_vld[i] ),
                    .res     ( blocks_res[i]     )
                );
            end
        end
    endgenerate

endmodule
