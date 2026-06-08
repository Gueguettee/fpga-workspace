module cmulCi #( parameter [7:0] customId = 8'd13 )
               ( input  wire        start,
                                    clock,
                                    reset,
                 input  wire [31:0] valueA,
                                    valueB,
                 input  wire [7:0]  ciN,
                 output wire        done,
                 output wire [31:0] result );

  // Packed Q15 complex multiply: t = b * w
  //   valueA = {br, bi}, valueB = {wr, wi}, result = {tr, ti}
  wire isMyCi_s = (ciN == customId) ? start : 1'b0;
  assign done = isMyCi_s;

  wire signed [15:0] br_s = valueA[31:16];
  wire signed [15:0] bi_s = valueA[15:0];
  wire signed [15:0] wr_s = valueB[31:16];
  wire signed [15:0] wi_s = valueB[15:0];

  // 4 x signed 16x16 multiplies map to MULT18X18D on ECP5
  wire signed [31:0] wrbr_s = wr_s * br_s;
  wire signed [31:0] wibi_s = wi_s * bi_s;
  wire signed [31:0] wrbi_s = wr_s * bi_s;
  wire signed [31:0] wibr_s = wi_s * br_s;

  // 33-bit signed sums (auto sign-extended); [30:15] renormalises Q30 -> Q15
  wire signed [32:0] trFull_s = wrbr_s - wibi_s;
  wire signed [32:0] tiFull_s = wrbi_s + wibr_s;
  wire signed [15:0] tr_s = trFull_s[30:15];
  wire signed [15:0] ti_s = tiFull_s[30:15];

  assign result = isMyCi_s ? {tr_s, ti_s} : 32'd0;
  
endmodule
