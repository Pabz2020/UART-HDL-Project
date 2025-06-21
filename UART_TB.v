`timescale 1ns/1ps
`include "uart_controller.v"  // Include your UART controller module

module UART_TB();

  reg clk = 0;
  reg reset_n = 0;

  reg [7:0] tx_byte = 0;
  reg       tx_ready = 0;

  wire rx_done;
  wire [7:0] rx_byte;
  wire tx_data;

  // Instantiate your UART controller (use the exact module name you have)
  uart_controller #(
    .CLOCK_RATE(25000000),
    .BAUD_RATE(9600),
    .RX_OVERSAMPLE(16)
  ) uart_inst (
    .clk(clk),
    .reset_n(reset_n),
    .i_Tx_Byte(tx_byte),
    .i_Tx_Ready(tx_ready),
    .o_Rx_Done(rx_done),
    .o_Rx_Byte(rx_byte),
    .o_Tx_Data(tx_data)
  );

  // Clock generation: 25 MHz clock (40 ns period)
  always #20 clk = ~clk;

  integer i;
  reg [7:0] test_data [0:7];  // Sample 8 bytes to test
  reg [7:0] received_data [0:7];

  initial begin
    // Initialize test data
    test_data[0] = 8'h55;
    test_data[1] = 8'hAA;
    test_data[2] = 8'h0F;
    test_data[3] = 8'hF0;
    test_data[4] = 8'h33;
    test_data[5] = 8'hCC;
    test_data[6] = 8'h99;
    test_data[7] = 8'h66;

    // Apply reset
    reset_n = 0;
    tx_ready = 0;
    #100;
    reset_n = 1;

    // Wait a little for the system to stabilize
    #1000;

    // Send each byte one by one
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge clk);
      tx_byte = test_data[i];
      tx_ready = 1;
      @(posedge clk);
      tx_ready = 0;

      // Wait for the receive done signal
      wait (rx_done == 1);

      // Capture received byte
      received_data[i] = rx_byte;

      // Check correctness
      if (received_data[i] == test_data[i]) begin
        $display("Test Passed for byte %0d: Sent %h, Received %h", i, test_data[i], received_data[i]);
      end else begin
        $display("Test FAILED for byte %0d: Sent %h, Received %h", i, test_data[i], received_data[i]);
      end

      // Wait a bit before sending next byte
      #10000;
    end

    $display("UART Testbench completed.");
    $finish;
  end

endmodule
