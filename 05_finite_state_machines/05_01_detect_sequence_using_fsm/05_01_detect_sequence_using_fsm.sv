//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Task:
  // Implement a module that detects the "110011" input sequence
  //
  // Hint: See Lecture 3 for details
  
  enum logic[2:0]
  {
     IDLE    = 3'b000, // no match
     S1      = 3'b001, // "1"
     S11     = 3'b010, // "11"
     S110    = 3'b011, // "110"
     S1100   = 3'b100, // "1100"
     S11001  = 3'b101, // "11001"
     S110011 = 3'b110  // "110011"
  }
  state, new_state;

  always_comb
  begin
    new_state = state;
    case (state)
      IDLE:    if (  a) new_state = S1;
      S1:      if (  a) new_state = S11;
               else     new_state = IDLE;
      S11:     if (  a) new_state = S11;
               else     new_state = S110;
      S110:    if (  a) new_state = S1;
               else     new_state = S1100;
      S1100:   if (  a) new_state = S11001;
               else     new_state = IDLE;
      S11001:  if (  a) new_state = S110011;
               else     new_state = IDLE;
      S110011: if (  a) new_state = S11;
               else     new_state = S110;
    endcase
  end

  assign detected = (state == S110011);

  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

