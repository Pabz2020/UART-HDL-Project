/*
 UART RX Controller
 Receives serial UART data bits and outputs received byte

 Inputs:
 - clk        : Oversampled baud rate clock tick (e.g., 16x baud)
 - reset_n    : Active-low asynchronous reset
 - i_Rx_Data  : Serial UART RX input line

 Outputs:
 - o_Rx_Done  : Pulses high for 1 clock tick when a full byte is received
 - o_Rx_Byte  : The received 8-bit data byte
*/

module uart_rx_controller #(parameter RX_OVERSAMPLE = 16)(
    input        clk,
    input        reset_n,
    input        i_Rx_Data,
    output       o_Rx_Done,
    output [7:0] o_Rx_Byte
);

    // UART RX states
    localparam UART_RX_IDLE  = 3'b000;
    localparam UART_RX_START = 3'b001;
    localparam UART_RX_DATA  = 3'b010;
    localparam UART_RX_STOP  = 3'b011;

    reg [7:0]  r_Rx_Data    = 8'd0;
    reg [2:0]  r_Bit_Index  = 3'd0;
    reg [4:0]  r_Clk_Count  = 5'd0;
    reg        r_Rx_Done    = 1'b0;
    reg [2:0]  r_State      = UART_RX_IDLE;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_State      <= UART_RX_IDLE;
            r_Bit_Index  <= 3'd0;
            r_Clk_Count  <= 5'd0;
            r_Rx_Done    <= 1'b0;
            r_Rx_Data    <= 8'd0;
        end else begin
            case (r_State)
                UART_RX_IDLE: begin
                    r_Rx_Done <= 1'b0;
                    r_Clk_Count <= 5'd0;
                    r_Bit_Index <= 3'd0;
                    if (i_Rx_Data == 1'b0) // Start bit detected (line goes low)
                        r_State <= UART_RX_START;
                end

                UART_RX_START: begin
                    if (r_Clk_Count == RX_OVERSAMPLE/2) begin
                        // Sample in middle of start bit
                        if (i_Rx_Data == 1'b0) begin
                            r_Clk_Count <= 5'd0;
                            r_State <= UART_RX_DATA;
                        end else
                            r_State <= UART_RX_IDLE; // False start bit
                    end else
                        r_Clk_Count <= r_Clk_Count + 1;
                end

                UART_RX_DATA: begin
                    if (r_Clk_Count < RX_OVERSAMPLE - 1) begin
                        r_Clk_Count <= r_Clk_Count + 1;
                    end else begin
                        r_Clk_Count <= 5'd0;
                        r_Rx_Data[r_Bit_Index] <= i_Rx_Data;
                        if (r_Bit_Index < 7) begin
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_State <= UART_RX_DATA;
                        end else begin
                            r_Bit_Index <= 3'd0;
                            r_State <= UART_RX_STOP;
                        end
                    end
                end

                UART_RX_STOP: begin
                    if (r_Clk_Count < RX_OVERSAMPLE - 1) begin
                        r_Clk_Count <= r_Clk_Count + 1;
                    end else begin
                        r_State <= UART_RX_IDLE;
                        r_Clk_Count <= 5'd0;
                        r_Rx_Done <= 1'b1;  // Byte received!
                    end
                end

                default: r_State <= UART_RX_IDLE;
            endcase
        end
    end

    assign o_Rx_Done = r_Rx_Done;
    assign o_Rx_Byte = r_Rx_Done ? r_Rx_Data : 8'h00;

endmodule
