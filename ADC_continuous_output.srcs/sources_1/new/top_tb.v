`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/24 15:18:46
// Design Name: 
// Module Name: top_tb
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


module top_tb();
    reg clk = 0;
    reg sclk_clk = 0;
    reg adc_enable = 0;
    wire cnv;
    wire sclk;
    reg data_in = 0;
    wire adc_busy;
    reg reset = 0;  
    wire [15:0] data_out;
    
    adc #(
        .N(16),
        .t_CONV(500),
        .t_EN(10),
        .CLK_PERIOD(5)
    )adc_inst(
        .clk(clk),
        .locked(1'b1),
        .sclk_clk(sclk_clk),
        .adc_enable(adc_enable),
        .data_input(data_in),
        .reset(reset),
        .cnv_out(cnv),
        .sclk_out(sclk),
        .data_output(data_out),
        .busy_out(adc_busy)
    );
    
    always #2.5 clk = ~clk;
    always #7.5 sclk_clk = ~sclk_clk;
    
    initial begin
        reset = 1;
        #10;
        reset = 0;
        adc_enable = 1;
        #537;
        
        data_in = 1;
        #23;
        data_in = 0;
        #36;
        
        data_in = 1;
        #23;
        data_in = 0;
        #36;
        
        data_in = 1;
        #23;
        data_in = 0;
        #36;
        
        data_in = 1;
        #23;
        data_in = 0;
        #36;
    end
endmodule
