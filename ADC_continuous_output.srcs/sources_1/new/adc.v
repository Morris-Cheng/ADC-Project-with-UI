`timescale 1ns / 1ps

module adc#(
        parameter N = 0,                //ADC resolution
        
        //timing specifications, refer to ADC datasheet
        parameter t_CONV                = 0,    //units: ns
        parameter t_EN                  = 0,
        parameter CLK_PERIOD            = 0
    )(
        input  wire           reset,
        input  wire           clk,
        input  wire           sclk_clk,
        input  wire           locked,
        input  wire           adc_enable,   //adc enable signal
        input  wire           data_input,   //data input bus
        output wire           cnv_out,      //cnv signal output bus
        output wire           sclk_out,     //sclk signal output bus
        output reg  [N-1:0]   data_output,  //data output bus
        output wire           busy_out      //busy indicator
    );
    
    wire fast_reset;
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
        .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .RST_ACTIVE_HIGH(1) // DECIMAL; 0=active low reset, 1=active high reset
    ) fast_domain_reset_inst (
        .dest_arst(fast_reset), // 1-bit output: src_arst asynchronous reset signal synchronized to destination clock domain. This output is registered.
        .dest_clk(clk), // 1-bit input: Destination clock.
        .src_arst(reset) // 1-bit input: Source asynchronous reset signal.
    );
    
    wire slow_reset;
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
        .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .RST_ACTIVE_HIGH(1) // DECIMAL; 0=active low reset, 1=active high reset
    ) slow_domain_reset_inst (
        .dest_arst(slow_reset), // 1-bit output: src_arst asynchronous reset signal synchronized to destination clock domain. This output is registered.
        .dest_clk(sclk_clk), // 1-bit input: Destination clock.
        .src_arst(reset) // 1-bit input: Source asynchronous reset signal.
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
    
    wire SPI_start_slow;    //SPI_start signal from slow domain
    wire SPI_start_fast;    //SPI start signal from fast domain
    xpm_cdc_single #(   //single bit synchronizer for SPI_start signal, from FAST to SLOW clock domain
        .DEST_SYNC_FF(2), // DECIMAL; range: 2-10
        .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        .SRC_INPUT_REG(1) // DECIMAL; 0=do not register input, 1=register input
    ) SPI_start_cdc_single_inst (
        .dest_out(SPI_start_slow), // 1-bit output: src_in synchronized to the destination clock domain. This output is registered.
        .dest_clk(sclk_clk), // 1-bit input: Clock signal for the destination clock domain.
        .src_clk(clk),      // 1-bit input: optional; required when SRC_INPUT_REG = 1
        .src_in(SPI_start_fast) // 1-bit input: Input signal to be synchronized to dest_clk domain.
    );
    
    wire sclk_out_unbuffered;
    ODDR #(                             //gated clock
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT(1'b1),                    //initial value
        .SRTYPE("SYNC")
    ) sclk_forward_inst (
        .Q(sclk_out_unbuffered),
        .C(sclk_clk),                   //input clock
        .CE(SPI_start_slow),            //enable clock
        .D1(1'b1),                      //positive edge signal
        .D2(1'b0),                      //negative edge signal
        .R(1'b0),                       //when true, forces Q to low
        .S(!SPI_start_slow)             //when true, forces Q to high
    );
    
    OBUF #(                     //output buffer for gated clock
        .DRIVE(12),
        .SLEW("SLOW")
    ) sclk_obuf_inst (
        .O(sclk_out),           //buffered output
        .I(sclk_out_unbuffered) //unbuffered input
    );
    
    reg  SPI_stop_slow;
    wire SPI_stop_fast;
    xpm_cdc_pulse #( //pulse transfer for sending SPI_stop signal from SLOW to FAST domain
        .DEST_SYNC_FF(2), // DECIMAL; range: 2-10
        .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
        .REG_OUTPUT(1), // DECIMAL; 0=disable registered output, 1=enable registered output
        .RST_USED(1), // DECIMAL; 0=no reset, 1=implement reset
        .SIM_ASSERT_CHK(0) // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    ) SPI_stop_cdc_pulse_inst (
        .dest_pulse(SPI_stop_fast), // 1-bit output: Outputs a pulse the size of one dest_clk period
        .dest_clk(clk), // 1-bit input: Destination clock.
        .dest_rst(fast_reset), //FIX: add macro for reset
        .src_clk(sclk_clk), // 1-bit input: Source clock.
        .src_pulse(SPI_stop_slow), // 1-bit input: Rising edge of this signal initiates a pulse transfer to the destination clock domain.
        .src_rst(slow_reset) //FIX: add macro for reset
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
                if(SPI_stop_fast) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    reg [N-1:0] data_buffer;
    always @(posedge clk) begin : delay_control //runs on 200MHz main clock
        if(fast_reset) begin //FIX: add macro for reset signal
            busy <= 0;
            cnv_reg <= 0;
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
            else if (SPI_stop_fast) begin
                data_output <= data_buffer;
                busy <= 0;
            end
            else begin
                data_output <= data_output;
                busy <= busy;
            end
        end
        
        state <= next_state;
    end
    
    always @(posedge sclk_clk) begin : SPI_communication //runs on sclk_clk slower clock
        if(slow_reset) begin //FIX: add reset macro for synchronous reset
            current_bit <= 0;
            data_buffer <= 0;
        end
        else begin
            if(SPI_start_slow) begin
                    current_bit <= current_bit + 1;
                    if(current_bit < N) begin : shift_data
                        data_buffer <= {data_buffer[N-2 : 0], data_input};
                    end
            end
            else if(current_bit >= N) begin
                current_bit <= 0;
            end
            else begin
                current_bit <= current_bit;
            end
        end
        
        if(current_bit >=  N) begin  //SPI stop signal for slow clock domain, true when current bit reaches max value
            SPI_stop_slow <= 1;
        end
        else begin
            SPI_stop_slow <= 0;
        end
    end
    
    assign SPI_start_fast = state == ACQ_WAIT; //SPI start signal for slow clock domain, true when during ACQ_WAIT stage
    assign busy_out = busy;
    assign cnv_out = cnv_reg;
endmodule