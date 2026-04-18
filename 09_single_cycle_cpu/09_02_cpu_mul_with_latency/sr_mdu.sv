//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "sr_cpu.svh"

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst,

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);

    logic [n_delay - 1:0] vld_pipe;
    logic [31:0]          result_pipe [0:n_delay - 1];

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            vld_pipe <= '0;

            for (int i = 0; i < n_delay; i ++)
                result_pipe [i] <= '0;
        end
        else
        begin
            vld_pipe [0]    <= i_vld;
            result_pipe [0] <= srcA * srcB;

            for (int i = 1; i < n_delay; i ++)
            begin
                vld_pipe [i]    <= vld_pipe [i - 1];
                result_pipe [i] <= result_pipe [i - 1];
            end
        end
    end

    assign o_vld  = vld_pipe [n_delay - 1];
    assign result = result_pipe [n_delay - 1];
    assign busy   = i_vld | (| vld_pipe);

endmodule

//----------------------------------------------------------------------------

module shift_register
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule

