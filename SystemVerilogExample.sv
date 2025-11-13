module statemachine (
    input  logic clk_i,
    input  logic reset_i,
    input  logic start_i,
    output logic rdy_o,
    output logic load_in_o,
    output logic load_out_o
);

    // State type
    typedef enum logic [1:0] {
        IDLE       = 2'b00,
        READ_IN    = 2'b01,
        WRITE_OUT  = 2'b10
    } states_t;

    // State signal
    states_t state_s;
    // Integer signal
    integer count_i;
    // Unsigned integer signal
    logic [7:0] data_u;

    // Conversion example
    // Converting integer to unsigned logic vector
    always_comb begin
        data_u = logic'(count_i);
    end
    // Converting unsigned logic vector to integer
    always_comb begin
        count_i = int'(data_u);
    end

    // 4-bit counter
    logic [3:0] counter;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            counter <= 4'b0000;
        else begin
            if (counter == 4'b1111) begin
                // Counter reached maximum (15 in decimal)
                counter <= 0; // Optional: reset counter
            end else
                counter <= counter + 1;
        end
    end

    // Variable assignment example
    logic [3:0] x, y, z;
    always_comb begin
        x = y + 1;  // x immediately gets y+1
        z = x + 2;  // z uses the new value of x
    end

    // State transition (sequential)
    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            state_s <= IDLE;
        end else begin
            case (state_s)
                IDLE: begin
                    if (start_i)
                        state_s <= READ_IN;
                end

                READ_IN: begin 
                    state_s <= WRITE_OUT;
                end

                WRITE_OUT: state_s <= IDLE;

                default: state_s <= IDLE;
            endcase
        end
    end

    // Output logic (combinational)
    always_comb begin
        // Default outputs
        rdy_o       = 1'b0;
        load_in_o   = 1'b0;
        load_out_o  = 1'b0;

        case (state_s)
            IDLE:      rdy_o      = 1'b1;
            READ_IN:   load_in_o  = 1'b1;
            WRITE_OUT: load_out_o = 1'b1;
        endcase
    end

endmodule
