module serial_to_parallel #(
    parameter int width = 8
) (
    input logic clk,
    input logic rst,

    input logic serial_valid,
    input logic serial_data,

    output logic             parallel_valid,
    output logic [width-1:0] parallel_data
);

  logic [$clog2(width) - 1:0] count;

  always_ff @(posedge clk) begin
    if (rst) begin
      parallel_data  <= '0;
      parallel_valid <= 1'b0;
      count          <= '0;
    end else begin
      parallel_valid <= 1'b0;

      if (serial_valid) begin
        parallel_data <= {serial_data, parallel_data[width-1:1]};

        if (count == width - 1) begin
          parallel_valid <= 1'b1;
          count          <= '0;
        end else begin
          count <= count + 1'b1;
        end
      end
    end
  end

endmodule
