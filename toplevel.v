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
    output cpld_p8,
    output status_yellow,
    output status_orange,
    output status_red
  );

	wire  frame_pulse;

  pixeldriver driver (
    .clock(clock),
    .led_sclk(led_sclk),
    .led_l_sin(led_l_sin),
    .led_r_sin(led_r_sin),
    .led_cal_sin(led_cal_sin),
    .led_mode(led_mode),
    .led_blank(led_blank),
    .led_xlat(led_xlat),
    .led_gsclk(led_gsclk),
    .frame_pulse(frame_pulse)
  );

	assign status_yellow = frame_pulse;
	assign status_orange = 0;
  assign status_red    = led_xerr;
  assign cpld_p8       = led_blank;
endmodule
