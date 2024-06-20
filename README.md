# Xilinx-virtex7-vc707
ps：算是自己从零开始学习的一个记录<br>

## 硬件连接
由于vc707官方套件不含国标适配器，需自配一个英/美转国标的转接座，硬件连接示例见官方手册：[ug848-VC707-getting-started-guide](https://docs.amd.com/v/u/en-US/ug848-VC707-getting-started-guide) ；vc707原理图：[vc707_Schematic_xtp135_rev1_0](https://github.com/Raynaril/Xilinx-virtex7-VC707/blob/main/info/vc707_Schematic_xtp135_rev1_0.pdf)

根据示例连接电源(J18)、JTAG(左侧)，同时下载驱动CP210x_VCP_Windows，硬件连接完成。

## Project
### 2024-06-20 时钟IP核 
 由于vc707上只有差分时钟，需要用差分转单端的原语：
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
配置时钟ip核，将200MHZ时钟转换为5MHZ：

>在Clocking Wizard 中将clk_in1输入频率设为200MHz，Output Clocks中只需一个时钟clk_out1 5MHz。

通过always语句块执行一段简单的流水灯循环进行验证（0.2us*2500,000=0.5s）：
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
