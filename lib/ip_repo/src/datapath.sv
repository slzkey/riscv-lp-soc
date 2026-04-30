module datapath (
    input logic clk, rst_n,
    //控制信号
    //X(i,a) A(a,j) P(i,j)
    input logic acc_clear,
    //数据接口
    input logic [31:0] data_x_0,
    input logic [31:0] data_x_1,
    input logic [31:0] data_a_0,
    input logic [31:0] data_a_1,

    output logic [31:0]  mac_result//输出结果
);
    //改为pipeline 流水线寄存器：时序化，分为2拍，第一拍乘，第二拍加。
    //乘加单元
    //乘
    logic [31:0] mul1_out, mul2_out;//改为流水线寄存器
    always_ff@(posedge clk or negedge rst_n) begin 
        if(!rst_n)begin
            mul1_out<=32'b0;
            mul2_out<=32'b0;
        end
        else begin
            mul1_out <= data_x_0 * data_a_0;
            mul2_out <= data_x_1 * data_a_1;
        end
    end
    //累加,acc_clear判断新结果，调整累加0或acc_reg
    logic [31:0]acc_reg, next_acc;
    assign next_acc = mul1_out + mul2_out + (acc_clear ? 0: acc_reg);

    always_ff @(posedge clk)begin
        if(!rst_n) acc_reg <= 32'b0;
        else   acc_reg <= next_acc;
    end
    //输出
    assign mac_result = acc_reg;

endmodule