`timescale 1ns / 1ps
module toplevel(
    input clock,
    output led_sclk,
    output [6:1] led_l_sin,
    output [6:1] led_r_sin,
    output led_cal_sin,
    input led_xerr,
    output led_mode,
    output led_blank,
    output led_xlat,
    output led_gsclk,	 
    output status_yellow,
    output status_orange,
    output status_red
  );

	reg pclock = 0;
  reg gclock = 0;
	wire [7:0] frame_count;	 

  pixeldriver driver (
    .led_sclk(led_sclk), 
    .led_l_sin(led_l_sin), 
    .led_r_sin(led_r_sin), 
    .led_cal_sin(led_cal_sin), 
    .led_mode(led_mode), 
    .led_blank(led_blank), 
    .led_xlat(led_xlat), 
    .led_gsclk(led_gsclk), 
    .pixel_clock(pclock), 
    .grayscale_clock(gclock),	 
    .frame_count(frame_count)
  );

	reg [24:0] blink_count = 0;
	
	assign status_yellow = frame_count[7];
	assign status_orange = blink_count[24];
  assign status_red    = led_xerr;
	
	always @(posedge clock)
	begin
    blink_count <= blink_count+1;
		pclock      <= blink_count[5]; // pixel clock is /(1<<5)
		gclock      <= blink_count[2]; // greyscale clock is /(1<<2)
	end

endmodule
