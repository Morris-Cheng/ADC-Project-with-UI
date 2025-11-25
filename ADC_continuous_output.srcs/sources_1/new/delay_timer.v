`timescale 1ns / 1ps

module delay_timer #(
        parameter DELAY_PERIOD = 0,
        parameter CYCLE_TIME   = 10,  //time required for each clock complete cycle
        parameter ROUND_MODE   = 0    //rounding mode: 0 to round down (set as default), 1 to round up
    )(
        input  wire clk,
        input  wire enable,
        output wire done
    );
    
    reg done_reg = 0;
    reg previous_enable = 0;
    wire enable_rising_edge;
    
    generate
        if(DELAY_PERIOD == 0 || (ROUND_MODE == 0 && DELAY_PERIOD / CYCLE_TIME == 0)) begin : zero_delay_block
            always @(posedge clk) begin
                if(enable_rising_edge) begin
                    done_reg <= 1;
                end
                else begin
                    done_reg <= 0;
                end
                previous_enable <= enable;
            end
            
            assign enable_rising_edge = enable & ~previous_enable;
        end
        else begin : delay_block
            //calculate the number of cycles needed to reach the desired delay time
            localparam DELAY_CYCLE = (ROUND_MODE == 0) ? (DELAY_PERIOD / CYCLE_TIME) : 
                                                         ((DELAY_PERIOD + CYCLE_TIME - 1) / CYCLE_TIME);
            reg [$clog2(DELAY_CYCLE + 1) - 1 : 0] delay_counter = 0;
            
            always @(posedge clk) begin
                done_reg <= 0;
                
                if (enable_rising_edge) begin
                    delay_counter <= DELAY_CYCLE;
                    done_reg <= 0;
                end
                else if (delay_counter > 1) begin
                    delay_counter <= delay_counter - 1;
                end
                else if (delay_counter == 1) begin
                    delay_counter <= 0;
                    done_reg <= 1;
                end
                else begin
                    delay_counter <= 0;
                end
                
                previous_enable <= enable;
            end
            
            assign enable_rising_edge = enable & ~previous_enable;
        end
        assign done = done_reg;
    endgenerate
endmodule
