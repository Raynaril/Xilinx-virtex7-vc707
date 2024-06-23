`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2024/06/21 10:08:21
// Design Name: ip_fifo
// Module Name: top_fifo
// Target Devices: Xilinx Virtex7 vc707
// Tool Versions: 
// copyright@ Raynaril from Purple Mountain Laboratories
//////////////////////////////////////////////////////////////////////////////////
module ip_fifo(
        input       sys_clk_p ,  // vc707差分输入时钟 200Mhz
        input       sys_clk_n , 
        input       sys_rst   ,  // vc707系统复位高有效
        output reg [7:0] led
    );
    
    //wire define
    wire         clk_50m       ;  // 50M时钟
    wire         clk_100m      ;  // 100M时钟
    wire         locked        ;  // 时钟锁定信号
    wire         rst_n         ;  // 复位，低有效
    wire         wr_rst_busy   ;  // 写复位忙信号
    wire         rd_rst_busy   ;  // 读复位忙信号
    wire         fifo_wr_en    ;  // FIFO写使能信号
    wire         fifo_rd_en    ;  // FIFO读使能信号
    wire  [7:0]  fifo_wr_data  ;  // 写入到FIFO的数据
    wire  [7:0]  fifo_rd_data  ;  // 从FIFO读出的数据
    wire         almost_full   ;  // FIFO将满信号
    wire         almost_empty  ;  // FIFO将空信号
    wire         full          ;  // FIFO满信号
    wire         empty         ;  // FIFO空信号
    wire  [7:0]  wr_data_count ;  // FIFO写时钟域的数据计数
    wire  [7:0]  rd_data_count ;  // FIFO读时钟域的数据计数
    wire         sys_clk_ibufg ;  // 时钟缓冲输出
    wire         fifo_wr_flag  ;  // FIFO写标志
    reg          state         ;  // 状态计数
    reg   [27:0] count         ;  // 延时计数
    
    IBUFGDS #   // 差分时钟转单端原语        
    (
    .DIFF_TERM ("FALSE"),
    .IBUF_LOW_PWR ("FALSE")
    )
    u_ibufg_sys_clk
    (
    .I (sys_clk_p),    // 差分时钟正端输入
    .IB (sys_clk_n),   // 差分时钟负端输入
    .O (sys_clk_ibufg) // 时钟缓冲输出
    );
        
    // 例化时钟 IP核
    clk_wiz_0 u_clk_wiz_0 (
        .clk_out1(clk_50m ),      // output clk_out1 50M
        .clk_out2(clk_100m),      // output clk_out2 100M
        .locked  (locked  ),      // output locked
        
        .clk_in1 (sys_clk_ibufg ) // input clk_in1
    );     
    
    // 通过sys_rst和时钟锁定locked信号产生新的复位信号 低有效
    assign   rst_n = (~sys_rst) & locked;
    
    // FIFO写模式下指示灯左循环 
    // 由于FIFO读写周期太短 相较于0.5s完全可忽略 视觉显示流水灯无停止间隔 但在ila中能明显看出
    always @(posedge clk_50m or negedge rst_n) begin
         if(!rst_n )begin
            led   <= 8'b00000001;
            count <= 28'd0      ;
            state <= 1'd0       ;
         end
         else begin
            case(state) 
                1'd0:begin
                    if(fifo_wr_flag) begin  // 如果FIFO开始写
                        state <= 1'd1;      // 进入延时状态
                        led   <= led ;
                    end
                    else begin
                        state <= state;
                        led   <= led  ; 
                    end
                end
                1'd1:begin  //等待
                    if(count ==28'd2500_0000)begin
                        count <= 16'd0             ;
                        state <= 1'd0              ;
                        led   <= {led[6:0],led[7]} ; // 流水灯左循环
                    end
                    else begin
                        count <= count+1;
                        led   <=led     ;
                        state <= state  ;
                    end
                 end
                 default: begin
                    state <=1'd0;
                    led   <=led ;
                 end
            endcase
         end
    end
      
    // 例化FIFO IP核
    fifo_generator_0  u_fifo_generator_0 (
        .rst           (~rst_n       ),  // input wire rst
        .wr_clk        (clk_50m      ),  // input wire wr_clk
        .rd_clk        (clk_100m     ),  // input wire rd_clk
        .wr_en         (fifo_wr_en   ),  // input wire wr_en
        .rd_en         (fifo_rd_en   ),  // input wire rd_en
        .din           (fifo_wr_data ),  // input wire [7 : 0] din
        .dout          (fifo_rd_data ),  // output wire [7 : 0] dout
        .almost_full   (almost_full  ),  // output wire almost_full
        .almost_empty  (almost_empty ),  // output wire almost_empty
        .full          (full         ),  // output wire full
        .empty         (empty        ),  // output wire empty
        .wr_data_count (wr_data_count),  // output wire [7 : 0] wr_data_count   
        .rd_data_count (rd_data_count),  // output wire [7 : 0] rd_data_count
        .wr_rst_busy   (wr_rst_busy  ),  // output wire wr_rst_busy
        .rd_rst_busy   (rd_rst_busy  )   // output wire rd_rst_busy
    );
    
    // 例化FIFO写模块
    fifo_wr  u_fifo_wr (
        .wr_clk        (clk_50m     ), // 写时钟
        .rst_n         (rst_n       ), // 复位信号
        .wr_rst_busy   (wr_rst_busy ), // 写复位忙信号
        .fifo_wr_en    (fifo_wr_en  ), // fifo写请求
        .fifo_wr_data  (fifo_wr_data), // 写入FIFO的数据
        .empty         (empty       ), // fifo空信号
        .almost_full   (almost_full ),  // fifo将满信号
        .fifo_wr_flag  (fifo_wr_flag ) // fifo写标志
    );
    
    //例化FIFO读模块
    fifo_rd  u_fifo_rd (
        .rd_clk       (clk_100m    ),  // 读时钟
        .rst_n        (rst_n       ),  // 复位信号
        .rd_rst_busy  (rd_rst_busy ),  // 读复位忙信号
        .fifo_rd_en   (fifo_rd_en  ),  // fifo读请求
        .fifo_rd_data (fifo_rd_data),  // 从FIFO输出的数据
        .almost_empty (almost_empty),  // fifo将空信号
        .full         (full        )   // fifo满信号
    );
//    // fifo_wr ila核
//    ila_0 u_ila_wr (
//        .clk       (clk_50m      ), // input wire clk
    
//        .probe0    (fifo_wr_en   ), // input wire [0:0]  probe0  
//        .probe1    (fifo_wr_data ), // input wire [7:0]  probe1 
//        .probe2    (almost_full  ), // input wire [0:0]  probe2 
//        .probe3    (full         ), // input wire [0:0]  probe3 
//        .probe4    (wr_data_count), // input wire [7:0]  probe4
//        .probe5    (fifo_wr_flag )  // input wire [0:0]  probe5
//    );
    
//    // fifo_rd ila核
//    ila_1 u_ila_rd (
//        .clk       (clk_100m     ), // input wire clk
    
//        .probe0    (fifo_rd_en   ), // input wire [0:0]  probe0  
//        .probe1    (fifo_rd_data ), // input wire [7:0]  probe1 
//        .probe2    (almost_empty ), // input wire [0:0]  probe2 
//        .probe3    (empty        ), // input wire [0:0]  probe3 
//        .probe4    (rd_data_count)  // input wire [7:0]  probe4
//    );
    //top_fifo ila核
//    ila_2 u_ila_top (
//        .clk   (clk_50m), // input wire clk
        
//        .probe0(clk_50m), // input wire [0:0]  probe0 
//        .probe1(count  ), // input wire [15:0]  probe1
//        .probe2(state ), // input wire [0:0]  probe2
//        .probe3(led)     // input wire [7:0]  probe0  
//);
    
endmodule 

