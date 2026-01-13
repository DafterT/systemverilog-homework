//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm #(
    parameter FLEN = 64
) (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    //------------------------------------------------------------------------
    // States

    enum logic [1:0]
    {
        st_idle    = 2'd0,
        st_cmp_bc  = 2'd1,
        st_cmp_ab2 = 2'd2
    }
    state;

    //------------------------------------------------------------------------
    // Registers

    logic [FLEN - 1:0] r0, r1, r2;
    logic              err_reg;

    //------------------------------------------------------------------------
    // Helpers

    localparam integer NE_LOCAL = (FLEN == 128) ? 15 :
                                  (FLEN == 64)  ? 11 :
                                  (FLEN == 32)  ? 8  :
                                  (FLEN == 16)  ? 5  : 8;

    function automatic logic is_err (input [FLEN - 1:0] v);
        return v [FLEN - 2 -: NE_LOCAL] === {NE_LOCAL{1'b1}};
    endfunction

    //------------------------------------------------------------------------
    // Comparator inputs

    always_comb
    begin
        f_le_a = 'x;
        f_le_b = 'x;

        case (state)
        st_idle:
        begin
            f_le_a = unsorted[0];
            f_le_b = unsorted[1];
        end
        st_cmp_bc:
        begin
            f_le_a = r1;
            f_le_b = r2;
        end
        st_cmp_ab2:
        begin
            f_le_a = r0;
            f_le_b = r1;
        end
        endcase
    end

    //------------------------------------------------------------------------
    // FSM datapath and outputs

    always_ff @ (posedge clk)
        if (rst)
        begin
            state     <= st_idle;
            r0        <= '0;
            r1        <= '0;
            r2        <= '0;
            err_reg   <= '0;
            valid_out <= '0;
        end
        else
        begin
            valid_out <= '0;

            case (state)
            st_idle:
                if (valid_in)
                begin
                    if (f_le_res)
                    begin
                        r0 <= unsorted[0];
                        r1 <= unsorted[1];
                    end
                    else
                    begin
                        r0 <= unsorted[1];
                        r1 <= unsorted[0];
                    end

                    r2      <= unsorted[2];
                    err_reg <= is_err(unsorted[0]) | is_err(unsorted[1]) | is_err(unsorted[2]) | f_le_err;
                    state   <= st_cmp_bc;
                end

            st_cmp_bc:
            begin
                if (! f_le_res)
                begin
                    r1 <= r2;
                    r2 <= r1;
                end

                err_reg <= err_reg | f_le_err;
                state   <= st_cmp_ab2;
            end

            st_cmp_ab2:
            begin
                if (! f_le_res)
                begin
                    r0 <= r1;
                    r1 <= r0;
                end

                err_reg   <= err_reg | f_le_err;
                valid_out <= '1;
                state     <= st_idle;
            end
            endcase

        end

    //------------------------------------------------------------------------
    // Outputs

    assign sorted[0] = r0;
    assign sorted[1] = r1;
    assign sorted[2] = r2;

    assign err  = err_reg;
    assign busy = (state != st_idle);

endmodule
