# Xilinx-virtex7-vc707
ps：算是自己从零开始学习的一个记录 / 仅供小白参考使用

## 硬件连接
由于 vc707 官方套件不含国标适配器，需自配一个英 / 美转国标的转接座，硬件连接示例见官方手册：[ug848-VC707-getting-started-guide](https://docs.amd.com/v/u/en-US/ug848-VC707-getting-started-guide) ； vc707 原理图：[vc707_Schematic_xtp135_rev1_0](https://github.com/Raynaril/Xilinx-virtex7-VC707/blob/main/info/vc707_Schematic_xtp135_rev1_0.pdf)

根据示例连接电源 ( J18 ) 、JTAG ( 左侧 ) ，同时下载驱动 CP210x_VCP_Windows，硬件连接完成。

## Project
### 2024-06-20 时钟 IP 核 
 由于 vc707 上只有差分时钟，需要用差分转单端的原语：
```Verilog
IBUFGDS #
    (
    .DIFF_TERM ("FALSE"),
    .IBUF_LOW_PWR ("FALSE")
    )
    u_ibufg_sys_clk
    (
    .I (sys_clk_p), //差分时钟正端输入
    .IB (sys_clk_n), // 差分时钟负端输入
    .O (sys_clk_ibufg) //时钟缓冲输出
    );
```
配置时钟 ip 核，将 200MHz 时钟转换为 5MHz ：

>在 Clocking Wizard 中将 clk_in1 输入频率设为 200MHz，Output Clocks 中只需一个时钟 clk_out1 5MHz 。

通过 always 语句块执行一段简单的流水灯循环进行验证（ 0.2us*2500,000 = 0.5s ）：
```Verilog
always@(posedge clk or posedge rst)begin
    if(rst)begin
        count <= 0;
        led   <= 8'b00000001;
    end
    else begin 
        if(count ==26'd2499999)begin
             count<= 0;
             led<={led[6:0],led[7]};
        end
        else count <=count+1;
    end
end
```
### 2024-06-23 FIFO 读写
 由于本人基础拉跨，一个简单的 FIFO 也不幸遇到了许多问题，故在此记录一下 ( 防止跟我一样的小白踩坑 )

 首先声明：整个模块的作用是例化一个 FIFO IP核 / fifo_generator_0，通过 FIFO 读写模块 / fifo_rd 和 fifo_wr 进行控制。首先向 FIFO 内写入 256 个 8bit 数据，在写满 / 标志位 full ( 注：要打两拍 ) 后将其读出，读空后继续写入，以此循环；top_fifo 中以写标志 fifo_wr_flag 控制流水灯循环 ( 不过由于写入仅占256个时钟周期 ( wr_clk = 50M ) 相对流水灯延时的 0.5s 太短，完全可忽略不计 ) 故上板验证现象为一直循环，意义不是很大，之后会改成其他更好的方案。

 系统框图如下：

 调试过程中所遇到的问题如下：

 1. ( 未解决 ) 根据手册，Virtex7 系列的 FIFO ( 频率在 200-300 MHz ) 读写同步周期为 3 ( Airtex7 则为2 ) ，不过在实际测试中似乎没有特别的影响，在 IP 核中选择 2 ( 打两拍 ) 也没有异常；
 
 2. ( 已解决 ) 在 run implemented 时报 critical warning: :[Timing 38-282] The design failed to meet the timing requirements. 且在 Timing Summary Report 详细信息中：最差保持时序裕量 WHS = -0.415 ns , THS = -0.650 ns , Number of Failing Endpoints : 2 

    ![image](https://github.com/Raynaril/Xilinx-virtex7-vc707/assets/67402948/24c41e76-d27a-45be-af6c-b135e90587cc)

    >解决方法：此类时序问题很有可能是由于自己所设置的 ILA 核的影响，所以在验证完功能且不需要观测信号后，应将所有 ILA 代码注释掉。其他可能的产生问题参考：[vivado 时序报错：建立时间和保持时间问题](https://blog.csdn.net/qq_38374491/article/details/117392772)


    
