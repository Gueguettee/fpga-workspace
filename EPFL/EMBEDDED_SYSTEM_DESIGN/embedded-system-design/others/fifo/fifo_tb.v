`timescale 1ps/1ps

module fifoTestBench;

  parameter NR_OF_ENTRIES = 16;
  parameter BIT_WIDTH = 32;

  reg clock, reset, push, pop;
  reg [BIT_WIDTH-1:0] pushData;
  wire full, empty;
  wire [BIT_WIDTH-1:0] popData;

  fifo #(
    .nrOfEntries(NR_OF_ENTRIES),
    .bitWidth(BIT_WIDTH)
  ) dut (
    .reset(reset),
    .clock(clock),
    .push(push),
    .pop(pop),
    .pushData(pushData),
    .full(full),
    .empty(empty),
    .popData(popData)
  );

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  integer i;

  initial begin
    reset = 1'b1;
    push = 1'b0;
    pop = 1'b0;
    pushData = 0;

    @(posedge clock);
    @(posedge clock);
    reset = 1'b0;

    for (i = 0; i < NR_OF_ENTRIES; i = i + 1) begin
      @(negedge clock);
      push = 1'b1;
      pushData = i * 10;
      @(posedge clock);
    end
    @(negedge clock);
    push = 1'b0;

    @(negedge clock);
    push = 1'b1;
    pushData = 32'hDEAD;
    @(posedge clock);
    @(negedge clock);
    push = 1'b0;

    for (i = 0; i < NR_OF_ENTRIES; i = i + 1) begin
      @(negedge clock);
      pop = 1'b1;
      @(posedge clock);
    end
    @(negedge clock);
    pop = 1'b0;

    @(negedge clock);
    pop = 1'b1;
    @(posedge clock);
    @(negedge clock);
    pop = 1'b0;

    for (i = 0; i < 4; i = i + 1) begin
      @(negedge clock);
      push = 1'b1;
      pushData = 32'hA0 + i;
      @(posedge clock);
    end
    @(negedge clock);
    push = 1'b0;

    @(negedge clock);
    push = 1'b1;
    pop = 1'b1;
    pushData = 32'hBEEF;
    @(posedge clock);
    @(negedge clock);
    push = 1'b0;
    pop = 1'b0;

    repeat (4) @(posedge clock);
    $finish;
  end

  initial begin
    $dumpfile("fifoSignals.vcd");
    $dumpvars(0, dut);
  end

endmodule
