//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant #(
    parameter FLEN = 64
) (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    //------------------------------------------------------------------------
    // Constants and helpers

    localparam integer NE_LOCAL = (FLEN == 128) ? 15 :
                                  (FLEN == 64)  ? 11 :
                                  (FLEN == 32)  ? 8  :
                                  (FLEN == 16)  ? 5  : 8;

    localparam [FLEN - 1:0] four = (FLEN == 64) ? 64'h4010_0000_0000_0000 :
                                  (FLEN == 32) ? 32'h4080_0000 :
                                  (FLEN == 16) ? 16'h4400 :
                                  {FLEN{1'b0}};

    function automatic logic is_invalid (input [FLEN - 1:0] v);
        return v [FLEN - 2 -: NE_LOCAL] === {NE_LOCAL{1'b1}};
    endfunction

    //------------------------------------------------------------------------
    // FSM

    enum logic [2:0]
    {
        st_idle       = 3'd0,
        st_wait_mults = 3'd1,
        st_start_four = 3'd2,
        st_wait_four  = 3'd3,
        st_start_sub  = 3'd4,
        st_wait_sub   = 3'd5
    }
    state, next_state;

    //------------------------------------------------------------------------
    // Registers

    logic [FLEN - 1:0] b2_reg;
    logic [FLEN - 1:0] ac_reg;
    logic [FLEN - 1:0] four_ac_reg;

    logic              done_b2;
    logic              done_ac;
    logic              err_reg;

    //------------------------------------------------------------------------
    // Datapath signals

    logic              mult_b2_up;
    logic              mult_ac_up;
    logic              mult_four_up;
    logic              sub_up;

    logic [FLEN - 1:0] mult_b2_res;
    logic [FLEN - 1:0] mult_ac_res;
    logic [FLEN - 1:0] mult_four_res;
    logic [FLEN - 1:0] sub_res;

    logic              mult_b2_vld;
    logic              mult_ac_vld;
    logic              mult_four_vld;
    logic              sub_vld;

    logic              mult_b2_err;
    logic              mult_ac_err;
    logic              mult_four_err;
    logic              sub_err;

    //------------------------------------------------------------------------
    // Floating-point units

    f_mult i_mult_b2 (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .a          ( b           ),
        .b          ( b           ),
        .up_valid   ( mult_b2_up  ),
        .res        ( mult_b2_res ),
        .down_valid ( mult_b2_vld ),
        .busy       (             ),
        .error      ( mult_b2_err )
    );

    f_mult i_mult_ac (
        .clk        ( clk         ),
        .rst        ( rst         ),
        .a          ( a           ),
        .b          ( c           ),
        .up_valid   ( mult_ac_up  ),
        .res        ( mult_ac_res ),
        .down_valid ( mult_ac_vld ),
        .busy       (             ),
        .error      ( mult_ac_err )
    );

    f_mult i_mult_four (
        .clk        ( clk           ),
        .rst        ( rst           ),
        .a          ( ac_reg        ),
        .b          ( four          ),
        .up_valid   ( mult_four_up  ),
        .res        ( mult_four_res ),
        .down_valid ( mult_four_vld ),
        .busy       (               ),
        .error      ( mult_four_err )
    );

    f_sub i_sub (
        .clk        ( clk      ),
        .rst        ( rst      ),
        .a          ( b2_reg   ),
        .b          ( four_ac_reg ),
        .up_valid   ( sub_up   ),
        .res        ( sub_res  ),
        .down_valid ( sub_vld  ),
        .busy       (          ),
        .error      ( sub_err  )
    );

    //------------------------------------------------------------------------
    // Control

    always_comb
    begin
        mult_b2_up   = (state == st_idle)      && arg_vld;
        mult_ac_up   = (state == st_idle)      && arg_vld;
        mult_four_up = (state == st_start_four);
        sub_up       = (state == st_start_sub);
    end

    always_comb
    begin
        next_state = state;

        case (state)
        st_idle:
            if (arg_vld)
                next_state = st_wait_mults;

        st_wait_mults:
            if ( (done_b2 | mult_b2_vld) && (done_ac | mult_ac_vld) )
                next_state = st_start_four;

        st_start_four:
            next_state = st_wait_four;

        st_wait_four:
            if (mult_four_vld)
                next_state = st_start_sub;

        st_start_sub:
            next_state = st_wait_sub;

        st_wait_sub:
            if (sub_vld)
                next_state = st_idle;
        endcase
    end

    //------------------------------------------------------------------------
    // State and registers

    always_ff @ (posedge clk)
        if (rst)
        begin
            state        <= st_idle;
            b2_reg       <= '0;
            ac_reg       <= '0;
            four_ac_reg  <= '0;
            done_b2      <= '0;
            done_ac      <= '0;
            err_reg      <= '0;
            res          <= '0;
            res_vld      <= '0;
            res_negative <= '0;
        end
        else
        begin
            state   <= next_state;
            res_vld <= '0;

            if (state == st_idle && arg_vld)
            begin
                err_reg <= is_invalid(a) | is_invalid(b) | is_invalid(c);
            end
            else
            begin
                err_reg <= err_reg
                         | ((state == st_wait_mults && mult_b2_vld) ? mult_b2_err : 1'b0)
                         | ((state == st_wait_mults && mult_ac_vld) ? mult_ac_err : 1'b0)
                         | ((state == st_wait_four  && mult_four_vld) ? mult_four_err : 1'b0)
                         | ((state == st_wait_sub   && sub_vld) ? sub_err : 1'b0);
            end

            if (state == st_wait_mults)
            begin
                if (mult_b2_vld)
                    b2_reg <= mult_b2_res;

                if (mult_ac_vld)
                    ac_reg <= mult_ac_res;
            end

            if (state == st_wait_four && mult_four_vld)
                four_ac_reg <= mult_four_res;

            if (state == st_wait_sub && sub_vld)
            begin
                res          <= sub_res;
                res_vld      <= '1;
                res_negative <= sub_res[FLEN - 1];
            end

            if (state == st_wait_mults)
            begin
                done_b2 <= done_b2 | mult_b2_vld;
                done_ac <= done_ac | mult_ac_vld;
            end
            else
            begin
                done_b2 <= '0;
                done_ac <= '0;
            end
        end

    //------------------------------------------------------------------------
    // Outputs

    assign err  = err_reg;
    assign busy = (state != st_idle);

endmodule
