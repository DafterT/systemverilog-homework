//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux (
    input  d0,
    d1,
    input  sel,
    output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux (
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections
  logic not_b;
  mux inv_b (1'b1, 1'b0, b, not_b);
  mux make_xor (b, not_b, a, o);

endmodule
