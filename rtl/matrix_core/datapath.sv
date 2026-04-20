module datapath (
    input logic clk, rst_n,
    //控制信号
    //X(i,a) A(a,j) P(i,j)
    input logic acc_clear,
    //load
    input logic load_en,
    input logic [4:0] load_cnt,
    //mu读X的地址,mu2在此基础上+1
    input logic [4:0] reg_raddr,
    //数据接口
    input logic [7:0] input_data, //X(i,a)
    input logic [13:0] rom_data,
    output logic [31:0] ram_wdata,
    //read验证相关
    input logic read_ram,//读ram信号
    output logic [8:0] ram_raddr,//给ram的读地址
    input logic [31:0] ram_rdata,//从ram读出的数据
    output logic [8:0]  read_data_out//给tb的读数据
);

logic [7:0] input_regs[0:31];
always_ff @(posedge clk)begin
    if(load_en)begin
        input_regs[load_cnt]<=input_data;
    end
end
//数据解包
//x(i,a)
logic [7:0] x1, x2;
logic [7:0] reg_raddr_1;
assign reg_raddr_1 = reg_raddr + 5'b1;
assign x1 = input_regs[reg_raddr];
assign x2 = input_regs[reg_raddr_1];
//a(a,j)
logic [6:0] a1, a2;
assign a1 = rom_data[13:7];
assign a2 = rom_data[6:0];
//乘加单元
//乘
logic[15:0] mul1_out, mul2_out;
assign mul1_out = x1 * a1;
assign mul2_out = x2 * a2;
//累加
logic [19:0]acc_reg, current_product_sum;
assign current_product_sum =mul1_out+  mul2_out;
always_ff @(posedge clk)begin
    if(!rst_n )begin
        acc_reg <= 20'b0;
    end
    else if(acc_clear) begin
        acc_reg <= current_product_sum;
    end
    else begin
        acc_reg <= current_product_sum + acc_reg;
    end
end
//输出
 assign ram_wdata = {12'b0,(acc_reg + current_product_sum)};
//read验证相关
logic byte_sel = 1'b0;//高低位选择信号 0高 1低
logic [8:0] ram_raddr_reg;//读地址寄存器
  logic ram_data_dly=1'b0;
  
assign ram_raddr = ram_raddr_reg;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        ram_raddr_reg <= 9'b0;
        byte_sel <= 1'b0;
      	ram_data_dly <=1'b0;
    end
  else if(read_ram) begin
        byte_sel <= ~byte_sel;
    	ram_data_dly <=1'b1;
        if(byte_sel) begin
            ram_raddr_reg <= ram_raddr_reg + 1;
        end
    end
  else begin
    byte_sel <=1'b0;
    ram_data_dly <=1'b0;
  end
 
end
always_comb begin
    if(ram_data_dly) begin
      if(!byte_sel) begin
            read_data_out = ram_rdata[8:0];//低9位
        $display("read low of addr %d, data %d.", ram_raddr_reg-1, read_data_out);
      end
      else begin
            read_data_out = ram_rdata[17:9];//高9位
      $display("read high of addr %d, data %d.", ram_raddr_reg, read_data_out);
      end
    end
    else
        read_data_out = 9'b0;
end

// 放在 datapath 模块内部最后面
// 调试逻辑：当加载结束时，打印前几个寄存器的值
always @(negedge load_en) begin
    $display("===== DEBUG: Check Input Regs =====");
    $display("Reg[0] = %d", input_regs[0]);
    $display("Reg[1] = %d", input_regs[1]);
    $display("Reg[2] = %d", input_regs[2]);
    $display("Reg[3] = %d", input_regs[3]);
    $display("===================================");
end

// 调试逻辑：打印每次读取的地址和结果
always @(posedge clk) begin
    if (!acc_clear) begin // 在计算期间
        $display("Time: %0t | Addr: %d | x1: %d | x2: %d", $time, reg_raddr, x1, x2);
    end
end

endmodule