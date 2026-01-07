`timescale 1ns / 1ps

module delay_timer #(
        parameter CLOCK_CYCLE_TIME = 0,
        parameter DELAY_TIME = 0,
        parameter ROUND_MODE = 0
    )(
        input  wire clk,
        input  wire enable,
        output wire done
    );
    
    reg enable_d = 0;
    wire enable_rising = enable & ~enable_d;
    
    generate 
        if(DELAY_TIME == 0) begin : zero_delay //bypasses all the code and outputs done for one clock cycle
            reg counter = 0;
            
            always @(posedge clk) begin
                if(enable_rising) begin
                    counter <= 1;
                end
                else begin
                    counter <= 0;
                end
                
                enable_d <= enable;
            end
            
            assign done = counter;
        end
        else begin : non_zero_delay
            localparam DELAY_CYCLE = (ROUND_MODE == 0) ? (DELAY_TIME / CLOCK_CYCLE_TIME): 
                                                        ((DELAY_TIME + CLOCK_CYCLE_TIME - 1) / CLOCK_CYCLE_TIME);
    
            reg [$clog2(DELAY_CYCLE + 1) : 0] delay_counter = 0;
            reg enable_flag = 0;
        
            always @(posedge clk) begin
                if(enable_rising) begin
                    enable_flag <= 1;
                end
                else if(delay_counter <= DELAY_CYCLE && enable_flag) begin
                    delay_counter <= delay_counter + 1;
                end
                else begin
                    delay_counter <= 0;
                    enable_flag <= 0;
                end
                enable_d <= enable;
            end
            
            assign done = delay_counter == DELAY_CYCLE;
        end
    endgenerate
endmodule
