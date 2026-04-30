#include<neorv32.h>
#include<stdio.h>

//============================
//硬件地址映射
//============================
#define MATRIX_BASE 0x40000000 //加速器基地址
//寄存器映射 转为volatile uint32_t 指针
#define REG_CTRL ((volatile uint32_t*)(MATRIX_BASE + 0x000)) //控制寄存器/start
#define REG_STATUS ((volatile uint32_t*)(MATRIX_BASE + 0x004)) //状态寄存器/finish_wire
//BRAM映射
#define BRAM_MAT_X ((volatile uint32_t*)(MATRIX_BASE + 0x100)) //矩阵X基地址
#define BRAM_MAT_A ((volatile uint32_t*)(MATRIX_BASE + 0x200)) //矩阵A基地址
#define BRAM_MAT_P ((volatile uint32_t*)(MATRIX_BASE + 0x300)) //结果矩阵P基地址

//============================
//中断服务历程ISR
//=============================
void button_isr(void) {
    neorv32_uart0_printf("\n[ISR] 外部中断触发！CPU已唤醒。\n");
    //1.灌入测试数据
    for (int i = 0; i < 32; i++) {
        BRAM_MAT_X[i] = i + 1; //矩阵X: 1,2,...,16
        BRAM_MAT_A[i] = (i + 1) * 10; //矩阵A: 10,20,...,160
    }
    //2.启动加速器
    neorv32_uart0_printf("[ISR] 启动加速器...\n");
    *REG_CTRL = 1; //写1启动计算
    *REG_CTRL = 0; //写0复位控制寄存器
    //3.等待计算完成
    while ((*REG_STATUS & 0x01) == 0) {
        asm volatile ("nop"); //空指令防止循环被编译器优化掉
    }
    //4.读取结果
    neorv32_uart0_printf("[ISR] 计算完成，结果矩阵P:\n");
    for (int i = 0; i < 16; i++) {
        neorv32_uart0_printf("%u\t", BRAM_MAT_P[i]);
        if ((i + 1) % 4 == 0) neorv32_uart0_printf("\n");
    }
    //5.清除状态寄存器
    *REG_STATUS = 0; //清除状态寄存器
}

//============================
//主函数
//=============================
int main() {
    //1.初始化串口
    neorv32_uart0_setup(19200, ~0); //波特率19200，无校验，1停止位
    neorv32_uart0_printf("=== 矩阵加速器SoC启动 ===\n");
    //2.配置neorv32运行时环境RTE，会接管RISC-V的异常向量表
    neorv32_rte_setup();
    //3.绑定中断：发生机器外部中断MEI时执行button_isr函数
    neorv32_rte_handler_install(RTE_TRAP_MEI, button_isr);
    //4.使能中断
    neorv32_cpu_csr_set(CSR_MIE, 1 << CSR_MIE_MEIE); //使能MEI中断
    neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE); //全局使能中断

    neorv32_uart0_printf("系统已进入低功耗等待外部中断...\n");
    //5.主循环：事件驱动
    while (1) {
        neorv32_uart0_printf("主循环: CPU sleeping...\n");

        //运行汇编指令wfi等待中断。
        neorv32_cpu_sleep(); //等待中断，进入低功耗模式
    }

    return 0;
}