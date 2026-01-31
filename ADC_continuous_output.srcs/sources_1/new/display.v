module display #(
    parameter N = 0
)(
    input  wire       clk,
    input  wire [N-1:0] value,
    output reg  [7:0]  seg,
    output reg  [3:0]  an
);

    reg [18:0] digit_counter = 0;
    reg [1:0]  cur_digit = 0;
    reg [3:0]  digits [3:0];
    integer    temp;

    // Slow down digit refresh for flicker-free display (~1ms)
    always @(posedge clk) begin
        if (digit_counter >= 19'd100_000) begin // (約1ms/輪，視你FPGA主頻可再微調)
            cur_digit    <= cur_digit + 1;
            digit_counter <= 0;
        end
        else
            digit_counter <= digit_counter + 1;
    end

    // 十進制拆字元（只處理前四位）
    always @(*) begin
        temp = value;
        digits[0] = temp % 10;   temp = temp / 10;
        digits[1] = temp % 10;   temp = temp / 10;
        digits[2] = temp % 10;   temp = temp / 10;
        digits[3] = temp % 10;
    end

    // Multiplexing to activate the current digit
    always @(*) begin
        an = 4'b1111;
        case (cur_digit)
            2'd0: an = 4'b1110;
            2'd1: an = 4'b1101;
            2'd2: an = 4'b1011;
            2'd3: an = 4'b0111;
        endcase
    end

    // 7SEG解碼 (共陰極適用, 共陽需移除~或改反向)
    always @(*) begin
        if(cur_digit == 3) begin
            case (digits[cur_digit])
                4'd0: seg = ~8'b10111111;
                4'd1: seg = ~8'b10000110;
                4'd2: seg = ~8'b11011011;
                4'd3: seg = ~8'b11001111;
                4'd4: seg = ~8'b11100110;
                4'd5: seg = ~8'b11101101;
                4'd6: seg = ~8'b11111101;
                4'd7: seg = ~8'b10000111;
                4'd8: seg = ~8'b11111111;
                4'd9: seg = ~8'b11101111;
                default: seg = 8'hFF;
            endcase
        end
        else begin
            case (digits[cur_digit])
                4'd0: seg = ~8'b00111111;
                4'd1: seg = ~8'b00000110;
                4'd2: seg = ~8'b01011011;
                4'd3: seg = ~8'b01001111;
                4'd4: seg = ~8'b01100110;
                4'd5: seg = ~8'b01101101;
                4'd6: seg = ~8'b01111101;
                4'd7: seg = ~8'b00000111;
                4'd8: seg = ~8'b01111111;
                4'd9: seg = ~8'b01101111;
                default: seg = 8'hFF;
            endcase
        end
        
    end
endmodule
