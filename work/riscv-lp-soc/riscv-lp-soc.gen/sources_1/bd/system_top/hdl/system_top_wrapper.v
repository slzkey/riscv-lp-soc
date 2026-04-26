//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
//Date        : Sun Apr 26 16:10:03 2026
//Host        : slzkey_Air running 64-bit major release  (build 9200)
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_wrapper
   (btnc,
    clk,
    cpu_resetn,
    uart_rx_out,
    uart_tx_in);
  input btnc;
  input clk;
  input cpu_resetn;
  output uart_rx_out;
  input uart_tx_in;

  wire btnc;
  wire clk;
  wire cpu_resetn;
  wire uart_rx_out;
  wire uart_tx_in;

  system_top system_top_i
       (.btnc(btnc),
        .clk(clk),
        .cpu_resetn(cpu_resetn),
        .uart_rx_out(uart_rx_out),
        .uart_tx_in(uart_tx_in));
endmodule
