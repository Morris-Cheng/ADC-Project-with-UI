`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/24 15:15:58
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
        input wire clk,
        input wire data_in,
        input wire reset,
        input wire adc_enable,
        output wire cnv,
        output wire sclk,
        output wire uart_tx,
        output wire [7:0] seg,
        output wire [3:0] an
    );
    
    wire clk_200MHz;
    wire sclk_clk;
    wire locked;
    clk_wiz_0 clock_wizard
   (
        // Clock out ports
        .clk_out1(clk_out1),     // output clk_out1
        .clk_out2(clk_out2),     // output clk_out2
        // Status and control signals
        .reset(reset), // input reset
        .locked(locked),       // output locked
       // Clock in ports
        .clk_in1(clk)      // input clk_in1
    );
    
    wire adc_busy;
    wire [15:0] data_out;
    
    adc #(
        .N(16),
        .t_CONV(500),
        .t_EN(10),
        .CLK_PERIOD(5)
    )adc_inst(
        .clk(clk_200MHz),
        .locked(locked),
        .sclk_clk(sclk_clk),
        .adc_enable(adc_enable),
        .data_input(data_in),
        .reset(reset),
        .cnv_out(cnv),
        .sclk_out(sclk),
        .data_output(data_out),
        .busy_out(adc_busy)
    );
    
    wire [31:0] temp;
    assign temp = (data_out * 16'd5000) >> 16;
    wire [15:0] value;
    assign value = temp;
    
    display #(
        .N(16)
    ) display_inst(
        .clk(clk),
        .value(value),
        .seg(seg),
        .an(an)
    );
endmodule
