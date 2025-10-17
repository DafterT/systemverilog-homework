//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_adder (
    input  clk,
    input  rst,
    input  a,
    input  b,
    output sum
);

  // Note:
  // carry_d represents the combinational data input to the carry register.

  logic carry;
  wire  carry_d;

  assign {carry_d, sum} = a + b + carry;

  always_ff @(posedge clk)
    if (rst) carry <= '0;
    else carry <= carry_d;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_adder_using_logic_operations_only (
    input  clk,
    input  rst,
    input  a,
    input  b,
    output logic sum
);

  // Task:
  // Implement a serial adder using only ^ (XOR), | (OR), & (AND), ~ (NOT) bitwise operations.
  //
  // Notes:
  // See Harris & Harris book
  // or https://en.wikipedia.org/wiki/Adder_(electronics)#Full_adder webpage
  // for information about the 1-bit full adder implementation.
  //
  // See the testbench for the output format ($display task).
  logic ab_xor, abc_xor, ab_xor_c_and, ab_and, carry_d;
  logic carry;

  always_comb begin
    ab_xor = a ^ b;
    sum = ab_xor ^ carry;
    ab_xor_c_and = ab_xor & carry;
    ab_and = a & b;
    carry_d = ab_and | ab_xor_c_and;
  end

  always_ff @(posedge clk)
    if (rst) carry <= '0;
    else carry <= carry_d;

endmodule
