`timescale 1ns / 1ps

module fifo #(
        parameter BUFFER_WIDTH = 0,        //number of data FIFO can hold
        parameter ADDR_WIDTH = 0           //bit size of each index
    )(
        input  wire clk,
        input  wire reset,
        
        input  wire wr_signal,
        input  wire rd_signal,
        
        input  wire [ADDR_WIDTH-1 : 0] write_data,
        output reg  [ADDR_WIDTH-1 : 0] read_data,
        
        output wire empty_out,
        output wire full_out
    );
    
    localparam BW = $clog2(BUFFER_WIDTH);
    
    //read and write pointers
    reg [BW : 0] wr_pointer = 0; //last bit as wrap bit
    reg [BW : 0] rd_pointer = 0;
    
    //data buffer used to store values
    reg [ADDR_WIDTH-1 : 0] data_buffer [BUFFER_WIDTH - 1 : 0];
    
    assign empty = (wr_pointer == rd_pointer);
    assign empty_out = empty;
    
    wire full = (wr_pointer[BW] != rd_pointer[BW]) && (wr_pointer[BW-1:0] == rd_pointer[BW-1:0]);

    wire [BW:0] wr_pointer_next = wr_pointer + wr_signal;
    assign full_out = ((wr_pointer_next[BW] != rd_pointer[BW]) && (wr_pointer_next[BW-1:0] == rd_pointer[BW-1:0]));
    
    always @(posedge clk) begin : write_data_block
        if(reset) begin
            wr_pointer <= 0;
        end
        //writes only when write signal is true and not full
        else if(wr_signal && ~full) begin
            data_buffer[wr_pointer[BW - 1: 0]] <= write_data;
            wr_pointer <= wr_pointer_next;
        end
    end
    
    always @(posedge clk) begin : read_data_block
        if(reset) begin
            rd_pointer <= 0;
        end
        else if(rd_signal && ~empty) begin
            rd_pointer <= rd_pointer + 1;
            read_data <= data_buffer[rd_pointer[BW - 1: 0]];
        end
    end
endmodule
