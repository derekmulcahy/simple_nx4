`timescale 1ns / 1ps

// http://www.ti.com/lit/ds/symlink/tlc5941.pdf

module pixeldriver(
    input  clock,
    output led_sclk,
    output [6:1] led_l_sin,
    output [6:1] led_r_sin,
    output led_cal_sin,
    output led_mode,
    output led_blank,
    output reg led_xlat = 0,
    output led_gsclk
  );

	// 16 x 12 bit words per driver (3 drivers in series, each 16ch; one R,G,B),
  // so 16*12*3=576 bits per 16-wide column (two columns in parallel)

	// if led_mode=1, you're writing dot correction data, 96 bits (6 bits per pixel bigt endian).
  // If Mode=0, you're sending 12 bits per pixel greyscale
	// blanking 0=unblanked, we have to clock a 1 every 4096 greyscale_clocks
	// gsclk is reference clock for pwm grayscale

	reg [5:0]  pixel_count    = 0;	   // 16 pixels per row
	reg [5:0]  bit_count     = 0;      // 36 bits per pixel
	reg [2:0]  row_count     = 0;      // 6 rows per frame
  reg [2:0]  gsclk_counter = {3{1}}; // Clock counter for gsclk
	reg [11:0] gsclk_count   = 0;      // gsclk counter for blanking
  reg [2:0]  sclk_counter  = {3{1}}; // Clock counter for gsclk
  reg sclk_stopped = 0;

  wire [35:0] pixel;

  assign led_mode     = 0;
  assign led_sclk     = sclk_counter[2];
  assign sclk_strobe  = sclk_counter[2:0] == 0;
  assign led_gsclk    = gsclk_counter[2];
  assign gsclk_strobe = gsclk_counter[2:0] == 0;
	assign led_blank    = gsclk_count == 0;
  assign pixel        = 36'h0000000C0;
  assign led_l_sin    = {6{pixel[bit_count]}};
  assign led_r_sin    = {6{pixel[bit_count]}};
  assign led_cal_sin  = 0;
  // assign led_xlat     = pixel_count == 0 && bit_count == 0;

	always @(posedge clock)
  begin
    gsclk_counter <= gsclk_counter + 1;
    if (gsclk_strobe) begin
	    gsclk_count <= gsclk_count + 1;
    end
	end

	always @(posedge clock)
	begin
    led_xlat <= 0;
    if (!sclk_stopped) begin
      sclk_counter <= sclk_counter + 1;
    end
    if (led_blank) begin
      sclk_stopped <= 0;
    end
    if (sclk_strobe) begin
      if (bit_count == 35) begin
        bit_count <= 0;
        if (pixel_count == 15) begin
          pixel_count <= 0;
          led_xlat <= 1;
          sclk_stopped <= 1;
          if (row_count == 5) begin
            row_count   <= 0;
          end else begin
            row_count <= row_count + 1;
          end
        end else begin
          pixel_count <= pixel_count + 1;
        end
      end else begin
        bit_count <= bit_count + 1;
      end
    end
  end

endmodule