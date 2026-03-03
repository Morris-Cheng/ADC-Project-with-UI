`timescale 1ns / 1ps

module adc#(
        parameter N = 0,                //ADC resolution
        
        //timing specifications, refer to ADC datasheet
        parameter t_CONV                = 0,    //units: ns
        parameter t_EN                  = 0,
        parameter CLK_PERIOD            = 0
    )(
        input  wire           clk,
        input  wire           locked,
        input  wire           sclk_clk,
        input  wire           adc_enable,   //adc enable signal
        input  wire           data_input,   //data input bus
        input  wire           reset,
        output wire           cnv_out,      //cnv signal output bus
        output wire           sclk_out,     //sclk signal output bus
        output reg  [N-1:0]   data_output,  //data output bus
        output wire           busy_out      //busy indicator
    );
    
    localparam N_bit = N - 1;
    reg  busy = 0;
    reg  [$clog2(N_bit + 1) : 0] current_bit = 0;
    
    reg  cnv_reg = 0;
    wire conv_delay_done;
    delay_timer #(
        .CLOCK_CYCLE_TIME(CLK_PERIOD),
        .DELAY_TIME(t_CONV - 3*CLK_PERIOD), //delay for 30ns (set to for zero delay)
        .ROUND_MODE(0)                      //round mode: 0 for round down, 1 for round up
    ) conv_delay_timer (                    //name of instance can be changed to any
        .clk(clk),
        .enable(cnv_reg),
        .done(conv_delay_done)
    );
    
    wire enable_delay_done;
    delay_timer #(
        .CLOCK_CYCLE_TIME(CLK_PERIOD),  //using a system clock of 100MHz = clock cycle time of 10ns
        .DELAY_TIME(t_EN),              //delay for 30ns (set to for zero delay)
        .ROUND_MODE(0)                  //round mode: 0 for round down, 1 for round up
    ) enable_delay_timer (              //name of instance can be changed to any
        .clk(clk),
        .enable(conv_delay_done),
        .done(enable_delay_done)
    );
    
    wire sclk_enable;
    wire sclk_out_unbuffered;
    ODDR #(                             //gated clock
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT(1'b1),                    //initial value
        .SRTYPE("SYNC")
    ) sclk_forward_inst (
        .Q(sclk_out_unbuffered),
        .C(sclk_clk),                   //input clock
        .CE(sclk_enable),               //enable clock
        .D1(1'b1),                      //positive edge signal
        .D2(1'b0),                      //negative edge signal
        .R(1'b0),                       //when true, forces Q to low
        .S(!sclk_enable)                //when true, forces Q to high
    );
    
    OBUF #(                     //output buffer for gated clock
        .DRIVE(12),
        .SLEW("SLOW")
    ) sclk_obuf_inst (
        .O(sclk_out),           //buffered output
        .I(sclk_out_unbuffered) //unbuffered input
    );
    
    //Define all the states
    localparam IDLE      = 0;  //idle state, waiting for conversion start
    localparam CONV      = 1;  //conversion state: waiting for conversion to end to move onto acquisition state
    localparam ACQ_START = 2;  //start of acquisition state, setting up clock signal
    localparam ACQ_WAIT  = 3;  //waiting for acquisition state to end to go back to idle state
    localparam ACQ_END   = 4;  //observing wait time until next acquisition cycle
    reg [2:0] state = 0;
    reg [2:0] next_state = 0;
    
    always @(*) begin : next_state_logic
        next_state = state;
        case(state)
            IDLE: begin
                if(adc_enable & locked) begin  //only start conversion when clock signal is stable
                    next_state = CONV;
                end
            end
            
            CONV: begin
                if(conv_delay_done) begin
                    next_state = ACQ_START;
                end
            end
            
            ACQ_START: begin
                if(enable_delay_done) begin
                    next_state = ACQ_WAIT;
                end
            end
            
            ACQ_WAIT: begin
                if(current_bit >= N) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    reg  sclk_d = 0;
    wire sclk_rising = sclk_clk & !sclk_d;
    
    always @(posedge clk) begin : state_register
        state <= next_state;
        sclk_d <= sclk_clk;
    end
    
    reg [N-1:0] data_buffer;
    
    always @(posedge clk) begin : output_register
        if(reset) begin
            busy <= 0;
            cnv_reg <= 0;
            current_bit <= 0;
            data_buffer <= 0;
            data_output <= 0;
        end
        else begin
            if(state == CONV) begin : CONV_register_update
                busy <= 1;
                cnv_reg <= 1;
            end
            else if(state == ACQ_START) begin
                cnv_reg <= 0;
            end
            else if(state == ACQ_WAIT) begin
                if(sclk_rising) begin
                    current_bit <= current_bit + 1;
                    if(current_bit < N) begin : shift_data
                        data_buffer <= {data_buffer[N-2 : 0], data_input};
                    end
                end
            end
            else if (current_bit >= N) begin
                data_output <= data_buffer;
                current_bit <= 0;
                busy <= 0;
            end
            else begin
                data_output <= data_output;
                current_bit <= current_bit;
                busy <= busy;
            end
        end
    end
    
    assign sclk_enable = state == ACQ_WAIT; //enable sclk clock output at ACQ_WAIT stage
    assign busy_out = busy;
    assign cnv_out = cnv_reg;
endmodule