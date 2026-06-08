module ramDmaCi #( parameter [7:0] customId = 8'h00 )
  ( input  wire        start,
    clock,
    reset,
    input  wire [31:0] valueA,
    valueB,
    input  wire [7:0]  ciN,
    output wire        done,
    output wire [31:0] result,
    // bus master interface
    output wire        requestBus,
    input  wire        busGrant,
    // bus inputs (registered internally per spec)
    input  wire        beginTransactionIn,
    input  wire        endTransactionIn,
    input  wire        dataValidIn,
    input  wire        busErrorIn,
    input  wire        busyIn,
    input  wire [31:0] addressDataIn,
    input  wire [3:0]  byteEnablesIn,
    input  wire [7:0]  burstSizeIn,
    // bus outputs (registered)
    output reg         beginTransactionOut,
    output reg  [31:0] addressDataOut,
    output reg         endTransactionOut,
    output reg  [3:0]  byteEnablesOut,
    output reg  [7:0]  burstSizeOut,
    output reg         readNotWriteOut,
    output reg         dataValidOut );

  reg        dataValid_r, busError_r, beginTrans_r, endTrans_r, busy_r;
  reg [31:0] addressData_r;
  reg [3:0]  byteEnables_r;
  reg [7:0]  burstSize_r;

  always @(posedge clock)
  begin
    dataValid_r   <= dataValidIn;
    busError_r    <= busErrorIn;
    beginTrans_r  <= beginTransactionIn;
    endTrans_r    <= endTransactionIn;
    busy_r        <= busyIn;
    addressData_r <= addressDataIn;
    byteEnables_r <= byteEnablesIn;
    burstSize_r   <= burstSizeIn;
  end

  wire        isMyCi_s      = (ciN == customId) & start;
  wire        validCiOp_s   = (valueA[31:13] == 19'd0);
  wire        isCiOp_s      = isMyCi_s & validCiOp_s;
  wire [2:0]  regSel_s      = valueA[12:10];
  wire        wenable_s     = valueA[9];

  wire        isMemOp_s     = isCiOp_s & (regSel_s == 3'd0);
  wire        write_s       = isMemOp_s & wenable_s;
  wire        read_s        = isCiOp_s  & ~wenable_s;
  wire        invalidMyCi_s = isMyCi_s  & ~validCiOp_s;

  // DMA configuration registers
  reg [31:0] dmaBaseAddr_r;    // bus start address for DMA
  reg [8:0]  dmaMemAddr_r;     // CI-memory start address
  reg [9:0]  dmaBlockSize_r;   // total words to transfer
  reg [7:0]  dmaBurstSize_r;   // words-per-burst minus one
  reg [1:0]  dmaStatus_r;      // [1]=busError, [0]=active
  reg        dmaDirWrite_r;    // 0=bus->CI (read), 1=CI->bus (write)

  localparam [2:0] IDLE        = 3'd0;
  localparam [2:0] REQ_BUS     = 3'd1;
  localparam [2:0] INIT_BURST  = 3'd2;
  localparam [2:0] DO_BURST    = 3'd3;
  localparam [2:0] END_ERR     = 3'd4;
  localparam [2:0] END_TRANS_W = 3'd5;

  reg [2:0] dmaState_r, dmaStateNext;

  // Running transfer pointers and counters
  reg [31:0] dmaBusPtr_r;      // current bus address (increments by 4 per word)
  reg [8:0]  dmaMemPtr_r;      // current CI-memory address
  reg [9:0]  dmaWordsLeft_r;   // words remaining in entire transfer
  reg [8:0]  dmaBurstLeft_r;   // words remaining in current burst (write dir)

  // Words to transfer in the next burst
  wire [9:0] bsizePlus1_s     = {2'b0, dmaBurstSize_r} + 10'd1;
  wire [9:0] wordsThisBurst_s = (dmaWordsLeft_r > bsizePlus1_s) ?
       bsizePlus1_s : dmaWordsLeft_r;

  // Transfer finishes on endTrans_r iff the block counter will reach 0 this cycle
  wire allDone_s = (dmaWordsLeft_r == 10'd0) |
                   (dmaWordsLeft_r == 10'd1 & dataValid_r);

  // Start DMA: control reg write with exactly one of valueB[1:0] set, DMA idle, blockSize>0
  wire startDma_s = isCiOp_s & wenable_s & (regSel_s == 3'd5) &
       (valueB[0] ^ valueB[1]) &
       (dmaStatus_r[0] == 1'b0) &
       (dmaBlockSize_r != 10'd0);
  wire startDir_s = valueB[1];

  // pauseWrite_r forces a 1-cycle gap between fires so busy_r can catch busyIn.
  reg pauseWrite_r;
  wire doWrite_s = (dmaState_r == DO_BURST) & dmaDirWrite_r &
                   (dmaBurstLeft_r[8] == 1'b0) & ~busy_r & ~pauseWrite_r;

  always @(posedge clock)
    pauseWrite_r <= (reset == 1'b1) ? 1'b0 : doWrite_s;

  always @*
  case (dmaState_r)
    IDLE       :
      dmaStateNext <= (startDma_s == 1'b1)                           ? REQ_BUS    : IDLE;
    REQ_BUS    :
      dmaStateNext <= (busGrant == 1'b1)                             ? INIT_BURST : REQ_BUS;
    INIT_BURST :
      dmaStateNext <= DO_BURST;
    DO_BURST   :
      dmaStateNext <= (busError_r & endTrans_r)                      ? IDLE        :
                      (busError_r)                                   ? END_ERR     :
                      // Read direction: wait for slave-driven endTrans_r.
                      (~dmaDirWrite_r & endTrans_r & allDone_s)      ? IDLE        :
                      (~dmaDirWrite_r & endTrans_r)                  ? REQ_BUS     :
                      // Write direction: end on own burst counter exhaustion.
                      (dmaDirWrite_r & dmaBurstLeft_r[8])            ? END_TRANS_W :
                                                                       DO_BURST;
    END_ERR    :
      dmaStateNext <= (endTrans_r == 1'b1)                           ? IDLE : END_ERR;
    END_TRANS_W:
      dmaStateNext <= (dmaWordsLeft_r == 10'd0)                      ? IDLE : REQ_BUS;
    default    :
      dmaStateNext <= IDLE;
  endcase

  assign requestBus = (dmaState_r == REQ_BUS);

  // Clocked state and register updates
  always @(posedge clock)
  begin
    dmaState_r     <= (reset == 1'b1) ? IDLE : dmaStateNext;

    dmaBaseAddr_r  <= (reset == 1'b1) ? 32'd0     : (isCiOp_s == 1'b1 && wenable_s == 1'b1 && regSel_s == 3'd1) ? valueB        : dmaBaseAddr_r;
    dmaMemAddr_r   <= (reset == 1'b1) ? 9'd0      : (isCiOp_s == 1'b1 && wenable_s == 1'b1 && regSel_s == 3'd2) ? valueB[8:0]   : dmaMemAddr_r;
    dmaBlockSize_r <= (reset == 1'b1) ? 10'd0     : (isCiOp_s == 1'b1 && wenable_s == 1'b1 && regSel_s == 3'd3) ? valueB[9:0]   : dmaBlockSize_r;
    dmaBurstSize_r <= (reset == 1'b1) ? 8'd0      : (isCiOp_s == 1'b1 && wenable_s == 1'b1 && regSel_s == 3'd4) ? valueB[7:0]   : dmaBurstSize_r;

    // status[0] = active. Cleared on transition back to IDLE.
    dmaStatus_r[0] <= (reset == 1'b1)                                  ? 1'b0 :
                      (startDma_s == 1'b1)                             ? 1'b1 :
                      (dmaState_r != IDLE && dmaStateNext == IDLE)     ? 1'b0 :
                      dmaStatus_r[0];

    // status[1] = bus error
    dmaStatus_r[1] <= (reset == 1'b1)                                  ? 1'b0 :
                      (startDma_s == 1'b1)                             ? 1'b0 :
                      (dmaState_r != IDLE && busError_r == 1'b1)       ? 1'b1 :
                      dmaStatus_r[1];

    dmaDirWrite_r  <= (reset == 1'b1)     ? 1'b0 :
                      (startDma_s == 1'b1) ? startDir_s : dmaDirWrite_r;

    dmaBusPtr_r    <= (reset == 1'b1)                                            ? 32'd0 :
                      (startDma_s == 1'b1)                                       ? dmaBaseAddr_r :
                      (dmaState_r == DO_BURST && ~dmaDirWrite_r && dataValid_r)  ? dmaBusPtr_r + 32'd4 :
                      (doWrite_s == 1'b1)                                        ? dmaBusPtr_r + 32'd4 :
                      dmaBusPtr_r;

    dmaMemPtr_r    <= (reset == 1'b1)                                            ? 9'd0 :
                      (startDma_s == 1'b1)                                       ? dmaMemAddr_r :
                      (dmaState_r == DO_BURST && ~dmaDirWrite_r && dataValid_r)  ? dmaMemPtr_r + 9'd1 :
                      (doWrite_s == 1'b1)                                        ? dmaMemPtr_r + 9'd1 :
                      dmaMemPtr_r;

    dmaWordsLeft_r <= (reset == 1'b1)                                            ? 10'd0 :
                      (startDma_s == 1'b1)                                       ? dmaBlockSize_r :
                      (dmaState_r == DO_BURST && ~dmaDirWrite_r && dataValid_r)  ? dmaWordsLeft_r - 10'd1 :
                      (doWrite_s == 1'b1)                                        ? dmaWordsLeft_r - 10'd1 :
                      dmaWordsLeft_r;

    // Write-direction per-burst word counter
    dmaBurstLeft_r <= (reset == 1'b1)                  ? 9'd0 :
                      (dmaState_r == INIT_BURST)       ? {1'b0, wordsThisBurst_s[7:0] - 8'd1} :
                      (doWrite_s == 1'b1)              ? dmaBurstLeft_r - 9'd1 :
                      dmaBurstLeft_r;

    beginTransactionOut <= (reset == 1'b1) ? 1'b0  : (dmaState_r == INIT_BURST) ? 1'b1           : 1'b0;
    readNotWriteOut     <= (reset == 1'b1) ? 1'b0  : (dmaState_r == INIT_BURST) ? ~dmaDirWrite_r : 1'b0;
    byteEnablesOut      <= (reset == 1'b1) ? 4'd0  : (dmaState_r == INIT_BURST) ? 4'hF           : 4'd0;
    burstSizeOut        <= (reset == 1'b1) ? 8'd0  : (dmaState_r == INIT_BURST) ? wordsThisBurst_s[7:0] - 8'd1 : 8'd0;

    addressDataOut      <= (reset == 1'b1)                                                         ? 32'd0 :
                           (dmaState_r == INIT_BURST)                                              ? dmaBusPtr_r :
                           (doWrite_s == 1'b1)                                                     ? dataOutB_s :
                           (dmaState_r == DO_BURST && dmaDirWrite_r && (busy_r || pauseWrite_r))   ? addressDataOut :
                                                                                                     32'd0;

    dataValidOut        <= (reset == 1'b1)                                                         ? 1'b0 :
                           (doWrite_s == 1'b1)                                                     ? 1'b1 :
                           (dmaState_r == DO_BURST && dmaDirWrite_r && (busy_r || pauseWrite_r))   ? dataValidOut :
                                                                                                     1'b0;

    endTransactionOut   <= (reset == 1'b1) ? 1'b0 : (dmaState_r == END_TRANS_W) ? 1'b1 : 1'b0;
  end

  wire [31:0] memOut_s;
  wire [31:0] dataOutB_s;

  // Port B writes only during a read-direction DMA burst when a bus word arrives.
  wire dmaWriteEn_s = (dmaState_r == DO_BURST) & ~dmaDirWrite_r & dataValid_r;

  sram512X32Dp memA (
                 .clockA      (clock),
                 .writeEnableA(write_s),
                 .addressA    (valueA[8:0]),
                 .dataInA     (valueB),
                 .dataOutA    (memOut_s),
                 .clockB      (~clock),           // negedge of uC clock
                 .writeEnableB(dmaWriteEn_s),
                 .addressB    (dmaMemPtr_r),
                 .dataInB     (addressData_r),
                 .dataOutB    (dataOutB_s) );

  reg readDone_r;

  always @(posedge clock)
    readDone_r <= reset ? 1'b0 : (read_s & ~readDone_r);

  reg [31:0] ciResult_s;
  always @*
  case (regSel_s)
    3'd0    :
      ciResult_s <= memOut_s;
    3'd1    :
      ciResult_s <= dmaBaseAddr_r;
    3'd2    :
      ciResult_s <= {23'd0, dmaMemAddr_r};
    3'd3    :
      ciResult_s <= {22'd0, dmaBlockSize_r};
    3'd4    :
      ciResult_s <= {24'd0, dmaBurstSize_r};
    3'd5    :
      ciResult_s <= {30'd0, dmaStatus_r};
    default :
      ciResult_s <= 32'd0;
  endcase

  assign done   = (isCiOp_s & wenable_s) | readDone_r | invalidMyCi_s;
  assign result = readDone_r ? ciResult_s : 32'd0;

endmodule
