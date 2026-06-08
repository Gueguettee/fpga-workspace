`timescale 1ns/1ps

module profiling_tb;

    localparam CUSTOM_ID = 8'd8;
    localparam CLK_PERIOD = 10;

    reg        clock, reset, start, stall, busIdle;
    reg [31:0] valueA, valueB;
    reg [7:0]  ciN;
    wire       done;
    wire [31:0] result;

    integer pass_count = 0;
    integer fail_count = 0;

    profileCi #(.customId(CUSTOM_ID)) dut (
        .start(start),
        .clock(clock),
        .reset(reset),
        .stall(stall),
        .busIdle(busIdle),
        .valueA(valueA),
        .valueB(valueB),
        .ciN(ciN),
        .done(done),
        .result(result)
    );

    always #(CLK_PERIOD/2) clock = ~clock;

    task ci_call(input [31:0] a, input [31:0] b, input [7:0] n);
        begin
            @(negedge clock);
            valueA = a;
            valueB = b;
            ciN = n;
            start = 1;
            @(negedge clock);
            start = 0;
            valueA = 0;
            valueB = 0;
            ciN = 0;
        end
    endtask

    task check(input condition, input [255:0] name);
        begin
            if (condition) begin
                $display("PASS: %0s", name);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %0s", name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clock = 0; reset = 0; start = 0; stall = 0; busIdle = 0;
        valueA = 0; valueB = 0; ciN = 0;

        @(negedge clock);
        reset = 1;
        repeat(3) @(negedge clock);
        reset = 0;
        @(negedge clock);

        check(done == 0, "done=0 when idle");
        check(result == 32'd0, "result=0 when idle");

        // Enable all counters and let them run
        ci_call(32'd0, 32'h0F, CUSTOM_ID);
        repeat(10) @(negedge clock);

        // Read counter0
        ci_call(32'd0, 32'd0, CUSTOM_ID);
        @(negedge clock);
        valueA = 32'd0; valueB = 32'd0; ciN = CUSTOM_ID; start = 1;
        #1;
        check(done == 1, "done=1 during CI call");
        check(result > 0, "counter0 has counted (>0)");
        $display("  counter0 value = %0d", result);
        @(negedge clock);
        start = 0; ciN = 0;

        // Enable stall counter, generate stall cycles, read back
        ci_call(32'd0, 32'h02, CUSTOM_ID);
        stall = 1;
        repeat(5) @(negedge clock);
        stall = 0;
        repeat(5) @(negedge clock);

        @(negedge clock);
        valueA = 32'd1; valueB = 32'd0; ciN = CUSTOM_ID; start = 1;
        #1;
        check(result > 0, "counter1 counted stall cycles");
        $display("  counter1 (stall) value = %0d", result);
        @(negedge clock);
        start = 0; ciN = 0;

        // Enable busIdle counter, generate busIdle cycles, read back
        ci_call(32'd0, 32'h04, CUSTOM_ID);
        busIdle = 1;
        repeat(8) @(negedge clock);
        busIdle = 0;
        repeat(4) @(negedge clock);

        @(negedge clock);
        valueA = 32'd2; valueB = 32'd0; ciN = CUSTOM_ID; start = 1;
        #1;
        check(result > 0, "counter2 counted busIdle cycles");
        $display("  counter2 (busIdle) value = %0d", result);
        @(negedge clock);
        start = 0; ciN = 0;

        // Disable counters, verify counter0 stops
        ci_call(32'd0, 32'h10, CUSTOM_ID);
        repeat(10) @(negedge clock);

        @(negedge clock);
        valueA = 32'd0; valueB = 32'd0; ciN = CUSTOM_ID; start = 1;
        #1;
        begin : disable_check
            reg [31:0] val1;
            val1 = result;
            @(negedge clock);
            start = 0; ciN = 0;
            repeat(5) @(negedge clock);
            @(negedge clock);
            valueA = 32'd0; valueB = 32'd0; ciN = CUSTOM_ID; start = 1;
            #1;
            check(result == val1, "counter0 stopped after disable");
            @(negedge clock);
            start = 0; ciN = 0;
        end

        repeat(2) @(negedge clock);
        $display("");
        $display("================================");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("================================");
        $finish;
    end

    initial begin
        $dumpfile("profiling_tb.vcd");
        $dumpvars(0, profiling_tb);
    end

endmodule
