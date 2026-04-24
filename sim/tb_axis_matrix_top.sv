`timescale 1ns/1ps

module tb_axis_matrix_top;

    //参数定义
    parameter integer C_S_AXI_DATA_WIDTH =32;
    parameter integer C_S_AXI_ADDR_WIDTH =12;
 
    //时钟与复位
    logic clk;
    logic rst_n;

    // AXI-Lite接口
    logic [C_S_AXI_ADDR_WIDTH-1:0] awaddr;
    logic awvalid, awready;
    logic [C_S_AXI_DATA_WIDTH-1:0] wdata;
    logic [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb;
    logic wvalid, wready;
    logic [1:0] bresp;
    logic bvalid, bready;
    logic [C_S_AXI_ADDR_WIDTH-1:0] araddr;
    logic arvalid, arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid, rready;

    //实例化被测模块
    axis_matrix_top #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) u_axis_matrix_top (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(awaddr),
        .S_AXI_AWVALID(awvalid),
        .S_AXI_AWREADY(awready),
        .S_AXI_WDATA(wdata),
        .S_AXI_WSTRB(wstrb),
        .S_AXI_WVALID(wvalid),
        .S_AXI_WREADY(wready),
        .S_AXI_BRESP(bresp),
        .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),
        .S_AXI_ARADDR(araddr),
        .S_AXI_ARVALID(arvalid),
        .S_AXI_ARREADY(arready),
        .S_AXI_RDATA(rdata),
        .S_AXI_RRESP(rresp),
        .S_AXI_RVALID(rvalid),
        .S_AXI_RREADY(rready)
    );

    //时钟生成 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz时钟
    end

    //虚拟CPU： AXI-Lite主设备模拟 读写task

    //AXI写操作：先写地址，再写数据，最后等待写响应
    task axi_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr <= addr;
            awvalid <= 1;
            wdata <= data;
            wvalid <= 1;
            wstrb <= 4'b1111; // 全字节有效
            bready <= 1;

            //等待从机握手接受
            wait (awready && wready); // 等待地址和数据被接受
            @(posedge clk);
            awvalid <= 0;
            wvalid <= 0;

            //等待从机写响应
            wait (bvalid); // 等待写响应有效
            @(posedge clk);
            bready <= 0; // 接收完写响应后拉低bready
        end
    endtask
    //AXI读操作：先写地址，然后等待读数据和读响应
    task axi_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr <= addr;
            arvalid <= 1;
            rready <= 1;

            //等待从机握手接受
            wait (arready); // 等待地址被接受
            @(posedge clk);
            arvalid <= 0;

            //等待从机读数据和读响应
            wait (rvalid); // 等待读数据有效
            data <= rdata;
            @(posedge clk);
            rready <= 0; // 接收完读数据后拉低rready
        end
    endtask

    //主测试序列


endmodule