module fifo #( parameter nrOfEntries = 16,
                parameter bitWidth = 32)
                ( input wire reset,
                             clock,
                             push,
                             pop,
                  input wire [bitWidth-1:0] pushData,
                  output reg full,
                              empty,
                  output reg [bitWidth-1:0] popData);
  
  localparam ptrWidth = $clog2(nrOfEntries);

  wire [bitWidth-1:0] ramOut;
  reg [ptrWidth-1:0] headPtr, tailPtr;
  reg [ptrWidth:0] count;
  
  reg ramWriteEnable, ramReadEnable;

  semiDualPortSSRAM #(
      .bitwidth(bitWidth),
      .nrOfEntries(nrOfEntries)
  ) mem (
      .clock(clock),
      .writeEnable(ramWriteEnable),
      .addressRead(headPtr),
      .addressWrite(tailPtr),
      .dataIn(pushData),
      .dataOut(ramOut)
  );

  always @(*) begin
    full = (count == nrOfEntries);
    empty = (count == 0);

    ramReadEnable = pop && !empty;
    ramWriteEnable = (push && (!full || ramReadEnable));

    popData = 0;
    if (ramReadEnable) begin
      popData = ramOut;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      headPtr <= 0;
      tailPtr <= 0;
      count <= 0;

    end else begin
      if (ramWriteEnable && ramReadEnable)
        count <= count;
      else if (ramWriteEnable)
        count <= count + 1;
      else if (ramReadEnable)
        count <= count - 1;

      if (ramReadEnable) begin
        if (headPtr < nrOfEntries-1)
          headPtr <= headPtr + 1;
        else
          headPtr <= 0;
      end
      if (ramWriteEnable) begin
        if (tailPtr < nrOfEntries-1)
          tailPtr <= tailPtr + 1;
        else
          tailPtr <= 0;
      end
    end
  end

endmodule
