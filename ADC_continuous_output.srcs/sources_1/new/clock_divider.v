`timescale 1ns / 1ps

module clock_divider #(
        parameter CLOCK_CYCLE_TIME = 0,
        parameter NEW_CLOCK_CYCLE_TIME = 0,
        parameter IDLE_STATE = 0,
        parameter ROUND_MODE = 0
    )(
        input  wire clk,
        input  wire enable,
        output wire divided_clk_out
    );
    
    localparam CLOCK_DIVIDER_CYCLE = (ROUND_MODE == 0) ? ((NEW_CLOCK_CYCLE_TIME / 2) / CLOCK_CYCLE_TIME) :
                                                        (((NEW_CLOCK_CYCLE_TIME / 2) + CLOCK_CYCLE_TIME - 1) / CLOCK_CYCLE_TIME);
    
    reg divided_clk_reg = IDLE_STATE;
    reg [$clog2(CLOCK_DIVIDER_CYCLE + 1) - 1 : 0] clock_divider_counter = 0;
    
    always @(posedge clk) begin : divider_counter_block
        if(enable) begin
            if(clock_divider_counter >= CLOCK_DIVIDER_CYCLE || clock_divider_counter == 0) begin 
                clock_divider_counter <= 1;
                divided_clk_reg <= ~divided_clk_reg;
            end
            else begin
                clock_divider_counter <= clock_divider_counter + 1;
            end
        end
        else begin
            divided_clk_reg <= IDLE_STATE;
            clock_divider_counter <= 0;
        end
    end
    
    assign divided_clk_out = divided_clk_reg;
endmodule
