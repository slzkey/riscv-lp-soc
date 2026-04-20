`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/20 20:17:28
// Design Name: 
// Module Name: tb_system_top_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_system_top_wrapper();

//信号定义
logic clk;
logic cpu_resetn;
logic uart_rx_out;
logic uart_tx_in;

//实例化system_top模块
system_top_wrapper system_top_inst (
    .clk(clk),
    .cpu_resetn(cpu_resetn),
    .uart_rx_out(uart_rx_out),
    .uart_tx_in(uart_tx_in)
);

//时钟生成
initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

//复位信号生成
initial begin
    //初始化UART in输入为高电平（空闲状态）
    uart_tx_in = 1'b1;
    //初始复位信号为低电平，保持1000ns后释放
    cpu_resetn = 1'b0;
    #1000;
    cpu_resetn = 1'b1;

    //运行50ms后结束仿真
    #50000000;
    $finish;
end

//监视UART out输出信号的变化
//CPU发送数据时，UART out线会被拉低（开始位）
always @(negedge uart_rx_out) begin
    $display("[%0t] UART out Line Pulled Low (Start Bit Detected!)", $time);
end

endmodule
