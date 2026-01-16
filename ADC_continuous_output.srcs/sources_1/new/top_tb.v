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
    reg adc_enable = 0;
    wire cnv;
    wire sclk;
    reg data_in = 0;
    wire adc_busy;
    wire [15:0] data_out;
    reg reset = 0;
        
    adc #(
        .N(16),
        .t_CONV(2200),
        .t_EN(15),
        .SCLK_PERIOD(30)
    )adc_inst(
        .clk(clk),
        .adc_enable(adc_enable),
        .data_input(data_in),
        .reset(reset),
        .cnv_out(cnv),
        .sclk_out(sclk),
        .data_output(data_out),
        .busy_out(adc_busy)
    );
    
    reg adc_busy_d = 0;
    wire adc_busy_falling = ~adc_busy && adc_busy_d;
    
    wire        wr_signal  = adc_busy_falling;
    reg         rd_signal  = 0;
    reg  [15:0] write_data = 0;
    wire [15:0] read_data;
    wire        empty;
    wire        full;
    
    fifo #(
        .BUFFER_WIDTH(256), //has to be a power of two ideally
        .ADDR_WIDTH(16)
    ) inst(
        .clk(clk),
        .reset(reset),
        .wr_signal(wr_signal),
        .rd_signal(rd_signal),
        .write_data(write_data),
        .read_data(read_data),
        .empty_out(empty),
        .full_out(full)
    );
    
    always @(posedge clk) begin
        adc_busy_d <= adc_busy;
        write_data <= data_out;
    end
    
    reg [1:0] state = 0;            //states of the tx module
    reg [7:0]  out_data;            //data being sent back to the PC
    reg        send_pulse = 0;      //sending pulse
    wire       busy;                //busy signal of the tx line
    reg busy_d = 0;
    wire busy_falling = ~busy && busy_d;
    
    uart_tx uart_tx_inst(
        .clk(clk), 
        .i_send(send_pulse), 
        .i_data(out_data), 
        .o_tx(uart_tx), 
        .o_busy(busy)
    );
    
    //tx block used to send data back to the computer
    always @(posedge clk) begin
        send_pulse <= 0;
        
        case(state)
            0: begin : idle_state
                rd_signal <= 1;
                send_pulse <= 1;
                state <= 1;
            end
        
            1: begin : header_send
                if (busy_falling) begin
                    out_data <= 8'hFF;
                    send_pulse <= 1;
                    state <= 2;
                end
                else begin
                    rd_signal <= 0;
                    out_data <= out_data;
                    state <= 1;
                end
            end
            
            2: begin : low_byte_send
                if (busy_falling) begin
                    out_data <= read_data[7:0]; //forms the low byte that's being sent first
                    send_pulse <= 1; 
                    state <= 3;
                end
                else begin
                    out_data <= out_data;
                    state <= 2;
                end
            end
            
            3: begin : high_byte_send
                if (busy_falling) begin
                    out_data <= read_data[15:8]; //forms the high byte that's being sent next
                    send_pulse <= 1; 
                    state <= 0;
                end
                else begin
                    out_data <= out_data;
                    state <= 3;
                end
            end
            
            default: begin : default_state
                state <= 0;
                out_data <= 0;
                send_pulse <= 0;
                rd_signal <= rd_signal;
            end
        endcase
        busy_d <= busy;
    end
    
    always #5 clk = ~clk;
    
    initial begin
        reset = 1;
        #10;
        reset = 0;
        adc_enable = 1;
        #25;
//        reset = 0;
        #2250;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        #65;
        
        data_in = 1;
        #15;
        data_in = 0;
        
        #1150;
        adc_enable = 1;
        #10;
        #2255;
        #20;
        
        data_in = 1;
        #95;
        data_in = 0;
        #145;
        data_in = 1;
        #270;
        data_in = 0;
        
        #5000;
        adc_enable = 0;
    end
endmodule
