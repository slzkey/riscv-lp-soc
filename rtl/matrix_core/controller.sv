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
logic [5:0] global_cnt;//1次4*8x8*4矩阵乘法4*4*8=128次乘法，共64个周期，每个周期2个乘法。

wire [1:0] k_step;
wire [1:0] j_cnt;
wire [1:0] i_cnt;

assign k_step = global_cnt[1:0];
assign j_cnt  = global_cnt[3:2];
assign i_cnt  = global_cnt[5:4];

//预备写信号，用来打1拍延迟
logic ram_wen_pre;
logic [4:0] ram_waddr_pre;

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
        CALC: if(global_cnt == 63 ) next_state = FINISH;
              else                      next_state = CALC;
        FINISH:                     next_state = IDLE;
        default:                    next_state = IDLE;
    endcase
end
//段3：计数器逻辑 （纯时序）
always_ff @(posedge clk)begin
    if (!rst_n) global_cnt <= 0;
    else if(current_state == IDLE && start) global_cnt <= 0;//在IDLE状态等start信号，收到后计数器清零准备开始计数
    else if (current_state == CALC) global_cnt <= global_cnt + 1;//在CALC状态计数器每周期加1
end

//地址生成与控制逻辑
always_comb begin 
    //默认值
    acc_clear = 1'b0;
    finish = 1'b0;
    ram_wen_pre = 1'b0;
    ram_waddr_pre = 0;

    //双发地址生成：步进为2
    x_raddr_0 = {i_cnt,k_step,1'b0};//i_cnt控制行，k_step控制列，最低位0/1分别对应同一元素的两次访问
    x_raddr_1 = {i_cnt,k_step,1'b1};
    a_raddr_0 = {k_step,1'b0,j_cnt};
    a_raddr_1 = {k_step,1'b1,j_cnt};

    case (current_state)
        IDLE: begin
            acc_clear = 1'b1;//IDLE状态清零累加器
        end
        CALC: begin
            if(k_step==0)//每次新i的第一拍时清零累加器，准备进行新的点积计算
                acc_clear = 1'b1;
            
            //最内层算完写出结果
            if (k_step==3)begin
                ram_wen_pre = 1'b1;//CALC状态预备写使能，等partial_cnt计数到3时正式生效
                ram_waddr_pre = {i_cnt,j_cnt};//写地址就是当前的步数计数值
            end
        end
        FINISH: begin
            finish = 1'b1;//FINISH状态拉高完成信号，通知CPU可以读结果了
        end
        default: ;
    endcase
end
//写信号打1拍延迟

always_ff @(posedge clk)begin
    if(!rst_n) begin
        ram_wen <= 1'b0;
        ram_waddr <= 0;
    end
    else begin
        ram_wen <= ram_wen_pre;
        ram_waddr <= {4'b0,ram_waddr_pre};
    end
end
endmodule