`timescale 1ns/1ps

// AXI-Lite Slave Wrapper
// 该模块实现了一个矩阵加速器作为AXI-Lite从设备，允许CPU通过AXI-Lite协议与矩阵加速器进行通信。它包含了AXI-Lite协议的握手逻辑，以及寄存器的读写管理。控制器和数据路径模块通过寄存器接口与CPU进行交互，实现矩阵加速器的控制和数据传输。
// 矩阵加速器的功能是执行unsigned 4*8矩阵X(X矩阵元素8bit)与8*4矩阵A（A矩阵元素7bit）进行矩阵乘法运算
// CPU通过写寄存器输入矩阵数据和启动信号，控制器根据状态机控制数据路径进行32周期计算，计算完成后将结果存储在BRAM中供CPU读取，同时通过状态寄存器反馈计算完成的信号。

module axis_matrix_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 12 //3个32位BRAM，寻址空间000-FFF
)   
(
    //时钟与复位
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    // AXI-Lite接口
    //写地址通道
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,//目标地址
    input wire  S_AXI_AWVALID,  //CPU地址有效
    output wire  S_AXI_AWREADY, //外设准备好接收地址

    //写数据通道
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,//写数据
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,//写数据有效字节
    input wire S_AXI_WVALID,  //CPU数据有效
    output wire S_AXI_WREADY, //外设准备好接收数据

    //写响应通道
    output wire [1:0]S_AXI_BRESP,//写响应 00:OKAY 01:EXOKAY 10:SLVERR 11:DECERR
    output wire S_AXI_BVALID, //外设写响应有效
    input wire S_AXI_BREADY, //CPU准备好接收写响应

    //读地址通道
    input wire [C_S_AXI_ADDR_WIDTH-1:0]S_AXI_ARADDR,//目标地址
    input wire S_AXI_ARVALID, //CPU地址有效
    output wire S_AXI_ARREADY, //外设准备好接收地址

    //读数据通道
    output wire [C_S_AXI_DATA_WIDTH-1:0]S_AXI_RDATA,//读数据
    output wire [1:0]S_AXI_RRESP,//读响应 00:OKAY 01:EXOKAY 10:SLVERR 11:DECERR
    output wire S_AXI_RVALID, //外设读数据有效
    input wire S_AXI_RREADY //CPU准备好接收读数据
);
   ///////////////////////////////////////////
    //////////// AXI-Lite协议握手简化 //////////////
    ///////////////////////////////////////////

    //READY&VALID Registers
    logic axi_awready;
    logic axi_wready;
    logic axi_bvalid;
    logic axi_arready;
    logic axi_rvalid;
    //物理引脚绑定寄存器
    //写
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_BRESP = 2'b00; // OKAY
    //读
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RRESP = 2'b00; // OKAY
    assign S_AXI_RVALID = axi_rvalid;

 
    //写通道握手 AW,W,B
    //经典简化：CPU把写地址AWVALID和写数据WVALID同时准备好，从机才拉高READY接收
    always_ff @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0)begin
            axi_awready <= 1'b0;
            axi_wready <= 1'b0;
            axi_bvalid <= 1'b0;
        end
        else begin 
            //1.接受CPU写请求
            //当地址数据VALID都1，且READY都0时，拉高READY接收
            if(~axi_awready && S_AXI_AWVALID && ~axi_wready && S_AXI_WVALID)begin
                axi_awready <= 1'b1;
                axi_wready <= 1'b1;
            end//下一个周期放下READY
            else begin
                axi_awready <= 1'b0;
                axi_wready <= 1'b0;
            end
            //2.回复CPU写响应
            //成功接受写请求但还没发送响应时，拉高BVALID
            if(axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
            end
            //CPU接受响应后放下BVALID
            else if(axi_bvalid && S_AXI_BREADY) begin
                axi_bvalid <= 1'b0;
            end
        end 
    end
    //读通道握手 AR,R
    //CPU把读地址ARVALID准备好，从机拉高ARREADY接收，准备好读数据后拉高RVALID
    always_ff @(posedge S_AXI_ACLK) begin
        if(S_AXI_ARESETN == 1'b0)begin
            axi_arready <= 0;
            axi_rvalid <= 0;
        end else begin
            //1.接受地址
            if(~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0; 
            end
            //2.发送数据
            //当地址有效且从机准备好接收时，拉高RVALID发送数据
            if(axi_arready && S_AXI_ARVALID && ~axi_rvalid)begin
                axi_rvalid <= 1'b1;
            end 
            //CPU接受数据后放下RVALID
            else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    ///////////////////////////////////////
    //寄存器、BRAM管理
    ///////////////////////////////////////
    //controller, datapath互联信号线
    logic start_pulse; //启动信号脉冲
    logic finish_wire; //计算完成信号
    logic ram_wen; //写RAM使能
    logic [4:0] ram_waddr; //写RAM地址
    logic acc_clear; //累加器清零信号
    logic [4:0] x_raddr_0, x_raddr_1; //矩阵X读地址
    logic [4:0] a_raddr_0, a_raddr_1; //矩阵A读
    logic [19:0] mac_result;

    //寄存器声明
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg0; // 地址0x000 CPU可写 控制/状态寄存器 start/finish
    (* ram_style = "block" *) logic [C_S_AXI_DATA_WIDTH-1:0] bram_x [0:31]; // 地址0x100-17F CPU可写 数据输入寄存器 矩阵X
    (* ram_style = "block" *) logic [C_S_AXI_DATA_WIDTH-1:0] bram_a [0:31];// 地址0x200-27F CPU可写 数据输入寄存器 系数矩阵A
    (* ram_style = "block" *) logic [C_S_AXI_DATA_WIDTH-1:0] bram_p [0:15];// 地址0x300-37F CPU可读 结果寄存器 结果矩阵P
    
    assign start_pulse = slv_reg0[0];
    
    //写控制寄存器
    always_ff @(posedge S_AXI_ACLK)begin
        if (!S_AXI_ARESETN)
            slv_reg0 <=0;
        else if (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID && S_AXI_AWADDR [11:8] == 0)
            slv_reg0 <= S_AXI_WDATA; //控制寄存器reg0
    end

    //BRAM分配逻辑
    //BRAM_X地址0x100-17F，BRAM_A地址0x200-27F，A口分时复用读、CPU写，B口仅读
    //计算中外设读写BRAM，硬件忙，CPU无法读写。
    logic hw_busy;
    always_ff@(posedge S_AXI_ACLK)begin
        if(!S_AXI_ARESETN) hw_busy<=1'b0;
        else if(start_pulse) hw_busy <=1'b1;
        else if(finish_wire) hw_busy <=1'b0;
    end
   
    logic [4:0] x_addr_a; logic x_we; logic [C_S_AXI_DATA_WIDTH-1:0] x_dout_0, x_dout_1;
    logic [4:0] a_addr_a; logic a_we; logic [C_S_AXI_DATA_WIDTH-1:0] a_dout_0, a_dout_1;
     //BRAM_X
    assign x_addr_a = (hw_busy) ? x_raddr_0 : S_AXI_AWADDR[6:2]; //计算中用controller提供地址，空闲时CPU写寄存器提供地址
    assign x_we = (hw_busy) ? 1'b0 : (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID && S_AXI_AWADDR[11:8] == 1); //计算中禁止写，空闲时CPU写寄存器提供写使能
    always_ff @(posedge S_AXI_ACLK)begin
       if(x_we) bram_x[x_addr_a] <= S_AXI_WDATA; //CPU写数据到BRAM_X
       x_dout_0 <= bram_x[x_addr_a];
       x_dout_1 <= bram_x[x_raddr_1];
    end 

    //BRAM_A 同BRAM_X
    assign a_addr_a = (hw_busy) ? a_raddr_0 : S_AXI_AWADDR[6:2];
    assign a_we = (hw_busy) ? 1'b0 : (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID && S_AXI_AWADDR[11:8] == 2);
    always_ff @(posedge S_AXI_ACLK)begin
       if(a_we) bram_a[a_addr_a] <= S_AXI_WDATA; //CPU写数据到BRAM_A
       a_dout_0 <= bram_a[a_addr_a];
       a_dout_1 <= bram_a[a_raddr_1];
    end

    //BRAM_p读写
    logic [C_S_AXI_DATA_WIDTH-1:0] p_dout_cpu; //数据路径输出结果寄存器
    always_ff @(posedge S_AXI_ACLK)begin
        if (ram_wen) bram_p[ram_waddr[3:0]] <= {12'b0,mac_result};//写结果到BRAM_p，假设结果是20bit，放在低20位
        p_dout_cpu <= bram_p[S_AXI_ARADDR[5:2]]; //CPU读结果寄存器
    end


    //读寄存器分配
    //读寄存器声明
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    assign S_AXI_RDATA = axi_rdata;
    //增加完成信号寄存器
    logic finish_reg;
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN || start_pulse) 
            finish_reg <= 1'b0;          // 收到复位或新的启动脉冲时清零
        else if (finish_wire) 
            finish_reg <= 1'b1;          // 抓到完成脉冲后，一直保持高电平
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else if(axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
            case (S_AXI_ARADDR[11:8])
                    4'h0: axi_rdata <= (S_AXI_ARADDR[4:2] == 3'h1) ? {31'b0, finish_reg} : slv_reg0; //地址为0x004（字索引1）？状态寄存器reg1 ：控制寄存器reg0
                4'h3: axi_rdata <= p_dout_cpu; //CPU读结果矩阵P
                default: axi_rdata <= 0;
            endcase     
        end
    end

    //实例化datapath和controller
    controller u_controller(
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .start(start_pulse),//CPU给的启动命令
        //内部互联
        .acc_clear(acc_clear),
        .ram_wen(ram_wen),
        .ram_waddr(ram_waddr),
        .x_raddr_0(x_raddr_0),
        .x_raddr_1(x_raddr_1),
        .a_raddr_0(a_raddr_0),
        .a_raddr_1(a_raddr_1),

        .finish(finish_wire)//给CPU的完成信号   
);
    datapath u_datapath(
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        //controller控制信号
        .acc_clear(acc_clear),
        .data_x_0(x_dout_0[7:0]), //从BRAM_X读出的矩阵X元素
        .data_x_1(x_dout_1[7:0]),
        .data_a_0(a_dout_0[6:0]), //从BRAM_A读出的矩阵A元素
        .data_a_1(a_dout_1[6:0]),
        .mac_result(mac_result)
    );


endmodule