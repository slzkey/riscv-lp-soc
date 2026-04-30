module controller(
    input logic clk,
    input logic rst_n,
    input logic start,
    //给datapath的控制信号
    output logic acc_clear,//累加器清零信号
    //读BRAM地址
    output logic [4:0] x_raddr_0,
    output logic [4:0] x_raddr_1,
    output logic [4:0] a_raddr_0,
    output logic [4:0] a_raddr_1,
    //写BRAM结果
    output logic ram_wen,
    output logic [11:0] ram_waddr,
    //finish信号
    output logic finish
);
//state registers状态寄存器
typedef enum logic [1:0] {
    IDLE,//空闲状态初始化
    CALC,//计算状态
    FINISH
} state_t;
state_t current_state, next_state;
logic [6:0] global_cnt;//1次4*8x8*4矩阵乘法4*4*8=128次乘法，共64个周期，每个周期2个乘法。+3拍流水线延迟=67个周期

wire [1:0] k_step;
wire [1:0] j_cnt;
wire [1:0] i_cnt;

assign k_step = global_cnt[1:0];
assign j_cnt  = global_cnt[3:2];
assign i_cnt  = global_cnt[5:4];

//流水线对齐控制 pipeline alignment
logic ram_wen_raw;
logic [4:0] ram_waddr_raw;
logic first_raw;

//3段式状态机
//段1：状态转移 （纯时序）
always_ff @( posedge(clk) or negedge(rst_n)) begin
    if (!rst_n)     current_state <= IDLE;
    else            current_state <= next_state;
end
//段2：下一个状态逻辑 （纯组合）
always_comb begin
    case (current_state)
        IDLE: if(start)     next_state = CALC;
              else                      next_state = IDLE;
        CALC: if(global_cnt == 66 ) next_state = FINISH;
              else                      next_state = CALC;
        FINISH:                     next_state = IDLE;
        default:                    next_state = IDLE;
    endcase
end
//段3：计数器逻辑 （纯时序）
always_ff @(posedge clk or negedge rst_n)begin
    if (!rst_n) global_cnt <= 0;
    else if(current_state == IDLE && start) global_cnt <= 0;//在IDLE状态等start信号，收到后计数器清零准备开始计数
    else if (current_state == CALC) global_cnt <= global_cnt + 1;//在CALC状态计数器每周期加1
end

//地址生成逻辑
always_comb begin 
    //双发地址生成：步进为2
    x_raddr_0 = {i_cnt,k_step,1'b0};//i_cnt控制行，k_step控制列，最低位0/1分别对应同一元素的两次访问
    x_raddr_1 = {i_cnt,k_step,1'b1};
    a_raddr_0 = {k_step,1'b0,j_cnt};
    a_raddr_1 = {k_step,1'b1,j_cnt};
end

//原始控制信号 第0拍 与地址同时生成。
assign ram_wen_raw = (current_state == CALC && global_cnt <=63 && k_step == 3);
assign ram_waddr_raw = {i_cnt,j_cnt};
assign first_raw = (current_state == CALC && global_cnt <=63 && k_step == 0);

//打拍移位寄存器
logic [2:0] wen_shift;
logic [4:0] waddr_shift [0:2];
logic [1:0] first_shift;

always_ff @(posedge clk or negedge(rst_n))begin
    if(!rst_n)begin
        wen_shift <= 3'b0;
        first_shift <= 2'b0;
    end else begin//移位
        wen_shift <={wen_shift[1:0],ram_wen_raw};
        first_shift <= {first_shift[0],first_raw};

        waddr_shift[0]<=ram_waddr_raw;
        waddr_shift[1]<= waddr_shift[0];
        waddr_shift[2]<=waddr_shift[1];
    end
end

assign acc_clear = first_shift[1];//延迟至累加前，与乘法器出数据对齐 2拍
assign ram_wen = wen_shift[2];//延迟至累加回写后，与输出最终结果对齐 3拍
assign ram_waddr = {7'b0,waddr_shift[2]};
assign finish = (current_state == FINISH);

endmodule