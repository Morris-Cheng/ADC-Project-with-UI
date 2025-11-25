`timescale 1ns / 1ps
// ============================================================================
//         A Standard, Verified, and Robust UART Transmitter Module
// ============================================================================

//testing purposes only...

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000, // 系統時脈頻率 (Hz) test test
    parameter BAUD_RATE = 115_200      // 目標鮑率 (Baud)
) (
    input  wire        clk,      // 系統時脈
    input  wire        i_send,   // 發送觸發信號 (拉高一拍啟動)
    input  wire [7:0]  i_data,   // 要發送的 8-bit 資料
    output reg         o_tx,     // UART TX 輸出腳位
    output wire        o_busy    // 忙碌旗標 (正在發送時為 1)
);

    localparam DIVIDER = CLK_FREQ / BAUD_RATE;
    
    localparam S_IDLE      = 3'd0;
    localparam S_START_BIT = 3'd1;
    localparam S_DATA_BITS = 3'd2;
    localparam S_STOP_BIT  = 3'd3;

    reg [2:0]  r_state        = S_IDLE;
    reg [15:0] r_clk_counter  = 0;
    reg [2:0]  r_bit_index    = 0;
    reg [7:0]  r_tx_data      = 0;

    assign o_busy = (r_state != S_IDLE);

    always @(posedge clk) begin
        case (r_state)
            S_IDLE: begin
                o_tx <= 1'b1;
                r_clk_counter <= 0;
                r_bit_index <= 0;
                if (i_send) begin
                    r_tx_data <= i_data;
                    r_state   <= S_START_BIT;
                end
            end
            S_START_BIT: begin
                o_tx <= 1'b0;
                if (r_clk_counter < DIVIDER - 1) begin
                    r_clk_counter <= r_clk_counter + 1;
                end else begin
                    r_clk_counter <= 0;
                    r_state <= S_DATA_BITS;
                end
            end
            S_DATA_BITS: begin
                o_tx <= r_tx_data[r_bit_index];
                if (r_clk_counter < DIVIDER - 1) begin
                    r_clk_counter <= r_clk_counter + 1;
                end else begin
                    r_clk_counter <= 0;
                    if (r_bit_index < 7) begin
                        r_bit_index <= r_bit_index + 1;
                    end else begin
                        r_bit_index <= 0;
                        r_state <= S_STOP_BIT;
                    end
                end
            end
            S_STOP_BIT: begin
                o_tx <= 1'b1;
                if (r_clk_counter < DIVIDER - 1) begin
                    r_clk_counter <= r_clk_counter + 1;
                end else begin
                    r_clk_counter <= 0;
                    r_state <= S_IDLE;
                end
            end
            default:
                r_state <= S_IDLE;
        endcase
    end
endmodule