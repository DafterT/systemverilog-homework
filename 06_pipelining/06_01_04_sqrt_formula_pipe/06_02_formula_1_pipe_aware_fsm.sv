//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // Task:
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0
    typedef enum logic [1:0]
    {
        st_idle   = 2'd0,
        st_send_b = 2'd1,
        st_send_c = 2'd2,
        st_wait   = 2'd3
    } state_t;

    state_t state;

    logic [31:0] b_r;
    logic [31:0] c_r;

    logic [31:0] sum;
    logic [1:0]  out_cnt;
    logic        last_output;

    assign last_output = isqrt_y_vld && (out_cnt == 2'd2);

    always_comb
    begin
        isqrt_x_vld = 1'b0;
        isqrt_x     = '0;

        case (state)
        st_idle:
        begin
            if (arg_vld)
            begin
                isqrt_x_vld = 1'b1;
                isqrt_x     = a;
            end
        end
        st_send_b:
        begin
            isqrt_x_vld = 1'b1;
            isqrt_x     = b_r;
        end
        st_send_c:
        begin
            isqrt_x_vld = 1'b1;
            isqrt_x     = c_r;
        end
        endcase
    end

    always_ff @ (posedge clk)
        if (rst)
        begin
            state <= st_idle;
            b_r   <= '0;
            c_r   <= '0;
        end
        else
        begin
            case (state)
            st_idle:
            begin
                if (arg_vld)
                begin
                    b_r   <= b;
                    c_r   <= c;
                    state <= st_send_b;
                end
            end
            st_send_b: state <= st_send_c;
            st_send_c: state <= st_wait;
            st_wait:
            begin
                if (last_output)
                    state <= st_idle;
            end
            default: state <= st_idle;
            endcase
        end

    always_ff @(posedge clk)
        if (rst)
        begin
            sum     <= '0;
            out_cnt <= '0;
            res     <= '0;
            res_vld <= 1'b0;
        end
        else
        begin
            res_vld <= 1'b0;

            if (state == st_idle && arg_vld)
            begin
                sum     <= '0;
                out_cnt <= '0;
            end

            if (isqrt_y_vld)
            begin
                if (out_cnt == 2'd2)
                begin
                    res     <= sum + 32'(isqrt_y);
                    res_vld <= 1'b1;
                    sum     <= '0;
                    out_cnt <= '0;
                end
                else
                begin
                    sum     <= sum + 32'(isqrt_y);
                    out_cnt <= out_cnt + 2'd1;
                end
            end
        end
endmodule
