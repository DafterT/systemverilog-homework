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

module cpu_cluster
#(
    parameter nCPUs = 3
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

    localparam romSize  = 64;
    localparam romAddrW = $clog2 (romSize);

    wire [nCPUs - 1:0][31:0] imAddr;
    wire [nCPUs - 1:0][31:0] imData;
    wire [nCPUs - 1:0]       imDataVld;

    logic [7:0] req;
    logic [7:0] gnt;

    logic [romAddrW - 1:0] romAddr;
    wire  [31:0] romData;

    genvar i;

    generate
        for (i = 0; i < nCPUs; i ++)
        begin : gen_cpu
            sr_cpu cpu
            (
                .clk       ( clk         ),
                .rst       ( rst         ),
                .rstPC     ( rstPC   [i] ),
                .imAddr    ( imAddr  [i] ),
                .imData    ( imData  [i] ),
                .imDataVld ( imDataVld[i] ),
                .regAddr   ( regAddr [i] ),
                .regData   ( regData [i] )
            );
        end
    endgenerate

    always_comb
    begin
        req = '0;
        req [nCPUs - 1:0] = { nCPUs { ~ rst } };
    end

    round_robin_arbiter_8 arbiter
    (
        .clk ( clk ),
        .rst ( rst ),
        .req ( req ),
        .gnt ( gnt )
    );

    always_comb
    begin
        romAddr = '0;

        case (1'b1)
            gnt [0] : romAddr = imAddr [0][romAddrW - 1:0];
            gnt [1] : romAddr = imAddr [1][romAddrW - 1:0];
            gnt [2] : romAddr = imAddr [2][romAddrW - 1:0];
        endcase
    end

    instruction_rom
    # (
        .SIZE   ( romSize  ),
        .ADDR_W ( romAddrW )
    )
    rom
    (
        .a  ( romAddr ),
        .rd ( romData )
    );

    generate
        for (i = 0; i < nCPUs; i ++)
        begin : gen_imux
            assign imData    [i] = romData;
            assign imDataVld [i] = gnt [i];
        end
    endgenerate


endmodule
