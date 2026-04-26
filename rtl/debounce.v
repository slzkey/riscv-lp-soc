module debounce(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_in,
    output reg  btn_out   // 直接声明为 output reg，省略中间变量
);

reg [20:0] cnt;
reg btn_sync_1, btn_sync_2;

// 纯同步设计：敏感列表里只有 clk
always @(posedge clk) begin
    if (!rst_n) begin
        // 所有寄存器在复位时都要有初始状态
        btn_sync_1 <= 1'b0;
        btn_sync_2 <= 1'b0;
        cnt        <= 21'b0;
        btn_out    <= 1'b0; // 直接对输出端口寄存器赋值
    end else begin
        // 1. 同步输入信号，消除亚稳态 (直接读取输入线 btn_in)
        btn_sync_1 <= btn_in;
        btn_sync_2 <= btn_sync_1;

        // 2. 防抖计数逻辑
        if(btn_sync_2 == btn_out) begin
            cnt <= 21'b0; //如果输入信号与输出信号相同，计数器清零
        end else begin
            cnt <= cnt + 1; //如果不同，开始计时
            // 21'hFFFFF 在 100MHz 下大约是 10.4ms，非常完美的消抖时间
            if (cnt == 21'hFFFFF) begin 
                btn_out <= btn_sync_2; 
                cnt <= 21'b0; 
            end
        end
    end
end

endmodule