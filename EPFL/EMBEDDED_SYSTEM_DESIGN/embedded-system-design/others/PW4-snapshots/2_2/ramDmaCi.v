module ramDmaCi #( parameter [7:0] customId = 8'h00 )
                 ( input  wire        start,
                                      clock,
                                      reset,
                   input  wire [31:0] valueA,
                                      valueB,
                   input  wire [7:0]  ciN,
                   output wire        done,
                   output wire [31:0] result );

  wire [31:0] memOut_s;

  wire isMyCi_s = (ciN == customId) ? start : 1'b0;
  wire validMemOp_s = (valueA[31:10] == 22'd0);
  wire write_s = isMyCi_s & validMemOp_s &  valueA[9];
  wire read_s = isMyCi_s & validMemOp_s & ~valueA[9];
  wire invalidMyCi_s = isMyCi_s & ~validMemOp_s;

  reg readDone_r;

  sram512X32Dp memA
    ( .clockA      (clock),
      .writeEnableA(write_s),
      .addressA    (valueA[8:0]),
      .dataInA     (valueB),
      .dataOutA    (memOut_s),
      .clockB      (clock),
      .writeEnableB(1'b0),
      .addressB    (9'd0),
      .dataInB     (32'd0),
      .dataOutB    () );

  always @(posedge clock)
  begin
    if (reset)
      readDone_r <= 1'b0;
    else
      readDone_r <= read_s & ~readDone_r;
  end

  assign done = write_s | readDone_r | invalidMyCi_s;
  assign result = readDone_r ? memOut_s : 32'd0;

endmodule
