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

    //乘加单元
    //乘
    logic [31:0] mul1_out, mul2_out;
    assign mul1_out = data_x_0 * data_a_0;
    assign mul2_out = data_x_1 * data_a_1;
    //累加
    logic [31:0]acc_reg, next_acc;
    assign next_acc = mul1_out + mul2_out + acc_reg;

    always_ff @(posedge clk)begin
        if(!rst_n || acc_clear) acc_reg <= 32'b0;
        else   acc_reg <= next_acc;
    end
    //输出
    assign mac_result = next_acc;

endmodule