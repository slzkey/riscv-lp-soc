module controller(
    input logic clk,
    input logic rst_n,
    input logic start,
    //给datapath的控制信号
    output logic acc_clear,//累加器清零信号
    //加载x数据控制信号
    output logic load_en,
    output logic [4:0] load_cnt,//x数据加载计数器 4*8
    //reg读地址
    output logic [4:0] reg_raddr,
    //ram读写控制信号
    output logic ram_wen,
    output logic [8:0] ram_waddr,
    //rom读地址
    output logic [4:0] rom_raddr,
    //finish信号
    output logic finish
);
logic [1:0] partial_cnt; //部分和计数器 0~3
logic [3:0] element_cnt; //当前计算的P矩阵元素计数器 0~15
logic [4:0] matrix_cnt; //矩阵计数器 0~15

//state registers状态寄存器
typedef enum logic [1:0] {
    IDLE,//空闲状态初始化
    LOAD,//加载X矩阵
    CALC,//计算状态
    FINISH
} state_t;
state_t current_state, next_state;

//状态转移
always_ff @( posedge(clk) or negedge(rst_n)) begin
    if (!rst_n)     current_state <= IDLE;
    else            current_state <= next_state;
end
//下一个状态逻辑
always_comb begin
    case (current_state)
        IDLE: if(start)     next_state = LOAD;
      LOAD: if(load_cnt >= 5'd31)   next_state = CALC;
              else                      next_state = LOAD;
        CALC: if(partial_cnt==3 && element_cnt == 4'd15) next_state = FINISH;
              else                      next_state = CALC;
        FINISH:                     next_state = IDLE;
        default:                    next_state = IDLE;
    endcase
end

//输出与计数器逻辑
always_ff @( posedge(clk) ) begin
    if(rst_n == 0) begin
        partial_cnt <= 2'b0;
        element_cnt <= 4'b0;
        matrix_cnt <= 5'b0;
        acc_clear <= 1'b1;
        load_cnt <= 5'b0;
    end
    else begin
    case(current_state)
        IDLE:begin
            partial_cnt <= 2'b0;
            element_cnt <= 4'b0;
            acc_clear <= 1'b1;
            load_cnt <= 5'b0;
        end
        LOAD:begin
            if(load_cnt<5'd31)begin
            load_cnt <= load_cnt + 1;
            end
            //else load_cnt保持不变,等待状态转移
        end
        CALC:begin
           if(partial_cnt < 3) begin
                partial_cnt <= partial_cnt + 1;
             acc_clear <= 1'b0;
           end
           else begin//当前p元素计算完成
                              
                //准备下个点的计算
                partial_cnt <= 2'b0;
                acc_clear <= 1'b1;
                //外层循环计数+1
                if(element_cnt < 4'd15) begin
                    element_cnt <= element_cnt + 1;
                end
                //else element_cnt保持不变,等待状态转移
           end
        end
        FINISH: begin
            matrix_cnt <= matrix_cnt + 1;
        end
    endcase
    end
end
assign load_en = (current_state == LOAD);
assign finish  = (current_state == FINISH);
//partial_cnt=3时即刻生效的ram写使能
assign ram_wen = (current_state == CALC && partial_cnt == 3);
//地址计算
assign ram_waddr = matrix_cnt * 16 + element_cnt;
assign rom_raddr = {element_cnt[1:0],partial_cnt};
assign reg_raddr = {element_cnt[3:2] , partial_cnt,1'b0};

endmodule