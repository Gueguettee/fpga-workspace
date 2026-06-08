module i2sReceiver #( parameter [31:0] baseAddress  = 32'h50000060,
                      parameter [6:0]  bclkDivider  = 7'd72 )
                   ( input  wire        clock,
                                        reset,

                     output wire        irq,

                     // bus slave (same protocol as uartBus)
                     input  wire        beginTransactionIn,
                                        endTransactionIn,
                                        readNWriteIn,
                                        dataValidIn,
                                        busyIn,
                     input  wire [31:0] addressDataIn,
                     input  wire  [3:0] byteEnablesIn,
                     input  wire  [7:0] burstSizeIn,
                     output wire [31:0] addressDataOut,
                     output reg         endTransactionOut,
                     output wire        dataValidOut,
                     output reg         busErrorOut,

                     // I2S external pins (FPGA is master)
                     output wire        i2sBclkOut,
                     output wire        i2sWsOut,
                     input  wire        i2sDataIn );

  // ===================================================================
  // Bus slave: same handshake as modules/uart/verilog/uartBus.v
  // ===================================================================
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] WAIT = 2'b01;
  localparam [1:0] END  = 2'b10;

  reg  [1:0]  readState_r, readStateNext_s;
  reg         startTransaction_r, transactionActive_r, readNWrite_r;
  reg         dataInValid_r, dataOutValid_r;
  reg  [3:0]  byteEnables_r;
  reg  [7:0]  burstSize_r;
  reg  [31:0] busAddress_r, dataIn_r, dataOut_r;
  wire [31:0] readValue_s;

  // 16-byte window (4 word registers); registers selected by busAddress_r[3:2]
  wire isMyTransaction_s = (transactionActive_r == 1'b1 &&
                            busAddress_r[31:4] == baseAddress[31:4]) ? 1'b1 : 1'b0;
  // word-only access; partial writes or bursts are illegal
  wire isBusError_s = ((byteEnables_r != 4'b1111 && readNWrite_r == 1'b0) || burstSize_r != 8'd0)
                      ? isMyTransaction_s : 1'b0;
  wire writeDataOut_s = (readState_r == IDLE && startTransaction_r == 1'b1 &&
                         isMyTransaction_s == 1'b1 && readNWrite_r == 1'b1) ? 1'b1 : 1'b0;
  wire resetDataOut_s = (reset == 1'b1 || (readState_r == WAIT && busyIn == 1'b0)) ? 1'b1 : 1'b0;

  assign dataValidOut   = dataOutValid_r;
  assign addressDataOut = dataOut_r;

  always @(posedge clock) begin
    startTransaction_r  <= (reset == 1'b1) ? 1'b0 : beginTransactionIn;
    transactionActive_r <= (reset == 1'b1 || endTransactionIn == 1'b1) ? 1'b0 :
                           (beginTransactionIn == 1'b1) ? 1'b1 : transactionActive_r;
    readNWrite_r        <= (reset == 1'b1) ? 1'b0 :
                           (beginTransactionIn == 1'b1) ? readNWriteIn : readNWrite_r;
    byteEnables_r       <= (reset == 1'b1) ? 4'd0 :
                           (beginTransactionIn == 1'b1) ? byteEnablesIn : byteEnables_r;
    burstSize_r         <= (reset == 1'b1) ? 8'd0 :
                           (beginTransactionIn == 1'b1) ? burstSizeIn : burstSize_r;
    busAddress_r        <= (reset == 1'b1) ? 32'd0 :
                           (beginTransactionIn == 1'b1) ? addressDataIn : busAddress_r;
    dataIn_r            <= (reset == 1'b1) ? 32'd0 :
                           (dataValidIn == 1'b1) ? addressDataIn : dataIn_r;
    dataInValid_r       <= (reset == 1'b1) ? 1'b0 :
                           dataValidIn & isMyTransaction_s & ~isBusError_s & ~readNWrite_r;
    dataOut_r           <= (resetDataOut_s == 1'b1) ? 32'd0 :
                           (writeDataOut_s == 1'b1) ? readValue_s : dataOut_r;
    dataOutValid_r      <= (resetDataOut_s == 1'b1) ? 1'b0 :
                           (writeDataOut_s == 1'b1) ? 1'b1 : dataOutValid_r;
    readState_r         <= (reset == 1'b1) ? IDLE : readStateNext_s;
    endTransactionOut   <= (reset == 1'b1) ? 1'b0 : (readState_r == END) ? 1'b1 : 1'b0;
    busErrorOut         <= (reset == 1'b1 || endTransactionIn == 1'b1) ? 1'b0 : isBusError_s;
  end

  always @* begin
    case (readState_r)
      IDLE    : readStateNext_s <= (writeDataOut_s == 1'b1) ? WAIT : IDLE;
      WAIT    : readStateNext_s <= (busyIn == 1'b1) ? WAIT : END;
      default : readStateNext_s <= IDLE;
    endcase
  end

  // ===================================================================
  // Register decode
  //   offset 0x0  STATUS  (R)  bit0=sample-avail, bit1=overrun, bits[12:7]=fill
  //   offset 0x4  SAMPLE  (R)  read dequeues; [15:0]=sample, [31:16]=counter
  //   offset 0x8  CTRL    (W)  bit0=enable, bit1=clear-fifo+overrun, bit2=irq-en
  //   offset 0xC  reserved
  // ===================================================================
  wire [1:0] regSel_s = busAddress_r[3:2];
  wire writeEnable_s  = dataInValid_r;

  reg  enable_r;
  reg  irqEnable_r;
  // bit-1 of CTRL is a single-cycle pulse (clear FIFO + clear overrun)
  wire ctrlWrite_s    = writeEnable_s && (regSel_s == 2'd2);
  wire clearPulse_s   = ctrlWrite_s && dataIn_r[1];

  always @(posedge clock) begin
    if (reset == 1'b1) begin
      enable_r    <= 1'b0;
      irqEnable_r <= 1'b0;
    end else if (ctrlWrite_s) begin
      enable_r    <= dataIn_r[0];
      irqEnable_r <= dataIn_r[2];
    end
  end

  // ===================================================================
  // I2S master clock generation
  //   BCLK period = bclkDivider system cycles (default 72 → ~1.03 MHz @ 74.25 MHz)
  //   WS toggles every 32 BCLK rising edges → frame = 64 BCLK → Fs ≈ 16.1 kHz
  // ===================================================================
  // BCLK has a 50% duty cycle; with an odd divisor the high phase is one cycle longer
  localparam [6:0] HALF_DIV = bclkDivider >> 1;
  localparam [6:0] HALF_HIT = HALF_DIV - 7'd1;
  localparam [6:0] FULL_HIT = bclkDivider - 7'd1;

  reg [6:0] phase_r;        // 0..bclkDivider-1
  reg       bclk_r;
  reg [5:0] frameCnt_r;     // 0..63 BCLK rising edges within one frame

  wire halfPeriodHit_s = (phase_r == HALF_HIT);
  wire periodEnd_s     = (phase_r == FULL_HIT);
  // sampleEdge_s strobes on the system cycle ENDING with BCLK going low→high
  wire sampleEdge_s    = halfPeriodHit_s && (bclk_r == 1'b0);

  always @(posedge clock) begin
    if (reset == 1'b1 || enable_r == 1'b0) begin
      phase_r    <= 7'd0;
      bclk_r     <= 1'b0;
      frameCnt_r <= 6'd0;
    end else begin
      phase_r <= periodEnd_s ? 7'd0 : phase_r + 7'd1;
      // BCLK has 50% duty: high during second half, low during first half
      if (halfPeriodHit_s)
        bclk_r <= ~bclk_r;
      else if (periodEnd_s)
        bclk_r <= 1'b0;
      // frameCnt advances at each BCLK rising edge
      if (sampleEdge_s)
        frameCnt_r <= (frameCnt_r == 6'd63) ? 6'd0 : frameCnt_r + 6'd1;
    end
  end

  // WS = MSB of frame counter: low for slot 0 (bits 0..31), high for slot 1
  // L/R-select on mic tied to GND → mic transmits during WS=low slot
  wire ws_s = frameCnt_r[5];

  assign i2sBclkOut = bclk_r;
  assign i2sWsOut   = ws_s;

  // ===================================================================
  // Data capture: 2-flop synchronizer, 24-bit shift register
  //   sampleEdge_s strobes the cycle BEFORE the BCLK rising edge that bumps
  //   frameCnt_r, so the comparator below sees the OLD frameCnt value:
  //   MSB sits on DATA when old frameCnt_r == 0, LSB when old == 23.
  // ===================================================================
  reg syncData_r0, syncData_r1;
  always @(posedge clock) begin
    syncData_r0 <= i2sDataIn;
    syncData_r1 <= syncData_r0;
  end

  reg [23:0] shift_r;
  wire shiftEn_s    = sampleEdge_s && (frameCnt_r <= 6'd23);
  wire pushSample_s = sampleEdge_s && (frameCnt_r == 6'd24);

  always @(posedge clock) begin
    if (reset == 1'b1 || enable_r == 1'b0)
      shift_r <= 24'd0;
    else if (shiftEn_s)
      shift_r <= {shift_r[22:0], syncData_r1};
  end

  reg [15:0] sampleCounter_r;
  always @(posedge clock) begin
    if (reset == 1'b1 || clearPulse_s)
      sampleCounter_r <= 16'd0;
    else if (pushSample_s)
      sampleCounter_r <= sampleCounter_r + 16'd1;
  end

  // ===================================================================
  // 32-deep × 32-bit FIFO  (low 16 = sample, high 16 = counter)
  // ===================================================================
  reg  [31:0] fifoMem_r [0:31];
  reg  [4:0]  wrPtr_r, rdPtr_r;
  reg  [5:0]  fifoCount_r;
  wire        fifoEmpty_s = (fifoCount_r == 6'd0);
  wire        fifoFull_s  = (fifoCount_r == 6'd32);

  wire [31:0] sampleWord_s = {sampleCounter_r, shift_r[23:8]};

  wire fifoWe_s = pushSample_s && !fifoFull_s;
  wire fifoRe_s = writeDataOut_s && (busAddress_r[3:2] == 2'd1) && !fifoEmpty_s;

  always @(posedge clock) begin
    if (reset == 1'b1 || clearPulse_s) begin
      wrPtr_r     <= 5'd0;
      rdPtr_r     <= 5'd0;
      fifoCount_r <= 6'd0;
    end else begin
      if (fifoWe_s) begin
        fifoMem_r[wrPtr_r] <= sampleWord_s;
        wrPtr_r <= wrPtr_r + 5'd1;
      end
      if (fifoRe_s)
        rdPtr_r <= rdPtr_r + 5'd1;
      case ({fifoWe_s, fifoRe_s})
        2'b10  : fifoCount_r <= fifoCount_r + 6'd1;
        2'b01  : fifoCount_r <= fifoCount_r - 6'd1;
        default: ;
      endcase
    end
  end

  wire [31:0] fifoHead_s = fifoMem_r[rdPtr_r];

  // overrun: sticky bit set when a new sample is pushed but FIFO is full
  reg overrun_r;
  wire overrunNow_s = pushSample_s && fifoFull_s;
  always @(posedge clock) begin
    if (reset == 1'b1 || clearPulse_s)
      overrun_r <= 1'b0;
    else if (overrunNow_s)
      overrun_r <= 1'b1;
  end

  // ===================================================================
  // Read mux + IRQ
  // ===================================================================
  reg [31:0] readMux_r;
  always @* begin
    case (regSel_s)
      2'd0    : readMux_r <= {24'd0, fifoCount_r, overrun_r, ~fifoEmpty_s};
      2'd1    : readMux_r <= fifoEmpty_s ? 32'd0 : fifoHead_s;
      default : readMux_r <= 32'd0;
    endcase
  end
  assign readValue_s = readMux_r;

  // IRQ asserts when half-full or more, gated by enable bit in CTRL
  assign irq = irqEnable_r && (fifoCount_r >= 6'd16);

endmodule
