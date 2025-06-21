`include "baudRateGenerator.v"
`include "uart_tx_controller.v"
`include "uart_rx_controller.v"

module uart_controller #(parameter CLOCK_RATE = 25000000,  // FPGA clock frequency in Hz
                         parameter BAUD_RATE = 9600,
                         parameter RX_OVERSAMPLE = 16) 

(

    input               clk,
    input               reset_n,
    
    input  [7:0]        i_Tx_Byte,
    input               i_Tx_Ready,
    
    output              o_Rx_Done,
    output [7:0]        o_Rx_Byte,
    
    output              o_Tx_Data
);

    wire w_Rx_ClkTick;
    wire w_Tx_ClkTick;
    wire w_Tx_Data;

    // Instantiate Baud Rate Generator
    baudRateGenerator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE),
        .RX_OVERSAMPLE(RX_OVERSAMPLE)
    ) baud_gen_inst (
        .clk(clk),
        .reset_n(reset_n),
        .o_Rx_ClkTick(w_Rx_ClkTick),
        .o_Tx_ClkTick(w_Tx_ClkTick)
    );

    // Instantiate UART TX Controller
    uart_tx_controller uart_tx_inst (
        .clk(w_Tx_ClkTick),
        .reset_n(reset_n),
        .i_Tx_Byte(i_Tx_Byte),
        .i_Tx_Ready(i_Tx_Ready),
        .o_Tx_Done(),      // Optional to connect if needed
        .o_Tx_Active(),    // Optional to connect if needed
        .o_Tx_Data(w_Tx_Data)
    );

    // Instantiate UART RX Controller
    uart_rx_controller #(
        .RX_OVERSAMPLE(RX_OVERSAMPLE)
    ) uart_rx_inst (
        .clk(w_Rx_ClkTick),
        .reset_n(reset_n),
        .i_Rx_Data(w_Tx_Data),  // Loopback: TX data connected to RX input internally
        .o_Rx_Done(o_Rx_Done),
        .o_Rx_Byte(o_Rx_Byte)
    );

    // Output TX data pin
    assign o_Tx_Data = w_Tx_Data;

endmodule
