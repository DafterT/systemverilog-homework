module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 05_07 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "05_07_float_discriminant.sv" from the Homework 05.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.

    // Latency in this setup is 12 cycles. One more cycle is needed until a block
    // becomes ready for the next transaction, so 13 blocks are enough to sustain
    // one input per cycle without stalling.
    localparam int n_blocks = 13;
    localparam int ptr_width = $clog2 (n_blocks);

    logic [ptr_width - 1:0] wr_ptr;

    logic [n_blocks - 1:0]  blocks_arg_vld;
    logic [n_blocks - 1:0]  blocks_res_vld;
    logic [FLEN - 1:0]      blocks_res [0:n_blocks - 1];
    logic [n_blocks - 1:0]  blocks_res_negative;
    logic [n_blocks - 1:0]  blocks_err;
    logic [n_blocks - 1:0]  blocks_busy;

    logic [FLEN - 1:0]      blocks_a [0:n_blocks - 1];
    logic [FLEN - 1:0]      blocks_b [0:n_blocks - 1];
    logic [FLEN - 1:0]      blocks_c [0:n_blocks - 1];

    logic                   res_sel_vld;
    logic [ptr_width - 1:0] res_sel_idx;

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

    always_comb
    begin
        res_vld       = res_sel_vld;
        res           = '0;
        res_negative  = '0;
        err           = '0;

        if (res_sel_vld)
        begin
            res          = blocks_res [res_sel_idx];
            res_negative = blocks_res_negative [res_sel_idx];
            err          = blocks_err [res_sel_idx];
        end
    end

    assign busy = | blocks_busy;

    //------------------------------------------------------------------------
    // Computational blocks

    generate
        genvar i;

        for (i = 0; i < n_blocks; i ++)
        begin : g_blocks
            float_discriminant i_float_discriminant
            (
                .clk          ( clk               ),
                .rst          ( rst               ),
                .arg_vld      ( blocks_arg_vld[i] ),
                .a            ( blocks_arg_vld[i] ? a : blocks_a[i] ),
                .b            ( blocks_arg_vld[i] ? b : blocks_b[i] ),
                .c            ( blocks_arg_vld[i] ? c : blocks_c[i] ),
                .res_vld      ( blocks_res_vld[i] ),
                .res          ( blocks_res[i]     ),
                .res_negative ( blocks_res_negative[i] ),
                .err          ( blocks_err[i]     ),
                .busy         ( blocks_busy[i]    )
            );
        end
    endgenerate

endmodule
