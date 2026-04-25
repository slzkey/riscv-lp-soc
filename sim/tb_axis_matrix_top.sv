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
    
    //1. 初始化总线信号，释放复位
    initial begin
        rst_n = 0;
        awaddr = 0;
        awvalid = 0;
        wdata = 0;
        wvalid = 0;
        wstrb = 0;
        bready = 0;
        araddr = 0;
        arvalid = 0;
        rready = 0;
        #50; // 等待100ns后释放复位        
        rst_n = 1;
        #50;
        $display("======================================");
        $display("Test Start. 开始配置矩阵...");
    
    //2. 写入X矩阵
        int i,j;
        for (i=0;i<C_S_AXI_DATA_WIDTH;i++)
        begin
            axi_write(12'h100 + i*4, 2); // 写入X矩阵元素，基地址100地址递增，数据全为2
        end
        //3. 写入A矩阵
        for (i=0;i<C_S_AXI_DATA_WIDTH;i++)
        begin
            axi_write(12'h200 + i*4, 3); // 写入A矩阵元素，基地址200地址递增，数据全为3
        end

        $display("矩阵配置完成，启动加速器进行计算...");
        //4. 启动加速器
        axi_write(12'h000, 32'd1); // 写控制寄存器启动计算，地址000，数据1表示启动
        axi_write(12'h000, 32'd0); // 结束启动脉冲。
        //5. 轮询等待加速器完成
        $$display("/n【TB】等待硬件计算...");
        logic [31:0] read_val=0;
        while (read_val == 0) begin
            axi_read(12'h004, read_val); // 读取状态寄存器，地址004，等待非0表示完成
            @(posedge clk);
        end
        $display("计算完成，读取结果矩阵...");
        $display("======================================");
        //6. 读取结果矩阵P并打印
        $display("结果矩阵P：");
        for (i=0;i<4;i++)begin
            for(j=0;j<4;j++)begin
                axi_read(12'h300 + (i*4 + j)*4, read_val); // 读取结果矩阵元素，基地址300，地址递增
                $display("P[%0d][%0d] = %0d", i, j, read_val);
            end
            $display("");// 换行显示下一行
        end
            $display("======================================");
        $display("Test Finished. 测试完成.结果应该都是48");
    end
endmodule