module mac_unit_3
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

    logic [15:0] mult_op_a;
    logic [15:0] mult_op_b;
    logic [31:0] accum;
    logic sign_a, sign_b;
    logic [31:0] mac_res, mac_res_d, mac_res_q;
    logic done_d, done_q;
    logic [31:0] op_a_q, op_b_q;

    typedef enum logic [1:0] {
      ALBL, ALBH, AHBL
    } mult_fsm_e;
    mult_fsm_e mult_state_q, mult_state_d;

    assign mac_res = $signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b}) + $signed(accum);

    assign result_o = mac_res_q;
    assign done_o   = done_q;

    always_comb begin
      mult_op_a    = op_a_i[15:0];
      mult_op_b    = op_b_i[15:0];
      sign_a       = 1'b0;
      sign_b       = 1'b0;
      accum        = op_c_i;
      mac_res_d    = mac_res;
      mult_state_d = mult_state_q;
      done_d       = 1'b0;

      unique case (mult_state_q)

        ALBL: begin
          // al*bl
          mult_op_a = op_a_i[15:0];
          mult_op_b = op_b_i[15:0];
          sign_a    = 1'b0;
          sign_b    = 1'b0;
          accum     = op_c_i;
          mac_res_d = mac_res;
          mult_state_d = start_i ? ALBH : ALBL;
        end

        ALBH: begin
          // al*bh<<16 + accum[31:16]
          mult_op_a = op_a_q[15:0];
          mult_op_b = op_b_q[31:16];
          sign_a    = 1'b0;
          sign_b    = op_b_q[31];
          // result of AL*BL always unsigned with no carry
          accum     = {16'b0, mac_res_q[31:16]};
          mult_state_d = AHBL;
          mac_res_d = {mac_res[15:0], mac_res_q[15:0]};
        end

        AHBL: begin
          // ah*bl<<16 + accum[31:16]
          mult_op_a = op_a_q[31:16];
          mult_op_b = op_b_q[15:0];
          sign_a    = op_a_q[31];
          sign_b    = 1'b0;
          accum        = {16'b0, mac_res_q[31:16]};
          mac_res_d    = {mac_res[15:0], mac_res_q[15:0]};
          mult_state_d = ALBL;
          done_d       = 1'b1;
        end 

        default: begin
          mult_state_d = ALBL;
        end
      endcase // mult_state_q
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        mult_state_q <= ALBL;
        mac_res_q    <= 32'b0;
        op_a_q       <= 32'b0;
        op_b_q       <= 32'b0;
        done_q       <= 1'b0;
      end else begin
          mult_state_q <= mult_state_d;
          if(mult_state_q == ALBL && start_i) begin
            op_a_q <= op_a_i;
            op_b_q <= op_b_i;
            mac_res_q <= mac_res_d;
          end else if (mult_state_q == ALBH || mult_state_q == AHBL) begin
            mac_res_q <= mac_res_d;
          end
          done_q    <= done_d;
      end
    end


endmodule
