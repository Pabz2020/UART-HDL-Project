

module baudRateGenerator #(
    parameter CLOCK_RATE     = 50000000,   // 50 MHz
    parameter BAUD_RATE      = 9600,
    parameter RX_OVERSAMPLE  = 16
)(
    input  wire clk,         // 50 MHz clock from FPGA (connect to PIN_R20)
    input  wire reset_n,     // active-low reset
    output reg  o_Rx_ClkTick, // tick for RX sampling (16x baud)
    output reg  o_Tx_ClkTick  // tick for TX sending (1x baud)
);

    // Divide clock to generate tick signals
    localparam TX_CNT = CLOCK_RATE / (2 * BAUD_RATE);
    localparam RX_CNT = CLOCK_RATE / (2 * BAUD_RATE * RX_OVERSAMPLE);

    localparam TX_CNT_WIDTH = $clog2(TX_CNT);
    localparam RX_CNT_WIDTH = $clog2(RX_CNT);

    reg [TX_CNT_WIDTH-1:0] r_Tx_Counter = 0;
    reg [RX_CNT_WIDTH-1:0] r_Rx_Counter = 0;

    // TX tick generator (toggles every TX bit duration)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            o_Tx_ClkTick <= 1'b0;
            r_Tx_Counter <= 0;
        end else if (r_Tx_Counter == TX_CNT - 1) begin
            o_Tx_ClkTick <= ~o_Tx_ClkTick;
            r_Tx_Counter <= 0;
        end else begin
            r_Tx_Counter <= r_Tx_Counter + 1;
        end
    end

    // RX tick generator (toggles 16x faster for oversampling)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            o_Rx_ClkTick <= 1'b0;
            r_Rx_Counter <= 0;
        end else if (r_Rx_Counter == RX_CNT - 1) begin
            o_Rx_ClkTick <= ~o_Rx_ClkTick;
            r_Rx_Counter <= 0;
        end else begin
            r_Rx_Counter <= r_Rx_Counter + 1;
        end
    end

endmodule
