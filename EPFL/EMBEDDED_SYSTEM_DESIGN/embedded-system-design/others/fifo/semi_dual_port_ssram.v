
module semiDualPortSSRAM #( 
        parameter bitwidth = 8,
        parameter nrOfEntries = 512 )
    ( 
        input wire clock,
        input wire writeEnable,
        input wire [$clog2(nrOfEntries)-1 : 0] addressRead, addressWrite,
        input wire [bitwidth-1 : 0] dataIn,
        output reg [bitwidth-1 : 0] dataOut
    );

    reg [bitwidth-1 : 0] memoryContent [nrOfEntries-1 : 0];

    always @(posedge clock)
    begin
        dataOut = memoryContent[addressRead];
        if (writeEnable == 1'b1) 
            memoryContent[addressWrite] = dataIn;
    end

endmodule
