//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module signed_add_with_saturation
(
  input  [3:0] a, b,
  output [3:0] sum
);

  // Task:
  //
  // Implement a module that adds two signed numbers with saturation.
  //
  // "Adding with saturation" means:
  //
  // When the result does not fit into 4 bits,
  // and the arguments are positive,
  // the sum should be set to the maximum positive number.
  //
  // When the result does not fit into 4 bits,
  // and the arguments are negative,
  // the sum should be set to the minimum negative number.
  logic [3:0] sum_temp;
  logic overflow;
  assign sum_temp = a + b;
  assign overflow = (~a[3] & ~b[3] &  sum_temp[3]) |  // два плюса дали минус
                    ( a[3] &  b[3] & ~sum_temp[3]);   // два минуса дали плюс

  assign sum = overflow ? a[3] ? 'b1000 : 'b0111: sum_temp;

endmodule
