module mac_unit_2
(
    input logic clk_i,
    input logic rst_ni,

    input logic [31:0] op_a_i,
    input logic [31:0] op_b_i,
    input logic [31:0] op_c_i,
    input logic start_i,
    output logic done_o,
    output logic [31:0] result_o
);

  logic [31:0] result_q, result_d;
  logic [31:0] op_c_q;
  logic done_q;

  assign result_d = op_a_i*op_b_i;
  assign done_o   = done_q;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
        result_q <= '0;
        op_c_q <= '0;
        done_q <= 1'b0;
    end else begin
        if (start_i) begin
          done_q   <= 1'b1;
          op_c_q   <= op_c_i;
          result_q <= result_d;
        end else begin
          done_q <= 1'b0;
        end
    end
  end

  assign result_o = result_q + op_c_q;

endmodule
