`timescale 1ns / 1ps

module adc#(
        parameter N = 0,                //ADC resolution
        
        //timing specifications, refer to ADC datasheet
        parameter t_CYC         = 0,    //units: us
        parameter t_CONV        = 0,    //units: us
        parameter t_CONV_SCALE  = 0,    //sclae factor for conversion time
        parameter t_EN          = 0,
        parameter SCLK_PERIOD   = 0,    //units: ns 60
        
        parameter CYCLE_TIME = 10       //time required for each clock complete cycle
    )(
        input  wire           clk,
        input  wire           adc_enable,   //adc enable signal
        input  wire           data_input,   //data input bus
        input  wire           reset,
        input  wire           continuous,   //continuous mode to stream out adc data
        output wire           cnv_out,      //cnv signal output bus
        output wire           sclk_out,     //sclk signal output bus
        output reg  [N-1:0]   data_output,  //data output bus
        output wire           busy_out      //busy indicator
    );
    
    //converting all time related variables to number of cycles
    localparam us_2_ns = 1000;
    localparam t_CYC_ns = t_CYC * us_2_ns;
    localparam t_CONV_ns = t_CONV * us_2_ns / t_CONV_SCALE;
    localparam N_bit = N - 1;
    
    reg [1:0] state = 0;
    reg [1:0] next_state = 0;
    
    //Define all the states
    reg [1:0] IDLE      = 0;  //idle state, waiting for conversion start
    reg [1:0] CONV      = 1;  //conversion state: waiting for conversion to end to move onto acquisition state
    reg [1:0] ACQ_START = 2;  //start of acquisition state, setting up clock signal
    reg [1:0] ACQ_WAIT  = 3;  //waiting for acquisition state to end to go back to idle state
    
    
    reg  continuous_enable = 0;
    reg  conv_ready_d = 0;
    wire conv_ready;
    wire conv_ready_rising_edge = conv_ready && ~conv_ready_d;
    clock_divider #(
        .CLOCK_PERIOD(t_CYC_ns),
        .CYCLE_TIME(10),
        .MODE(1),
        .ROUND_MODE(1)
    ) conv_clk(
        .clk(clk),
        .enable(continuous_enable),
        .divided_clk_out(conv_ready)
    );
    
    reg  sclk_d = 0;
    reg  sclk_enable = 0;
    wire sclk_reg;
    wire sclk_rising_edge = sclk_reg & ~sclk_d;
    clock_divider #(
        .CLOCK_PERIOD(SCLK_PERIOD),
        .CYCLE_TIME(10),
        .MODE(0),       //sets the idle state signal to low, since t_EN has already accounted for the data valid period, no need to create falling edge on sclk line
        .ROUND_MODE(1)  //sets round mode to round up
    ) serial_clk(
        .clk(clk),
        .enable(sclk_enable),
        .divided_clk_out(sclk_reg)
    );
    
    reg  cnv_reg = 0;
    reg  cnv_d = 0;
    wire cnv_rising_edge = cnv_reg & ~cnv_d;
    wire conv_delay_done;
    delay_timer #(
        .DELAY_PERIOD(t_CONV_ns - CYCLE_TIME), //used to account for the additional clock cycle delay from latching registers, there is still 10ns extra just to be safe
        .CYCLE_TIME(10),
        .ROUND_MODE(0)
    ) conv_delay_timer(
        .clk(clk),
        .enable(cnv_rising_edge), //enables delay timer when cnv rising edge is detected
        .done(conv_delay_done)
    );
    
    reg enable_delay_trigger = 0;
    wire enable_delay_done;
    delay_timer #(
        .DELAY_PERIOD(t_EN),
        .CYCLE_TIME(10),
        .ROUND_MODE(0)
    ) enable_delay_timer(
        .clk(clk),
        .enable(conv_delay_done),  //enables delay timer when conversion is over
        .done(enable_delay_done)
    );
    
    reg  busy = 0;
    reg  [$clog2(N_bit + 1) : 0] current_bit = 0;
    reg  adc_enable_d = 0;
    wire adc_enable_rising_edge = adc_enable & ~adc_enable_d;
    
    assign busy_out = busy;
    assign cnv_out = cnv_reg;
    assign sclk_out = sclk_reg;
    
    always @(posedge clk) begin : state_register
        state <= next_state;
        adc_enable_d <= adc_enable;
        cnv_d <= cnv_reg;
        sclk_d <= sclk_reg;
    end
    
    always @(*) begin : next_state_logic
        next_state = state;
        case(state)
            IDLE: begin
                if((conv_ready_rising_edge && continuous) || (adc_enable_rising_edge && ~continuous)) begin
                    next_state = CONV;
                end
                else begin
                    next_state = next_state;
                end
            end
            
            CONV: begin
                if(conv_delay_done) begin
                    next_state = ACQ_START;
                end
                else begin
                    next_state = next_state;
                end
            end
            
            ACQ_START: begin
                if(enable_delay_done) begin
                    next_state = ACQ_WAIT;
                end
                else begin
                    next_state = next_state;
                end
            end
            
            ACQ_WAIT: begin
                if(current_bit >= N) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = next_state;
                end
            end
            
            default: begin
                next_state = next_state;
            end
        endcase
    end
    
    reg [N-1:0] data_buffer;
    
    always @(posedge clk) begin : output_register
        if(reset) begin
            busy <= 0;
            cnv_reg <= 0;
            sclk_enable <= 0;
            current_bit <= 0;
            data_buffer <= 0;
            data_output = 0;
        end
        else begin
            if(state == CONV) begin : CONV_register_update
                busy <= 1;
                cnv_reg <= 1;
                if(continuous) begin
                    continuous_enable <= 1;
                end
                else begin
                    continuous_enable <= 0;
                end
            end
            else if(state == ACQ_START) begin
                cnv_reg <= 0;
            end
            else if(state == ACQ_WAIT) begin
                sclk_enable <= 1;
                if(sclk_rising_edge) begin
                    current_bit <= current_bit + 1;
                    if(current_bit < N) begin : shift_data
                        data_buffer <= {data_buffer[N-1 : 0], data_input};
                    end
                end
            end
            else if (current_bit >= N) begin
                data_output <= data_buffer;
                current_bit <= 0;
                sclk_enable <= 0;
                busy <= 0;
            end
            else begin
                data_output <= data_output;
                current_bit <= current_bit;
                sclk_enable <= sclk_enable;
                busy <= busy;
            end
        end
    end
endmodule