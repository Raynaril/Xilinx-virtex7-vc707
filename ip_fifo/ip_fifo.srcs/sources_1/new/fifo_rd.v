`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2024/06/21 10:08:21
// Design Name: ip_fifo
// Module Name: top_fifo
// Target Devices: Xilinx Virtex7 vc707
// Tool Versions: 
// copyright@ Raynaril from Purple Mountain Laboratories
//////////////////////////////////////////////////////////////////////////////////

module fifo_rd(
    //system clock
    input               rd_clk      , //时钟信号 100M
    input               rst_n       , //复位信号
    //FIFO interface
    input               rd_rst_busy , //读复位忙信号
    input        [7:0]  fifo_rd_data, //从FIFO读出的数据
    input               full        , //FIFO满信号
    input               almost_empty, //FIFO将空信号
    output  reg         fifo_rd_en    //FIFO读使能
);

//reg define
reg       full_d0;
reg       full_d1;

//因为full信号是属于FIFO写时钟域的
//所以对full打两拍同步到读时钟域下
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        full_d0 <= 1'b0;
        full_d1 <= 1'b0;
    end
    else begin
        full_d0 <= full;
        full_d1 <= full_d0;
    end
end    
    
//对fifo_rd_en进行赋值,FIFO写满之后开始读，读空之后停止读
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) 
        fifo_rd_en <= 1'b0;
    else if(!rd_rst_busy) begin
        if(full_d1)           // 写满开始读
           fifo_rd_en <= 1'b1;
        else if(almost_empty) // 快空停止读
           fifo_rd_en <= 1'b0; 
    end
    else
        fifo_rd_en <= 1'b0;
end

endmodule