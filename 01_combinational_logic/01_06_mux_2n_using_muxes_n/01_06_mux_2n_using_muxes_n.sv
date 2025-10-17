//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input  [3:0] d0, d1,
  input        sel,
  output [3:0] y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // Task:
  // Implement mux_4_1 using three instances of mux_2_1
  logic [3:0] d01_res, d23_res;

  mux_2_1 d0_d1_inst (d0, d1, sel[0], d01_res);
  mux_2_1 d2_d3_inst (d2, d3, sel[0], d23_res);
  mux_2_1 res_inst (d01_res, d23_res, sel[1], y);

endmodule
