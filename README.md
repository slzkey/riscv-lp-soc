# RISC-V Low-Power Edge Computing SoC

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English Version

###  Project Goal
To design and implement a low-power heterogeneous SoC based on the **NEORV32** processor for edge matrix acceleration.

###  Key Low-Power Techniques
* **Event-Driven Architecture:** Utilizing RISC-V `WFI` instruction to minimize idle power consumption.
* **Dynamic Clock Gating:** Implementing `BUFGCE` primitives on the AXI4-Lite bus to cut off the clock tree of the matrix accelerator when idle.

###  Project Structure
* `rtl/`:Hardware Design, including AXI4-Lite Slave Wrapper and Matrix Multiplication Core, and Top-lever SoC Integration
* `sw/`:Embedded Software & Firmware
* `constraints/`: FPGA Physical Constraints
* `docs/`: Project Documentations & Reports

---

<a name="中文"></a>
## 中文版本

###  项目目标
基于 **NEORV32** 处理器，设计并实现一个用于边缘矩阵加速的低功耗异构 SoC 系统。

###  核心低功耗技术
* **事件驱动架构 (Event-Driven):** 利用 RISC-V 的 `WFI` 指令，使 CPU 在空闲时挂起流水线，最大程度降低静态功耗。
* **动态时钟门控 (Clock Gating):** 在 AXI4-Lite 总线层引入 `BUFGCE` 原语。当矩阵加速器空闲时，通过软件配置物理切断其时钟树翻转，大幅降低动态功耗。
  
##  目录结构
* `rtl/`: 包含 AXI Slave Wrapper 和矩阵加速器核心代码。
* `sw/`: 包含 C 语言驱动、中断处理程序及测试固件。
* `constraints/`: Nexys Video 开发板的 XDC 约束文件。
* `docs/`: 功耗分析报告及架构设计图。
