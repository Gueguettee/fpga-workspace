module mac_unit
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
  logic done_q;

  assign result_d = op_a_i*op_b_i + op_c_i;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
        result_q <= '0;
        done_q <= 1'b0;
    end else begin
      if (start_i)  
        result_q <= result_d;
      done_q <= start_i;
    end
  end

  assign result_o = result_q;
  assign done_o = done_q;

endmodule
