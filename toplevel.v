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
    output status_red,
    output cpld_p2
  );

  pixeldriver driver (
    .clock(clock),
    .led_sclk(led_sclk),
    .led_l_sin(led_l_sin),
    .led_r_sin(led_r_sin),
    .led_cal_sin(led_cal_sin),
    .led_mode(led_mode),
    .led_blank(led_blank),
    .led_xlat(led_xlat),
    .led_gsclk(led_gsclk)
  );

  reg blank_previous    = 0;
  reg [9:0] blank_count = 0;
  reg [15:0] test_count = 0;

	assign status_yellow = blank_count[9];
	assign status_orange = 0;
  assign status_red    = !led_xerr; // XERR is active low
  assign cpld_p8       = led_blank; // Activate CPLD watchdog
  assign cpld_p2       = test_count[15];

  always @(posedge clock) begin
    test_count <= test_count + 1;
    blank_previous <= led_blank;
    if (!blank_previous && led_blank) begin
        blank_count <= blank_count + 1;
    end
  end
endmodule
