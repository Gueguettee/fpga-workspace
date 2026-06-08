module ramDmaCi #( parameter [7:0] customId = 8'h00 )
                 ( input wire         start,
                                      clock,
                                      reset,
                   input wire [31:0]  valueA,
                                      valueB,
                   input wire [7:0]   ciN,
                   output wire        done,
                   output wire [31:0] result,

                   // Bus master interface
                   output wire        requestTransaction,
                   input wire         transactionGranted,
                   input wire         endTransactionIn,
                                      dataValidIn,
                                      busErrorIn,
                                      busyIn,
                   input wire [31:0]  addressDataIn,
                   output reg         beginTransactionOut,
                                      readNotWriteOut,
                                      endTransactionOut,
                   output wire        dataValidOut,
                   output reg [3:0]   byteEnablesOut,
                   output reg [7:0]   burstSizeOut,
                   output wire [31:0] addressDataOut);

  wire [31:0] sramDataValue_s;

  // Custom-instruction decode
  wire isMyCi_s     = (ciN == customId) ? start : 1'b0;
  wire isSramWrite_s = (valueA[31:10] == 22'd0) ? isMyCi_s & valueA[9] : 1'b0;
  wire isSramRead_s  = isMyCi_s & ~valueA[9];
  reg  isSramRead_r;

  assign done = (isMyCi_s & valueA[9]) | isSramRead_r;

  always @(posedge clock) isSramRead_r = ~reset & isSramRead_s;

  // DMA configuration registers
  reg [31:0] busStartAddress_r;
  reg [8:0]  memoryStartAddress_r;
  reg [9:0]  blockSize_r;
  reg [7:0]  usedBurstSize_r;

  always @(posedge clock)
    begin
      busStartAddress_r    <= (reset == 1'b1) ? 32'd0 :
                              (isMyCi_s == 1'b1 && valueA[12:9] == 4'b0011) ? valueB : busStartAddress_r;
      memoryStartAddress_r <= (reset == 1'b1) ? 9'd0 :
                              (isMyCi_s == 1'b1 && valueA[12:9] == 4'b0101) ? valueB[8:0] : memoryStartAddress_r;
      blockSize_r          <= (reset == 1'b1) ? 10'd0 :
                              (isMyCi_s == 1'b1 && valueA[12:9] == 4'b0111) ? valueB[9:0] : blockSize_r;
      usedBurstSize_r      <= (reset == 1'b1) ? 8'd0 :
                              (isMyCi_s == 1'b1 && valueA[12:9] == 4'b1001) ? valueB[7:0] : usedBurstSize_r;
    end

  // Bus-input pipeline registers
  reg        endTransactionIn_r, dataValidIn_r;
  reg [31:0] addressDataIn_r;

  always @(posedge clock)
    begin
      endTransactionIn_r <= endTransactionIn;
      dataValidIn_r      <= dataValidIn;
      addressDataIn_r    <= addressDataIn;
    end

  // Dual-port memory: port A for CI, port B for DMA on inverted clock
  reg  [8:0]  ramCiAddress_r;
  wire        ramCiWriteEnable_s;
  wire [31:0] busRamData_s;

  dualPortSSRAM #( .bitwidth(32),
                   .nrOfEntries(512)) memory
                 ( .clockA(clock),
                   .clockB(~clock),
                   .writeEnableA(isSramWrite_s),
                   .writeEnableB(ramCiWriteEnable_s),
                   .addressA(valueA[8:0]),
                   .addressB(ramCiAddress_r),
                   .dataInA(valueB),
                   .dataInB(addressDataIn_r),
                   .dataOutA(sramDataValue_s),
                   .dataOutB(busRamData_s));

  // DMA state machine
  localparam [3:0] IDLE                  = 4'd0;
  localparam [3:0] INIT                  = 4'd1;
  localparam [3:0] REQUEST_BUS           = 4'd2;
  localparam [3:0] SET_UP_TRANSACTION    = 4'd3;
  localparam [3:0] DO_READ               = 4'd4;
  localparam [3:0] WAIT_END              = 4'd5;
  localparam [3:0] DO_WRITE              = 4'd6;
  localparam [3:0] END_TRANSACTION_ERROR = 4'd7;
  localparam [3:0] END_WRITE_TRANSACTION = 4'd8;

  reg [3:0] dmaState_r, dmaNextState_s;
  reg       busError_r;
  reg       isReadBurst_r;
  reg [8:0] wordsWritten_r;

  wire requestDmaIn_s  = (valueA[12:9] == 4'b1011) ? isMyCi_s &  valueB[0] & ~valueB[1] : 1'b0;
  wire requestDmaOut_s = (valueA[12:9] == 4'b1011) ? isMyCi_s & ~valueB[0] &  valueB[1] : 1'b0;
  wire dmaIsBusy_s     = (dmaState_r == IDLE) ? 1'b0 : 1'b1;
  wire dmaDone_s;

  always @*
    case (dmaState_r)
      IDLE                  : dmaNextState_s <= (requestDmaIn_s == 1'b1 || requestDmaOut_s == 1'b1) ? INIT : IDLE;
      INIT                  : dmaNextState_s <= REQUEST_BUS;
      REQUEST_BUS           : dmaNextState_s <= (transactionGranted == 1'b1) ? SET_UP_TRANSACTION : REQUEST_BUS;
      SET_UP_TRANSACTION    : dmaNextState_s <= (isReadBurst_r == 1'b1) ? DO_READ : DO_WRITE;
      DO_READ               : dmaNextState_s <= (busErrorIn == 1'b1) ? WAIT_END :
                                                (endTransactionIn_r == 1'b1 && dmaDone_s == 1'b1) ? IDLE :
                                                (endTransactionIn_r == 1'b1) ? REQUEST_BUS : DO_READ;
      WAIT_END              : dmaNextState_s <= (endTransactionIn_r == 1'b1) ? IDLE : WAIT_END;
      DO_WRITE              : dmaNextState_s <= (busErrorIn == 1'b1) ? END_TRANSACTION_ERROR :
                                                (wordsWritten_r[8] == 1'b1 && busyIn == 1'b0) ? END_WRITE_TRANSACTION : DO_WRITE;
      END_WRITE_TRANSACTION : dmaNextState_s <= (dmaDone_s == 1'b1) ? IDLE : REQUEST_BUS;
      default               : dmaNextState_s <= IDLE;
    endcase

  always @(posedge clock)
    begin
      dmaState_r    <= (reset == 1'b1) ? IDLE : dmaNextState_s;
      busError_r    <= (reset == 1'b1 || dmaState_r == INIT) ? 1'b0 :
                       (dmaState_r == WAIT_END || dmaState_r == END_TRANSACTION_ERROR) ? 1'b1 : busError_r;
      isReadBurst_r <= (dmaState_r == IDLE) ? requestDmaIn_s : isReadBurst_r;
    end

  // DMA shadow registers
  reg [31:0] busStartAddressShadow_r;
  reg [9:0]  blockSizeShadow_r;
  wire       doBusWrite_s = (dmaState_r == DO_WRITE) ? ~busyIn & ~wordsWritten_r[8] : 1'b0;

  // Second case handles end-of-transaction colliding with the last data-valid
  assign dmaDone_s = (blockSizeShadow_r == 10'd0 ||
                      (blockSizeShadow_r == 10'd1 && endTransactionIn_r == 1'b1 && dataValidIn_r == 1'b1)) ? 1'b1 : 1'b0;
  assign ramCiWriteEnable_s = (dmaState_r == DO_READ) ? dataValidIn_r : 1'b0;

  always @(posedge clock)
    begin
      busStartAddressShadow_r <= (dmaState_r == INIT) ? busStartAddress_r :
                                 (ramCiWriteEnable_s == 1'b1 || doBusWrite_s == 1'b1) ? busStartAddressShadow_r + 32'd4 : busStartAddressShadow_r;
      blockSizeShadow_r       <= (dmaState_r == INIT) ? blockSize_r :
                                 (ramCiWriteEnable_s == 1'b1 || doBusWrite_s == 1'b1) ? blockSizeShadow_r - 10'd1 : blockSizeShadow_r;
      ramCiAddress_r          <= (dmaState_r == INIT) ? memoryStartAddress_r :
                                 (ramCiWriteEnable_s == 1'b1 || doBusWrite_s == 1'b1) ? ramCiAddress_r + 9'd1 : ramCiAddress_r;
    end

  // Bus-out signals
  reg        dataOutValid_r;
  reg [31:0] addressDataOut_r;
  wire [9:0] maxBurstSize_s     = {2'd0,usedBurstSize_r} + 10'd1;
  wire [9:0] restingBlockSize_s = blockSizeShadow_r - 10'd1;
  wire [7:0] usedBurstSize_s    = (blockSizeShadow_r > maxBurstSize_s) ? usedBurstSize_r : restingBlockSize_s[7:0];

  assign requestTransaction = (dmaState_r == REQUEST_BUS) ? 1'd1 : 1'd0;
  assign dataValidOut       = dataOutValid_r;
  assign addressDataOut     = addressDataOut_r;

  always @(posedge clock)
    begin
      beginTransactionOut <= (dmaState_r == SET_UP_TRANSACTION) ? 1'b1 : 1'b0;
      readNotWriteOut     <= (dmaState_r == SET_UP_TRANSACTION) ? isReadBurst_r : 1'b0;
      byteEnablesOut      <= (dmaState_r == SET_UP_TRANSACTION) ? 4'hF : 4'd0;
      burstSizeOut        <= (dmaState_r == SET_UP_TRANSACTION) ? usedBurstSize_s : 8'd0;
      addressDataOut_r    <= (dmaState_r == DO_WRITE && busyIn == 1'b1) ? addressDataOut_r :
                             (doBusWrite_s == 1'b1) ? busRamData_s :
                             (dmaState_r == SET_UP_TRANSACTION) ? {busStartAddressShadow_r[31:2],2'd0} : 32'd0;
      wordsWritten_r      <= (dmaState_r == SET_UP_TRANSACTION) ? {1'b0,usedBurstSize_s} :
                             (doBusWrite_s == 1'b1) ? wordsWritten_r - 9'd1 : wordsWritten_r;
      endTransactionOut   <= (dmaState_r == END_TRANSACTION_ERROR || dmaState_r == END_WRITE_TRANSACTION) ? 1'b1 : 1'b0;
      dataOutValid_r      <= (busyIn == 1'b1 && dmaState_r == DO_WRITE) ? dataOutValid_r : doBusWrite_s;
    end

  // Result mux
  reg [31:0] result_s;

  always @*
    case (valueA[12:10])
      3'b000  : result_s <= sramDataValue_s;
      3'b001  : result_s <= busStartAddress_r;
      3'b010  : result_s <= {23'd0,memoryStartAddress_r};
      3'b011  : result_s <= {22'd0,blockSize_r};
      3'b100  : result_s <= {24'd0,usedBurstSize_r};
      3'b101  : result_s <= {30'd0,busError_r,dmaIsBusy_s};
      default : result_s <= 32'd0;
    endcase

  assign result = (isSramRead_r == 1'b1) ? result_s : 32'd0;

endmodule
