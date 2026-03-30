//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

  // Task:
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;

  logic [8:0] pending_ones;
  logic [6:0] token_streak;
  logic       burst_limited;

  logic       input_one;
  logic       emit_one;

  assign up_ready   = burst_limited ? down_ready : 1'b1;
  assign input_one  = up_valid & up_ready & up_token;
  assign emit_one   = (pending_ones != '0) | input_one;
  assign down_valid = 1'b1;
  assign down_data  = emit_one;

  always_ff @ (posedge clk)
    if (rst)
    begin
      pending_ones  <= '0;
      token_streak  <= '0;
      burst_limited <= 1'b0;
    end
    else
    begin
      pending_ones <= pending_ones
                    + (input_one ? 9'd2 : 9'd0)
                    - ((down_ready & emit_one) ? 9'd1 : 9'd0);

      if (down_ready)
        token_streak <= '0;
      else if (input_one)
      begin
        if (token_streak == 7'd100)
          token_streak <= 7'd100;
        else
          token_streak <= token_streak + 7'd1;
      end

      if (~ burst_limited & ~ down_ready & input_one & token_streak == 7'd99)
        burst_limited <= 1'b1;
      else if (burst_limited & pending_ones == '0)
        burst_limited <= 1'b0;
    end

endmodule
